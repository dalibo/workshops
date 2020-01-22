## Partitionnement

<div class="slide-content">

  * Clés étrangères
  * Fonctions d'information : 
    * `pg_partition_root()`
    * `pg_partition_ancestors()`
    * `pg_partition_tree()`
  * Commande `\dP`

</div>  

<div class="notes">


</div>

----

### Clés étrangères dans les tables partitionnées 

<div class="slide-content">

  * Support des clés étrangères entre tables partitionnées
  
</div>


<div class="notes">

Il est désormais possible de mettre en place une clé étrangère dans une tables partitionnée vers une autre table partitionnée. La relation sera établie entre la table partitionnée et toutes les partitions de la table référencée.

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
ALTER TABLE ONLY public.mere ATTACH PARTITION public.fille_1_5 FOR VALUES FROM (1) TO (5);

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
