<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=3b00a944a9b3847fb02dae7c9ea62fe0b211b396

Discussions :

* https://postgr.es/m/20220630193848.5b02e0d6076b86617a915682@sraoss.co.jp

-->

<div class="slide-content">

  * TRUNCATE sur table externe possible
  * Mais pas de trigger sur `TRUNCATE` pour ce type de table
  * Même gestion que pour une table normale
  * Intérêts
    + audit des opérations sur une table externe
    * interdiction de cette opération

</div>

<div class="notes">

La version 16 permet d'ajouter un trigger sur `TRUNCATE` pour des tables externes.

Voici un exemple complet sous la forme d'un script SQL :

```sql
DROP DATABASE IF EXISTS b1;
DROP DATABASE IF EXISTS b2;
CREATE DATABASE b1;
CREATE DATABASE b2;
\c b2
CREATE TABLE t1 (c1 integer, c2 text);
INSERT INTO t1
  SELECT i, 'Ligne '||i FROM generate_series(1,5) i;
\c b1
CREATE EXTENSION postgres_fdw;
CREATE SERVER remote_b2
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (dbname 'b2');
CREATE USER MAPPING FOR CURRENT_ROLE SERVER remote_b2;
CREATE FOREIGN TABLE public.remote_t1 (c1 integer, c2 text)
  SERVER remote_b2
  OPTIONS (table_name 't1');

TABLE remote_t1;
TRUNCATE remote_t1;
TABLE remote_t1;

INSERT INTO remote_t1 SELECT i, 'Ligne '||i FROM generate_series(1,5) i;

CREATE FUNCTION deny_truncate_function() RETURNS trigger LANGUAGE plpgsql AS
$$
begin
  raise exception 'You shall not truncate foreign tables!';
  return null;
end
$$;

CREATE TRIGGER deny_truncate_trigger
  BEFORE TRUNCATE ON remote_t1
  FOR EACH STATEMENT
  EXECUTE FUNCTION deny_truncate_function();

TABLE remote_t1;
TRUNCATE remote_t1;
TABLE remote_t1;
```

Et voici le résultat suite à l'exécution de ce script avec _psql_ :

```sql
DROP DATABASE
DROP DATABASE
CREATE DATABASE
CREATE DATABASE
You are now connected to database "b2" as user "postgres".
CREATE TABLE
INSERT 0 5
You are now connected to database "b1" as user "postgres".
CREATE EXTENSION
CREATE SERVER
CREATE USER MAPPING
CREATE FOREIGN TABLE
 c1 |   c2    
----+---------
  1 | Ligne 1
  2 | Ligne 2
  3 | Ligne 3
  4 | Ligne 4
  5 | Ligne 5
(5 rows)

TRUNCATE TABLE
 c1 | c2 
----+----
(0 rows)

INSERT 0 5
CREATE FUNCTION
CREATE TRIGGER
 c1 |   c2    
----+---------
  1 | Ligne 1
  2 | Ligne 2
  3 | Ligne 3
  4 | Ligne 4
  5 | Ligne 5
(5 rows)

psql:script.sql:39: ERROR:  You shall not truncate foreign tables!
CONTEXT:  PL/pgSQL function deny_truncate_function() line 3 at RAISE
 c1 |   c2    
----+---------
  1 | Ligne 1
  2 | Ligne 2
  3 | Ligne 3
  4 | Ligne 4
  5 | Ligne 5
(5 rows)
```

</code>

</div>
