<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=055fee7eb4dcc78e58672aef146334275e1cc40d

Discussion

* https://www.postgresql.org/message-id/flat/454638cf-d563-ab76-a585-2564428062af@2ndquadrant.com

-->

<div class="slide-content">

* Permet de référencer les colonnes de jointures
* Syntaxe :
  `SELECT ... FROM t1 JOIN t2 USING (a, b, c) AS x`

</div>

<div class="notes">

Il est désormais possible d'utiliser un alias sur une jointure effectuée avec la
syntaxe `JOIN .. USING`. Ce dernier peut être utilisé pour référencer les
colonnes de jointures.

C'est une fonctionnalité du standard SQL. Elle s'ajoute à la liste des
[fonctionnalitées
supportées](https://docs.postgresql.fr/14/features.html).

Exemple :

```sql
CREATE TABLE region (
  region_id int,
  region_name text
);

CREATE TABLE ville (
  ville_id int,
  region_id int,
  ville_name text
);
```

```sql
SELECT c.*
  FROM ville a INNER JOIN region b USING (region_id) AS c \gdesc
```
```sh
  Column   |  Type
-----------+---------
 region_id | integer
```

</div>
