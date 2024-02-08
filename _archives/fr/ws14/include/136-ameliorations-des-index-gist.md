
<div class="slide-content">

* Amélioration des performances de certains index GiST
  * plus rapides, plus petits
  * type : `point`
* Support des index SPGiST couvrants

</div>

<div class="notes">

**Améliorations lors de la création d'index GiST**
<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=16fa9b2b30a357b4aea982bd878ec2e5e002dbcc

Discussion

* https://www.postgresql.org/message-id/flat/1A36620E-CAD8-4267-9067-FB31385E7C0D@yandex-team.ru
-->

La création de certains index GiST est rendue plus rapide par l'exécution d'un
pré-tri. Un effet secondaire de cette amélioration est que la taille des index
bénéficiant de cette optimisation est plus petite. Cela va permettre de
diminuer la durée des opérations de maintenances sur ces index GiST (`INDEX`,
`REINDEX`) et limiter l'espace utilisé.

```sql
-- PostgreSQL 14
\timing on
CREATE TABLE gist_fastbuild 
    AS SELECT point(random(),random()) as pt
         FROM  generate_series(1,10000000,1);
COPY gist_fastbuild TO '/tmp/gist_fastbuild.copy';

CREATE INDEX ON gist_fastbuild USING gist (pt);
-- Time: 15837.450 ms (00:15.837)
```
```sh
=# \di+ gist_fastbuild_pt_idx
                             List of relations
         Name          | Type  |     Table      | Access method |  Size  
-----------------------+-------+----------------+---------------+--------
 gist_fastbuild_pt_idx | index | gist_fastbuild | gist          | 474 MB 
```
```sql
EXPLAIN (ANALYZE, BUFFERS) 
 SELECT pt FROM gist_fastbuild 
  WHERE pt <@ box(point(.5,.5), point(.75,.75));
```
```sh
                         QUERY PLAN
---------------------------------------------------------------
 Index Only Scan using gist_fastbuild_pt_idx on gist_fastbuild
  (cost=0.42..419.42 rows=10000 width=16)
  (actual time=0.497..130.077 rows=624484 loops=1)
   Index Cond: (pt <@ '(0.75,0.75),(0.5,0.5)'::box)
   Heap Fetches: 0
   Buffers: shared hit=301793
 Planning Time: 4.406 ms
 Execution Time: 149.662 ms
```
```sql
-- PostgreSQL 13
\timing on
CREATE TABLE gist_fastbuild(pt point);
COPY gist_fastbuild FROM '/tmp/gist_fastbuild.copy';

CREATE INDEX ON gist_fastbuild USING gist (pt);
-- Time: 168469.405 ms (02:48.469)
```
```sh
=# \di+ gist_fastbuild_pt_idx
                                            List of relations
         Name          | Type  |     Table      |  Size  
-----------------------+-------+----------------+--------
 gist_fastbuild_pt_idx | index | gist_fastbuild | 711 MB 
```
```sql
EXPLAIN (ANALYZE, BUFFERS) 
 SELECT pt FROM gist_fastbuild 
  WHERE pt <@ box(point(.5,.5), point(.75,.75));
```
```sh
                         QUERY PLAN
---------------------------------------------------------------
 Index Only Scan using gist_fastbuild_pt_idx on gist_fastbuild 
  (cost=0.42..539.42 rows=10000 width=16)
  (actual time=0.492..107.536 rows=624484 loops=1)
   Index Cond: (pt <@ '(0.75,0.75),(0.5,0.5)'::box)
   Heap Fetches: 0
   Buffers: shared hit=17526
 Planning Time: 0.143 ms
 Execution Time: 126.951 ms
```

On voit que le temps d'exécution et la taille de l'index ont beaucoup diminué
en version 14. Malheureusement, dans ce cas, le plan en version 14 montre
une augmentation du nombre de pages lues et du temps d'exécution.
<!-- FIXME : pourquoi ??? -->

Pour permettre cette fonctionnalité, une nouvelle fonction de support
optionnelle a été ajoutée à la méthode d'accès `gist`. Lorsqu'elle est définie,
la construction de l'index passe par une étape de tri des données avec un ordre
défini par la fonction de support. Cela permet de regrouper les enregistrements
plus efficacement et donc de réduire la taille de l'index.

Actuellement seule la classe d'opérateur pour les types `point` dispose de cette
fonction :

```sql
SELECT f.opfname AS famille,
       ap.amproc AS fonction_de_support,
       tl.typname AS type_gauche_op,
       tr.typname AS type_droit_op,
       m.amname AS methode
  FROM pg_amproc ap
       INNER JOIN pg_type tl ON tl.oid = ap.amproclefttype
       INNER JOIN pg_type tr ON tr.oid = ap.amprocrighttype
       INNER JOIN pg_opfamily f ON ap.amprocfamily = f.oid
       INNER JOIN pg_am m ON f.opfmethod = m.oid
 WHERE ap.amproc::text LIKE '%sortsupport'
   AND m.amname = 'gist';
```
```sh
  famille  |  fonction_de_support   | type_gauche_op | type_droit_op | methode
-----------+------------------------+----------------+---------------+---------
 point_ops | gist_point_sortsupport | point          | point         | gist
```

**Index SPGiST couvrants**
<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=09c1c6ab4bc5764dd69c53ccfd43b2060b1fd090

Discussion

* https://commitfest.postgresql.org/32/2675/
-->

Il est désormais possible d'inclure des colonnes dans les index SPGiST de la
même façon qu'il était possible d'inclure des colonnes dans les index btree
depuis la version v11 et GiST depuis la version v12.

```sql
CREATE INDEX airports_coordinates_quad_idx ON airports_ml 
 USING spgist(coordinates) INCLUDE (name);
```

</div>
