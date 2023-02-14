<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/E1nVzfM-000bAp-9u@gemulon.postgresql.org

Discussion

* https://postgr.es/m/CA+HiwqFvkBCmfwkQX_yBqv2Wz8ugUGiBDxum8=WvVbfU1TXaNg@mail.gmail.com
* https://postgr.es/m/CAL54xNZsLwEM1XCk5yW9EqaRzsZYHuWsHQkA2L5MOSKXAwviCQ@mail.gmail.com

-->

<div class="slide-content">
 * Correction du comportement de PostgreSQL lorsqu'un `UPDATE` sur une table
   partitionnée référencée par une contrainte de clé étrangère provoque la
   migration d'une ligne vers une autre partition.
</div>

<div class="notes">

Lorsqu'un `UPDATE` sur une table partitionnée référencée par une contrainte de
clé étrangère provoque la migration d'une ligne vers une autre partition,
l'opération est implémentée sous la forme d'un `DELETE` sur la partition
source, suivi d'un `INSERT` sur la partition cible.

Sur les versions précédentes, cela pose un souci lorsque la contrainte de clé
étrangère implémente la clause `ON DELETE`. En effet, dans ce cas, le changement
de partition provoque le déclenchement de l'action associée à la commande
`DELETE`, par exemple : une suppression. C'est une erreur puisqu'en réalité la
ligne est juste déplacée vers une autre partition.

En version 15, le trigger posé par la contrainte de clé étrangère ne se
déclenche plus sur le `DELETE` exécuté sur la partition, mais sur un `UPDATE`
exécuté sur la table mère. Cela permet d'obtenir le comportement attendu.

L'implémentation choisie à une limitation : elle ne fonctionne que si la
contrainte de clé étrangère concerne la table partitionnée. Cela ne devrait pas
être un facteur limitant, en effet, il est rare d'avoir des clés étrangères
différentes qui pointent vers les différentes partitions. On trouve
généralement plutôt une clé étrangère qui pointe vers une ou plusieurs
colonnes de la table partitionnée dans son ensemble.

Voici un exemple du comportement en version 14 puis 15.

Mise en place :

```sql
CREATE TABLE tpart (i int PRIMARY KEY, t text) PARTITION BY RANGE ( i );
CREATE TABLE tpart_1_10 PARTITION OF tpart FOR VALUES FROM (1) TO (10);
CREATE TABLE tpart_11_20 PARTITION OF tpart FOR VALUES FROM (11) TO (20);
CREATE TABLE foreignk(j int PRIMARY KEY, i int CONSTRAINT fk_tpart_i REFERENCES tpart(i) ON DELETE CASCADE, t text );
INSERT INTO tpart VALUES (1, 'value 1');
INSERT INTO foreignk VALUES (1, 1, 'fk 1');
```

Voici les données présentes dans les tables :

```sql
SELECT *, tableoid::regclass FROM tpart;
```
```sh
 i |    t    |  tableoid  
---+---------+------------
 1 | value 1 | tpart_1_10
(1 row)
```

```sql
SELECT * FROM foreignk ;
```
```sh
 j | i |  t   
---+---+------
 1 | 1 | fk 1
(1 row)
```

Mise à jour et nouveaux contrôles en version 14 :

```sql
UPDATE tpart SET i = 11 WHERE i = 1;
SELECT *, tableoid::regclass FROM tpart;
```
```sh
 i  |    t    |  tableoid
----+---------+-------------
 11 | value 1 | tpart_11_20
(1 row)
```

```sql
SELECT * FROM foreignk ;
```
```sh
j | i | t
---+---+---
(0 rows)
```

La ligne a bien changé de partition, en revanche elle a été supprimée de la
table qui référence la table partitionnée.


Avec PostgreSQL 15, on obtient désormais l'erreur suivante :

```text
ERROR:  update or delete on table "tpart" violates foreign key constraint "fk_tpart_i" on table "foreignk"
DETAIL:  Key (i)=(1) is still referenced from table "foreignk".
```

</div>
