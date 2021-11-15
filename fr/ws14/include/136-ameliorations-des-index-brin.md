<!--
Les commits sur ce sujet sont : BRIN multi-minmax and bloom indexes

Les commits sur ce sujet sont :
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=77b88cd1bb9041a735f24072150cacfa06c699a3
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=77b88cd1bb9041a735f24072150cacfa06c699a3

Discussion
* https://commitfest.postgresql.org/32/2523/
-->

<div class="slide-content">

* Nouvelles classes d'opérateurs
  * `*_bloom_ops` : permet d'utiliser les index BRIN pour des données dont
    l'ordre physique ne coïncide pas avec l'ordre logique
  * `*_minmax_multi_ops` : permet d'utiliser les index BRIN avec des prédicats
    de sélection de plage de données

</div>

<div class="notes">

Les index BRIN permettent de créer des index très petits, ils sont très
efficaces lorsque l'ordre physique des données est corrélé avec l'ordre
logique. Malheureusement, dès que cette corrélation change les performances se
dégradent, ce qui limite les cas d'utilisations à des tables d'historisation
par exemple.

PostgreSQL 14 élargit le champ d'utilisation des index BRIN. Deux nouvelles
classes d'opérateurs ont été créées pour les index brin : `*_bloom_ops` et
`*_minmax_multi_ops`.

```sql
SELECT amname,
       CASE WHEN opcname LIKE '%bloom%' THEN '*_bloom_ops'
           WHEN opcname LIKE '%multi%' THEN '*_minmax_multi_ops'
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
 brin   | *_minmax_multi_ops    |              19
 brin   | *_bloom_ops          |              24
(3 rows)
```

**Classe d'opérateur bloom_ops**

Les classes d'opérateurs `*_bloom_ops` visent à permettre l'utilisation d'index
BRIN pour satisfaire des prédicats d'égalité même si l'ordre physique de la
table ne correspond pas à son ordre logique.

```sql
CREATE TABLE bloom_test (id uuid, padding text);
INSERT INTO bloom_test
  SELECT md5((mod(i,1000000)/100)::text)::uuid, md5(i::text)
    FROM generate_series(1,2000000) s(i);
VACUUM ANALYZE bloom_test;
```

Pour le test, nous allons désactiver le parallélisme et les parcours
séquentiels afin de se focaliser sur l'utilisation des index :

```sql
SET enable_seqscan TO off;
SET max_parallel_workers_per_gather TO 0;
```

Commençons par tester avec un index B-tree :

```sql
CREATE INDEX test_btree_idx on bloom_test (id);
EXPLAIN (ANALYZE,BUFFERS)
  SELECT * FROM bloom_test
   WHERE id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da';
```

Voici le plan de la requête :

```text
                                     QUERY PLAN
----------------------------------------------------------------------------
 Bitmap Heap Scan on bloom_test (cost=5.96..742.23 rows=198 width=49)
                                (actual time=0.069..0.130 rows=200 loops=1)
   Recheck Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
   Heap Blocks: exact=5
   Buffers: shared hit=9
   ->  Bitmap Index Scan on test_btree_idx
                                (cost=0.00..5.91 rows=198 width=0)
                                (actual time=0.043..0.044 rows=200 loops=1)
         Index Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
         Buffers: shared hit=4
 Planning Time: 0.168 ms
 Execution Time: 0.198 ms
```

Essayons maintenant avec un index BRIN utilisant les `uuid_minmax_ops` (la
classe d'opérateur par défaut) :

```sql
DROP INDEX test_btree_idx;
CREATE INDEX test_brin_minmax_idx ON bloom_test USING brin (id);
EXPLAIN (ANALYZE,BUFFERS)
  SELECT * FROM bloom_test
   WHERE id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da';
```

Voici le plan de la requête :

```text
                                     QUERY PLAN
------------------------------------------------------------------------------
 Bitmap Heap Scan on bloom_test (cost=17.23..45636.23 rows=198 width=49)
                                (actual time=1.527..216.911 rows=200 loops=1)
   Recheck Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
   Rows Removed by Index Recheck: 1999800
   Heap Blocks: lossy=20619
   Buffers: shared hit=1 read=20620 written=2
   ->  Bitmap Index Scan on test_brin_minmax_idx
                                (cost=0.00..17.18 rows=2000000 width=0)
                                (actual time=1.465..1.465 rows=206190 loops=1)
         Index Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
         Buffers: shared hit=1 read=1
 Planning:
   Buffers: shared hit=1
 Planning Time: 0.132 ms
 Execution Time: 216.968 ms
```

Le temps d'exécution de la requête avec cet index est beaucoup plus long
qu'avec l'index B-tree. Cela s'explique en partie par le grand nombre d'accès
en dehors du
cache qui doivent être réalisés, environ 20620 contre une dizaine, et surtout par
le très grand nombre de vérifications qui doivent être faites dans la table
(presque 2 millions).

Pour terminer, essayons avec l'index BRIN et la nouvelle classe d'opérateur :

```sql
DROP INDEX test_brin_minmax_idx;
CREATE INDEX test_brin_bloom_idx on bloom_test USING brin (id uuid_bloom_ops);
EXPLAIN (ANALYZE,BUFFERS)
  SELECT * FROM bloom_test
   WHERE id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da';
```

Voici le plan de la requête :

```text
                                     QUERY PLAN
----------------------------------------------------------------------------
 Bitmap Heap Scan on bloom_test (cost=145.23..45764.23 rows=198 width=49)
                                (actual time=5.369..7.502 rows=200 loops=1)
   Recheck Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
   Rows Removed by Index Recheck: 25656
   Heap Blocks: lossy=267
   Buffers: shared hit=301
   ->  Bitmap Index Scan on test_brin_bloom_idx
                                (cost=0.00..145.18 rows=2000000 width=0)
                                (actual time=5.345..5.345 rows=2670 loops=1)
         Index Cond: (id = 'cfcd2084-95d5-65ef-66e7-dff9f98764da'::uuid)
         Buffers: shared hit=34
 Planning:
   Buffers: shared hit=1
 Planning Time: 0.129 ms
 Execution Time: 7.553 ms
```

On voit que le nouvel index accède à soixante fois moins de bloc en mémoire que
l'index BRIN _minmax_. Le nombre de lignes vérifiées dans la table est
également nettement inférieur (presque 80 fois moins). Les performances
globales sont meilleures qu'avec l'index BRIN _minmax_. Dans ce cas, le coût
estimé est cependant légèrement supérieur, si les deux index sont présents en
même temps sur la table, l'index BRIN _minmax_sera donc choisi.

Comparé au plan avec l'index B-tree, les performances sont nettement moins
bonnes. C'est principalement dû au nombre d'accès nécessaire pour traiter le
prédicat.

En répétant les tests avec des quantités de doublons différentes, on voit que
l'index BRIN _bloom_ permet d'accéder un nombre plus petit de pages que l'index
BRIN _minmax_, ce qui le rend souvent plus performant. L'index B-tree est
toujours plus performant.

La comparaison des tailles montre que l'index BRIN utilisant les
`uuid_bloom_ops` est plus grand que l'index BRIN classique mais nettement plus
petit que l'index B-tree.

```text
                           List of relations
         Name         | Type  |   Table    | Access method |  Size
----------------------+-------+------------+---------------+--------
 test_brin_bloom_idx  | index | bloom_test | brin          | 304 kB
 test_brin_minmax_idx | index | bloom_test | brin          | 48 kB
 test_btree_idx       | index | bloom_test | btree         | 13 MB
```

La classe d'opérateur `*_bloom_ops` accepte deux paramètres qui permettent de
dimensionner l'index bloom :

* `n_distinct_per_range` :  permet d'estimer le nombre de valeurs distinctes
  dans un ensemble de blocs brin. Il doit être supérieur à -1 et sa valeur par
  défaut est -0.1. Il fonctionne de la même manière que la colonne `n_distinct`
  de la vue `pg_stats`. S'il est positif, il indique le nombre de valeurs
  distinctes. S'il est négatif, il indique la fraction de valeurs distinctes
  pour cette colonne dans la table.

* `false_positive_rate` :  permet d'estimer le nombre de faux positifs généré
  par l'index bloom. Il doit être compris entre 0.0001 et 0.25, sa valeur par
  défaut est 0.01.

Un paramétrage incorrect peut rendre impossible la création de l'index :

```sql
CREATE INDEX test_bloom_parm_idx on bloom_test
       USING brin (id uuid_bloom_ops(false_positive_rate=.0001)
);
```
```text
ERROR:  the bloom filter is too large (8924 > 8144)
```

Il est impératif de bien tester les insertions comme le montre cet exemple :

```sql
CREATE TABLE bloom_test (id uuid, padding text);
CREATE INDEX test_bloom_parm_idx on bloom_test
       USING brin (id uuid_bloom_ops(false_positive_rate=.0001)
);
INSERT INTO bloom_test VALUES (md5('a')::uuid, md5('a'));
```

Si la table est vide, on voit que l'erreur ne survient pas lors de la création
de l'index mais lors de la première insertion :

```text
CREATE TABLE
CREATE INDEX
ERROR:  the bloom filter is too large (8924 > 8144)
```

**Classe d'opérateur minmax_multi_ops**

Cette version a également introduit les classes d'opérateurs
`*_minmax_multi_ops` qui visent à permettre l'utilisation d'index BRIN pour
satisfaire des prédicats de sélection de plages de valeurs même si l'ordre
physique de la table ne correspond pas à son ordre logique.

```sql
CREATE TABLE brin_multirange AS
     SELECT '2021-09-29'::timestamp - INTERVAL '1 min' * x AS d
       FROM generate_series(1, 1000000) AS F(x);

UPDATE brin_multirange SET d = current_timestamp WHERE random() < .01;
```

Une fois de plus, nous allons désactiver le parallélisme et les parcours
séquentiels afin de se concentrer sur l'utilisation des index :

```sql
SET enable_seqscan TO off;
SET max_parallel_workers_per_gather TO 0;
```

Commençons par tester une requête avec un `BETWEEN` sur un index B-tree :

```sql
CREATE INDEX brin_multirange_btree_idx
  ON brin_multirange USING btree (d);
EXPLAIN (ANALYZE, BUFFERS)
  SELECT * FROM brin_multirange
   WHERE d BETWEEN '2021-04-05'::timestamp AND '2021-04-06'::timestamp;
```

Voci le plan généré :

```text
                                   QUERY PLAN
---------------------------------------------------------------------------
 Bitmap Heap Scan on brin_multirange (cost=107.67..4861.46 rows=5000 width=8)
                                     (actual time=0.254..0.698 rows=1429 loops=1)
   Recheck Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
              AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
   Heap Blocks: exact=7
   Buffers: shared hit=14
   ->  Bitmap Index Scan on brin_multirange_btree_idx
                                     (cost=0.00..106.42 rows=5000 width=0)
                                     (actual time=0.227..0.227 rows=1429 loops=1)
         Index Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
                  AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
         Buffers: shared hit=7
 Planning Time: 0.119 ms
 Execution Time: 0.922 ms
```

Testons la même requête en supprimant avec un index BRIN _minmax_ :

```sql
DROP INDEX brin_multirange_btree_idx;
CREATE INDEX brin_multirange_minmax_idx
  ON brin_multirange USING brin (d);

EXPLAIN (ANALYZE, BUFFERS)
  SELECT * FROM brin_multirange
   WHERE d BETWEEN '2021-04-05'::timestamp AND '2021-04-06'::timestamp;
```
```text
                                  QUERY PLAN
--------------------------------------------------------------------------------
 Bitmap Heap Scan on brin_multirange (cost=12.42..4935.32 rows=1550 width=8)
                                     (actual time=5.486..7.959 rows=1429 loops=1)
   Recheck Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
              AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
   Rows Removed by Index Recheck: 53627
   Heap Blocks: lossy=246
   Buffers: shared hit=248
   ->  Bitmap Index Scan on brin_multirange_minmax_idx
                                     (cost=0.00..12.03 rows=30193 width=0)
                                     (actual time=0.056..0.056 rows=2460 loops=1)
         Index Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
                  AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
         Buffers: shared hit=2
 Planning:
   Buffers: shared hit=1
 Planning Time: 0.146 ms
 Execution Time: 8.039 ms
```

Comparé à l'index B-tree, l'index BRIN _minmax_ accéde à beaucoup plus de blocs,
cela se ressent au niveau du temps d'exécution de la requête qui est plus
important.

Pour finir, testons avec l'index BRIN _multirange_minmax_ :

```sql
DROP INDEX brin_multirange_minmax_idx;
CREATE INDEX brin_multirange_minmax_multi_idx
  ON brin_multirange USING brin (d timestamp_minmax_multi_ops);

EXPLAIN (ANALYZE, BUFFERS)
  SELECT * FROM brin_multirange
   WHERE d BETWEEN '2021-04-05'::timestamp AND '2021-04-06'::timestamp;
```
```text
                                     QUERY PLAN
-------------------------------------------------------------------------------
 Bitmap Heap Scan on brin_multirange (cost=16.42..4939.32 rows=1550 width=8)
                                     (actual time=5.689..6.300 rows=1429 loops=1)
   Recheck Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
              AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
   Rows Removed by Index Recheck: 27227
   Heap Blocks: lossy=128
   Buffers: shared hit=131
   ->  Bitmap Index Scan on brin_multirange_minmax_multi_idx
                                     (cost=0.00..16.03 rows=30193 width=0)
                                     (actual time=0.117..0.117 rows=1280 loops=1)
         Index Cond: ((d >= '2021-04-05 00:00:00'::timestamp without time zone)
                  AND (d <= '2021-04-06 00:00:00'::timestamp without time zone))
         Buffers: shared hit=3
 Planning:
   Buffers: shared hit=1
 Planning Time: 0.148 ms
 Execution Time: 6.380 ms
```

Le plan avec la nouvelle classe d'opérateur est accède à moins de bloc que
celui avec la classe d'opérateur par défaut. Le temps d'exécution est donc plus
court. Le coût estimé par l'optimiseur est légèrement supérieur à l'index brin
_minmax_. Si les deux index sont présents, l'index bin _minmax_ sera donc
choisi.

On peut voir que l'index BRIN avec la classe d'opérateur `*_minmax_multi_ops`
est plus gros que l'index BRIN traditionnel mais, il est toujours beaucoup plus
petit que l'index B-tree.

```text
               Name               | Type  |     Table      |Access method | Size
----------------------------------+-------+----------------+--------------+-------
 brin_multirange_btree_idx        | index |brin_multirange |btree         | 21 MB
 brin_multirange_minmax_idx       | index |brin_multirange |brin          | 48 kB
 brin_multirange_minmax_multi_idx | index |brin_multirange |brin          | 56 kB
```

Pour conclure, les index B-tree sont toujours plus performants que les index
BRIN. La nouvelle classe d'opérateur améliore les performances par rapport aux
index BRIN classiques. Ce gain de performance est fait au prix d'une
augmentation de la taille de l'index. La taille de l'index est toujours bien
inférieure à celle d'un index B-tree. Cette nouvelle version permet donc de
rendre polyvalent les index BRIN tout en conservant leurs atouts.

</div>
