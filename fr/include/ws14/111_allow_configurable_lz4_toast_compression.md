<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2813/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=bbe0a81db69bd10bd166907c3701492a29aca294

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/111

-->

<div class="slide-content">

* Il est maintenant possible de compresser les données `TOAST` au format `lz4`
* Nécessite l'option `--with-lz4` à la compilation
* Plusieurs niveaux de définition (globale ou par colonne)
* Nouvelle option `--no-toast-compression` pour `pg_dump`
* N'affecte pas le fonctionnement de la réplication

</div>

<div class="notes">

Historiquement, le seul algorithme de compression disponible dans PostgreSQL était `pglz`. À présent, il est possible d'utiliser `lz4` et de définir un type de compression jusqu'au niveau d'une colonne.

Afin de pouvoir utiliser `lz4`, il faudra veiller à ce que PostgreSQL ait bien été compilé avec l'option `--with-lz4` et que le paquet `liblz4-dev` pour Debian ou `lz4-devel` pour RedHat soit installé.

```bash
# Vérification des options de compilation de PostgreSQL
postgres@pop-os:~$ pg_config | grep 'with-lz4'
CONFIGURE =  [...] '--with-lz4' [...]
```

Plusieurs options sont disponibles pour changer le mode de compression :

* Au niveau de la colonne lors des opérations de `CREATE TABLE` et `ALTER TABLE`.

```sql
test=# create table t1 (champ1 text compression lz4);

test=# \d+ t1
                                                   Table « public.t1 »
 Colonne | Type | Collationnement | NULL-able | Par défaut | Stockage | Compression 
---------+------+-----------------+-----------+------------+----------+-------------
 champ1  | text |                 |           |            | extended | lz4         

test=# alter table t1 alter column champ1 set compression pglz;

test=# \d+ t1
                                                   Table « public.t1 »
 Colonne | Type | Collationnement | NULL-able | Par défaut | Stockage | Compression 
---------+------+-----------------+-----------+------------+----------+-------------
 champ1  | text |                 |           |            | extended | pglz        

```

* Via le paramètre `default_toast_compression` dans le fichier `postgresql.conf`, la valeur par defaut étant `pglz`. Sa modification ne nécessite qu'un simple rechargement de l'instance. Ce paramètre étant global à l'instance, il n'est pas prioritaire sur la clause `COMPRESSION` des commandes `CREATE TABLE` et `ALTER TABLE`.

```sql
test=# show default_toast_compression;
 default_toast_compression 
---------------------------
 pglz

test=# SET default_toast_compression TO lz4;

test=# show default_toast_compression;
 default_toast_compression 
---------------------------
 lz4
```

La modification du type de compression, qu'elle soit globale ou spécifique à un objet, n'entraînera aucune réécriture, seules les futures données insérées seront concernées. Il est donc tout à fait possible d'avoir des lignes compressées différemment dans une même table.

Une nouvelle fonction est également disponible : `pg_column_compression()` retourne l'algorithme de compression qui a été utilisé lors de l'insertion d'une ligne.

```sql
test=# SHOW default_toast_compression ;
 default_toast_compression 
---------------------------
 pglz
test=# create table t2 (champ2 text);

test=# insert into t2 values (repeat('123456789', 5000));

test=# SET default_toast_compression TO lz4;

test=# insert into t2 values (repeat('123456789', 5000));

test=# select pg_column_compression(champ2) from t2;
 pg_column_compression 
-----------------------
 pglz
 lz4
```

Point particulier concernant les commandes de type `CREATE TABLE AS`, `SELECT INTO` ou encore `INSERT ... SELECT`, les valeurs déjà compressées dans la table source ne seront pas recompressées lors de l'insertion pour des raisons de performance.

```sql
test=# select pg_column_compression(champ2) from t2;
 pg_column_compression 
-----------------------
 pglz
 lz4

test=# create table t3 as select * from t2;

test=# select pg_column_compression(champ2) from t3;
 pg_column_compression 
-----------------------
 pglz
 lz4
```

Concernant la réplication, il est possible de rejouer les WAL qui contiennent des données compressées avec `lz4` sur une instance secondaire via les réplications physique ou logique même si celle-ci ne dispose pas de `lz4`.
Il faudra cependant faire attention en cas d'utilisation d'algorithmes différents entre primaire et secondaire notamment au niveau de la volumétrie et du temps nécessaire à la compression.

```sql
-- Un exemple simple afin de mettre en évidence la différence
-- entre les deux algorithmes
test=# \d+ compress_pglz
                                              Table « public.compress_pglz »
 Colonne | Type | Collationnement | NULL-able | Par défaut | Stockage | Compression 
---------+------+-----------------+-----------+------------+----------+-------------
 champ1  | text |                 |           |            | extended | pglz        

test=# \d+ compress_lz4 
                                              Table « public.compress_lz4 »
 Colonne | Type | Collationnement | NULL-able | Par défaut | Stockage | Compression 
---------+------+-----------------+-----------+------------+----------+-------------
 champ1  | text |                 |           |            | extended | lz4         

-- Comparaison à l'insertion des données
test=# insert into compress_pglz select repeat('123456789', 100000) from generate_series(1,10000);
Durée : 36934,700 ms

test=# insert into compress_lz4 select repeat('123456789', 100000) from generate_series(1,10000);
Durée : 2367,150 ms

-- Comparaison de la volumétrie
-- pour les données TOAST compréssées avec pglz
test=# select pg_size_pretty(pg_relation_size('pg_toast.pg_toast_16476'));
 pg_size_pretty 
----------------
 117 MB

-- pour les données TOAST compressées avec lz4
test=# select pg_size_pretty(pg_relation_size('pg_toast.pg_toast_16481'));
 pg_size_pretty 
----------------
 39 MB
```

Afin d'éviter les problèmes de compatibilité, l'option `--no-toast-compression` a été ajoutée à `pg_dump`. Elle permet de ne pas exporter les méthodes de compression définies avec `CREATE TABLE` et `ALTER TABLE`.

Pour les données déjà insérées et compressées, s'il y a un besoin de changement ou d'unification des algorithmes employés, il faudra passer par une procédure d'export / import. Avec cette méthode, les lignes seront réinsérées en utilisant la clause `COMPRESSION` des colonnes concernées ou à défaut le paramètre `default_toast_compression`.

<!-- 
D'après le _commit_ de cette nouveauté disponible [ici](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=bbe0a81db69bd10bd166907c3701492a29aca294), une commande `VACUUM FULL` ou `CLUSTER` devrait permettre de modifier la compression des lignes déjà insérées. Cependant, nous n'avons pas réussi à reproduire ce comportement pendant nos tests.
-->

</div>