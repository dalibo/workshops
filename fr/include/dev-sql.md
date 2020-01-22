## Développement / SQL


<div class="slide-content">

  * Colonnes générées
  * Colonne `OID`
  * `COMMIT` ou `ROLLBACK AND CHAIN`
  * `COPY FROM WHERE`

</div>

<div class="notes"></div>
----

### Ajout du support des colonnes générées

<div class="slide-content">

  * Colonnes générées par une expression
  * Valeur assignée à l'écriture et consignée dans la table ( `STORED` )
  * Plus efficace qu'un _trigger_
  * Colonne en lecture seule (sauf mot clé `DEFAULT`)
  * Colonnes indexables
  * Mode `VIRTUAL` non supporté
</div>


<div class="notes">

Cette fonctionnalité du standard SQL, permet de créer des colonnes calculées
à partir d'une expression plutôt qu'une assignation classique.

Dans le mode `STORED`, l'expression est évaluée **à l'écriture** et le
résultat est consigné dans la table auprès des autres colonnes.


```sql
-- définition de la table

$ CREATE TABLE table1(
    id serial PRIMARY KEY,
    a int NOT NULL DEFAULT 0,
    b int NOT NULL DEFAULT 0,
    prod int generated always as (a * b) stored
) ;
```

```
$ \d table1
Table "public.table1"
Column |  Type   | Collation | Nullable |              Default
--------+---------+-----------+----------+------------------------------------
id     | integer |           | not null | nextval('table1_id_seq'::regclass)
a      | integer |           | not null | 0
b      | integer |           | not null | 0
prod   | integer |           |          | generated always as (a * b) stored
Indexes:
"table1_pkey" PRIMARY KEY, btree (id)
```

```sql

-- insertion

INSERT INTO table1 (a,b) VALUES (6,7) ;
SELECT * FROM table1 ;
```

```
 id | a | b | prod
----+---+---+------
  1 | 6 | 7 |   42
(1 row)
```

Les modifications des colonnes calculées sont interdites à moins de rétablir
la valeur par défaut :

```sql
$ UPDATE table1 SET prod = 43 ;
ERROR:  column "prod" can only be updated to DEFAULT
DETAIL:  Column "prod" is a generated column.

$ UPDATE table1 SET prod = DEFAULT ;
```

Toute mise à jour d'enregistrement étant une insertion d'un nouvel
enregistrement (voir le fonctionnement du
[MVCC](https://docs.postgresql.fr/12/mvcc.html)), les colonnes générées sont
donc recalculées quel que soit le champ modifié.

Il est tout à fait possible de créer des index utilisant des colonnes générées.

Enfin, le mode `VIRTUAL` permettant de ne pas stocker la colonne et d'évaluer
l'expression **à la lecture** n'est pas encore implémenté. Ce mode est
prévu dans une future version.

</div>

----

#### Restriction

<div class="slide-content">

  * Expression `IMMUTABLE`

</div>


<div class="notes">

L'expression utilisée dans une colonne générée doit être de type
[_immutable_](inaltérable), c'est à dire qu'elle doit toujours produire le
même résultat pour les mêmes arguments en entrée. Certaines fonctions de
PostgreSQL sont de type [_volatile_](instable), comme par exemple la plupart
des fonctions traitant du texte ou des dates, et lorsqu'elles dépendent de la _locale_. Il faut
donc créer des fonctions intermédiaires déclarées _immutable_, faire en
sorte qu'elles ne soient pas impactées par la _locale_ et les utiliser en lieu et
place.

</div>

----

### Visibilité de la colonne OID

<div class="slide-content">

  * La fin des `OID`
    * anomalies de restauration possible
</div>

<div class="notes">

Le comportement spécial de la colonne cachée `oid` a été supprimé. Cette
colonne, si elle existe, est désormais visible comme toutes les autres
colonnes et il n'est plus possible de créer des tables ayant ce champ spécial.

La restauration de ce type de table peut poser problème. Par exemple, **en
version 11** :

```sql
=$ CREATE TABLE table2 (nom text, f_group int, sous_group int) WITH OIDS;
=$ INSERT INTO table2 SELECT i,i,i FROM generate_series(1,1000) i;
=$ SELECT * FROM TABLE2 LIMIT 1;
```

```
 nom  | f_group | sous_group
------+---------+------------
 1    |       1 |          1
```

```sql
=$ SELECT oid,* FROM TABLE2 LIMIT 1;
```

```
  oid  | nom | f_group | sous_group
-------+-----+---------+------------
 29256 | 1   |       1 |          1
```

Voici la restauration de cette base dans une **instance en v12** :


```shell
/usr/lib/postgresql/12/bin/pg_dump -p 5433 -t table2 postgres | psql -U postgres
```

```
pg_dump: warning: WITH OIDS is not supported anymore (table "table2")
[...]
CREATE TABLE
ALTER TABLE
COPY 1000
```

La table résultante dans la version 12 n'a plus la colonne `oid` :

```sql
=$ SELECT  attname FROM pg_catalog.pg_attribute
WHERE attrelid = 'public.table2'::regclass;

  attname
------------
 cmax
 cmin
 ctid
 f_group
 nom
 sous_group
 tableoid
 xmax
 xmin
(9 rows)
```

Il est important de bien utiliser la version 12 de pg_dump comme pour toute mise à
jour majeure. Effectivement, l'outil gère ce cas de figure en version 12, mais
naturellement pas dans les versions précédentes. Si nous restaurons sur une
instance en version 12 une sauvegarde créée par le pg_dump de la version 11,
nous aurions alors les erreurs suivantes :


```shell
/usr/lib/postgresql/11/bin/pg_dump --oids -p 5433 -t table2 postgres | 
psql -U postgres
...
ERROR:  syntax error at or near "WITH"
LINE 1: COPY public.table2 (nom, f_group, sous_group) WITH OIDS FROM...
                                                      ^
invalid command \.
ERROR:  syntax error at or near "29256"
LINE 1: 29256 1 1 1
```

Notez l'utilisation de l'argument `--oids` pour inclure les valeurs des OIDs.
Ici, la version 12 de PostgreSQL rejette l'option `WITH OIDS` de l'ordre `COPY
FROM` et le reste de la restauration échoue.

</div>

----

### COMMIT AND CHAIN

<div class="slide-content">

  * `COMMIT AND CHAIN`
  * `ROLLBACK AND CHAIN`
  * Enchaîne les transactions avec les mêmes caractéristiques
</div>


<div class="notes">

Une transaction peut désormais être validée ou annulée, tout en en initiant
_immédiatement_ une autre, avec les mêmes caractéristiques (voir
[`SET TRANSACTION`](https://docs.postgresql.fr/12/sql-set-transaction.html)).

Ceci permet par exemple d'enchaîner des transactions particulières tant que
cela est possible, à défaut de quoi l'ouverture de la suivante échoue.

```sql
$ SHOW TRANSACTION_ISOLATION
transaction_isolation
-----------------------
 read committed
(1 row)

$ BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
$ SELECT 1;
$ COMMIT AND CHAIN ;
$ SHOW TRANSACTION_ISOLATION;
 transaction_isolation
-----------------------
 repeatable read
(1 row)

$ COMMIT;
COMMIT

$ SHOW TRANSACTION_ISOLATION;
 transaction_isolation
-----------------------
 read committed
(1 row)
```
</div>

----

### COPY FROM WHERE...

<div class="slide-content">

  * Filtrer l'import massif de données
    
    ```COPY FROM... WHERE...```

</div>

<div class="notes">

Il est désormais possible d'ajouter une clause `WHERE` à la commande `COPY
FROM` et donc de contrôler les lignes qui seront retournées.

**Exemple de COPY FROM conditionnel**

En reprenant la table table2 précédente :

```sql
$ COPY table2 TO '/tmp/table2';
$ CREATE TABLE table22 (LIKE table2 INCLUDING ALL);
$ COPY table22 FROM '/tmp/table2' WHERE f_group BETWEEN 500 AND 505;
COPY 6
```

L'insertion par `COPY` a bien sélectionné les enregistrements désirés :

```sql
$ TABLE table22 ;
```
```
 nom | f_group | sous_group 
-----+---------+------------
 500 |     500 |        500
 501 |     501 |        501
 502 |     502 |        502
 503 |     503 |        503
 504 |     504 |        504
 505 |     505 |        505
```

</div>

----
