<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=e717a9a18b2e34c9c40e5259ad4d31cd7e420750

Discussion

* https://www.postgresql.org/message-id/flat/1c11f1eb-f00c-43b7-799d-2d44132c02d7@2ndquadrant.com

-->

<div class="slide-content">

* Nouvelles syntaxes :
  * `RETURN`
  * `BEGIN ATOMIC .. END;`
* Limitées au langage SQL
* Impossible d'utiliser des paramètres polymorphiques (`anyelement`, etc.)
* Dépendances avec les objets utilisés (`DROP CASCADE`)

</div>

<div class="notes">

La version 14 de PostgreSQL permet de créer des procédures et fonctions avec un
corps qui respecte le standart SQL. Cette nouvelle fonctionnalité se limite aux
fonctions écrites avec le langage SQL.

Deux syntaxes sont disponibles :

```sql
-- RETURN
CREATE FUNCTION add(a integer, b integer) RETURNS integer
  LANGUAGE SQL
  RETURN a + b;

-- BEGIN ATOMIC .. END
CREATE PROCEDURE insert_data(a integer, b integer)
  LANGUAGE SQL
BEGIN ATOMIC
  INSERT INTO tbl VALUES (a);
  INSERT INTO tbl VALUES (b);
END;
```

Ce type de déclaration ne permet pas d'utiliser les [types
polymorphiques](https://docs.postgresql.fr/14/extend-type-system.html#EXTEND-TYPES-POLYMORPHIC) :

```sql
CREATE OR REPLACE FUNCTION display_type(a anyelement) RETURNS text
LANGUAGE SQL
RETURN 'The input type is ' || pg_typeof(a);
```
```text
ERROR:  SQL function with unquoted function body cannot have polymorphic arguments
```

Pour cela, il faut continuer d'utiliser l'ancienne syntaxe avec l'encadrement
du corps de la fonction par des doubles `$$` :

```sql
CREATE OR REPLACE FUNCTION display_type(a anyelement) RETURNS text
LANGuAGE SQL
AS $$ SELECT 'The input type is ' || pg_typeof(a); $$
-- CREATE FUNCTION
```

Cette différence de comportement s'explique par le fait que la nouvelle
syntaxe est analysée (_parsed_) lors de la définition de la routine, alors que
l'ancienne l'était à chaque exécution.

La nouvelle approche permet de définir les dépendances entre la routine
et les objets qu'elle utilise. Il en résulte une suppression des routines
lors de l'exécution d'un `DROP CASCADE` sur les objets en question.

Exemple :

```sql
CREATE TABLE tbl1(i int);
CREATE TABLE tbl2(i int);

-- Procédure avec la nouvelle syntaxe
CREATE OR REPLACE PROCEDURE insert_data_new(a integer, b integer)
  LANGUAGE SQL
BEGIN ATOMIC
  INSERT INTO tbl1 VALUES (a);
  INSERT INTO tbl2 VALUES (a);
END;

-- Procédure avec l'ancienne syntaxe
CREATE OR REPLACE PROCEDURE insert_data_old(a integer, b integer)
  LANGUAGE SQL
AS $$
  INSERT INTO tbl1 VALUES (a);
  INSERT INTO tbl2 VALUES (a);
$$;
```

Lors de la création, seule la procédure utilisant la nouvelle méthode est
supprimée.

```sql
DROP TABLE tbl1, tbl2 CASCADE; 
-- NOTICE:  drop cascades to function insert_data_new(integer,integer)
-- DROP TABLE
```

Les deux méthodes renvoient une erreur si on utilise des objets qui n'existent
pas lors de la création de la routine :

```text
ERROR:  relation "tbl1" does not exist
LINE 4:   INSERT INTO tbl1 VALUES (a);
```

</div>
