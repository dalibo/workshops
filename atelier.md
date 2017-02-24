## Atelier

<div class="notes">
### Installation
Les machines de la salle de formation sont en CentOS 6. L'utilisateur dalibo peut utiliser sudo pour les opérations système.

Le site postgresql.org propose son propre dépôt RPM, nous allons donc l'utiliser.

```
rpm -ivh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-
6-x86_64/pgdg-centos96-9.6-3.noarch.rpm

Retrieving https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-
6-x86_64/pgdg-centos96-9.6-3.noarch.rpm
Preparing...               ########################################### [100%]
   1:pgdg-centos96        ########################################### [100%]
```





```
yum install postgresql96 postgresql96-server postgresql96-contrib
```

Les paquets suivants seront installés :

```
(1/5): libxslt-1.1.26-2.el6_3.1.x86_64.rpm
(2/5): postgresql96-9.6.0-1PGDG.rhel6.x86_64.rpm
(3/5): postgresql96-contrib-9.6.0-1PGDG.rhel6.x86_64.rpm
(4/5): postgresql96-libs-9.6.0-1PGDG.rhel6.x86_64.rpm
(5/5): postgresql96-server-9.6.0-1PGDG.rhel6.x86_64.rpm
```

Commençons par créer une instance PostgreSQL 9.6 :

```
sudo /etc/init.d/postgresql-9.6 initdb
Initialisation de la base de données :                     [  OK  ]
```

Et par la lancer (ce n'est pas automatique sur RedHat/CentOS) :

```
sudo /etc/init.d/postgresql-9.6 start
```

Les fichiers de la base de données seront dans `/var/lib/pgsql/9.6/data`, y compris `postgresql.conf` et `pg_hba.conf`.

Pour se connecter sans modifier `pg_hba.conf` :

```
sudo -iu postgres psql
```





### Parallélisation
Créer les tables suivantes :

```sql
CREATE TABLE t1 AS SELECT * FROM generate_series(1,51110000) id;
CREATE TABLE t2 AS SELECT * FROM generate_series(1,30000000) id;
CREATE TABLE t3 AS SELECT * FROM generate_series(1,3100000) id;
```

Modifier le paramètre `max_parallel_workers_per_gather` afin de permettre la parallélisation.


  * Calculer la taille de chaque objet :

```sql
b1=# SELECT pg_relation_size('t1')/1024/8 AS t1_blocks_nb;
 t1_blocks_nb
--------------
   226151
(1 ligne)

b1=# SELECT pg_relation_size('t2')/1024/8 AS t2_blocks_nb;
 t2_blocks_nb
--------------
   132744
(1 row)

b1=# SELECT pg_relation_size('t3')/1024/8 AS t3_blocks_nb;
 t3_blocks_nb
--------------
   13717
(1 row)
```

  * Chercher le plan d'un SELECT sur toute la table :

```sql
b1=# EXPLAIN (ANALYZE,BUFFERS,VERBOSE) SELECT * FROM t1;
                                QUERY PLAN
----------------------------------------------------------------------------
 Seq Scan on public.t1  (cost=0.00..737251.16 rows=51110016 width=4)
   (actual time=0.025..2823.214 rows=51110000 loops=1)
   Output: id
   Buffers: shared hit=769 read=225382
 Planning time: 0.027 ms
 Execution time: 4477.773 ms
(5 rows)
```


=> Pas de Parallélisation : le coût pour remonter les lignes au gather est trop important.


  * Si l'on teste avec un filtre :

```sql
b1=# EXPLAIN (ANALYZE,BUFFERS,VERBOSE) SELECT * FROM t1 WHERE id = 4;
                                  QUERY PLAN
------------------------------------------------------------------------------
 Gather  (cost=1000.00..386869.90 rows=1 width=4)
   (actual time=0.170..1096.948 rows=1 loops=1)
   Output: id
   Workers Planned: 4
   Workers Launched: 4
   Buffers: shared hit=1202 read=225153
   ->  Parallel Seq Scan on public.t1  (cost=0.00..385869.80 rows=1 width=4)
         (actual time=852.222..1071.570 rows=0 loops=5)
         Output: id
         Filter: (t1.id = 4)
         Rows Removed by Filter: 10222000
         Buffers: shared hit=998 read=225153
         Worker 0: actual time=1065.204..1065.204 rows=0 loops=1
           Buffers: shared hit=149 read=46784
         Worker 1: actual time=1065.214..1065.214 rows=0 loops=1
           Buffers: shared hit=157 read=35837
         Worker 2: actual time=1065.336..1065.336 rows=0 loops=1
           Buffers: shared hit=162 read=35762
         Worker 3: actual time=1065.331..1065.331 rows=0 loops=1
           Buffers: shared hit=361 read=62164
 Planning time: 0.040 ms
 Execution time: 1108.502 ms
```


Moins de lignes à retourner : Parallélisation (cf le paramètre
`parallel_tuple_cost` qui indique le coût par ligne)

Lire les compteurs loops et row.

Compter les blocs


  * Test avec une jointure :

```sql
b1=# EXPLAIN (ANALYZE,BUFFERS,VERBOSE)
     SELECT * FROM t1 JOIN t2 ON t1.id=t2.id;
                                   QUERY PLAN
---------------------------------------------------------------------------------
 Hash Join  (cost=924932.72..4523070.84 rows=30000032 width=8)
   (actual time=5315.295..41891.417 rows=30000000 loops=1)
   Output: t1.id, t2.id
   Hash Cond: (t1.id = t2.id)
   Buffers: shared hit=1636 read=357262, temp read=238699 written=237677
   ->  Seq Scan on public.t1  (cost=0.00..737251.16 rows=51110016 width=4)
         (actual time=0.033..3210.287 rows=51110000 loops=1)
         Output: t1.id
         Buffers: shared hit=1158 read=224993
   ->  Hash  (cost=432744.32..432744.32 rows=30000032 width=4)
         (actual time=5311.760..5311.760 rows=30000000 loops=1)
         Output: t2.id
         Buckets: 131072  Batches: 512  Memory Usage: 3083kB
         Buffers: shared hit=475 read=132269, temp written=87470
         ->  Seq Scan on public.t2  (cost=0.00..432744.32 rows=30000032 width=4)
               (actual time=0.019..1849.495 rows=30000000 loops=1)
               Output: t2.id
               Buffers: shared hit=475 read=132269
 Planning time: 0.199 ms
 Execution time: 42907.328 ms
(16 rows)
```



Là encore trop de lignes retournées, et pas de Parallélisation


  * Jointure avec présence d'un filtre :

```sql
b1=# EXPLAIN (ANALYZE,BUFFERS,VERBOSE)
     SELECT * FROM t1 JOIN t2 ON t1.id=t2.id WHERE t2.id = 100000;
                                  QUERY PLAN
----------------------------------------------------------------------------------
 Nested Loop  (cost=2000.00..803393.83 rows=1 width=8)
   (actual time=1546.641..2173.989 rows=1 loops=1)
   Output: t1.id, t2.id
   Buffers: shared hit=2298 read=356813
   ->  Gather  (cost=1000.00..493349.10 rows=1 width=4)
         (actual time=1542.343..1542.345 rows=1 loops=1)
         Output: t1.id
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=1294 read=224965
         ->  Parallel Seq Scan on public.t1  (cost=0.00..492349.00 rows=1 width=4)
               (actual time=1027.876..1539.231 rows=0 loops=3)
               Output: t1.id
               Filter: (t1.id = 100000)
               Rows Removed by Filter: 17036666
               Buffers: shared hit=1186 read=224965
               Worker 0: actual time=1536.289..1536.289 rows=0 loops=1
                 Buffers: shared hit=263 read=52931
               Worker 1: actual time=5.143..1539.207 rows=1 loops=1
                 Buffers: shared hit=628 read=119079
   ->  Gather  (cost=1000.00..310044.72 rows=1 width=4)
         (actual time=4.296..631.640 rows=1 loops=1)
         Output: t2.id
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=1004 read=131848
         ->  Parallel Seq Scan on public.t2  (cost=0.00..309044.62 rows=1 width=4)
               (actual time=420.601..629.706 rows=0 loops=3)
               Output: t2.id
               Filter: (t2.id = 100000)
               Rows Removed by Filter: 10000000
               Buffers: shared hit=896 read=131848
               Worker 0: actual time=627.925..627.925 rows=0 loops=1
                 Buffers: shared hit=304 read=43543
               Worker 1: actual time=629.771..629.771 rows=0 loops=1
                 Buffers: shared hit=312 read=44036
 Planning time: 0.063 ms
 Execution time: 2175.036 ms
(33 rows)
```


=> On obtient une jointure entre deux parallel seq scan. Ce n'est pas
une jointure parallélisée ! La parallélisation n'a joué que sur les
parcours des deux tables, toutes les deux filtrées par la condition.


  * Jointure avec un filtre retournant de nombreuses lignes.

```sql
EXPLAIN (ANALYZE,BUFFERS,VERBOSE)
SELECT * FROM t1 JOIN t3 ON t1.id=t3.id WHERE t1.id < 400000;
                                   QUERY PLAN
--------------------------------------------------------------------------------
 Gather  (cost=84467.00..581042.97 rows=28735 width=8)
   (actual time=734.866..1889.276 rows=399999 loops=1)
   Output: t1.id, t3.id
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=37823 read=229759
   ->  Hash Join  (cost=83467.00..577169.47 rows=28735 width=8)
         (actual time=744.604..1804.314 rows=133333 loops=3)
         Output: t1.id, t3.id
         Hash Cond: (t1.id = t3.id)
         Buffers: shared hit=37703 read=229759
         Worker 0: actual time=747.513..1823.809 rows=174698 loops=1
           Buffers: shared hit=13202 read=75647
         Worker 1: actual time=751.694..1826.538 rows=166089 loops=1
           Buffers: shared hit=12929 read=75868
         ->  Parallel Seq Scan on public.t1  (cost=0.00..492349.00 rows=197398
               width=4) (actual time=0.041..1014.365 rows=133333 loops=3)
               Output: t1.id
               Filter: (t1.id < 400000)
               Rows Removed by Filter: 16903334
               Buffers: shared hit=673 read=225478
               Worker 0: actual time=0.047..1018.647 rows=174698 loops=1
                 Buffers: shared hit=217 read=74835
               Worker 1: actual time=0.046..1018.083 rows=166089 loops=1
                 Buffers: shared hit=217 read=74783
         ->  Hash  (cost=44717.00..44717.00 rows=3100000 width=4)
               (actual time=729.633..729.633 rows=3100000 loops=3)
               Output: t3.id
               Buckets: 4194304  Batches: 1  Memory Usage: 141753kB
               Buffers: shared hit=36870 read=4281
               Worker 0: actual time=733.596..733.596 rows=3100000 loops=1
                 Buffers: shared hit=12905 read=812
               Worker 1: actual time=737.104..737.104 rows=3100000 loops=1
                 Buffers: shared hit=12632 read=1085
               ->  Seq Scan on public.t3  (cost=0.00..44717.00 rows=3100000
                     width=4) (actual time=0.013..183.375 rows=3100000 loops=3)
                     Output: t3.id
                     Buffers: shared hit=36870 read=4281
                     Worker 0: actual time=0.014..185.594 rows=3100000 loops=1
                       Buffers: shared hit=12905 read=812
                     Worker 1: actual time=0.019..187.250 rows=3100000 loops=1
                       Buffers: shared hit=12632 read=1085
 Planning time: 0.156 ms
 Execution time: 1911.047 ms
(39 rows)
```



Là on a une jointure (_hash join_) parallélisé.

Note : _Rows Removed by Filter: 16903334_ => à multiplier pour le nombre de loops => 50710002

Dans le hash de t3 : La table t3 est lue 3 fois!

```
Buffers: shared hit=36870 read=4281 => 41151 = t3*3 = 13717 *3
```

Chaque worker a lu la table une fois et le gather l'a lu une fois
également.

Pour vérifier les nombres de lignes ou blocs lus , consulter les
tables système `pg_stat_user_tables` ou `pg_stat_io_user_tables`, que
vous pouvez réinitialiser entre deux essais avec la fonction
`pg_stat_reset`.

  * Les multiples parcours de t3 ci-dessus n'étaient possibles que
    parce que t3 tenait en mémoire. Exécuter la requête précédente en
    modifiant `work_mem` (mémoire de travail disponible au processus
    dédié, retournée avec `show work_mem`, modifiable avec `set
    work_mem = '12MB' `, `1 GB ` ou `96MB`)






### Index bloom

  * Nous allons comparer un index btree classique et un bloom sur seulement deux attributs :

```sql
-- pour garantir une reproductibilité des ordres random() ci-dessous
SELECT setseed(1);

CREATE TABLE tab800 AS
  SELECT generate_series AS id,
    (random()*1000)::int4 AS bla,         -- integer
    md5(random()::text) AS bli,           -- varchar
    (random()*1000) AS blu                -- double precision
  FROM generate_series (1, 10*1000*1000); --800 Mo et 10 millions de lignes

\d tab800

CREATE INDEX idx_bt_tab800 ON tab800 USING btree (bla, bli varchar_pattern_ops);

ANALYZE tab800;
```

La ligne qui va nous servir d'exemple à rechercher vaudra `bla=50` et
`bli = 'e00b425b7ff60f42bd5fa61e043a46d6'`.


  * Le plus efficace dans ce cas précis restera le btree (`Index Seq Scan`) :

```sql
EXPLAIN ANALYZE
SELECT * FROM tab800 WHERE bla = 50 AND bli = 'e00b425b7ff60f42bd5fa61e043a46d6';
```

  * Si le critère ne porte que sur la deuxième colonne, l'index
    devient inutilisable et on se retrouve avec un Seq Scan sur la
    table même :

```sql
EXPLAIN (ANALYZE ,VERBOSE, BUFFERS)
SELECT * FROM tab800 WHERE bli = 'e00b425b7ff60f42bd5fa61e043a46d6';
```

  * Ajouter l'index bloom :

```sql
CREATE EXTENSION bloom;

CREATE INDEX idx_bloom_tab800 ON tab800 USING bloom (bla, bli text_ops);

ANALYZE tab800 ;
```

  * Comparer les tailles de la table et des index

```sql
SELECT
  relname,
  pg_size_pretty( pg_relation_size(relname::text) ) AS taille,
  relpages AS nb_blocs
FROM pg_class
WHERE relname LIKE '%tab800%';
```

  * Mêmes recherches avec l'index bloom seul :

```sql
DROP INDEX idx_bt_tab800 ;

EXPLAIN (ANALYZE ,VERBOSE, BUFFERS)
SELECT *
FROM tab800
WHERE bla = 50 AND bli = 'e00b425b7ff60f42bd5fa61e043a46d6';
```


Le plan obtenu est le suivant. L'index bloom est moins efficace que le
btree car il doit être parcouru entièrement. Noter les mentions sur le
besoin de retourner dans la table filtrer les lignes : 7 sont alors
filtrées alors que l'index les avait trouvées.

```
                                    QUERY PLAN
-----------------------------------------------------------------------------------
 Bitmap Heap Scan on public.tab800  (cost=178436.00..178440.02 rows=1 width=49)
   (actual time=84.572..84.581 rows=1 loops=1)
   Output: id, bla, bli, blu
   Recheck Cond: ((tab800.bla = 50) AND
     (tab800.bli = 'e00b425b7ff60f42bd5fa61e043a46d6'::text))
   Rows Removed by Index Recheck: 7
   Heap Blocks: exact=8
   Buffers: shared hit=19616
   ->  Bitmap Index Scan on idx_tab800_bloom  (cost=0.00..178436.00 rows=1 width=0)
         (actual time=84.554..84.554 rows=8 loops=1)
         Index Cond: ((tab800.bla = 50) AND
           (tab800.bli = 'e00b425b7ff60f42bd5fa61e043a46d6'::text))
         Buffers: shared hit=19608
 Planning time: 0.291 ms
 Execution time: 84.678 ms
(11 lignes)
```

  * Par contre si l'on n'a que la deuxième colonne, l'index bloom reste utilisable :

```sql
EXPLAIN (ANALYZE ,VERBOSE, BUFFERS)
SELECT * FROM tab800 WHERE bli = 'e00b425b7ff60f42bd5fa61e043a46d6';

                                     QUERY PLAN
-----------------------------------------------------------------------------------
 Bitmap Heap Scan on public.tab800  (cost=153436.00..153440.01 rows=1 width=49)
   (actual time=68.305..83.765 rows=1 loops=1)
   Output: id, bla, bli, blu
   Recheck Cond: (tab800.bli = 'e00b425b7ff60f42bd5fa61e043a46d6'::text)
   Rows Removed by Index Recheck: 16528
   Heap Blocks: exact=15286
   Buffers: shared hit=34894
   ->  Bitmap Index Scan on idx_tab800_bloom  (cost=0.00..153436.00 rows=1 width=0)
         (actual time=62.100..62.100 rows=16529 loops=1)
         Index Cond: (tab800.bli = 'e00b425b7ff60f42bd5fa61e043a46d6'::text)
         Buffers: shared hit=19608
 Planning time: 0.130 ms
 Execution time: 83.868 ms
(11 lignes)
```


  * Enfin, une des limitations de l'index est son incapacité à gérer
    les inégalités : le code suivant générera un `Seq Scan`.

```sql
EXPLAIN (ANALYZE ,VERBOSE, BUFFERS)
SELECT *
FROM tab800
WHERE bla BETWEEN 50 AND 51 AND bli LIKE 'e00b%';
```



### FDW


  * Dans une première instance : instance1 (celle par défaut sur votre poste)
    * Installer l'extension postgres_fdw
    * Créer un utilisateur bobby avec un mot de passe

  * Dans une seconde instance : instance2 (créée sur le même poste sur un autre port, ou sur une autre machine)
    * Créer un utilisateur bobby avec un mot de passe
    * Créer 2 tables test1 et test2
    * Donner les droits à bobby sur ces deux tables

  * Dans la première instance
    * Créer un serveur distant
    * Créer deux tables distantes atteignant les tables test1 et test2
    * Donner les droits à bobby sur ces deux tables
    * Afficher le plan d'exécution d'une requête réalisant un tri sur une table distante.



  * Sur la première instance (sur laquelle on écrira les requêtes) :

Création de l'extension :

```sql
postgres=# CREATE EXTENSION postgres_fdw;
```

  * Créer la seconde instance si une autre n'est pas
disponible ailleurs. Ce qui suit suppose une instance 9.6 installée sur la
même machine, port 5433.


  * Sur les deux instances, création de l'utilisateur :

```
postgres=# CREATE USER bobby WITH PASSWORD 'bobby';
```

  * Sur la seconde instance on crée la base "distante" et les tables :

```sql
postgres=# CREATE DATABASE distante;
\c distante
distante=# CREATE TABLE table1 (id serial, bla text);
distante=# CREATE TABLE table2 (id serial, bli text);
```

Accorder les droits à l'utilisateur bobby :

```sql
distante=# GRANT SELECT,INSERT ON table1 TO bobby;
distante=# GRANT SELECT,INSERT ON table2 TO bobby;
```

Toujours sur l'instance2, modifier pg_hba.conf pour que l'on puisse se
connecter à l'utilisateur bobby depuis l'instance1:

```sql
host bobby           bobby           127.0.0.1/32         md5
```

Recharger la configuration de l'instance2 : `SELECT
pg_reload_conf();`. Tester la connexion avec `psql -p 5433 -h
localhost distante bobby`


  * Sur l'instance1, ajouter la ligne suivante en tête de pg_hba.conf
pour pouvoir vous connecter en tant que bobby sur votre poste :

```sql
local  postgres           bobby           127.0.0.1/32         md5
```

  * Sur l'instance1, créer le serveur distant en précisant hôte, nom
de base de données et port de la base distante :

```sql
postgres=# CREATE SERVER serveurdistant
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host '127.0.0.1', dbname 'distante', port '5433');
```

Le nom de l'utilisateur est géré séparément, on crée une liaison entre
le bobby de l'instance 1 et celui de l'instance distante :

```sql
postgres=# CREATE USER MAPPING FOR bobby
SERVER serveurdistant OPTIONS (user 'bobby' ,  password 'bobby');
```

Sur l'instance1, créer les deux tables distantes :

```sql
postgres=# CREATE FOREIGN TABLE table1_distante (id serial, bla text)
SERVER serveurdistant OPTIONS (table_name 'table1');

postgres=# CREATE FOREIGN TABLE table2_distante (id serial, bli text)
SERVER serveurdistant OPTIONS (table_name 'table2');
```



Attention !
 * Spécifier le nom de la table accédée n'est pas optionnel.
 * Faire attention à bien déclarer la table distante avec la même définition.
 
On ne peut profiter d'une table distante pour renommer ses
colonnes. Pour définir de nombreuses tables, voir `IMPORT FOREIGN
SCHEMA`.

On peut consulter la liste des tables distantes avec `\det+`.

Accorder les droits à bobby sur les tables distantes :

```
postgres=# GRANT SELECT,INSERT ON table1_distante TO bobby;
postgres=# GRANT SELECT,INSERT ON table2_distante TO bobby;
```

  * Enfin on teste depuis l'instance1 :

Se connecter avec l'utilisateur bobby et afficher le plan d'exécution
d'une sélection triée par l'identifiant :

```sql
\c postgres bobby
postgres=> INSERT INTO table1_distante SELECT generate_series (1, 1000);
postgres=> INSERT INTO table2_distante SELECT generate_series (2, 1000);

postgres=> EXPLAIN (ANALYZE,VERBOSE)
SELECT * FROM table1_distante ORDER BY id;
                                 QUERY PLAN
---------------------------------------------------------------------------
 Sort  (cost=222.03..225.44 rows=1365 width=36)
   (actual time=0.214..0.217 rows=20 loops=1)
   Output: id, bla
   Sort Key: table1_distante.id
   Sort Method: quicksort  Memory: 26kB
   ->  Foreign Scan on public.table1_distante (cost=100.00..150.95
           rows=1365 width=36) (actual time=0.199..0.202 rows=20 loops=1)
         Output: id, bla
         Remote SQL: SELECT id, bla FROM public.table1
 Planning time: 0.056 ms
 Execution time: 0.418 ms
(9 lignes)


postgres=> EXPLAIN (VERBOSE, ANALYZE)
SELECT * FROM table1_distante
JOIN table2_distante
  ON table1_distante.id=table2_distante.id
WHERE table2_distante.id = 1  ;

                                 QUERY PLAN
---------------------------------------------------------------------------
 Foreign Scan  (cost=100.00..155.35 rows=49 width=72)
   (actual time=188.179..188.179 rows=0 loops=1)
   Output: table1_distante.id, table1_distante.bla, table2_distante.id,
     table2_distante.bli
   Relations: (public.table1_distante) INNER JOIN (public.table2_distante)
   Remote SQL: SELECT r1.id, r1.bla, r2.id, r2.bli FROM (public.table1 r1
     INNER JOIN public.table2 r2 ON (((r2.id = 1)) AND ((r1.id = 1))))
 Planning time: 0.371 ms
 Execution time: 188.982 ms
(6 lignes)
```


  * Tenter les mêmes exemples avec des
volumétries plus importantes, chercher la cause des débits assez bas.





### Sauvegardes


  * Faire une sauvegarde classique et vérifier le contenu des fichiers backup_label puis XXXX.XXXX.backup
  * Faire deux sauvegardes concurrentes et vérifier ces mêmes fichiers

Préalable : dans `postgresql.conf`, l'archivage doit être
actif:`wal_level = replica`, `archive_mode = on`, `archive_command =
'cp %p /ARCHIVAGE_LOGS/%f' ` (ou juste pour tester : `archive_command
= '/bin/true' `).


  * Petit rappel de la méthode non concurrente :

```FIXME
postgres=# select pg_start_backup('save95', true);
 pg_start_backup
-----------------
 0/7000028
(1 ligne)
```

La fonction `pg_start_backup()`, en autre, crée un fichier `backup_label`
contenant les informations suivantes :

```
-bash-4.2$ cat backup_label

START WAL LOCATION: 0/7000028 (file 000000010000000000000007)
CHECKPOINT LOCATION: 0/7000060
BACKUP METHOD: pg_start_backup
BACKUP FROM: master
START TIME: 2016-08-12 17:50:47 CEST
LABEL: save95
```

On copie nos fichiers et on termine la sauvegarde :

```
postgres=# SELECT pg_stop_backup();
NOTICE:  pg_stop_backup terminé, tous les journaux de transactions requis
  ont été archivés
 pg_stop_backup
----------------
 0/7000130
```


La fonction `pg_stop_backup()` a ajouté des informations dans le
fichier `backup_label`, qu'elle a renommé et déplacé dans le répertoire
d'archivage.

```
-bash-4.2$ cat 000000010000000000000007.00000028.backup

START WAL LOCATION: 0/7000028 (file 000000010000000000000007)
STOP WAL LOCATION: 0/7000130 (file 000000010000000000000007)
CHECKPOINT LOCATION: 0/7000060
BACKUP METHOD: pg_start_backup
BACKUP FROM: master
START TIME: 2016-08-12 17:50:47 CEST
LABEL: save95
STOP TIME: 2016-08-12 17:51:36 CEST
```

  * Maintenant intéressons nous à la réalisation de deux sauvegardes
concurrentes, depuis deux sessions différentes, la première en étant
connecté sur la base piloup, la suivante sur la base postgres :

```
piloup=# SELECT * FROM pg_start_backup('save96', true, false) ;
 pg_start_backup
-----------------
 1/17000028
(1 ligne)
```

On lance la copie des fichiers de notre instance :

```
cp -R /pg_data/9.6/instance1/* /pg_backup/snapshot/96/save96/
```

On lance la seconde sauvegarde :

```
postgres=# SELECT * FROM pg_start_backup('save96-bis', true, false);
 pg_start_backup
-----------------
 1/18000060
(1 ligne)
```

On lance la copie des fichiers :

```
cp -R /pg_data/9.6/instance1/* /pg_backup/snapshot/96/save96-bis/
```

On termine la première sauvegarde :

```sql
piloup=# SELECT * FROM pg_stop_backup(false);

NOTICE:  pg_stop_backup terminé, tous les journaux de transactions requis ont été
  archivés
    lsn     |                           labelfile                            | spcmapfile
------------+----------------------------------------------------------------+------------
 1/1D0002F0 | START WAL LOCATION: 1/1C000060 (file 00000001000000010000001C)+|
            | CHECKPOINT LOCATION: 1/1C000098                               +|
            | BACKUP METHOD: streamed                                       +|
            | BACKUP FROM: master                                           +|
            | START TIME: 2016-08-12 18:00:38 CEST                          +|
            | LABEL: save96                                                 +|
            |                                                                |
```

Le fichier indiquant la fin du backup apparaît parmi les fichiers de transaction dans `pg_xlog` :

```
-bash-4.2$ cat 00000001000000010000001C.00000060.backup
START WAL LOCATION: 1/1C000060 (file 00000001000000010000001C)
STOP WAL LOCATION: 1/1D0002F0 (file 00000001000000010000001D)
CHECKPOINT LOCATION: 1/1C000098
BACKUP METHOD: streamed
BACKUP FROM: master
START TIME: 2016-08-12 18:00:38 CEST
LABEL: save96
STOP TIME: 2016-08-12 18:13:12 CEST
```

On termine ensuite la seconde sauvegarde :

```sql
postgres=#  SELECT * FROM pg_stop_backup(false);
NOTICE:  pg_stop_backup terminé, tous les journaux de transactions requis ont été
archivés
    lsn     |                           labelfile                            | spcmapfile
------------+----------------------------------------------------------------+------------
 1/1E000088 | START WAL LOCATION: 1/1D000028 (file 00000001000000010000001D)+|
            | CHECKPOINT LOCATION: 1/1D000060                               +|
            | BACKUP METHOD: streamed                                       +|
            | BACKUP FROM: master                                           +|
            | START TIME: 2016-08-12 18:01:57 CEST                          +|
            | LABEL: save96-bis                                             +|
            |                                                                |
```


Un autre fichier apparaît dans `pg_xlog` :

```FIXME
-bash-4.2$ cat 00000001000000010000001D.00000028.backup
START WAL LOCATION: 1/1D000028 (file 00000001000000010000001D)
STOP WAL LOCATION: 1/1E000088 (file 00000001000000010000001E)
CHECKPOINT LOCATION: 1/1D000060
BACKUP METHOD: streamed
BACKUP FROM: master
START TIME: 2016-08-12 18:01:57 CEST
LABEL: save96-bis
STOP TIME: 2016-08-12 18:14:58 CEST
```





### Visibility Map
* On crée une nouvelle table avec 451 lignes :

```
CREATE TABLE test_visibility AS SELECT generate_series(0,450) AS id;
```

On regarde dans quel état est la visibility map :

```sql
CREATE EXTENSION pg_visibility;

SELECT * FROM pg_visibility('test_visibility');
 blkno | all_visible | all_frozen | pd_all_visible
-------+-------------+------------+----------------
     0 | f           | f          | f
     1 | f           | f          | f
```

Les deux blocs que composent la table test_visibility sont à false,
c'est normal puisque l'opération de vacuum n'a jamais été exécutée sur
cette table.

On lance donc une opération de vacuum :

```sql
VACUUM VERBOSE test_visibility ;

INFO:  exécution du VACUUM sur « public.test_visibility »
INFO:  « test_visibility » : 0 versions de ligne supprimables, 451 non supprimables
parmi 2 pages sur 2
DÉTAIL : 0 versions de lignes mortes ne peuvent pas encore être supprimées.
Il y avait 0 pointeur d'éléments inutilisés.
Ignore 0 page à cause des verrous de blocs.
0 page est entièrement vide.
CPU 0.00s/0.00u sec elapsed 0.00 sec.
```


Vacuum voit bien nos 451 lignes, et met donc la visibility_map a jour.
Lorsqu'on la consulte, on voit bien que toutes les lignes sont
visibles

```
SELECT * FROM pg_visibility('test_visibility');
 blkno | all_visible | all_frozen | pd_all_visible
-------+-------------+------------+----------------
     0 | t           | f          | t
     1 | t           | f          | t
(2 lignes)
```

On va maintenant réaliser un update sur les 50 dernières lignes.  En
pratique, ces 50 lignes vont être taguées comme obsolètes et 50
nouvelles lignes vont être créées à la suite.

```sql
UPDATE test_visibility SET id = 3 where id > 400;
```

Lorsqu'on regarde de nouveau la visibility map, on constate que le
premier bloc est resté inchangé, qu'un nouveau bloc a été créé, et que
lui et un nouveau bloc sont passés à false.

```sql
SELECT * FROM pg_visibility('test_visibility');

 blkno | all_visible | all_frozen | pd_all_visible
-------+-------------+------------+----------------
     0 | t           | f          | t
     1 | f           | f          | f
     2 | f           | f          | f
```

On exécute de nouveau un vacuum verbose :

```sql
VACUUM VERBOSE test_visibility ;

INFO:  exécution du VACUUM sur « public.test_visibility »
INFO:  « test_visibility » : 50 versions de ligne supprimées parmi 1 pages
INFO:  « test_visibility » : 50 versions de ligne supprimables, 451 non supprimables
parmi 3 pages sur 3
DÉTAIL : 0 versions de lignes mortes ne peuvent pas encore être supprimées.
Il y avait 0 pointeur d'éléments inutilisés.
Ignore 0 page à cause des verrous de blocs.
0 page est entièrement vide.
CPU 0.00s/0.00u sec elapsed 0.00 sec.
```


```sql
SELECT * FROM pg_visibility('test_visibility');
 blkno | all_visible | all_frozen | pd_all_visible
-------+-------------+------------+----------------
     0 | t           | f          | t
     1 | t           | f          | t
     2 | t           | f          | t
```

Toutes les lignes contenues dans les trois blocs sont visibles.  A
priori, il reste de quoi insérer 50 lignes dans le deuxième bloc.

Si on relance une opération de vacuum alors que toutes les lignes sont
visibles :

```sql
vacuum VERBOSE test_visibility ;
INFO:  exécution du VACUUM sur « public.test_visibility »
INFO:  « test_visibility » : 0 versions de ligne supprimables, 451 non supprimables
parmi 3 pages sur 3
DÉTAIL : 0 versions de lignes mortes ne peuvent pas encore être supprimées.
Il y avait 49 pointeurs d'éléments inutilisés.
Ignore 0 page à cause des verrous de blocs.
0 page est entièrement vide.
CPU 0.00s/0.00u sec elapsed 0.00 sec.
```


« Il y avait 49 pointeurs d'éléments inutilisés » : effectivement, il
reste bien de l'espace dans le deuxième bloc.

```sql
SELECT count (*) FROM test_visibility ;
 count
-------
   451
```

si on compte 226 lignes pour 1 bloc, on devrait pouvoir ajouter 220
lignes et ne pas excéder 3 blocs (672 lignes)

```sql
INSERT INTO test_visibility (SELECT generate_series(1,220));
```

```
SELECT * FROM pg_visibility('test_visibility');

blkno | all_visible | all_frozen | pd_all_visible
-------+-------------+------------+----------------
     0 | t           | f          | t
     1 | f           | f          | f
     2 | f           | f          | f
```

Les deux derniers blocs ont été modifiés, ce qui signifie que les
espaces du deuxième bloc ont été réutilisés et que le reste des lignes
a été ajouté à la suite.

```sql
VACUUM VERBOSE test_visibility ;

INFO:  exécution du VACUUM sur « public.test_visibility »
INFO:  « test_visibility » : 0 versions de ligne supprimables, 671 non supprimables
parmi 3 pages sur 3
DÉTAIL : 0 versions de lignes mortes ne peuvent pas encore être supprimées.
Il y avait 0 pointeur d'éléments inutilisés.
Ignore 0 page à cause des verrous de blocs.
0 page est entièrement vide.
CPU 0.00s/0.00u sec elapsed 0.00 sec.
```

On ajoute 10 lignes :

```sql
INSERT INTO test_visibility (SELECT generate_series(1,10));

SELECT count(*) FROM test_visibility;
 count
-------
   681
(1 ligne)
```

On a bien créé un nouveau bloc et modifié le dernier, les deux premiers
blocs sont eux restés identiques :

```sql
SELECT * FROM pg_visibility('test_visibility');

 blkno | all_visible | all_frozen | pd_all_visible
-------+-------------+------------+----------------
     0 | t           | f          | t
     1 | t           | f          | t
     2 | f           | f          | f
     3 | f           | f          | f
```



```
VACUUM VERBOSE test_visibility ;
INFO:  exécution du VACUUM sur « public.test_visibility »
INFO:  « test_visibility » : 0 versions de ligne supprimables, 681 non supprimables
parmi 4 pages sur 4
DÉTAIL : 0 versions de lignes mortes ne peuvent pas encore être supprimées.
Il y avait 0 pointeur d'éléments inutilisés.
Ignore 0 page à cause des verrous de blocs.
0 page est entièrement vide.
CPU 0.00s/0.00u sec elapsed 0.00 sec.
```


« Il y avait 0 pointeur d'éléments inutilisés » nous indique bien que
les espaces inutilisés ont été remplis.


  * Regardons maintenant comment se comporte le VACUUM FREEZE :

On lance un VACUUM FREEZE sur notre table test_visibility :

```
SELECT * FROM pg_visibility('test_visibility');

 blkno | all_visible | all_frozen | pd_all_visible
-------+-------------+------------+----------------
     0 | t           | t          | t
     1 | t           | t          | t
     2 | t           | t          | t
     3 | t           | t          | t
```

En consultant la vue on constate que toutes les lignes, dans tous les
blocs sont passées en gelées.

Effectivement, tous les `xmin` des lignes ont été passés à la même valeur :

```
SELECT xmin, xmax, * FROM test_visibility LIMIT 10;
 xmin | xmax | id
------+------+----
 1882 |    0 |  0
 1882 |    0 |  1
 1882 |    0 |  2
 1882 |    0 |  3
 1882 |    0 |  4
 1882 |    0 |  5
 1882 |    0 |  6
 1882 |    0 |  7
 1882 |    0 |  8
 1882 |    0 |  9
```

si maintenant on fait une mise à jour de presque toute la
table :

```sql
UPDATE test_visibility SET id = 3 WHERE id < 400;
```

Tous les `xmin` des lignes mises à jour sont modifiés :

```sql
SELECT xmin, xmax, * FROM test_visibility LIMIT 10;
 xmin | xmax | id
------+------+-----
 1882 |    0 | 400
 1890 |    0 |   3
 1890 |    0 |   3
 1890 |    0 |   3
 1890 |    0 |   3
 1890 |    0 |   3
 1890 |    0 |   3
 1890 |    0 |   3
 1890 |    0 |   3
 1890 |    0 |   3
```

Vue l'ampleur des changements, un autovacuum a été déclenché au moment
de cette opération :

```sql
SELECT * FROM pg_stat_user_tables WHERE relname = 'test_visibility';

relname             | test_visibility
last_autovacuum     | 2016-08-12 10:57:01.125126+02
vacuum_count        | 4
autovacuum_count    | 1
```

Ce qui nous donne le résultat suivant lorsque l'on vérifie pg_visibility :

```
SELECT * FROM pg_visibility('test_visibility');

 blkno | all_visible | all_frozen | pd_all_visible
-------+-------------+------------+----------------
     0 | t           | t          | t
     1 | t           | t          | t
     2 | t           | t          | t
     3 | t           | f          | t
     4 | t           | f          | t
     5 | t           | f          | t
     6 | t           | f          | t
```

Les lignes modifiées des blocs 0,1,2 et 3 peuvent
désormais être réécrites, et qu'elles sont restées gelées.

Si maintenant on réalise une insertion d'une dizaine de lignes :

```
INSERT INTO test_visibility (SELECT generate_series(1,10));
```



```sql
SELECT * FROM pg_visibility('test_visibility');

 blkno | all_visible | all_frozen | pd_all_visible
-------+-------------+------------+----------------
     0 | f           | f          | f
     1 | t           | t          | t
     2 | t           | t          | t
     3 | t           | f          | t
     4 | t           | f          | t
     5 | t           | f          | t
     6 | t           | f          | t
```

Ces lignes ont été écrites dans le bloc 0 et entraînent le retour à false
des attributs all_visible et all_frozen.



### Fonctions SQL

Afficher le sinus pour 30° puis pour 0,523599 rd


```sql
SELECT sind(30);
 sind
------
  0.5
```

```sql
SELECT sin(0.523599);
        sin
-------------------
 0.500000194337561
```





### Réplication Synchrone


  * Installer deux nouvelles instances en 9.6.
  * Mettre en place la réplication.
  * Mettre en place la réplication synchrone.
  * arrêter le slave et lancer une commande sur le maître.
  * redémarrer le slave.


* Installation des 2 instances supplémentaires avec `initdb` (RedHat,
  CentOS...) ou `pg_createcluster` (Debian), port d'écoute `5433` pour
  l'instance 2 et `5434` pour l'instance 3.


  * Création de l'utilisateur de réplication sur l'instance primaire :

```
createuser -p 5432 replication --replication -P
```

  * Modification de `pg_hba.conf` pour lui donner accès :

```FIXME
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust

local   replication     replication                             trust
host    replication     replication        127.0.0.1/32         trust
```

  * Modification de postgresql.conf :

Pour la réplication, dans les trois `postgresql.conf`  :

```
wal_level = logical             # minimal, replica, or logical
max_wal_senders = 5             # max number of walsender processes
max_replication_slots = 5       # max number of replication slots
hot_standby = on                # "on" allows queries during recovery
```

  * Création des slots de réplication sur le maître :

```
SELECT pg_create_physical_replication_slot('standby2');
SELECT pg_create_physical_replication_slot('standby3');
```

  * Pour la réplication synchrone dans `postgresql.conf` :

```
synchronous_standby_names = '2 (standby2, standby3)'
```


  * Restauration de l'instance primaire sur les deux autres serveurs :
    d'abord on vide les répertoires cibles, puis on lance la copie, et
    on profite aussi

```
pg_basebackup -D /pg_data/9.6/instance2/ -p 5433 -U replication \
--write-recovery-conf --slot=standby2 --xlog-method=stream --progress --verbose
pg_basebackup -D /pg_data/9.6/instance3/ -p 5434 -U replication \
--write-recovery-conf --slot=standby3 --xlog-method=stream --progress --verbose
```

  * Modification des fichiers recovery.conf : il faut notamment
    préciser `application_name` pour que le serveur primaire
    reconnaisse les secondaires.

Instance 2 :

```
standby_mode=on
primary_conninfo = 'host=127.0.0.1 port=5432 user=replication
  password=repli application_name=standby2'
primary_slot_name='standby2'
```


Instance 3 :

```
standby_mode = on
primary_conninfo = 'host=127.0.0.1 port=5432 user=replication
  password=repli application_name=standby3'
primary_slot_name='standby3'
```


  * Les instances doivent démarrer et répercuter les modifications aux données de l'instance maître.


  * Si l'une des deux instances secondaires est arrêtée, aucune modification de données n'est possible sur l'instance maître, sauf à modifier le paramètre ainsi : `synchronous_standby_names = '1 (standby2, standby3)'  `


  * Testez les différentes de performance entre les différentes valeurs de `synchronous_commit`, par exemple avec pgbench :
    * Initialisation dans une base dédiée nommée pgbench : ` pgbench -i -s 100 --foreign-keys -p 5432 pgbench`
    * Tests (à répéter plusieurs fois à cause du cache) avec `pgbench --client=3 --jobs=4 --transactions=1000 -p 5432 pgbench`
</div>