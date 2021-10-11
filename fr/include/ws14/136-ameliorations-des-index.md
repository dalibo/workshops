
<div class="slide-content">

* Amélioration des performances de certains indexGiST
  * plus rapide, plus petit
  * type : point
* Nettoyage des index btree "par le haut"
  * limite la fragmentation lorsque des lignes sont fréquemment modifiées.
* Index brin, nouvelles classes d'opréateurs
  * `*_bloom_ops` : permet d'utiliser les index bin pour des données dont
    l'ordre physique ne cohincide pas avec l'ordre logique.
  * `*_minmax_multi_ops` : permet d'utiliser les index brin avec des prédicats
    de sélection de plage de données

</div>

<div class="notes">

**Améliorations lors de la création d'index GiST**
<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=16fa9b2b30a357b4aea982bd878ec2e5e002dbcc

Discussion

* https://www.postgresql.org/message-id/flat/1A36620E-CAD8-4267-9067-FB31385E7C0D@yandex-team.ru
-->

La création de certains index GiST est rendue plus rapide par l'exécution d'un
pré-tri. Un effet secondaire de cette amélioration est que la taille des index
bénéficiant de cette optimisation est plus petite. Cela va permettre de
diminuer la durée des opérations de maintenances sur ces index GiST (`INDEX`,
`REINDEX`) et limiter l'espace utilisée.

```sql
-- PostgreSQL 14
=# CREATE TABLE gist_fastbuild AS SELECT point(random(),random()) as pt FROM  generate_series(1,10000000,1);
SELECT 10000000
=# \timing on
Timing is on.
=# CREATE INDEX ON gist_fastbuild USING gist (pt);
CREATE INDEX
Time: 15837.450 ms (00:15.837)
=# \di+ gist_fastbuild_pt_idx
                                                    List of relations
 Schema |         Name          | Type  |  Owner   |     Table      | Persistence | Access method |  Size  | Description
--------+-----------------------+-------+----------+----------------+-------------+---------------+--------+-------------
 public | gist_fastbuild_pt_idx | index | postgres | gist_fastbuild | permanent   | gist          | 474 MB |
(1 row)

=# EXPLAIN (ANALYZE, BUFFERS) SELECT pt FROM gist_fastbuild WHERE pt <@ box(point(.5,.5), point(.75,.75));
                                             QUERY PLAN
------------------------------------------------------------------------------------------------------
 Index Only Scan using gist_fastbuild_pt_idx on gist_fastbuild  (cost=0.42..419.42 rows=10000 width=16)
                                                                (actual time=0.497..130.077 rows=624484 loops=1)
   Index Cond: (pt <@ '(0.75,0.75),(0.5,0.5)'::box)
   Heap Fetches: 0
   Buffers: shared hit=301793
 Planning Time: 4.406 ms
 Execution Time: 149.662 ms
(6 rows)

Time: 165.305 ms

=# COPY gist_fastbuild TO '/tmp/gist_fastbuild.copy';
COPY 10000000

-- PostgreSQL 13
=# CREATE TABLE gist_fastbuild(pt point);
=# COPY gist_fastbuild FROM '/tmp/gist_fastbuild.copy';
COPY 10000000
=# \timing on
Timing is on.
=# CREATE INDEX ON gist_fastbuild USING gist (pt);
CREATE INDEX
Time: 168469.405 ms (02:48.469)
=# \di+ gist_fastbuild_pt_idx
                                            List of relations
 Schema |         Name          | Type  |  Owner   |     Table      | Persistence |  Size  | Description 
--------+-----------------------+-------+----------+----------------+-------------+--------+-------------
 public | gist_fastbuild_pt_idx | index | postgres | gist_fastbuild | permanent   | 711 MB | 
(1 row)

=# EXPLAIN (ANALYZE, BUFFERS) SELECT pt FROM gist_fastbuild WHERE pt <@ box(point(.5,.5), point(.75,.75));
                                             QUERY PLAN
------------------------------------------------------------------------------------------------------
 Index Only Scan using gist_fastbuild_pt_idx on gist_fastbuild  (cost=0.42..539.42 rows=10000 width=16)
                                                                (actual time=0.492..107.536 rows=624484 loops=1)
   Index Cond: (pt <@ '(0.75,0.75),(0.5,0.5)'::box)
   Heap Fetches: 0
   Buffers: shared hit=17526
 Planning Time: 0.143 ms
 Execution Time: 126.951 ms
(6 rows)

Time: 127.601 ms
```

On voit que le temps d'exécution et la taille de l'index ont beaucoup diminué
en version 14. On voit égalemement que dans ce cas le plan en version 14 montre
une augmentation du nombre de pages lues et du temps d'exécution.

Pour permettre cette fonctionnalité, une nouvelle fonction de support
optionnelle a été ajoutée à la méthode d'accès `gist`. Lorsqu'elle est définie,
la construction de l'index passe par une étape de tri des données avec un ordre
défini par la fonction de support. Cela permet de regrouper les enregistrements
plus efficacement et donc de réduire la taille de l'index.

Actuellement seul la classe d'opérateur pour les types `point` dispose de cette
fonction :

```sql
=# SELECT f.opfname AS famille,
       ap.amproc AS fonction_de_support,
       tl.typname AS type_gauche_operateur,
       tr.typname AS type_droit_operateur,
       m.amname AS methode_d_acces
  FROM pg_amproc ap
       INNER JOIN pg_type tl ON tl.oid = ap.amproclefttype
       INNER JOIN pg_type tr ON tr.oid = ap.amprocrighttype
       INNER JOIN pg_opfamily f ON ap.amprocfamily = f.oid
       INNER JOIN pg_am m ON f.opfmethod = m.oid
 WHERE ap.amproc::text LIKE '%sortsupport'
   AND m.amname = 'gist';
```
```text
  famille  |  fonction_de_support   | type_gauche_operateur | type_droit_operateur | methode_d_acces
-----------+------------------------+-----------------------+----------------------+-----------------
 point_ops | gist_point_sortsupport | point                 | point                | gist
(1 row)
```

**Nettoyage des index btree**
<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=d168b666823b6e0bcf60ed19ce24fb5fb91b8ccf
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9dc718bd

Discussion

* https://www.postgresql.org/message-id/flat/CAH2-Wzm+maE3apHB8NOtmM=p-DO65j2V5GzAWCOEEuy3JZgb2g@mail.gmail.com
-->

Lorsqu'une ligne est mise à jour par un ordre `UPDATE`, PostgreSQL garde
l'ancienne version de la ligne dans la table jusqu'à ce qu'elle ne soit plus
nécessaire à aucune transaction. L'adresse physique de chaque version est
différente. Il faut donc ajouter cette nouvelle version à tous les index (y
compris ceux pour lesquels la donnée n'a pas changé), afin de s'assurer qu'elle
soit visible lors des parcours d'index. Ce processus est très pénalisant pour
les performances et peut provoquer de la fragmentation.

La notion de `Heap Only Tuple` a été mis en place pour palier à ce problème.
Lorsqu'une mise à jour ne touche aucune colonne indexée et que la nouvelle
version de ligne peut être stockée dans la même page que les autres versions,
PostgreSQL peut éviter la mise à jour des index.

Il y a cependant beaucoup de cas ou il n'est pas possible d'éviter la mise à
jour de colonnes indexée. Dans certains profils d'activité avec beaucoup de
mise à jour, cela peut mener à la création de beaucoup d'enregistrement d'index
correspondant à des versions différentes d'une même ligne dans la table, mais
pour lequel l'enregistrement dans l'index est identique.

PostgreSQL 14 introduit un nouveau mécanisme pour limiter fortement la
fragmentation due à des changements de versions fréquents d'une ligne de la
table sans changement des données dans l'index. Lorsque ce genre de
modifications se produisent, l'exécuteur marque les tuples avec le hint
_logically unchanged index_. Par la suite, lorsqu'une page menace de se diviser
(_page split_), PostgreSQL déclenche un nettoyage des doublons de ce genre
correspondant à des lignes mortes. Ce nettoyage est décrit comme _bottom up_
(du bas vers le haut) car c'est la requête qui le déclenche lorsque la page va
se remplir.  Il se distingue du nettoyage qualifié de _top down_ (de haut en
bas) effectué par l'autovacuum. Un autre mécanisme se déclenche en prévention
d'une division de page : la suppression des entrées d'index marquées comme
mortes lors d'index scan précédents (avec le flag `LP_DEAD`). Cette dernière
est qualifiée de _simple index tuple deletion_ (suppression simple de tuple
d'index).

Si le nettoyage _top down_ et _simple_ ne suffisent pas, la déduplication tente
de faire de la place dans la page. En dernier recours, la page se divise en
deux (_page split_) ce qui fait grossir l'index.

Pour le tester, on peut comparer la taille des index sur une base pgbench
suite a 10 minutes d'activité en version 13 et 14 :


```
createdb bench
pgbench -i -s 100 bench
pgbench -n -c 90 -T 600 bench
```

Le résultat montre que les index ont moins grossi en v14.

| Schema |         Name          |  Taille avant | Taille après v13  |  Taille après v14  |
|--------|-----------------------|---------------|-------------------|--------------------|
| public | pgbench_accounts_pkey | 214 MB        | 214 MB            | 214 MB             |
| public | pgbench_branches_pkey | 16 kB         | 56 kB             | 40 kB              |
| public | pgbench_tellers_pkey  | 40 kB         | 224 kB            | 144 kB             |


**Index SPGiST couvrants**
<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=09c1c6ab4bc5764dd69c53ccfd43b2060b1fd090

Discussion

* https://commitfest.postgresql.org/32/2675/
-->

Il est désormais possible d'inclure des colonnes dans les index SPGiST de la
même façon qu'il était possible d'inclure des colonnes dans les index btree
depuis la version v11 et GiST depuis la version v12.

```
CREATE INDEX airports_coordinates_quad_idx ON airports_ml USING spgist(coordinates) INCLUDE (name);
```

**Index BRIN Bloom et Multirange**
<!--
Les commits sur ce sujet sont : BRIN multi-minmax and bloom indexes

Les commits sur ce sujet sont :
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=77b88cd1bb9041a735f24072150cacfa06c699a3
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=77b88cd1bb9041a735f24072150cacfa06c699a3

Discussion
* https://commitfest.postgresql.org/32/2523/
-->

Les index BRIN permettent de créer des index très petits, ils sont très
efficaces lorsque l'ordre physique des données est corrélé avec l'ordre
logique. Malheureusement, dès que cette corrélation change les performances se
dégradent, ce qui limite les cas d'utilisations à des tables d'historisation
par exemple.

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

```
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

```
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

``sql
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

``sql
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
