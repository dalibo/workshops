<!--
Les commits sur ce sujet sont :

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9d701e624f4b9386cbd99519dab7936afe3d5aed

Discussion:

https://postgr.es/m/07b226e6-fa49-687f-b110-b7c37572f69e@dalibo.com

-->

<div class="slide-content">

* `EXPLAIN` avec l'option `BUFFERS` affiche désormais l'utilisation des buffers
  lors de la phase de planification ;
* L'option `BUFFERS` ne requiert plus l'utilisation de `ANALYZE` pour être
  utilisée.

</div>

<div class="notes">

La commande `EXPLAIN` peut désormais afficher l'utilisation des buffers
pendant la phase de planification.

L'information apparaît avec l'activation de l'option `BUFFERS`.

```console
postgres@bench=# EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM pgbench_accounts ;

                   QUERY PLAN
--------------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..80029.47 rows=3032147 width=97)
                               (actual time=0.056..1250.572 rows=3000000 loops=1)
   Buffers: shared hit=2253 read=47455 dirtied=32194 written=16228
 Planning:
   Buffers: shared hit=32 read=1 dirtied=1
 Planning Time: 0.624 ms
 Execution Time: 1357.520 ms
(6 rows)
```

L'option `BUFFERS` peut désormais être utilisée sans `ANALYZE`. Il n'affiche
alors que le volume de buffers manipulé lors de la phase de planification :

```console
postgres@bench=# EXPLAIN (BUFFERS) SELECT * FROM pgbench_accounts ;
                                QUERY PLAN
---------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..80029.47 rows=3032147 width=97)
 Planning:
   Buffers: shared hit=47 read=8
(3 rows)
```

</div>
