<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=3696a600e2292d43c00949ddf0352e4ebb487e5b

Discussion

* https://www.postgresql.org/message-id/flat/db80ceee-6f97-9b4a-8ee8-3ba0c58e5be2@2ndquadrant.com

-->

<div class="slide-content">
</div>

<div class="notes">

PostgreSQL permet de créer des requêtes récursives grace à la clause `WITH
RECURSIVE`. Ce genre de requêtes permet de remonter une arborescences
d'enregistrements lié par des colonnes de type `id`, `parent_id`.

Dans ce genre de requête, il est courant d'écrire la requête afin de tracer :
* le chemin parcouru ;
* la profondeur de l'enregistrement dans l'arborescence ;
* l'apparition d'un cycle, une séquence d'enregistrement provoquant une boucle.

La norme SQL prémvoit différentes syntaxes pour réaliser ce genre de tâches.
Elle sont désormais implémentées dans PostgreSQL.

Création d'un jeu d'essais :

```
CREATE TABLE tree(id int, parent_id int, name text);
ALTER TABLE tree ADD PRIMARY KEY (id);
INSERT INTO tree(id, parent_id, name) 
VALUES (1, NULL, 'Albert'),
       (2, 1, 'Bob'),
       (3, 1, 'Barbara'),
       (4, 1, 'Britney'),
       (5, 3, 'Clara'),
       (6, 3, 'Clement'),
       (7, 2, 'Craig'),
       (8, 5, 'Debby'),
       (9, 5, 'Dave'),
       (10, 9, 'Edwin');
```

Voici un exemple de requête qui remonte toute l'arborescence sous une personne
avec l'id 1 (Albert):

```
--- Déclaration d'une CTE récursive
WITH RECURSIVE mtree(id, name) AS (
   --- Initialisation de la boucle
   SELECT id, name
     FROM tree
    WHERE id = 1
   --- Parcours de l'arborescence
   UNION ALL
   SELECT t.id, t.name
     FROM tree AS t
          -- Predicat de jointure pour parcourir l'arborescence
          INNER JOIN mtree AS m ON t.parent_id = m.id
)
SELECT * FROM mtree;

RESULTAT: 

 id |  name
----+---------
  1 | Albert
  2 | Bob
  3 | Barbara
  4 | Britney
  5 | Clara
  6 | Clement
  7 | Craig
  8 | Debby
  9 | Dave
 10 | Edwin
(10 rows)
```

Il est fréquent de vouloir récupérer la profondeur d'un enregistrement dans
l'arbre que l'on reconstitue. Voici un exemple qui récupère la ou les personnes
avec le niveau de récursion le plus bas.

```
--- ajout d'un champ profondeur (depth)
WITH RECURSIVE mtree(id, name, depth) AS (
   -- initialisation de la profondeur a 0 pour le point de départ
   SELECT id, name, 0
     FROM tree
    WHERE id = 1
   UNION ALL
   -- Incrémenter la profondeur de 1
   SELECT t.id, t.name, m.depth + 1
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
)
SELECT * FROm mtree ORDER BY depth DESC LIMIT 1;

RESULTAT:

 id | name  | depth
----+-------+-------
 10 | Edwin |     4
(1 row)
```

La syntaxe suivant permet de récupérer des infos simialires : 

```
with_query_name [ ( column_name [, ...] ) ] AS [ [ NOT ] MATERIALIZED ] ( select )
        [ SEARCH BREADTH FIRST BY column_name [, ...] SET search_seq_col_name ];
```

Exemple :

```
[local]:5436 postgres@postgres=# WITH RECURSIVE mtree(parent_id, name) AS (
   SELECT parent_id, name
     FROM tree
    WHERE id = 9
   UNION ALL
   SELECT t.parent_id, t.name
     FROM tree AS t
          INNER JOIN mtree AS m ON m.parent_id = t.id
) SEARCH BREADTH FIRST BY name SET morder
SELECT * FROM mtree;
 parent_id |  name   |   morder
-----------+---------+-------------
         5 | Dave    | (0,Dave)
         3 | Clara   | (1,Clara)
         1 | Barbara | (2,Barbara)
         ¤ | Albert  | (3,Albert)
(4 rows)

[local]:5436 postgres@postgres=# WITH RECURSIVE mtree(parent_id, name) AS (
   SELECT parent_id, name
     FROM tree
    WHERE id = 9
   UNION ALL
   SELECT t.parent_id, t.name
     FROM tree AS t
          INNER JOIN mtree AS m ON m.parent_id = t.id
) SEARCH DEPTH FIRST BY name SET morder
SELECT * FROM mtree;
 parent_id |  name   |               morder
-----------+---------+-------------------------------------
         5 | Dave    | {(Dave)}
         3 | Clara   | {(Dave),(Clara)}
         1 | Barbara | {(Dave),(Clara),(Barbara)}
         ¤ | Albert  | {(Dave),(Clara),(Barbara),(Albert)}
(4 rows)

[local]:5436 postgres@postgres=# WITH RECURSIVE mtree(id, name) AS (
   SELECT id, name
     FROM tree
    WHERE parent_id IS NULL
   UNION ALL
   SELECT t.id, t.name
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
) SEARCH BREADTH FIRST BY name SET morder
SELECT * FROM mtree;
 id |  name   |   morder    
----+---------+-------------
  1 | Albert  | (0,Albert)
  2 | Bob     | (1,Bob)
  3 | Barbara | (1,Barbara)
  4 | Britney | (1,Britney)
  5 | Clara   | (2,Clara)
  6 | Clement | (2,Clement)
  7 | Craig   | (2,Craig)
  8 | Debby   | (3,Debby)
  9 | Dave    | (3,Dave)
 10 | Edwin   | (4,Edwin)
(10 rows)

[local]:5436 postgres@postgres=# WITH RECURSIVE mtree(id, name) AS (
   SELECT id, name
     FROM tree
    WHERE parent_id IS NULL
   UNION ALL
   SELECT t.id, t.name
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
) SEARCH DEPTH FIRST BY name SET morder
SELECT * FROM mtree;
 id |  name   |                   morder                    
----+---------+---------------------------------------------
  1 | Albert  | {(Albert)}
  2 | Bob     | {(Albert),(Bob)}
  3 | Barbara | {(Albert),(Barbara)}
  4 | Britney | {(Albert),(Britney)}
  5 | Clara   | {(Albert),(Barbara),(Clara)}
  6 | Clement | {(Albert),(Barbara),(Clement)}
  7 | Craig   | {(Albert),(Bob),(Craig)}
  8 | Debby   | {(Albert),(Barbara),(Clara),(Debby)}
  9 | Dave    | {(Albert),(Barbara),(Clara),(Dave)}
 10 | Edwin   | {(Albert),(Barbara),(Clara),(Dave),(Edwin)}
(10 rows)

[local]:5436 postgres@postgres=# UPDATE tree SET parent_id = 10 WHERE id = 1;

[local]:5436 postgres@postgres=# WITH RECURSIVE mtree(id, name) AS (
   SELECT id, name
     FROM tree
    WHERE id = 1
   UNION ALL
   SELECT t.id, t.name
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
) SEARCH DEPTH FIRST BY name SET morder
  CYCLE id SET is_cycle USING path
SELECT * FROM mtree;
 id |  name   |                        morder                        | is_cycle |            path
----+---------+------------------------------------------------------+----------+----------------------------
  1 | Albert  | {(Albert)}                                           | f        | {(1)}
  2 | Bob     | {(Albert),(Bob)}                                     | f        | {(1),(2)}
  3 | Barbara | {(Albert),(Barbara)}                                 | f        | {(1),(3)}
  4 | Britney | {(Albert),(Britney)}                                 | f        | {(1),(4)}
  5 | Clara   | {(Albert),(Barbara),(Clara)}                         | f        | {(1),(3),(5)}
  6 | Clement | {(Albert),(Barbara),(Clement)}                       | f        | {(1),(3),(6)}
  7 | Craig   | {(Albert),(Bob),(Craig)}                             | f        | {(1),(2),(7)}
  8 | Debby   | {(Albert),(Barbara),(Clara),(Debby)}                 | f        | {(1),(3),(5),(8)}
  9 | Dave    | {(Albert),(Barbara),(Clara),(Dave)}                  | f        | {(1),(3),(5),(9)}
 10 | Edwin   | {(Albert),(Barbara),(Clara),(Dave),(Edwin)}          | f        | {(1),(3),(5),(9),(10)}
  1 | Albert  | {(Albert),(Barbara),(Clara),(Dave),(Edwin),(Albert)} | t        | {(1),(3),(5),(9),(10),(1)}
(11 rows)
```


</div>
