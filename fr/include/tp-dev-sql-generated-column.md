## TP sur les colonnes générées

<div class="slide-content">

  * Création d'une colonne générée
  * Observations lors d'un `UPDATE`
  * Utilisation des index

</div>

<div class="notes">

### Définition de la table

Pour ce rapide travail pratique, nous créons une table `table1` avec une colonne
générée à partir de deux autres colonnes.

```sql
CREATE TABLE table1(
  id serial PRIMARY KEY,
  a int NOT NULL DEFAULT 0,
  b int NOT NULL DEFAULT 0,
  prod int generated always as (a * b) stored
);
```

On constate la définition `generated always as stored` dans la description de 
la colonne `prod` pour notre table.

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

### Modifications du contenu de la table

À l'ajout d'une nouvelle ligne dans la table `table1`, le moteur génére 
automatiquement la valeur `prod` calculée à partir des valeurs `a` et `b`.

```sql
INSERT INTO table1 (a,b) VALUES (6,7);
SELECT * FROM table1;

 id | a | b | prod 
----+---+---+------
  1 | 6 | 7 |   42
(1 row)
```

Lors d'une modification, le fonctionnement interne MVCC crée une nouvelle version
de la ligne et recalcule à la volée la valeur `prod`. À la validation de la 
transaction (`COMMIT`), toutes les nouvelles transactions verront la nouvelle 
version de la ligne et la valeur de la colonne générée `prod`.

```sql
UPDATE table1 SET a=7 WHERE a=6;
SELECT * FROM table1;

 id | a | b | prod 
----+---+---+------
  1 | 7 | 7 |   49
(1 row)
```

### Tentative de modification de la colonne générée

Les colonnes générées sont en lecture seule et ne peuvent être modifiées que lors
d'une réévaluation à l'écriture de la ligne (`INSERT` ou `UPDATE`). 
Les modifications des colonnes calculées sont interdites à moins de rétablir
la valeur par défaut :

```sql
UPDATE table1 SET prod = 43;

ERROR:  column "prod" can only be updated to DEFAULT
DETAIL:  Column "prod" is a generated column.
```

### Ajout d'un index sur une colonnne générée

Puisque la donnée d'une colonne générée est stockée (`STORED`) aux côtés des
données de la table, le mécanisme d'indexation est tout à fait valable.

Nous pouvons alimenter la table `table1` avec un peu plus de données avant de 
créer un index sur la colonne `prod`.

```sql
TRUNCATE TABLE table1;
INSERT INTO table1 (a,b) 
  SELECT (random()*100)::int+i, (random()*10)::int+i 
    FROM generate_series(1,10000) as i;

CREATE INDEX ON table1(prod);
```

L'index sera utilisé lors d'une recherche sur la colonne `prod` comme le montre
le plan d'exécution suivant (`Index Scan using table1_prod_idx on table1`) :

```sql
EXPLAIN (analyze,buffers)
  SELECT a,b,prod FROM table1 WHERE prod BETWEEN 10 AND 100;

                       QUERY PLAN
--------------------------------------------------------------
 Index Scan using table1_prod_idx on table1
  (cost=0.29..8.30 rows=1 width=12)
  (actual time=0.011..0.013 rows=1 loops=1)
   Index Cond: ((prod >= 10) AND (prod <= 100))
   Buffers: shared hit=3
 Planning Time: 0.183 ms
 Execution Time: 0.036 ms
(5 rows)

```

</div>

----