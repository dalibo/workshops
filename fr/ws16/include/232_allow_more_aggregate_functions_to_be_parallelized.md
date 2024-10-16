<!--
Les commits sur ce sujet sont :
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a9c70b46dbe152e094f137f7e6ba9cd3a638ee25

-->

<div class="slide-content">

  * Parallélisation possible de ces deux fonctions d'agrégat
  * Comme d'habitude, un _Partial Aggregate_, suivi d'un _Full Aggregate_

</div>

<div class="notes">

Voici un exemple :

```
CREATE TABLE t1(c1 integer, c2 text);
INSERT INTO t1 SELECT i, 'Ligne '||i FROM generate_series(1, 1_000_000) i;

EXPLAIN (ANALYZE, TIMING OFF) SELECT string_agg(c2,',') FROM t1;

                                         QUERY PLAN
-------------------------------------------------------------------------------
 Finalize Aggregate (actual time=1503.482..1503.671 rows=1 loops=1)
   ->  Gather (actual time=1450.959..1459.871 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate (actual time=1444.608..1444.618 rows=1 loops=3)
               ->  Parallel Seq Scan on t1
                   (actual time=0.023..716.970 rows=333333 loops=3)
 Planning Time: 0.110 ms
 Execution Time: 1514.484 ms
(8 rows)
```

La fonction `array_agg()` est aussi parallélisable.

</div>
