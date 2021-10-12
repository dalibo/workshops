<!--
Les commits sur ce sujet sont : BRIN multi-minmax and bloom indexes

Les commits sur ce sujet sont :
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=77b88cd1bb9041a735f24072150cacfa06c699a3
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=77b88cd1bb9041a735f24072150cacfa06c699a3

Discussion
* https://commitfest.postgresql.org/32/2523/
-->

<div class="slide-content">

* Nouvelles classes d'opréateurs
  * `*_bloom_ops` : permet d'utiliser les index bin pour des données dont
    l'ordre physique ne cohincide pas avec l'ordre logique.
  * `*_minmax_multi_ops` : permet d'utiliser les index brin avec des prédicats
    de sélection de plage de données

</div>

<div class="notes">

Les index BRIN permettent de créer des index très petits, ils sont très
efficaces lorsque l'ordre physique des données est corrélé avec l'ordre
logique. Malheureusement, dès que cette corrélation change les performances se
dégradent, ce qui limite les cas d'utilisations à des tables d'historisation
par exemple.

**Classe d'opérateur bloom_ops**

PostgreSQL 14 devrait changer la donne sur ce front, deux nouvelles classes
d'opérateurs ont été créés pour les index brin : `*_bloom_ops` et
`*_minmax_multi_ops`.

```sql
SELECT amname,
       CASE WHEN opcname LIKE '%bloom%' THEN '*_bloom_ops'
           WHEN opcname LIKE '%multi%' THEN '*_minmax_muli_ops'
           ELSE                             '*_mimmax_ops'
       END AS "classes d'opérateurs",
       count(*) as  "types supportés"
  FROM pg_opclass c
       INNER JOIN pg_am m ON c.opcmethod = m.oid
 WHERE opcname LIKE ANY(ARRAY['%bloom%', '%minmax%'])
GROUP BY 1, 2;
```
```text
 amname | classes d'opérateurs | types supportés
--------+----------------------+-----------------
 brin   | *_mimmax_ops         |              26
 brin   | *_minmax_muli_ops    |              19
 brin   | *_bloom_ops          |              24
(3 rows)
```

Les classes d'opérateurs `*_bloom_ops` visent à permettre l'utilisation d'index
brin pour satisfaire des prédicats d'égalité même si l'ordre physique de la
table ne correspond pas à son ordre logique.

```sql
CREATE TABLE bloom_test (id uuid, padding text);
INSERT INTO bloom_test
  SELECT md5((mod(i,1000000)/100)::text)::uuid, md5(i::text)
    FROM generate_series(1,2000000) s(i);
VACUUM ANALYZE bloom_test;

CREATE INDEX test_brin_idx ON bloom_test USING brin (id);
CREATE INDEX test_bloom_idx on bloom_test USING brin (id uuid_bloom_ops);
CREATE INDEX test_btree_idx on bloom_test (id);
```

La comparaison des tailles montre que l'index brin utilisant les
`uuid_bloom_ops` est plus grand que l'index brin classique mais nettement plus
petit que l'index btree. 

```text
=# \di+
                                              List of relations
 Schema |      Name      | Type  |  Owner   |   Table    | Persistence | Access method |  Size  | Description
--------+----------------+-------+----------+------------+-------------+---------------+--------+-------------
 public | test_bloom_idx | index | postgres | bloom_test | permanent   | brin          | 304 kB |
 public | test_brin_idx  | index | postgres | bloom_test | permanent   | brin          | 48 kB  |
 public | test_btree_idx | index | postgres | bloom_test | permanent   | btree         | 13 MB  |
(3 rows)
```

Pour le test, nous allons désactiver le parallélisme et les parcours
séquentiels afin de se focaliser sur l'utilisation des index :

```sql
SET enable_seqscan TO off;
SET max_parallel_workers_per_gather TO 0;
```

Exécuter un expain le `SELECT` suivant montre que l'index btree est choisi.

```sql
EXPLAIN (ANALYZE,BUFFERS) 
    SELECT * FROM bloom_test
     WHERE id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da';
```
```text
                                     QUERY PLAN
------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on bloom_test  (cost=5.98..749.38 rows=200 width=49)
                                 (actual time=0.132..0.227 rows=200 loops=1)
   Recheck Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
   Heap Blocks: exact=5
   Buffers: shared hit=3 read=6
   ->  Bitmap Index Scan on test_btree_idx  (cost=0.00..5.93 rows=200 width=0)
                                            (actual time=0.078..0.079 rows=200 loops=1)
         Index Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
         Buffers: shared read=4
 Planning:
   Buffers: shared hit=11 read=4 dirtied=1
 Planning Time: 0.496 ms
 Execution Time: 0.299 ms
(11 rows)
```

Après avoir supprimé l'index btree, on voit que l'index brin classique est
choisi. Le nombre de pages accédées est beacuoup plus important. Le nombre de
recheck dans la table en est probablement la cause.

```sql
DROP INDEX test_btree_idx;
EXPLAIN (ANALYZE,BUFFERS) 
    SELECT * FROM bloom_test
     WHERE id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da';
```
```text
                                     QUERY PLAN
------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on bloom_test  (cost=16.26..40957.16 rows=200 width=49)
                                 (actual time=1.537..186.802 rows=200 loops=1)
   Recheck Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
   Rows Removed by Index Recheck: 1999800
   Heap Blocks: lossy=20619
   Buffers: shared hit=10136 read=10485 written=6
   ->  Bitmap Index Scan on test_brin_idx  (cost=0.00..16.21 rows=1625752 width=0)
                                           (actual time=1.488..1.489 rows=206190 loops=1)
         Index Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
         Buffers: shared read=2
 Planning:
   Buffers: shared hit=7 dirtied=1
 Planning Time: 0.228 ms
 Execution Time: 186.857 ms
(12 rows)
```

Après avoir supprimé l'index brin minmax, on voit que l'index brin bloom n'a
pas été choisi lors du test précédent car son coût d'utilisation est légèrement
supérieur. Le nombre de pages accédé est pourtant bien inférieur.

```sql
DROP INDEX test_brin_idx;
EXPLAIN (ANALYZE,BUFFERS) 
    SELECT * FROM bloom_test
     WHERE id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da';
```
```text
                                     QUERY PLAN
------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on bloom_test  (cost=144.26..41085.16 rows=200 width=49)
                                 (actual time=5.347..7.411 rows=200 loops=1)
   Recheck Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
   Rows Removed by Index Recheck: 25656
   Heap Blocks: lossy=267
   Buffers: shared hit=272 read=29
   ->  Bitmap Index Scan on test_bloom_idx  (cost=0.00..144.21 rows=1625752 width=0)
                                            (actual time=5.338..5.338 rows=2670 loops=1)
         Index Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
         Buffers: shared hit=5 read=29
 Planning:
   Buffers: shared hit=6
 Planning Time: 0.204 ms
 Execution Time: 7.451 ms
(12 rows)
```

En répétant les tests avec des quantités de doublons différentes on voit que
l'index brin bloom permet d'accéder un nombre plus petit de pages que l'index
brin minmax, ce qui le rends souvent plus performant. L'index btree est
toujours plus performant pour une taille bien supérieure.

**Classe d'opérateur minmax_multi_ops**

Cette version a également introduit les classes d'opérateurs
`*_minmax_multi_ops` qui visent à permettre l'utilisation d'index brin pour
satisfaire des prédicats de sélection de plages de valeurs même si l'ordre
physique de la table ne correspond pas à son ordre logique.

```sql
CREATE TABLE brin_multirange AS
     SELECT '2021-09-29'::timestamp - INTERVAL '1 min' * x AS d
       FROM generate_series(1, 1000000) AS F(x);

UPDATE brin_multirange SET d = current_timestamp WHERE random() < .01;

CREATE INDEX brin_multirange_btree_idx ON brin_multirange USING btree (d);
CREATE INDEX brin_multirange_minmax_idx ON brin_multirange USING brin (d);
CREATE INDEX brin_multirange_minmax_multi_idx ON brin_multirange USING brin (d timestamp_minmax_multi_ops);
```
```text
=# \di+ brin_multirange*
                                     List of relations
 Schema |               Name               |      Table      | Persistence | Access method | Size  |
--------+----------------------------------+-----------------+-------------+---------------+-------+
 public | brin_multirange_btree_idx        | brin_multirange | permanent   | btree         | 21 MB |
 public | brin_multirange_minmax_idx       | brin_multirange | permanent   | brin          | 48 kB |
 public | brin_multirange_minmax_multi_idx | brin_multirange | permanent   | brin          | 56 kB |
(3 rows)
```

On peut voir que l'index brin avec la classe d'opérateur `*_minmax_multi_ops`
est plus gros que l'index brin traditionnel mais, il est toujours beaucoup plus
petit que l'index btree.

Test d'une requête sélectionnant une plage de donnée sur la colonne `d` :

```sql
EXPLAIN (ANALYZE, BUFFERS)
    SELECT *
    FROM brin_multirange
    WHERE d BETWEEN '2021-04-05'::timestamp AND '2021-04-06'::timestamp;
```
```text
                                     QUERY PLAN
------------------------------------------------------------------------------------------------------
 Index Only Scan using brin_multirange_btree_idx on brin_multirange  (cost=0.42..61.44 rows=1551 width=8)
                                                                     (actual time=0.110..1.130 rows=1428 loops=1)
   Index Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
            AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
   Heap Fetches: 1428
   Buffers: shared hit=8 read=7
 Planning:
   Buffers: shared hit=9 read=1
 Planning Time: 0.411 ms
 Execution Time: 1.352 ms
(8 rows)
```

On voit qu'un index scan sur l'index btree a été choisi par l'optimiseur.

Testons la même requête en supprimant l'index btree :

```sql
DROP INDEX brin_multirange_btree_idx;
EXPLAIN (ANALYZE, BUFFERS)
    SELECT *
    FROM brin_multirange
    WHERE d BETWEEN '2021-04-05'::timestamp AND '2021-04-06'::timestamp;
```
```text
                                     QUERY PLAN
------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on brin_multirange  (cost=12.42..4909.98 rows=1551 width=8)
                                      (actual time=5.408..7.891 rows=1428 loops=1)
   Recheck Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
              AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
   Rows Removed by Index Recheck: 53475
   Heap Blocks: lossy=245
   Buffers: shared hit=247
   ->  Bitmap Index Scan on brin_multirange_minmax_idx  (cost=0.00..12.03 rows=28571 width=0)
                                                        (actual time=0.055..0.055 rows=2450 loops=1)
         Index Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
                  AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
         Buffers: shared hit=2
 Planning:
   Buffers: shared hit=7 dirtied=1
 Planning Time: 0.254 ms
 Execution Time: 7.975 ms
(12 rows)
```

On voit que l'index brin classique a été choisi. Testons à nouveau sans l'index
brin classique.

```sql
DROP INDEX brin_multirange_minmax_idx;
EXPLAIN (ANALYZE, BUFFERS)
    SELECT *
    FROM brin_multirange
    WHERE d BETWEEN '2021-04-05'::timestamp AND '2021-04-06'::timestamp;
```
```text
                                     QUERY PLAN
------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on brin_multirange  (cost=16.42..4913.98 rows=1551 width=8)
                                      (actual time=5.443..5.941 rows=1428 loops=1)
   Recheck Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
              AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
   Rows Removed by Index Recheck: 27192
   Heap Blocks: lossy=128
   Buffers: shared hit=131
   ->  Bitmap Index Scan on brin_multirange_minmax_multi_idx  (cost=0.00..16.03 rows=28571 width=0)
                                                              (actual time=0.110..0.110 rows=1280 loops=1)
         Index Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
                  AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
         Buffers: shared hit=3
 Planning:
   Buffers: shared hit=6
 Planning Time: 0.228 ms
 Execution Time: 6.019 ms
(12 rows)
```

L'index bin utilisant la nouvelle classe d'opérateur a été choisi.  Il
nécessite globalement moins de lectures (bitmap index scan + bitmap heap scan)
que l'autre index brin. En revanche, le coût estimé du plan qui l'utilise est
légèrement plus élevé ce qui explique qu'il ne soit pas choisi lorsque les deux
index sont présents.

Pour conclure, les index btree sont toujours plus performants que les index
brin. La nouvelle classe d'opérateur améliore les performances par rapport aux
index brin classiques. Ce gain de performance est fait au prix d'une
augmentation de la taille de l'index. La taille de l'index est toujours bien
inférieure à celle d'un index btree. Cette nouvelle version permet donc de
rendre polyalent les index brin tout en conservant leurs atouts.

</div>
