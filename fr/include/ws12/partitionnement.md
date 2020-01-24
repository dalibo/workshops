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
$ \d mere 
          Partitioned table "public.mere"
Column |  Type   | Collation | Nullable | Default 
--------+---------+-----------+----------+---------
i      | integer |           | not null | 
idlieu | integer |           |          | 
Partition key: RANGE (i)
Indexes:
  "mere_pkey" PRIMARY KEY, btree (i)
Foreign-key constraints:
  "mere_idlieu_fkey" FOREIGN KEY (idlieu) REFERENCES lieu(id)
Referenced by:
  TABLE "pere" CONSTRAINT "pere_idmere_fkey" FOREIGN KEY (idmere) REFERENCES mere(i)
Number of partitions: 2 (Use \d+ to list them.)

$ CREATE TABLE public.fille_1_5 (
    i integer NOT NULL,
    idlieu integer
);

$ ALTER TABLE ONLY public.mere ATTACH PARTITION public.fille_1_5 FOR VALUES FROM (1) TO (5);

$ CREATE TABLE pere (
    i INT PRIMARY KEY, 
    idlieu INT REFERENCES lieu(id), 
    idmere INT REFERENCES mere(i)
  ) PARTITION BY RANGE (i);

$ \d pere
          Partitioned table "public.pere"
 Column |  Type   | Collation | Nullable | Default 
--------+---------+-----------+----------+---------
 i      | integer |           | not null | 
 idlieu | integer |           |          | 
 idmere | integer |           |          | 
Partition key: RANGE (i)
Indexes:
    "pere_pkey" PRIMARY KEY, btree (i)
Foreign-key constraints:
    "pere_idlieu_fkey" FOREIGN KEY (idlieu) REFERENCES lieu(id)
    "pere_idmere_fkey" FOREIGN KEY (idmere) REFERENCES mere(i)
Number of partitions: 0

$ \d fille_1_5 
          Table "public.fille_1_5"
Column |  Type   | Collation | Nullable | Default 
--------+---------+-----------+----------+---------
i      | integer |           | not null | 
idlieu | integer |           |          | 
Partition of: mere FOR VALUES FROM (1) TO (5)
Indexes:
  "fille_1_5_pkey" PRIMARY KEY, btree (i)
Foreign-key constraints:
  TABLE "mere" CONSTRAINT "mere_idlieu_fkey" FOREIGN KEY (idlieu) REFERENCES lieu(id)
Referenced by:
  TABLE "pere" CONSTRAINT "pere_idmere_fkey" FOREIGN KEY (idmere) REFERENCES mere(i)
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

$ CREATE TABLE mere (i INT) PARTITION BY RANGE (i) TABLESPACE tb1;
$ CREATE TABLE fille_1_5 PARTITION OF mere FOR VALUES FROM  (1) TO (5);

$ \d fille_1_5 
             Table "public.fille_1_5"
 Column |  Type   | Collation | Nullable | Default 
--------+---------+-----------+----------+---------
 i      | integer |           |          | 
Partition of: mere FOR VALUES FROM (1) TO (5)
Tablespace: "tb1"

$ ALTER TABLE mere SET TABLESPACE tb2;
$ CREATE TABLE fille_6_10 PARTITION OF mere FOR VALUES FROM  (6) TO (10) TABLESPACE tb2;

$ SELECT tablename, tablespace FROM pg_tables 
   WHERE tablename = 'mere' OR tablename LIKE 'fille%';

 tablename  | tablespace 
------------+------------
 mere       | tb2
 fille_1_5  | tb1
 fille_6_10 | tb2
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
\dP+
List of partitioned relations
Schema |   Name    |  Owner   |       Type        | Table 
--------+-----------+----------+-------------------+-------
public | mere      | postgres | partitioned table | 
public | meteo     | postgres | partitioned table | 
public | pere      | postgres | partitioned table | 
public | mere_pkey | postgres | partitioned index | mere
public | pere_pkey | postgres | partitioned index | pere
```

</div>

---
