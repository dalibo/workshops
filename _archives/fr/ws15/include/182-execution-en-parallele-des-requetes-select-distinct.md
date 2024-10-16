<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/E1mHlhP-0005P0-8X@gemulon.postgresql.org

-->

<div class="slide-content">

* Parallélisation des clauses `DISTINCT` en deux phases :
  + première phase de déduplication (parallélisée)
  + seconde phase d'agrégation et de déduplication des résultats de la
    première phase

</div>

<div class="notes">

Depuis la version 9.6, les agrégations peuvent être parallélisées par
PostgreSQL. Cette fonctionnalité ne pouvait cependant pas être utilisée pour
la clause `DISTINCT`.

Voici un jeu d'essais qui permet de mettre en évidence le comportement de
PostgreSQL :

```sql
CREATE TABLE test_distinct(i int);
INSERT INTO test_distinct SELECT (random()*10000)::int FROM generate_series(1, 1000000);
ANALYZE test_distinct;
```

Le plan de la requête suivante en version 14 est alors :

```sql
EXPLAIN (ANALYZE) SELECT DISTINCT i FROM test_distinct;
```
```text
                                   QUERY PLAN
-------------------------------------------------------------------------------------
 HashAggregate  (cost=16925.00..17024.68 rows=9968 width=4)
                (actual time=1001.069..1006.089 rows=10001 loops=1)
   Group Key: i
   Batches: 1  Memory Usage: 913kB
   ->  Seq Scan on test_distinct  (cost=0.00..14425.00 rows=1000000 width=4)
                                  (actual time=0.049..278.769 rows=1000000 loops=1)
 Planning Time: 0.260 ms
 Execution Time: 1007.694 ms
(6 rows)
```

La version 15 découpe la déduplication en deux phases. La première phase, qui
peut être parallélisée, permet de rendre les lignes distinctes avec un `sort
unique` ou un `hashaggregate`. Le résultat produit par les processus
parallélisés sont combinés et rendu distinct a nouveau dans une seconde phase.

```text
                                            QUERY PLAN
-----------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=12783.76..12883.78 rows=10002 width=4)
                (actual time=346.312..350.351 rows=10001 loops=1)
   Group Key: i
   Batches: 1  Memory Usage: 913kB
   ->  Gather  (cost=10633.33..12733.75 rows=20004 width=4)
               (actual time=316.791..328.705 rows=30003 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  HashAggregate  (cost=9633.33..9733.35 rows=10002 width=4)
                            (actual time=308.740..312.559 rows=10001 loops=3)
               Group Key: i
               Batches: 1  Memory Usage: 913kB
               Worker 0:  Batches: 1  Memory Usage: 913kB
               Worker 1:  Batches: 1  Memory Usage: 913kB
               ->  Parallel Seq Scan on test_distinct  (cost=0.00..8591.67 rows=416667 width=4)
                                                       (actual time=0.033..79.344 rows=333333 loops=3)
 Planning Time: 0.222 ms
 Execution Time: 351.886 ms
(14 rows)
```

La méthode employée par PostgreSQL pour rendre les lignes distinctes dépend de
la répartition des données.

Par exemple, en régénérant les données avec 1000 valeurs différentes au lieu de 10000 :

```sql
TRUNCATE test_distinct;
INSERT INTO test_distinct SELECT (random()*1000)::int FROM generate_series(1, 1000000);
ANALYSE test_distinct;
```

On voit que PostgreSQL utilise un distinct pour la seconde phase :

```text
[local]:5437 postgres@postgres=# EXPLAIN (ANALYZE) SELECT DISTINCT i FROM test_distinct ;
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------------------
 Unique  (cost=10953.33..10963.34 rows=1001 width=4)
         (actual time=280.039..284.113 rows=1001 loops=1)
   ->  Sort  (cost=10953.33..10958.33 rows=2002 width=4)
             (actual time=280.035..283.177 rows=3003 loops=1)
         Sort Key: i
         Sort Method: quicksort  Memory: 97kB
         ->  Gather  (cost=10633.33..10843.54 rows=2002 width=4)
                     (actual time=277.377..281.096 rows=3003 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               ->  HashAggregate  (cost=9633.33..9643.34 rows=1001 width=4)
                                  (actual time=270.683..271.037 rows=1001 loops=3)
                     Group Key: i
                     Batches: 1  Memory Usage: 129kB
                     Worker 0:  Batches: 1  Memory Usage: 129kB
                     Worker 1:  Batches: 1  Memory Usage: 129kB
                     ->  Parallel Seq Scan on test_distinct  (cost=0.00..8591.67 rows=416667 width=4)
                                                             (actual time=0.036..89.688 rows=333333 loops=3)
 Planning Time: 0.201 ms
 Execution Time: 284.301 ms
(15 rows)
```

</div>
