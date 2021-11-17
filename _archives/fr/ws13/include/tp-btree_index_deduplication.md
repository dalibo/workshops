## TP - Déduplication des index B-Tree

<div class="slide-content">

Test sur :

  * la taille des index ;
  * les temps de création ;
  * les temps de sélection.

</div>

<div class="notes">

**Mise en place**

Création de la table suivante :

```sql
CREATE TABLE t_2col_large (
  i int,
  t text
);
```

On pourra lancer les commandes suivantes et étudier les temps pour chaque
requête :

```sql
\timing on

INSERT INTO t_2col_large (i, t)
  SELECT g % 10000, md5((g % 10000)::text) FROM generate_series(1, 1000000) g;
CREATE INDEX t_2col_large_dedup_idx ON t_2col_large (i, t);
SELECT pg_size_pretty(pg_relation_size('t_2col_large_dedup_idx'));
DROP INDEX t_2col_large_dedup_idx;
CREATE INDEX t_2col_large_no_dedup_idx ON t_2col_large (i, t) WITH (deduplicate_items = OFF);
SELECT pg_size_pretty(pg_relation_size('t_2col_large_no_dedup_idx'));
DROP INDEX t_2col_large_no_dedup_idx;

TRUNCATE t_2col_large;
CREATE INDEX t_2col_large_dedup_idx ON t_2col_large (i, t);
INSERT INTO t_2col_large (i, t)
  SELECT g % 10000, md5((g % 10000)::text) FROM generate_series(1, 1000000) g;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM t_2col_large WHERE i>2000 and i<3000;
DROP INDEX t_2col_large_dedup_idx;

TRUNCATE t_2col_large;
CREATE INDEX t_2col_large_no_dedup_idx ON t_2col_large (i, t) WITH (deduplicate_items = OFF);
INSERT INTO t_2col_large (i, t)
  SELECT g % 10000, md5((g % 10000)::text) FROM generate_series(1, 1000000) g;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM t_2col_large WHERE i>2000 and i<3000;
DROP INDEX t_2col_large_no_dedup_idx;
```

Taille de l'index non dédupliqué : 56 Mo contre 7,3 Mo en mode dupliqué.

Création de l'index non dupliqué dans une table remplie : 1,8 s contre 0,8 s
en mode dupliqué.

Insertion d'éléments dans une table : 7,2 secondes avec un index non dupliqué
contre 6,1 secondes avec un index dupliqué.

Sélection en 25 ms avec un index non dupliqué contre 19 ms avec un index
dupliqué.

On pourra tester en modifiant le nombre de lignes ou la proportion de lignes
identiques.

</div>
