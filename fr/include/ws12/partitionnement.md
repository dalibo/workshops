## Partitionnement

<div class="slide-content">

  * Support des clés étrangères
  * Définition du tablespace pour les partitions
  * Fonctions d'information :
    * `pg_partition_root()`
    * `pg_partition_ancestors()`
    * `pg_partition_tree()`
  * Nouvelle commande `\dP` pour les partitions

</div>  

<div class="notes">


</div>

----

### Clés étrangères dans les tables partitionnées 

<div class="slide-content">

  * Support des clés étrangères entre tables partitionnées
  
</div>


<div class="notes">

Il est désormais possible de mettre en place une clé étrangère dans une table partitionnée vers une autre table partitionnée. La relation sera établie entre la table partitionnée et toutes les partitions de la table référencée.

```sql
$ CREATE TABLE foo (i INT PRIMARY KEY, f FLOAT) PARTITION BY RANGE (i);
$ CREATE TABLE bar (i INT PRIMARY KEY, ifoo INT REFERENCES foo(i)) 
     PARTITION BY RANGE (i);

$ \d foo
               Partitioned table "public.foo"
 Column |       Type       | Collation | Nullable | Default 
--------+------------------+-----------+----------+---------
 i      | integer          |           | not null | 
 f      | double precision |           |          | 
Partition key: RANGE (i)
Indexes:
    "foo_pkey" PRIMARY KEY, btree (i)
Referenced by:
    TABLE "bar" CONSTRAINT "bar_ifoo_fkey" FOREIGN KEY (ifoo) REFERENCES foo(i)
Number of partitions: 0

$ CREATE TABLE foo_1_5 (i INT NOT NULL, f FLOAT);
$ ALTER TABLE ONLY foo ATTACH PARTITION foo_1_5 FOR VALUES FROM (1) TO (5);

$ \d foo_1_5
                   Table "public.foo_1_5"
 Column |       Type       | Collation | Nullable | Default 
--------+------------------+-----------+----------+---------
 i      | integer          |           | not null | 
 f      | double precision |           |          | 
Partition of: foo FOR VALUES FROM (1) TO (5)
Indexes:
    "foo_1_5_pkey" PRIMARY KEY, btree (i)
Referenced by:
    TABLE "bar" CONSTRAINT "bar_ifoo_fkey" FOREIGN KEY (ifoo) REFERENCES foo(i)
```

</div>

----

### Définition du tablespace pour les partitions


<div class="slide-content">

  * Gestion des tablespaces pour les tables partitionnées
    * Propagation du tablespace aux partitions filles
    * Surcharge du tablespace par partitions filles

</div>

<div class="notes">

Dans les versions précédentes, le choix des tablespace pour une table partitionnée
n'était pas supporté bien que la commande `CREATE TABLE ... TABLESPACE ...` puisse
être utilisée sans erreur.

À partir de la version 12, la gestion fine des tablespace est possible à n'importe
quelle moment de la vie d'une table partitionnée et de ses partitions filles. Tout
changement de tablespace au niveau de la table mère se propage pour les futures 
partitions filles ; toutes les partitions existantes doivent être déplacées une à
une avec la commande `ALTER TABLE ... SET TABLESPACE`.

```sql
$ \! mkdir /var/lib/pgsql/tb1
$ \! mkdir /var/lib/pgsql/tb2
$ CREATE TABLESPACE tb1 LOCATION '/var/lib/pgsql/tb1/';
$ CREATE TABLESPACE tb2 LOCATION '/var/lib/pgsql/tb2/';

$ CREATE TABLE foo (i INT) PARTITION BY RANGE (i) TABLESPACE tb1;
$ CREATE TABLE foo_1_5 PARTITION OF foo FOR VALUES FROM  (1) TO (5);

$ \d foo_1_5 
              Table "public.foo_1_5"
 Column |  Type   | Collation | Nullable | Default 
--------+---------+-----------+----------+---------
 i      | integer |           |          | 
Partition of: foo FOR VALUES FROM (1) TO (5)
Tablespace: "tb1"

$ ALTER TABLE foo SET TABLESPACE tb2;
$ CREATE TABLE foo_6_10 PARTITION OF foo FOR VALUES FROM (6) TO (10) TABLESPACE tb2;

$ SELECT tablename, tablespace FROM pg_tables WHERE tablename LIKE 'foo%';
 tablename | tablespace 
-----------+------------
 foo       | tb2
 foo_1_5   | tb1
 foo_6_10  | tb2
```
</div>

----

### Fonctions d'information sur le partitionnement

<div class="slide-content">

  * `pg_partition_root(regclass)` 
  * `pg_partition_ancestors(regclass)`
  * `pg_partition_tree(regclass)`
  
</div>


<div class="notes">

Trois nouvelles fonctions permettent de récupérer les informations d'un partitionnement à partir de la table mère ou à partir d'une des partitions.

`pg_partition_root` renvoie la partition mère d'une partition,
`pg_partition_ancestors` renvoie la partition mère ainsi que la partition concernée,
`pg_partition_tree` renvoie tout l'arbre de la partition sous forme de tuples

</div>

----

### Commande psql pour les tables partitionnées


<div class="slide-content">

  * Commande `\dP[tin+] [PATTERN]`
  
</div>


<div class="notes">

Le client psql est maintenant doté d'une commande rapide pour lister les tables partitionnées :

```
\dP
List of partitioned relations
Schema |   Name    |  Owner   |       Type        | Table 
--------+-----------+----------+-------------------+-------
public | foo      | postgres | partitioned table | 
public | bar      | postgres | partitioned table | 
public | foo_pkey | postgres | partitioned index | foo
public | bar_pkey | postgres | partitioned index | bar
```

</div>

---
