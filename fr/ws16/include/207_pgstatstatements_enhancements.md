<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=daa8365a9

Discussion

* https://postgr.es/m/Y+MRdEq9W9XVa2AB@paquier.xyz

-->

<div class="slide-content">

* Normalise la requête indiquée dans les ordres :
  + DECLARE
  + EXPLAIN
  + CREATE MATERIALIZED VIEW
  + CREATE TABLE AS
* Par exemple

\tiny

```sql
CREATE TABLE pgss_ctas AS SELECT a, $1 b FROM generate_series($2, $3) a;
DECLARE cursor_stats_1 CURSOR WITH HOLD FOR SELECT $1;
```

\normalsize

</div>

<div class="notes">

Avant cette version, aucune requête DDL n'était normalisée. Avec la version 16,
les ordres qui intègrent des requêtes SQL (comme la déclaration d'un curseur, la
récupération d'un plan d'exécution, etc) sont aussi normalisés.

La requête :

```sql
CREATE TABLE pgss_ctas AS SELECT a, 'ctas' b FROM generate_series(1, 10) a;
```

devient donc

```sql
CREATE TABLE pgss_ctas AS SELECT a, $1 b FROM generate_series($2, $3) a;
```

</div>
