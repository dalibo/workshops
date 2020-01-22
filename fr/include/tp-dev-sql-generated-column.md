## TP sur les Colonnes générées

<div class="slide-content">


</div>

<div class="notes">


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
</div>
  1 | 6 | 7 |   42
(1 row)
```

**Le système du _MVCC_ fait qu'une mise à jour est en fait une insertion**

```sql

-- Mise à jour

UPDATE table1 SET a=7 WHERE a=6;
SELECT * FROM table1 ;
```

Le champ `prod` est recalculé

```
 id | a | b | prod 
----+---+---+------
  1 | 7 | 7 |   49
(1 row)
```

**Tentative de modification de la colonne générée**

```sql
$ UPDATE table1 SET prod = 43 ;
ERROR:  column "prod" can only be updated to DEFAULT
DETAIL:  Column "prod" is a generated column.
```

**Valeur par défaut**

```sql
$ UPDATE table1 SET prod = DEFAULT ;
```

</div>

----