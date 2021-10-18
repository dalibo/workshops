<!--- 

### Tri incrémental    

-->

<div class="slide-content">
  * Nouveau nœud Incremental Sorting
  * Profiter des index déjà présents
  * Trier plus rapidement
    * notamment en présence d'un LIMIT
</div>

<div class="notes">

PostgreSQL est capable d'utiliser un index pour trier les données. Cependant,
dans certains cas, il ne sait pas utiliser l'index alors qu'il pourrait le
faire.  Prenons un exemple.

Voici un jeu de données contenant une table à trois colonnes, et un index sur
une colonne :

```
DROP TABLE IF exists t1;
CREATE TABLE t1 (c1 integer, c2 integer, c3 integer);
INSERT INTO t1 SELECT i, i+1, i+2 FROM generate_series(1, 10000000) AS i;
CREATE INDEX ON t1(c2);
ANALYZE t1;
```

PostgreSQL sait utiliser l'index pour trier les données. Par exemple, voici le
plan d'exécution pour un tri sur la colonne `c2` (colonne indexée au niveau de
l'index `t1_c2_idx`) :

```
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM t1 ORDER BY c2;

                               QUERY PLAN
---------------------------------------------------------------------------------
 Index Scan using t1_c2_idx on t1  (cost=0.43..313749.06 rows=10000175 width=12)
                             (actual time=0.016..1271.115 rows=10000000 loops=1)
   Buffers: shared hit=81380
 Planning Time: 0.173 ms
 Execution Time: 1611.868 ms
(4 rows)
```

En revanche, si le tri concerne les colonnes c2 et c3, les versions 12 et
antérieures ne savent pas utiliser l'index, comme le montre ce
plan d'exécution :

```
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM t1 ORDER BY c2, c3;

                                QUERY PLAN
-------------------------------------------------------------------------------
 Gather Merge  (cost=697287.64..1669594.86 rows=8333480 width=12)
          (actual time=1331.307..3262.511 rows=10000000 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=54149, temp read=55068 written=55246
  ->  Sort  (cost=696287.62..706704.47 rows=4166740 width=12)
       (actual time=1326.112..1766.809 rows=3333333 loops=3)
       Sort Key: c2, c3
       Sort Method: external merge  Disk: 61888kB
       Worker 0:  Sort Method: external merge  Disk: 61392kB
       Worker 1:  Sort Method: external merge  Disk: 92168kB
       Buffers: shared hit=54149, temp read=55068 written=55246
       ->  Parallel Seq Scan on t1  (cost=0.00..95722.40 rows=4166740 width=12)
                              (actual time=0.015..337.901 rows=3333333 loops=3)
             Buffers: shared hit=54055
 Planning Time: 0.068 ms
 Execution Time: 3716.541 ms
(14 rows)
```

Comme PostgreSQL ne sait pas utiliser un index pour réaliser ce tri, il passe
par un parcours de table (parallélisé dans le cas présent), puis effectue le
tri, ce qui prend beaucoup de temps. La requête a plus que doublé en durée
d'exécution.

La version 13 est beaucoup plus maligne à cet égard. Elle est capable
d'utiliser l'index pour faire un premier tri des données (sur la colonne c2
d'après notre exemple), puis elle complète le tri par rapport à la
colonne c3 :

```
                                      QUERY PLAN
-------------------------------------------------------------------------------
Incremental Sort  (cost=0.48..763746.44 rows=10000000 width=12)
           (actual time=0.082..2427.099 rows=10000000 loops=1)
 Sort Key: c2, c3
 Presorted Key: c2
 Full-sort Groups: 312500  Sort Method: quicksort  
     Average Memory: 26kB  Peak Memory: 26kB
 Buffers: shared hit=81387
 -> Index Scan using t1_c2_idx on t1 (cost=0.43..313746.43 rows=10000000 width=12)
                             (actual time=0.007..1263.517 rows=10000000 loops=1)
       Buffers: shared hit=81380
Planning Time: 0.059 ms
Execution Time: 2766.530 ms
(9 rows)
```

La requête en version 12 prenait 3,7 secondes en parallélisant sur trois
processus. La version 13 n'en prend que 2,7 secondes, sans parallélisation. On
remarque un nouveau type de nœud, le « Incremental Sort »,
qui s'occupe de re-trier les données après un renvoi de données partiellement
triées, grâce au parcours d'index.

L'apport en performance est déjà très intéressant, d'autant qu'il réduit à la
fois le temps d'exécution de la requête, mais aussi la charge induite sur
l'ensemble du système. Cet apport en performance devient remarquable
si on utilise une clause `LIMIT`. Voici le résultat en version 12 :

```
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM t1 ORDER BY c2, c3 LIMIT 10;

                                    QUERY PLAN
----------------------------------------------------------------------------------------
 Limit  (cost=186764.17..186765.34 rows=10 width=12)
      (actual time=718.576..724.791 rows=10 loops=1)
   Buffers: shared hit=54149
   ->  Gather Merge  (cost=186764.17..1159071.39 rows=8333480 width=12)
                         (actual time=718.575..724.788 rows=10 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=54149
         ->  Sort  (cost=185764.15..196181.00 rows=4166740 width=12)
                      (actual time=716.606..716.608 rows=10 loops=3)
               Sort Key: c2, c3
               Sort Method: top-N heapsort  Memory: 25kB
               Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
               Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
               Buffers: shared hit=54149
               ->  Parallel Seq Scan on t1  (cost=0.00..95722.40 rows=4166740 width=12)
                                      (actual time=0.010..347.085 rows=3333333 loops=3)
                     Buffers: shared hit=54055
 Planning Time: 0.044 ms
 Execution Time: 724.818 ms
(16 rows)
```

Et celui en version 13 :
```
                                   QUERY PLAN
----------------------------------------------------------------------------------------------
 Limit  (cost=0.48..1.24 rows=10 width=12) (actual time=0.027..0.029 rows=10 loops=1)
   Buffers: shared hit=4
   ->  Incremental Sort  (cost=0.48..763746.44 rows=10000000 width=12)
                            (actual time=0.027..0.027 rows=10 loops=1)
         Sort Key: c2, c3
         Presorted Key: c2
         Full-sort Groups: 1  Sort Method: quicksort  Average Memory: 25kB  Peak Memory: 25kB
         Buffers: shared hit=4
         ->  Index Scan using t1_c2_idx on t1  (cost=0.43..313746.43 rows=10000000 width=12)
                                                  (actual time=0.012..0.014 rows=11 loops=1)
               Buffers: shared hit=4
 Planning Time: 0.052 ms
 Execution Time: 0.038 ms
(11 rows)
```

La requête passe donc de 724 ms avec parallélisation, à 0,029 ms sans
parallélisation.

</div>
