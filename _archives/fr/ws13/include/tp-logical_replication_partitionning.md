## TP - Réplication logique et partitionnement

<div class="slide-content">

  * Ajout d'une table partitionnée à une publication ;
  * Réplication vers une table partitionnée de même schéma ;
  * Réplication vers une table partitionnée de schéma différent.
</div>

<div class="notes">  

### Prérequis

Il faut deux instances PostgreSQL avec le paramètre `wal_level = 'logical'`
pour faire ce tp. On désignera ces deux instances comme **source** et
**cible** dans la suite.

### Ajout d'une table partitionnée à une publication

Créer une base de données, ajouter une table partitionnée et créer une
publication pour cette table :

```
CREATE DATABASE rl;
\c rl

CREATE TABLE livres (
	id int,
	titre text,
	date_sortie timestamp with time zone)
PARTITION BY RANGE (date_sortie);

CREATE TABLE livres_2020_05
PARTITION OF livres FOR VALUES
	FROM ('20200501'::timestamp with time zone)
	TO   ('20200601'::timestamp with time zone);

CREATE PUBLICATION thepub
	FOR TABLE livres;
```

Créer une base de données sur une seconde instance, créer les mêmes tables et
créer une souscription avec une chaîne de connexion adaptée (ici 5433 est le
port de l'instance source):

```
CREATE DATABASE rl;
\c rl

CREATE TABLE livres (
	id int,
	titre text,
	date_sortie timestamp with time zone)
PARTITION BY RANGE (date_sortie);

CREATE TABLE livres_2020_05
PARTITION OF livres FOR VALUES
	FROM ('20200501'::timestamp with time zone)
	TO   ('20200601'::timestamp with time zone);


CREATE SUBSCRIPTION thesub
    CONNECTION 'host=/tmp port=5433 dbname=rl'
    PUBLICATION thepub;
```

Observer les tables dans la publication :

```
[source] postgres@rl=# SELECT oid, prpubid, prrelid::regclass
                         FROM pg_publication_rel ;

  oid  | prpubid | prrelid
-------+---------+---------
 17337 |   17336 | livres
(1 row)

[source] postgres@rl=# SELECT * FROM pg_publication_tables ;

 pubname | schemaname |   tablename
---------+------------+----------------
 thepub  | public     | livres_2020_05
(1 row)
```

Observer les tables dans la souscription :

```
[cible] postgres@rl=# SELECT srsubid, srrelid::regclass AS tablename,
                             srsubstate, srsublsn
                        FROM pg_subscription_rel;

 srsubid |   tablename    | srsubstate | srsublsn
---------+----------------+------------+-----------
   17402 | livres_2020_05 | r          | 0/7254B28
(1 row)
```

Ajoutez une partition sur les deux instances :

```
CREATE TABLE livres_2020_06
PARTITION OF livres FOR VALUES
	FROM ('20200601'::timestamp with time zone)
	TO   ('20200701'::timestamp with time zone);
```

Observer à nouveau les tables présentes dans la publication et la souscription.

```
[source] postgres@rl=# SELECT oid, prpubid, prrelid::regclass
                         FROM pg_publication_rel ;

  oid  | prpubid | prrelid
-------+---------+---------
 17337 |   17336 | livres
(1 row)

[source] postgres@rl=# SELECT * FROM pg_publication_tables ;
 pubname | schemaname |   tablename
---------+------------+----------------
 thepub  | public     | livres_2020_05
 thepub  | public     | livres_2020_06
(2 rows)

---

[cible] postgres@rl=# SELECT srsubid, srrelid::regclass AS tablename,
                             srsubstate, srsublsn
                        FROM pg_subscription_rel;
                        
                        
```


```
 srsubid |   tablename    | srsubstate | srsublsn
---------+----------------+------------+-----------
   17402 | livres_2020_05 | r          | 0/7254B28
```

On constate que la nouvelle partition est ajoutée automatiquement à la
publication mais qu'elle n'est pas présente dans la souscription. En effet, il
faut lancer la commande suivante pour rafraîchir la liste des tables dans la
souscription à partir de la publication associée :

```
ALTER SUBSCRIPTION thesub REFRESH PUBLICATION;
```

On peut alors voir les deux partitions dans la souscription :

```
[cible] postgres@rl=# SELECT srsubid, srrelid::regclass AS tablename,
                             srsubstate, srsublsn
                        FROM pg_subscription_rel;

 srsubid |   tablename    | srsubstate | srsublsn
---------+----------------+------------+-----------
   17402 | livres_2020_05 | r          | 0/7254B28
   17402 | livres_2020_06 | r          | 0/72709A0
(2 rows)
```

Supprimer la partition `livres_2020_06`, rafraîchir la souscription et observer
le résultat :

```
[source] postgres@rl=# DROP TABLE livres_2020_06;
DROP TABLE
[local]:5433 postgres@rl=# SELECT oid, prpubid, prrelid::regclass
                             FROM pg_publication_rel ;

  oid  | prpubid | prrelid
-------+---------+---------
 17337 |   17336 | livres
(1 row)

[source] postgres@rl=# SELECT * FROM pg_publication_tables ;
 pubname | schemaname |   tablename
---------+------------+----------------
 thepub  | public     | livres_2020_05
(1 row)

---

[cible] postgres@rl=# DROP TABLE livres_2020_06;
DROP TABLE
[cible] postgres@rl=# ALTER SUBSCRIPTION thesub REFRESH PUBLICATION;
ALTER SUBSCRIPTION
[cible] postgres@rl=# SELECT srsubid, srrelid::regclass AS tablename,
                             srsubstate, srsublsn
                        FROM pg_subscription_rel;

 srsubid |   tablename    | srsubstate | srsublsn
---------+----------------+------------+-----------
   17402 | livres_2020_05 | r          | 0/7254B28
(1 row)
```

### Réplication vers une table partitionnée ayant le même schéma

Ajouter deux partitions à la table sur les deux instances :

```
CREATE TABLE livres_2020_06
PARTITION OF livres FOR VALUES
	FROM ('20200601'::timestamp with time zone)
	TO   ('20200701'::timestamp with time zone);

CREATE TABLE livres_2020_07
PARTITION OF livres FOR VALUES
	FROM ('20200701'::timestamp with time zone)
	TO   ('20200801'::timestamp with time zone);
```

Rafraîchir la souscription :

```
ALTER SUBSCRIPTION thesub REFRESH PUBLICATION;
```

Insérer des données dans la table sur l'instance source :

```
INSERT INTO livres (id, titre, date_sortie)
        SELECT  i,
                'Livre no ' || i,
                '20200501'::timestamp with time zone
		    + INTERVAL '1 minute' * (random()  * 60 * 24 * 30 * 3 )::int
        FROM generate_series(1, 1000) AS F(i);
```

Lister les partitions alimentées sur les deux instances avec le nombre de
lignes associées :

```
[source] postgres@rl=# SELECT tableoid::regclass, count(*)
                         FROM livres GROUP BY 1 ORDER BY 1;

    tableoid    | count
----------------+-------
 livres_2020_05 |   342
 livres_2020_06 |   319
 livres_2020_07 |   339
(3 rows)

---

[cible] postgres@rl=# SELECT tableoid::regclass, count(*)
                        FROM livres GROUP BY 1 ORDER BY 1;

    tableoid    | count
----------------+-------
 livres_2020_05 |   342
 livres_2020_06 |   319
 livres_2020_07 |   339
(3 rows)
```

On constate que le nombre de lignes présentes sur les deux instances est
identique.

### Réplication vers une table partitionnée ayant un schéma différent

Supprimer la souscription et la base de données sur le serveur cible :

```
\c rl
DROP SUBSCRIPTION thesub;
\c postgres
DROP DATABASE rl;
```

Modifier la publication :

```
ALTER PUBLICATION thepub
      SET (publish_via_partition_root = true);
```

Créer un schéma de partitionnement différent et recréer une souscription :

```
CREATE DATABASE rl;
\c rl

CREATE TABLE livres (
	id int,
	titre text,
	date_sortie timestamp with time zone)
PARTITION BY RANGE (id);

CREATE TABLE livres_500
PARTITION OF livres FOR VALUES
	FROM (1)
	TO   (500);

CREATE TABLE livres_1000
PARTITION OF livres FOR VALUES
	FROM (500)
	TO   (1000);

CREATE TABLE livres_1500
PARTITION OF livres FOR VALUES
	FROM (1000)
	TO   (1500);

CREATE SUBSCRIPTION thesub
    CONNECTION 'host=/tmp port=5433 dbname=rl'
    PUBLICATION thepub;
```

Lister les tables dans la publication et la souscription, ainsi que la liste
des partitions alimentées et le nombre de lignes associées.

```
[source] postgres@rl=# SELECT oid, prpubid, prrelid::regclass
                         FROM pg_publication_rel ;

  oid  | prpubid | prrelid
-------+---------+---------
 17337 |   17336 | livres
(1 row)

[source] postgres@rl=# SELECT * FROM pg_publication_tables ;
 pubname | schemaname | tablename
---------+------------+-----------
 thepub  | public     | livres
(1 row)

[source] postgres@rl=# SELECT tableoid::regclass, count(*)
                         FROM livres GROUP BY 1 ORDER BY 1;



    tableoid    | count
----------------+-------
 livres_2020_05 |   342
 livres_2020_06 |   319
 livres_2020_07 |   339
(3 rows)

---

[cible] postgres@rl=# SELECT srsubid, srrelid::regclass AS tablename,
                             srsubstate, srsublsn
                      FROM pg_subscription_rel;
 srsubid | tablename | srsubstate | srsublsn
---------+-----------+------------+-----------
   17452 | livres    | r          | 0/72F6EE8
(1 row)

[cible] postgres@rl=# SELECT tableoid::regclass, count(*)
                        FROM livres GROUP BY 1 ORDER BY 1;

  tableoid   | count
-------------+-------
 livres_500  |   499
 livres_1000 |   500
 livres_1500 |     1
(3 rows)
```

On constate que :

* la table partitionnée est désormais la seule présente dans la liste des
  tables de la publication et de la souscription. C'est l'effet de
  `publish_via_partition_root` ;
* les lignes sont correctement réparties dans les partitions de la souscription
  qui a pourtant un schéma de partitionnement différent.

</div>
