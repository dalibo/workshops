<!--
Les commits sur ce sujet sont :
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=11c2d6fdf

-->

<div class="slide-content">

  * Nouveau nœud _Parallel Hash Full Join_
    + parallélisation des `FULL OUTER JOIN`
    + parallélisation des `RIGHT OUTER JOIN`
  * Jointure par hachage dans ces deux cas

</div>

<div class="notes">

Voici un exemple :

```
CREATE TABLE t1(c1 integer, c2 text);
INSERT INTO t1 SELECT i, 'Ligne '||i FROM generate_series(1, 1_000_000) i;

EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
  SELECT COUNT(*) FROM t1 a FULL OUTER JOIN t1 b USING (c1);

                                      QUERY PLAN
--------------------------------------------------------------------------------------
 Finalize Aggregate (actual rows=1 loops=1)
   ->  Gather (actual rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate (actual rows=1 loops=3)
               ->  Parallel Hash Full Join (actual rows=333333 loops=3)
                     Hash Cond: (a.c1 = b.c1)
                     ->  Parallel Seq Scan on t1 a (actual rows=333333 loops=3)
                     ->  Parallel Hash (actual rows=333333 loops=3)
                           Buckets: 262144  Batches: 8  Memory Usage: 6976kB
                           ->  Parallel Seq Scan on t1 b (actual rows=333333 loops=3)
 Planning Time: 0.300 ms
 Execution Time: 826.873 ms
(13 rows)

```

Sur les versions précédentes, le plan ressemblait à celui-ci :

```
                            QUERY PLAN                            
------------------------------------------------------------------
 Aggregate (actual rows=1 loops=1)
   ->  Hash Full Join (actual rows=1000000 loops=1)
         Hash Cond: (a.c1 = b.c1)
         ->  Seq Scan on t1 a (actual rows=1000000 loops=1)
         ->  Hash (actual rows=1000000 loops=1)
               Buckets: 262144  Batches: 8  Memory Usage: 6446kB
               ->  Seq Scan on t1 b (actual rows=1000000 loops=1)
 Planning Time: 1.380 ms
 Execution Time: 1801.073 ms
(9 rows)
```

Sur cet exemple basique, nous divisons par deux le temps d'exécution, la table
de test étant très peu volumineuse.

</div>
