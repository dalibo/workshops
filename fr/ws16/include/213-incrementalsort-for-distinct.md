<!--
Les commits sur ce sujet sont :
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a9c70b46dbe152e094f137f7e6ba9cd3a638ee25

-->

<div class="slide-content">

  * Nœud _Incremental Sort_ utilisé dans plus de cas
  * Notamment pour `DISTINCT`

</div>

<div class="notes">

Le nœud _Incremental Sort_ a été créé pour la version 13. Lors d'un tri de
plusieurs colonnes, si la première colonne est indexée, PostgreSQL peut utiliser
l'index pour réaliser rapidement un premier tri. Puis il utilise un nœud _Sort_
pour trier sur les colonnes suivantes. Cela ne fonctionnait que pour les clauses
`ORDER BY`.

La version 16 améliore cela en permettant son utilisation dans un plus grand
nombre de cas, voici un exemple avec le cas d'une clause `DISTINCT` :

```
SET max_parallel_workers_per_gather TO 0;
DROP TABLE IF exists t1;
CREATE TABLE t1 (c1 integer, c2 integer);
INSERT INTO t1 SELECT i, i+1 FROM generate_series(1, 1000000) AS i;
VACUUM ANALYZE t1;

EXPLAIN SELECT DISTINCT c1 FROM t1;

                            QUERY PLAN                            
------------------------------------------------------------------
 HashAggregate  (cost=68175.00..85987.50 rows=1000000 width=4)
   Group Key: c1
   Planned Partitions: 16
   ->  Seq Scan on t1  (cost=0.00..14425.00 rows=1000000 width=4)
(4 rows)

CREATE INDEX ON t1(c1);

EXPLAIN SELECT DISTINCT c1 FROM t1;

                            QUERY PLAN
------------------------------------------------------------------
 Unique  (cost=0.42..28480.42 rows=1000000 width=4)
   ->  Index Only Scan using t1_c1_idx on t1
       (cost=0.42..25980.42 rows=1000000 width=4)
(2 rows)

EXPLAIN SELECT DISTINCT c1, c2 FROM t1;

                            QUERY PLAN
--------------------------------------------------------------------
 Unique  (cost=0.47..80408.43 rows=1000000 width=8)
   ->  Incremental Sort  (cost=0.47..75408.43 rows=1000000 width=8)
         Sort Key: c1, c2
         Presorted Key: c1
         ->  Index Scan using t1_c1_idx on t1
             (cost=0.42..30408.42 rows=1000000 width=8)
(5 rows)
```

En version 15, on aurait eu plutôt :

```
EXPLAIN SELECT DISTINCT c1, c2 FROM t1;

                            QUERY PLAN                            
------------------------------------------------------------------
 HashAggregate  (cost=70675.00..88487.50 rows=1000000 width=8)
   Group Key: c1, c2
   Planned Partitions: 16
   ->  Seq Scan on t1  (cost=0.00..14425.00 rows=1000000 width=8)
(4 rows)
```

</div>
