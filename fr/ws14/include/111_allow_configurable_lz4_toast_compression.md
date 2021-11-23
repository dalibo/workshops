<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2813/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=bbe0a81db69bd10bd166907c3701492a29aca294

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/111

-->

<div class="slide-content">
* Historiquement : `pglz`
* Nouveau : `lz4`, plus rapide
* Nécessite `--with-lz4` à la compilation
* Définition :
  * `SET default_toast_compression = …`
  * `ALTER TABLE … SET COMPRESSION …`
* Compatibilité : `pg_dump --no-toast-compression`
* N'affecte pas le fonctionnement de la réplication

</div>

<div class="notes">

Historiquement, le seul algorithme de compression disponible dans PostgreSQL était `pglz`. À présent, il est possible d'utiliser `lz4` et de définir un type de compression jusqu'au niveau d'une colonne.

De manière générale, `lz4` est nettement plus rapide à (dé)compresser, pour un taux de
compression légèrement plus faible que l'algorithme historique.

Afin de pouvoir utiliser `lz4`, il faudra veiller à ce que PostgreSQL ait bien été compilé avec l'option `--with-lz4` et que le paquet `liblz4-dev` pour Debian ou `lz4-devel` pour RedHat soit installé. Les paquets précompilés du PGDG incluent cela.

```bash
# Vérification des options de compilation de PostgreSQL
postgres@pop-os:~$ pg_config | grep 'with-lz4'
CONFIGURE =  [...] '--with-lz4' [...]
```

Plusieurs options sont disponibles pour changer le mode de compression :

* Au niveau de la colonne, lors des opérations de `CREATE TABLE` et `ALTER TABLE`.

```sql
test=# CREATE TABLE t1 (champ1 text COMPRESSION lz4);

test=# \d+ t1
                                                   Table « public.t1 »
 Colonne | Type | Collationnement | NULL-able | Par défaut | Stockage | Compression 
---------+------+-----------------+-----------+------------+----------+-------------
 champ1  | text |                 |           |            | extended | lz4         

test=# ALTER TABLE t1 ALTER COLUMN champ1 SET COMPRESSION pglz;

test=# \d+ t1
                                                   Table « public.t1 »
 Colonne | Type | Collationnement | NULL-able | Par défaut | Stockage | Compression 
---------+------+-----------------+-----------+------------+----------+-------------
 champ1  | text |                 |           |            | extended | pglz        

```

* Via le paramètre `default_toast_compression` dans le fichier `postgresql.conf`,
  la valeur par defaut étant `pglz`. Sa modification ne nécessite qu'un simple
  rechargement de la configuration de l'instance. Ce paramètre étant global à
  l'instance, il n'est pas prioritaire sur la clause `COMPRESSION` des commandes
  `CREATE TABLE` et `ALTER TABLE`.

```sql
test=# SHOW default_toast_compression;
 default_toast_compression 
---------------------------
 pglz

test=# SET default_toast_compression TO lz4;

test=# SHOW default_toast_compression;
 default_toast_compression 
---------------------------
 lz4
```

La modification du type de compression, qu'elle soit globale ou spécifique à un objet, n'entraînera aucune réécriture, seules les futures données insérées seront concernées. Il est donc tout à fait possible d'avoir des lignes compressées différemment dans une même table.

Pour le voir, une nouvelle fonction est également disponible : `pg_column_compression()` retourne l'algorithme de compression qui a été utilisé lors de l'insertion d'une ligne. Il peut y en avoir plusieurs :

```sql
test=# SHOW default_toast_compression ;
 default_toast_compression 
---------------------------
 pglz
test=# CREATE TABLE t2 (champ2 text);

test=# INSERT INTO t2 VALUES (repeat('123456789', 5000));

test=# SET default_toast_compression TO lz4;

test=# INSERT INTO t2 VALUES (repeat('123456789', 5000));

test=# SELECT pg_column_compression(champ2) FROM t2;
 pg_column_compression 
-----------------------
 pglz
 lz4
```

Point particulier concernant les commandes de type `CREATE TABLE AS`, `SELECT INTO` ou encore `INSERT ... SELECT`, les valeurs déjà compressées dans la table source ne seront pas recompressées lors de l'insertion pour des raisons de performance.

```sql
test=# SELECT pg_column_compression(champ2) FROM t2;
 pg_column_compression 
-----------------------
 pglz
 lz4

test=# CREATE TABLE t3 AS SELECT * FROM t2;

test=# SELECT pg_column_compression(champ2) FROM t3;
 pg_column_compression 
-----------------------
 pglz
 lz4
```

Concernant la réplication, il est possible de rejouer les WAL qui contiennent des données compressées avec `lz4` sur une instance secondaire via les réplications physique ou logique même si celle-ci ne dispose pas de `lz4`.

Principal inconvénient de la réplication physique, toute tentative de lecture de ces données entraînera une erreur.

La réplication logique n'est pas impactée par ce problème, les données seront compressées en utilisant l'algorithme configuré sur le secondaire. Il faudra cependant faire attention en cas d'utilisation d'algorithmes différents entre primaire et secondaire notamment au niveau de la volumétrie et du temps nécessaire à la compression.

<!-- plutôt théoriques , ces problèmes, si on reste en v14 et paquets du PGDG... -->

Un exemple simple afin de mettre en évidence la différence
entre les deux algorithmes :

```sql
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
test=# INSERT INTO compress_pglz SELECT repeat('123456789', 100000) FROM generate_series(1,10000);
Durée : 36934,700 ms

test=# INSERT INTO compress_lz4 SELECT repeat('123456789', 100000) FROM generate_series(1,10000);
Durée : 2367,150 ms
```

Le nouvel algorithme est donc beaucoup plus performant.

<!-- requête suivante de module M4 -->
```sql
# SELECT
    c.relnamespace::regnamespace || '.' || relname AS TABLE,
    reltoastrelid::regclass::text AS table_toast,
    reltuples AS nb_lignes_estimees,
    pg_size_pretty(pg_relation_size(c.oid)) AS "  Heap",
    pg_size_pretty(pg_relation_size(reltoastrelid)) AS "  Toast",
    pg_size_pretty(pg_indexes_size(reltoastrelid)) AS  "  Toast (PK)",
    pg_size_pretty(pg_total_relation_size(c.oid)) AS "Total"
FROM  pg_class c
WHERE relkind = 'r'
AND   relname LIKE 'compress%' \gx
```
```sh
-[ RECORD 1 ]------+-------------------------
table              | public.compress_lz4
table_toast        | pg_toast.pg_toast_357496
nb_lignes_estimees | 10000
  Heap             | 512 kB
  Toast            | 39 MB
  Toast (PK)       | 456 kB
Total              | 40 MB
-[ RECORD 2 ]------+-------------------------
table              | public.compress_pglz
table_toast        | pg_toast.pg_toast_357491
nb_lignes_estimees | 10000
  Heap             | 512 kB
  Toast            | 117 MB
  Toast (PK)       | 1328 kB
Total              | 119 MB
```

Dans ce cas précis, `lz4` est plus efficace à la compression. Ce n'est pas le cas
général, comme constaté dans cet [article de Fujitsu](https://www.postgresql.fastware.com/blog/what-is-the-new-lz4-toast-compression-in-postgresql-14) : `lz4` est généralement un peu moins
efficace en compression.
<!--  TODO ? Refaire l'exemple avec la base textes du projet Gutenberg ?
La compression est la même.
create table textes_pglz AS SELECT livre, string_agg (contenu, ' ') AS contenu
FROM (SELECT * FROM textes  ORDER BY livre, ligne) t GROUP BY livre;
-->

Afin d'éviter les problèmes de compatibilité avec des versions plus anciennes, l'option `--no-toast-compression` a été ajoutée à `pg_dump`. Elle permet de ne pas exporter les méthodes de compression définies avec `CREATE TABLE` et `ALTER TABLE`.

Pour les données déjà insérées et compressées, s'il y a un besoin de changement ou d'unification des algorithmes employés, il faudra le forcer par une procédure d'export/import. Avec cette méthode, les lignes seront réinsérées en utilisant la clause `COMPRESSION` des colonnes concernées ou à défaut le paramètre `default_toast_compression`.

<!-- 
D'après le _commit_ de cette nouveauté disponible [ici](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=bbe0a81db69bd10bd166907c3701492a29aca294), une commande `VACUUM FULL` ou `CLUSTER` devrait permettre de modifier la compression des lignes déjà insérées. Cependant, nous n'avons pas réussi à reproduire ce comportement pendant nos tests.
-->
<!--
Apparemment il faut un UPDATE SET champ1=champ1||''  pour que le champ soit bien dé- 
et re-compressé.
-->

</div>

