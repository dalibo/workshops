
<div class="slide-content">

* Amélioration des performances de certains index GiST
  * plus rapide, plus petit
  * type : point
* Support des index GiST couvrants

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

</div>
