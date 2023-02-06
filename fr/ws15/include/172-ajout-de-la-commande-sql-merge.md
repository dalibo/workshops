<!--
Les commits sur ce sujet sont :

* 2022: https://www.postgresql.org/message-id/flat/537759.1663625579%40sss.pgh.pa.us#04a1b7fd13241810eb939e6c7a776c207
* 2018: https://www.postgresql.org/message-id/flat/CAH2-WzkJdBuxj9PO%3D2QaO9-3h3xGbQPZ34kJH%3DHukRekwM-GZg%40mail.gmail.com
* 2017: https://www.postgresql.org/message-id/CANP8+jKitBSrB7oTgT9CY2i1ObfOt36z0XMraQc+Xrz8QB0nXA@mail.gmail.com

Discussion

* Lien vers la discussion

-->

<div class="slide-content">
 * Insérer, mettre à jour ou supprimer des lignes conditionnellement 
 en un seul ordre SQL.
 
</div>

<div class="notes">

**Fonctionnement de la commande MERGE**

La commande `MERGE` permet d'insérer, mettre à jour ou supprimer des lignes
conditionnellement en un seul ordre SQL.

Voici un exemple d'utilisation de cette commande :

```sql
CREATE TABLE mesures_capteurs (
  id INT PRIMARY KEY,
  top_mesure INT,
  derniere_mesure INT,
  derniere_maj TIMESTAMP WITH TIME ZONE
);

INSERT 
  INTO mesures_capteurs
  VALUES (1, 10, 10, current_timestamp - INTERVAL  '1 day'),
         (2,  5,  5, current_timestamp - INTERVAL '11 day'),
         (3, 20, 20, current_timestamp - INTERVAL  '1 day'),
         (4, 15, 15, current_timestamp - INTERVAL  '1 day');

CREATE TABLE import_mesures_capteurs (
  id INT,
  mesure INT
);

INSERT
  INTO import_mesures_capteurs(id, mesure)
  VALUES (2, 15), -- supprimer la ligne dans la table mesures_capteurs (trop ancienne)
         (3, 10), -- ne pas mettre a jour le top
         (4, 16), -- mettre a jour le top
         (5, 19); -- insérer la ligne

BEGIN;

MERGE INTO mesures_capteurs c
USING import_mesures_capteurs i
ON c.id = i .id
WHEN NOT MATCHED THEN
  -- insérer les nouvelles lignes
  INSERT (id, top_mesure, derniere_mesure, derniere_maj)
  VALUES (i.id, i.mesure, i.mesure, current_timestamp)
WHEN MATCHED AND ( c.derniere_maj + INTERVAL '10 days' <= current_timestamp ) THEN
  -- supprimer les mesures de capteurs si l'ancienne mesure date de plus de 10 jours
  DELETE
WHEN MATCHED AND ( c.top_mesure > i.mesure ) THEN
  -- mettre à jour seulement la mesure
  UPDATE
  SET derniere_mesure = i.mesure,
      derniere_maj = current_timestamp
WHEN MATCHED THEN
  -- mettre à jour le top et la mesure
  UPDATE
  SET top_mesure = i.mesure,
      derniere_mesure = i.mesure,
      derniere_maj = current_timestamp
;

TABLE mesures_capteurs;

ROLLBACK;
```

Le résultat correspond à l'attendu :

* la ligne 1 n'a pas changée ;
* la ligne 2 a été supprimée car elle est trop ancienne ;
* la ligne 3 a été mise à jour (colonnes `derniere_mesure` et `derniere_maj`) ;
* la ligne 4 a été mise à jour (colonnes `top_mesures`, `derniere_mesure` et
  `derniere_maj`) ;
* la ligne 5 a été insérée.


```sql
TABLE mesures_capteurs ;
```
```text
 id | top_mesure | derniere_mesure |         derniere_maj
----+------------+-----------------+-------------------------------
  1 |         10 |              10 | 2022-12-13 16:29:55.671426+01
  3 |         20 |              10 | 2022-12-14 16:30:01.658568+01
  4 |         16 |              16 | 2022-12-14 16:30:01.658568+01
  5 |         19 |              19 | 2022-12-14 16:30:01.658568+01
(4 rows)
```

Le prototype de la commande est le suivant :

```sql
[ WITH with_query [, ...] ]
MERGE INTO target_table_name [ [ AS ] target_alias ]
USING data_source ON join_condition
when_clause [...]
```

Ou _data\_source_ est :

```
{ source_table_name | ( source_query ) } [ [ AS ] source_alias ]
```

Lors de son exécution, la commande commence par réaliser une jointure entre la
source de donnée et la cible.

* la source de donnée peut être une table, une requête ou une CTE ;
* la table cible ne peut pas être une vue matérialisée, une table étrangère ou
  la cible de la définition d'une [règle] ;
* la condition de jointure ne doit contenir que des colonnes des tables source
  et cible qui participent à la jointure ;
* la jointure ne doit produire qu'une ligne pour chaque ligne candidate. C'est
  à dire qu'à chaque ligne de la cible, il ne doit correspondre qu'une ligne dans
  la source. Si ce n'est pas le cas, la première ligne sera utilisée pour
  modifier la cible et la suivante provoquera une erreur. Ce genre de situation
  peut également se produire si un `TRIGGER` insère une ligne qui est ensuite
  modifiée par la commande `MERGE`.

[règle]: https://www.postgresql.org/docs/15/sql-createrule.html

Voici un exemple où l'action exécutée sur la seconde ligne est un `INSERT` :

```sql
BEGIN;

-- mesure qui déclenche l'insertion d'une nouvelle ligne dans la cible
-- car l'id 5 n'existe pas dans la table mesures_capteurs mais figure déjà
-- dans import_mesures_capteurs
INSERT INTO import_mesures_capteurs VALUES (5,1);

MERGE INTO mesures_capteurs c
USING import_mesures_capteurs i
ON c.id = i .id
WHEN NOT MATCHED THEN
  -- clause WHEN qui insére les nouvelles lignes
  INSERT (id, top_mesure, derniere_mesure, derniere_maj)
  VALUES (i.id, i.mesure, i.mesure, current_timestamp)
WHEN MATCHED AND ( c.derniere_maj + INTERVAL '10 days' <= current_timestamp ) THEN
  DELETE  
WHEN MATCHED AND ( c.top_mesure > i.mesure ) THEN
  UPDATE
  SET derniere_mesure = i.mesure,
      derniere_maj = current_timestamp
WHEN MATCHED THEN
  UPDATE
  SET top_mesure = i.mesure,
      derniere_mesure = i.mesure,
      derniere_maj = current_timestamp
;

ROLLBACK;
```
```text
ERROR:  duplicate key value violates unique constraint "mesures_capteurs_pkey"
DETAIL:  Key (id)=(5) already exists.
```

Ce second exemple illustre un cas où c'est l'action `UPDATE` qui est déclenchée
deux fois :

```sql
BEGIN;

-- mesures pour le capteur numéro 3 qui déclenche une mise à jour des
-- colonnes derniere_mesure et derniere_maj
INSERT INTO import_mesures_capteurs VALUES (3,1);

MERGE INTO mesures_capteurs c
USING import_mesures_capteurs i
ON c.id = i .id
WHEN NOT MATCHED THEN
  INSERT (id, top_mesure, derniere_mesure, derniere_maj)
  VALUES (i.id, i.mesure, i.mesure, current_timestamp)
WHEN MATCHED AND ( c.derniere_maj + INTERVAL '10 days' <= current_timestamp ) THEN
  DELETE  
WHEN MATCHED AND ( c.top_mesure > i.mesure ) THEN
  -- clause WHEN déclenchée
  UPDATE
  SET derniere_mesure = i.mesure,
      derniere_maj = current_timestamp
WHEN MATCHED THEN
  UPDATE
  SET top_mesure = i.mesure,
      derniere_mesure = i.mesure,
      derniere_maj = current_timestamp
;
ROLLABCK;
```
```text
ERROR:  MERGE command cannot affect row a second time
HINT:  Ensure that not more than one source row matches any one target row.
```

La clause _when\_clause_ de la commande `MERGE` correspond à :

```
{ WHEN MATCHED [ AND condition ] THEN { merge_update | merge_delete | DO NOTHING } |
  WHEN NOT MATCHED [ AND condition ] THEN { merge_insert | DO NOTHING } }
```

Chaque ligne candidate se voit assigner le statut `[NOT] MATCHED` suivant que
la jointure a été un succès ou non. Ensuite, les clauses `WHEN` sont évaluées
dans l'ordre où elles sont spécifiées. Seule l'action associée à la première
clause `WHEN` qui renvoie `vrai` est exécutée.

Si une clause `WHEN [NOT] MATCHED` est spécifiée sans clause `AND`, elle sera
la dernière clause `[NOT] MATCHED` de ce type pour la requête. Si une autre
clause de ce type est présente après, une erreur est remontée.

Voici un exemple :

```sql
BEGIN;

MERGE INTO mesures_capteurs c
USING import_mesures_capteurs i
ON c.id = i .id
WHEN NOT MATCHED THEN
  INSERT (id, top_mesure, derniere_mesure, derniere_maj)
  VALUES (i.id, i.mesure, i.mesure, current_timestamp)
WHEN MATCHED AND ( c.derniere_maj + INTERVAL '10 days' <= current_timestamp ) THEN
  DELETE
WHEN MATCHED THEN
  UPDATE
  SET top_mesure = i.mesure,
      derniere_mesure = i.mesure,
      derniere_maj = current_timestamp
WHEN MATCHED AND ( c.top_mesure > i.mesure ) THEN
  -- clause WHEN qui provoque l'erreur
  UPDATE
  SET derniere_mesure = i.mesure,
      derniere_maj = current_timestamp;

ROLLBACK;
```
```text
ERROR:  unreachable WHEN clause specified after unconditional WHEN clause
```

Les clauses `merge_insert`, `merge_update` et `merge_delete` correspondent
respectivement à :

```
INSERT [( column_name [, ...] )]
[ OVERRIDING { SYSTEM | USER } VALUE ]
{ VALUES ( { expression | DEFAULT } [, ...] ) | DEFAULT VALUES }
```

```
UPDATE SET { column_name = { expression | DEFAULT } |
 ( column_name [, ...] ) = ( { expression | DEFAULT } [, ...] ) } [, ...]
```

````
DELETE
```

Lorsqu'elles sont exécutées, ces actions ont les mêmes effets que des ordres
`INSERT`, `UPDATE` ou `DELETE` classiques. La syntaxe est similaire, à la
différence prêt qu'il n'a ni clause `FROM` ni clause `WHERE`. Les actions
agissent sur la cible, utilisent les lignes courantes de la jointure et
agissent sur la cible. Il est possible de spécifier `DO NOTHING` si on souhaite
ignorer la ligne en cours. Ce résultat peut également être obtenu si aucune
clause n'est évaluée à `vrai`.

De la même manière que pour un ordre `INSERT` classique, il est possible de
forcer des valeurs pour les colonnes auto-générées en plaçant la clause
`OVERRIDING {SYSTEM | USER} VALUE` juste avant la clause VALUES de l'`INSERT`.

Les actions `INSERT`, `UPDATE` et `DELETE` ne contiennent pas de clause
`RETURNING`, la commande `MERGE` n'en dispose donc pas non plus.

**Privilèges**

Les privilèges nécessaires pour exécuter la commande `MERGE` sont les mêmes que
pour exécuter les commandes `INSERT`, `UPDATE` et `DELETE` implémentées dans le
`MERGE` sur la table cible (ou ses colonnes). Il est également nécessaire
d'avoir le droit en lecture sur la table source et toutes les colonnes de la
table cible présentes dans les prédicats.

**MERGE et triggers**

La commande `MERGE` fonctionne également avec les _triggers_ :

* `BEFORE STATEMENT`, qui se déclenchent pour toutes les actions spécifiées
  dans l'ordre `MERGE` qu'elles soient exécutées ou non ;
* `BEFORE ROW`, qui se déclenchent après qu'une clause `WHEN` soit validée mais
  avant que l'action ne soit exécutée ;
* `AFTER ROW`, qui se déclenchent après qu'une action ait été exécutée ;
* `AFTER STATEMENT`, qui sont exécutés après l'évaluation des clauses `WHEN`
  pour toutes les actions spécifiées qu'elles aient été exécutées ou non.

**INSERT ON CONFLICT vs MERGE**

La version 9.5 a vu l'arrivée de la commande `INSERT ON CONFLICT` qui permet
d'exécuter une action lorsque une erreur de violation de contrainte d'unicité
ou d'exécution est détectée. Le cas d'utilisation le plus fréquent est la
réalisation d'un `UPSERT` (`INSERT` ou `UPDATE` atomique). On remarque ici que
les fonctionnalités couvertes par la commande `MERGE` se recoupe en partie mais
pas totalement.

Les actions disponibles pour `INSERT ON CONFLICT` sont de deux types : `UPDATE`
ou `DO NOTHING`. Là encore, il y a une différence avec la commande `MERGE` qui
permet en plus de faire des suppressions.

`ON CONFLICT UPDATE` garantit l'exécution atomique d'un `INSERT` ou d'un
`UPDATE` même en cas de forte concurrence d'accès. La commande `MERGE` n'a pas
ce genre de garantie. Si une commande `INSERT` est exécutée en même temps que
le `MERGE`, il est possible que le `MERGE` ne la voit pas et choisisse
d'utiliser l'action `INSERT`, ce qui aboutira à une erreur de violation de
contrainte d'unicité.  C'est la raison pour laquelle la commande `MERGE` avait
été initialement refusée et remplacée par `INSERT ON CONFLICT`.

Pour finir, la façon dont les lignes sont sélectionnées pour réaliser une
action est différente. `INSERT ON CONFLICT` permet de spécifier la ou les
colonnes d'un index avec la clause `UNIQUE` ou une contrainte. Si un conflit
est détecté, l'action spécifiée est exécutée. La commande `MERGE` joint les
lignes de deux tables afin de déterminer s'il y a une correspondance et permet
ensuite de réaliser des filtres sur d'autres colonnes des tables afin de
décider quelle action exécuter. Le mécanisme est donc très différent.

Les deux commandes peuvent donc être utilisées pour réaliser des opérations
similaires mais ne sont pas interchangeables.

</div>
