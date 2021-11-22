<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=3696a600e2292d43c00949ddf0352e4ebb487e5b

Discussion

* https://www.postgresql.org/message-id/flat/db80ceee-6f97-9b4a-8ee8-3ba0c58e5be2@2ndquadrant.com

-->

<div class="slide-content">

* Génération d'une colonne de tri pour les requêtes récursives :

```sql
  [ SEARCH { BREADTH | DEPTH } FIRST BY column_name [, ...]
      SET search_seq_col_name ]
```

* Protection contre les cycles :

```sql
  [ CYCLE column_name [, ...]
      SET cycle_mark_col_name
      [ TO cycle_mark_value DEFAULT cycle_mark_default ]
      USING cycle_path_col_name ]
```
</div>

<div class="notes">

PostgreSQL permet de créer des requêtes récursives grâce à la clause `WITH
RECURSIVE`. Ce genre de requêtes permet de remonter une arborescence
d'enregistrements liés par des colonnes de type `id` et `parent_id`.

Dans ce genre de requête, il est courant de vouloir :

* ordonner les données en fonction de leur profondeur ;
* afficher le chemin parcouru ou la profondeur de l'enregistrement dans
  l'arborescence ;
* détecter l'apparition d'un cycle, une séquence d'enregistrement provoquant
  une boucle.

La norme SQL prévoit différentes syntaxes pour réaliser ce genre de tâches.
Elles sont désormais implémentées dans PostgreSQL.

Création d'un jeu d'essais :

```sql
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

Il est fréquent de vouloir récupérer la profondeur d'un enregistrement dans
l'arbre que l'on reconstitue afin d'ordonner les données. Voici un exemple qui
récupère la ou les personnes avec la plus grande profondeur dans
l'arborescence.

```sql
--- ajout d'un champ profondeur (depth)
WITH RECURSIVE mtree(id, name, depth) AS (
   -- initialisation de la profondeur à 0 pour le point de départ
   SELECT id, name, 0
     FROM tree
    WHERE id = 1

   UNION ALL

   -- Incrémenter la profondeur de 1
   SELECT t.id, t.name, m.depth + 1
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
)
SELECT * FROM mtree ORDER BY depth DESC LIMIT 1;
```
```sh
 id | name  | depth
----+-------+-------
 10 | Edwin |     4
(1 row)
```

En version 14, la syntaxe suivante permet de récupérer des informations
similaires :


```sh
with_query_name [ ( column_name [, ...] ) ] AS [ [ NOT ] MATERIALIZED ] ( query )
  [ SEARCH BREADTH FIRST BY column_name [, ...] SET search_seq_col_name ];

query: ( select | values | insert | update | delete )
```

Exemple :

```sql
WITH RECURSIVE mtree(id, name) AS (
   SELECT id, name
     FROM tree
    WHERE id = 1

   UNION ALL

   SELECT t.id, t.name
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
) SEARCH BREADTH FIRST BY name SET morder
SELECT * FROM mtree ORDER BY morder DESC;
```

```sh
 id |  name   |   morder
----+---------+-------------
 10 | Edwin   | (4,Edwin)
  8 | Debby   | (3,Debby)
  9 | Dave    | (3,Dave)
  7 | Craig   | (2,Craig)
  6 | Clement | (2,Clement)
  5 | Clara   | (2,Clara)
  4 | Britney | (1,Britney)
  2 | Bob     | (1,Bob)
  3 | Barbara | (1,Barbara)
  1 | Albert  | (0,Albert)
(10 rows)
```

En appliquant la clause `LIMIT 1`. On obtient donc le même résultat que
précédemment.

Ce genre de requête a pour inconvénient de risquer de boucler si un cycle est
introduit dans le jeu de données. Il faut donc se prémunir contre ce genre de
problème.


```sql
UPDATE tree SET parent_id = 10 WHERE id = 1;
-- UPDATE 1
```

```sql
-- ajout de deux champs:
-- * un booleen qui permet de détecter les cycles (is_cycle)
-- * un tableau qui contient le chemin parcouru (path)
WITH RECURSIVE mtree(id, name, depth, is_cycle, path) AS (
   -- initialisations
   SELECT id, name, 0,
          false,          -- initialement, on ne boucle pas
          ARRAY[ROW(id)]  -- le premier élément du chemin
     FROM tree
    WHERE id = 1

   UNION ALL

   SELECT t.id, t.name, m.depth + 1,
          ROW(t.id) = ANY(m.path), -- déja traitré ?
          m.path || ROW(t.id)      -- ajouter le tuple au chemin
   FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id

   -- stopper l'itération si on détecte un cycle
   WHERE NOT m.is_cycle
)
SELECT * FROM mtree ORDER BY depth DESC LIMIT 1;
```

```sh
 id |  name  | depth | is_cycle |            path
----+--------+-------+----------+----------------------------
  1 | Albert |     5 | t        | {(1),(3),(5),(9),(10),(1)}
(1 row)
```

Le même résultat peut être obtenu en utilisant la clause CYCLE :

```sh
with_query_name [ ( column_name [, ...] ) ] AS [ [ NOT ] MATERIALIZED ] ( query )
  [ CYCLE column_name [, ...] SET cycle_mark_col_name
                              [ TO cycle_mark_value DEFAULT cycle_mark_default ]
                              USING cycle_path_col_name ]

query: ( select | values | insert | update | delete )
```

Voici un exemple :

```sql
WITH RECURSIVE mtree(id, name) AS (
   SELECT id, name
     FROM tree
    WHERE id = 1
   UNION ALL
   SELECT t.id, t.name
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
) SEARCH BREADTH FIRST BY name SET morder
  CYCLE id SET is_cycle USING path
SELECT * FROM mtree ORDER BY morder DESC LIMIT 1;
```

```sh
 id |  name  |   morder   | is_cycle |            path
----+--------+------------+----------+----------------------------
  1 | Albert | (5,Albert) | t        | {(1),(3),(5),(9),(10),(1)}
(1 row)
```

Il est également possible de construire un tableau avec le contenu de la
table et de trier à partir de ce contenu grâce à la syntaxe suivante :

```sh
with_query_name [ ( column_name [, ...] ) ] AS [ [ NOT ] MATERIALIZED ] ( query )
  [ SEARCH DEPTH FIRST BY column_name [, ...] SET search_seq_col_name ];

query: ( select | values | insert | update | delete )
```

Comme vous pouvez le voir dans l'exemple ci-dessous, il est possible d'utiliser
la clause `CYCLE` avec cette syntaxe aussi :

```sql
WITH RECURSIVE mtree(id, name) AS (
   SELECT id, name
     FROM tree
    WHERE id = 1

   UNION ALL

   SELECT t.id, t.name
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
) SEARCH DEPTH FIRST BY name SET morder
  CYCLE id SET is_cycle USING path
SELECT * FROM mtree WHERE not is_cycle ORDER BY morder DESC;
```

```sh
 id |  name   |                   morder                    | is_cycle |          path
----+---------+---------------------------------------------+----------+------------------------
  4 | Britney | {(Albert),(Britney)}                        | f        | {(1),(4)}
  7 | Craig   | {(Albert),(Bob),(Craig)}                    | f        | {(1),(2),(7)}
  2 | Bob     | {(Albert),(Bob)}                            | f        | {(1),(2)}
  6 | Clement | {(Albert),(Barbara),(Clement)}              | f        | {(1),(3),(6)}
  8 | Debby   | {(Albert),(Barbara),(Clara),(Debby)}        | f        | {(1),(3),(5),(8)}
 10 | Edwin   | {(Albert),(Barbara),(Clara),(Dave),(Edwin)} | f        | {(1),(3),(5),(9),(10)}
  9 | Dave    | {(Albert),(Barbara),(Clara),(Dave)}         | f        | {(1),(3),(5),(9)}
  5 | Clara   | {(Albert),(Barbara),(Clara)}                | f        | {(1),(3),(5)}
  3 | Barbara | {(Albert),(Barbara)}                        | f        | {(1),(3)}
  1 | Albert  | {(Albert)}                                  | f        | {(1)}
(10 rows)
```

L'[implémentation
actuelle](https://www.postgresql.org/message-id/4a068167-37ed-3d6c-5ec5-c9b03cae84e6%40enterprisedb.com)
ne permet pas d'interagir avec les valeurs ramenées par les clauses `{ BREADTH |
DEPTH } FIRST` car leur fonction est de produire une colonne qui facilite le
tri des résultats.

```sql
WITH RECURSIVE mtree(id, name) AS (
   SELECT id, name
     FROM tree
    WHERE id = 1
   UNION ALL
   SELECT t.id, t.name
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
) SEARCH BREADTH FIRST BY name SET morder
  CYCLE id SET is_cycle USING path
SELECT id, name, (morder).* FROM mtree ORDER BY morder DESC LIMIT 1;
```

``` text
ERROR:  CTE mtree does not have attribute 3
```

Il est cependant possible d'y accéder en transformant le champ en objet JSON.

```sql
 WITH RECURSIVE mtree(id, name) AS (
   SELECT id, name
     FROM tree
    WHERE id = 1
   UNION ALL
   SELECT t.id, t.name
     FROM tree AS t
          INNER JOIN mtree AS m ON t.parent_id = m.id
) SEARCH BREADTH FIRST BY name SET morder
  CYCLE id SET is_cycle USING path
SELECT id, name, row_to_json(morder) -> '*DEPTH*' AS depth
  FROM mtree ORDER BY morder DESC LIMIT 1;
```

```sh
 id |  name  | depth
----+--------+-------
  1 | Albert | 5
(1 row)
```

</div>
