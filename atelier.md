# Atelier

<div class="slide-content">
À présent, place à l'atelier...

  * Installation
  * Découverte de PostgreSQL 10
  * Authentification avec SCRAM-SHA-256
  * Vue pg_hba_file_rules
  * Vue pg_sequence
  * Modifications dans pg_basebackup
  * Parallélisation
  * Partitionnement
  * Performances
  * Collations ICU
  * Réplication logique
</div>

-----

## Installation

<div class="notes">
Les machines de la salle de formation utilisent CentOS 6. L'utilisateur dalibo peut utiliser sudo pour les opérations système.

Le site postgresql.org propose son propre dépôt RPM, nous allons donc l'utiliser pour installer PostgreSQL 10.

On commence par installer le RPM du dépôt `pgdg-centos10-10-1.noarch.rpm` :

```
# export pgdg_yum=https://download.postgresql.org/pub/repos/yum/
# wget $pgdg_yum/testing/10/redhat/rhel-6-x86_64/pgdg-centos10-10-1.noarch.rpm
# yum install -y pgdg-centos10-10-1.noarch.rpm
Installing:
 pgdg-centos10                     noarch                     10-1

# yum install -y postgresql10 postgresql10-server postgresql10-contrib
Installing:
 postgresql10                        x86_64                10.0-beta4_1PGDG.rhel6
 postgresql10-contrib                x86_64                10.0-beta4_1PGDG.rhel6
 postgresql10-server                 x86_64                10.0-beta4_1PGDG.rhel6
Installing for dependencies:
 postgresql10-libs                   x86_64                10.0-beta4_1PGDG.rhel6
```

On peut ensuite initialiser une instance :

```
# service postgresql-10 initdb
Initializing database:                                     [  OK  ]
```

Enfin, on démarre l'instance, car ce n'est par défaut pas automatique sous RedHat et CentOS :

```
# service postgresql-10 start
Starting postgresql-10 service:                            [  OK  ]
```

Pour se connecter à l'instance sans modifier `pg_hba.conf` :

```
# sudo -iu postgres /usr/pgsql-10/bin/psql
```

Enfin, on vérifie la version :

```sql
postgres=# SELECT version();
                                      version
--------------------------------------------------------------------------------
 PostgreSQL 10beta4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.4.7 20120313
 (Red Hat 4.4.7-18), 64-bit
(1 ligne)
```

On répète ensuite le processus d'installation de façon à installer PostgreSQL 9.6 aux côtés de PostgreSQL 10.

Le RPM du dépôt est `pgdg-centos96-9.6-3.noarch.rpm` :

```
# export pgdg_yum=https://download.postgresql.org/pub/repos/yum/
# wget $pgdg_yum/9.6/redhat/rhel-6-x86_64/pgdg-centos96-9.6-3.noarch.rpm
# yum install -y pgdg-centos96-9.6-3.noarch.rpm
Installing:
 pgdg-centos96                    noarch                    9.6-3

# yum install -y postgresql96 postgresql96-server postgresql96-contrib
Installing:
 postgresql96                      x86_64        9.6.5-1PGDG.rhel6
 postgresql96-contrib              x86_64        9.6.5-1PGDG.rhel6
 postgresql96-server               x86_64        9.6.5-1PGDG.rhel6
Installing for dependencies:
 postgresql96-libs                 x86_64        9.6.5-1PGDG.rhel6

# service postgresql-9.6 initdb
Initializing database:                                     [  OK  ]

# sed -i "s/#port = 5432/port = 5433/" \
  /var/lib/pgsql/9.6/data/postgresql.conf

# service postgresql-9.6 start
Starting postgresql-9.6 service:                           [  OK  ]

# sudo -iu postgres /usr/pgsql-9.6/bin/psql -p 5433
```

Dans cet atelier, les différentes sorties des commandes `psql` utilisent :

```
\pset columns 80
\pset format wrapped 
```
</div>

-----

## Découverte de PostgreSQL 10

<div class="notes">
Vous pouvez à présent consulter l'arborescence des répertoires et fichiers.

Vous devriez pouvoir observer quelque chose de similaire :

```
$ ls -al 10/data/
total 140
drwx------. 21 postgres postgres  4096 Aug  7 16:41 .
drwx------.  4 postgres postgres  4096 Aug  7 11:28 ..
drwx------.  7 postgres postgres  4096 Jul 25 15:44 base
-rw-------.  1 postgres postgres    30 Aug  7 16:37 current_logfiles
drwx------.  2 postgres postgres  4096 Aug  7 16:37 global
drwx------.  2 postgres postgres  4096 Aug  7 11:31 log
drwx------.  2 postgres postgres  4096 Jul 25 14:43 pg_commit_ts
drwx------.  2 postgres postgres  4096 Jul 25 14:43 pg_dynshmem
-rw-------.  1 postgres postgres  4420 Aug  7 16:41 pg_hba.conf
-rw-------.  1 postgres postgres  1636 Jul 25 14:43 pg_ident.conf
drwx------.  2 postgres postgres  4096 Jul 25 14:43 pg_log
drwx------.  4 postgres postgres  4096 Aug  7 16:42 pg_logical
drwx------.  4 postgres postgres  4096 Jul 25 14:43 pg_multixact
drwx------.  2 postgres postgres  4096 Aug  7 16:37 pg_notify
drwx------.  2 postgres postgres  4096 Jul 25 14:43 pg_replslot
drwx------.  2 postgres postgres  4096 Jul 25 14:43 pg_serial
drwx------.  2 postgres postgres  4096 Jul 25 14:43 pg_snapshots
drwx------.  2 postgres postgres  4096 Aug  7 16:37 pg_stat
drwx------.  2 postgres postgres  4096 Aug  7 16:45 pg_stat_tmp
drwx------.  2 postgres postgres  4096 Jul 25 14:43 pg_subtrans
drwx------.  2 postgres postgres  4096 Jul 25 14:43 pg_tblspc
drwx------.  2 postgres postgres  4096 Jul 25 14:43 pg_twophase
-rw-------.  1 postgres postgres     3 Jul 25 14:43 PG_VERSION
drwx------.  3 postgres postgres  4096 Aug  7 15:14 pg_wal
drwx------.  2 postgres postgres  4096 Jul 25 14:43 pg_xact
-rw-------.  1 postgres postgres    88 Jul 25 14:43 postgresql.auto.conf
-rw-------.  1 postgres postgres 22675 Aug  7 16:36 postgresql.conf
-rw-------.  1 postgres postgres    57 Aug  7 16:37 postmaster.opts
-rw-------.  1 postgres postgres   103 Aug  7 16:37 postmaster.pid
```

On peut constater la présence des répertoires `pg_wal` et `pg_xact`.

Au niveau des fonctions, on peut également constater les effets des différents renommages. Par exemple :

```sql
postgres=# \df *switch_xlog*
                       List of functions
 Schema | Name | Result data type | Argument data types | Type 
--------+------+------------------+---------------------+------
(0 rows)

postgres=# \df *switch_wal*
                              List of functions
   Schema   |     Name      | Result data type | Argument data types |  Type  
------------+---------------+------------------+---------------------+--------
 pg_catalog | pg_switch_wal | pg_lsn           |                     | normal
(1 row)
```
</div>

-----

## Authentification avec SCRAM-SHA-256

<div class="notes">
Créons tout d'abord un utilisateur sans préciser l'algorithme de chiffrement :

```sql
postgres=# CREATE USER testmd5 WITH PASSWORD 'XXX';
CREATE ROLE
```

Si on veut modifier l'algorithme par défaut au niveau de la session PostgreSQL, on peut constater que seuls `md5` et `scram-sha-256` sont supportés si l'on demande à psql de compléter l'ordre SQL à l'aide
de la touche tabulation :

```sql
postgres=# SET password_encryption TO <tab> 
DEFAULT          md5              "scram-sha-256"
```

On va à présent modifier ce paramètre de session afin d'utiliser `SCRAM-SHA-256` :

```sql
postgres=# SET password_encryption TO "scram-sha-256";
SET

postgres=#  CREATE USER testscram WITH PASSWORD 'YYY';
CREATE ROLE
```

Si on regarde la vue `pg_shadow`, on peut constater que l'algorithme est bien différent :

```sql
postgres=# SELECT usename, passwd FROM pg_shadow WHERE usename ~ '^test';
  usename  |                               passwd                               
-----------+--------------------------------------------------------------------
 testscram | SCRAM-SHA-256$4096:ZnsfXch56A+PtxLS$CcXGokTlOeBIw/ZGa/tTZ1rz0w5wKL.
           |.ibEuuqVd0QCY8=:6+sWvAwqa4XU6cwVXA0doLAVJarfZTVK4ePp5CTMDqg=
 testmd5   | md5456b263399eb9de93ec8f395d6f45256
(2 rows)
```

Enfin, si on souhaite rendre ce changement permanent, on peut utiliser :

```sql
postgres=# ALTER SYSTEM SET password_encryption TO "scram-sha-256";
ALTER SYSTEM

postgres=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

Il est possible d'utiliser une authentification `md5` (dans le fichier `pg_hba.conf`) avec un mot de passe `scram-sha-256`, mais pas l'inverse.
</div>

-----

## Vue pg_hba_file_rules

<div class="notes">
La vue `pg_hba_file_rules` permet de consulter en lecture les règles d'accès qui sont configurées :

```sql
postgres=# SELECT type,database,user_name,auth_method FROM pg_hba_file_rules;
 type  |   database    |  user_name  | auth_method  
-------+---------------+-------------+--------------
 local | {all}         | {testmd5}   | md5
 local | {all}         | {testscram} | scram-sha256
 local | {all}         | {all}       | peer
 local | {replication} | {all}       | peer
 host  | {replication} | {all}       | ident
 host  | {replication} | {all}       | ident
(6 rows)
```

Attention, on voit les lignes dès lors qu'elles sont présentes dans le fichier `pg_hba.conf`, même si elles ne sont pas en application.
</div>

-----

## Vue pg_sequence

<div class="notes">
On commence par se connecter à PostgreSQL de façon à créer une base de données de test sur les 2 instances en version 9.6 (`workshop96`) et 10 (`workshop10`) :

```sql
postgres=# CREATE DATABASE workshopXX;
CREATE DATABASE

postgres=# \c workshopXX
You are now connected to database "workshopXX" as user "postgres".
```

On peut alors créer deux tables `t1` et `t2` dans l'instance de la version 10 en utilisant une colonne d'identité :

```sql
workshop10=# CREATE TABLE t1 (id int GENERATED BY DEFAULT AS IDENTITY, data text);
CREATE TABLE

workshop10=# CREATE TABLE t2 (id int GENERATED BY DEFAULT AS IDENTITY, data text);
CREATE TABLE
```

Et deux tables `t1` et `t2` dans l'instance de la version 9.6 en utilisant une séquence :

```sql
workshop96=# CREATE TABLE t1 (id serial, data text);
CREATE TABLE

workshop96=# CREATE TABLE t2 (id serial, data text);
CREATE TABLE
```

On insère des valeurs dans les 2 tables des 2 instances :

```sql
workshopXX=# INSERT INTO t1 (data) SELECT 'test' || i FROM generate_series(1,10) i;
INSERT 0 10

workshopXX=# INSERT INTO t2 (data) SELECT 'test' || i FROM generate_series(1,20) i;
INSERT 0 20
```

et on vérifie leurs schémas :

```sql
workshop10=# \d t1
                            Table "public.t1"
 Column |  Type   | Collation | Nullable |            Default             
--------+---------+-----------+----------+--------------------------------
 id     | integer |           | not null | generated by default as identity
 data   | text    |           |          | 

workshop10=# \d t2
                            Table "public.t2"
 Column |  Type   | Collation | Nullable |            Default             
--------+---------+-----------+----------+--------------------------------
 id     | integer |           | not null | generated by default as identity
 data   | text    |           |          | 
```

```sql
workshop96=# \d t1
                            Table "public.t1"
 Column |  Type   |                    Modifiers                    
--------+---------+-------------------------------------------------
 id     | integer | not null default nextval('t1_id_seq'::regclass)
 data   | text    | 

workshop96=# \d t2
                            Table "public.t2"
 Column |  Type   |                    Modifiers                    
--------+---------+-------------------------------------------------
 id     | integer | not null default nextval('t2_id_seq'::regclass)
 data   | text    | 
```

Dans l'instance utilisant PostgreSQL 9.6, on a uniquement accès aux contenus des séquences :

```sql
workshop96=# SELECT * FROM t1_id_seq;
-[ RECORD 1 ]-+--------------------
sequence_name | t1_id_seq
last_value    | 10
start_value   | 1
increment_by  | 1
max_value     | 9223372036854775807
min_value     | 1
cache_value   | 1
log_cnt       | 23
is_cycled     | f
is_called     | t

workshop96=# SELECT * FROM t2_id_seq;
-[ RECORD 1 ]-+--------------------
sequence_name | t2_id_seq
last_value    | 20
start_value   | 1
increment_by  | 1
max_value     | 9223372036854775807
min_value     | 1
cache_value   | 1
log_cnt       | 13
is_cycled     | f
is_called     | t
```

Pour avoir une vue agrégée, il est nécessaire d'utiliser une requête SQL adaptée :

```sql
workshop96=#  SELECT * FROM t1_id_seq UNION ALL SELECT * FROM t2_id_seq;
-[ RECORD 1 ]-+--------------------
sequence_name | t1_id_seq
last_value    | 10
start_value   | 1
increment_by  | 1
max_value     | 9223372036854775807
min_value     | 1
cache_value   | 1
log_cnt       | 23
is_cycled     | f
is_called     | t
-[ RECORD 2 ]-+--------------------
sequence_name | t2_id_seq
last_value    | 20
start_value   | 1
increment_by  | 1
max_value     | 9223372036854775807
min_value     | 1
cache_value   | 1
log_cnt       | 13
is_cycled     | f
is_called     | t
```

Dans l'instance utilisant PostgreSQL 10, on a également accès aux contenus des séquences, mais on constate qu'il y a moins d'informations :

```sql
workshop10=# SELECT * FROM t1_id_seq;
-[ RECORD 1 ]--
last_value | 10
log_cnt    | 23
is_called  | t

workshop10=# SELECT * FROM t2_id_seq;
-[ RECORD 1 ]--
last_value | 20
log_cnt    | 13
is_called  | t
```

Une requête avec un UNION ALL reste possible pour agréger les résultats mais la table `pg_sequence` et la vue `pg_sequences` permettent d'accéder facilement à de telles informations :

```sql
workshop10=# SELECT * FROM pg_sequence;
-[ RECORD 1 ]+-----------
seqrelid     | 40983
seqtypid     | 23
seqstart     | 1
seqincrement | 1
seqmax       | 2147483647
seqmin       | 1
seqcache     | 1
seqcycle     | f
-[ RECORD 2 ]+-----------
seqrelid     | 40994
seqtypid     | 23
seqstart     | 1
seqincrement | 1
seqmax       | 2147483647
seqmin       | 1
seqcache     | 1
seqcycle     | f

workshop10=# SELECT * FROM pg_sequences;
-[ RECORD 1 ]-+-----------
schemaname    | public
sequencename  | t1_id_seq
sequenceowner | postgres
data_type     | integer
start_value   | 1
min_value     | 1
max_value     | 2147483647
increment_by  | 1
cycle         | f
cache_size    | 1
last_value    | 10
-[ RECORD 2 ]-+-----------
schemaname    | public
sequencename  | t2_id_seq
sequenceowner | postgres
data_type     | integer
start_value   | 1
min_value     | 1
max_value     | 2147483647
increment_by  | 1
cycle         | f
cache_size    | 1
last_value    | 20
```
</div>

-----

## Modifications dans pg_basebackup

<div class="notes">
On commence par regarder l'aide :

```
bash-4.1$ pg_basebackup --help
pg_basebackup takes a base backup of a running PostgreSQL server.

Usage:
  pg_basebackup [OPTION]...

Options controlling the output:
  -D, --pgdata=DIRECTORY receive base backup into directory
  -F, --format=p|t       output format (plain (default), tar)
  -r, --max-rate=RATE    maximum transfer rate to transfer data directory
                         (in kB/s, or use suffix "k" or "M")
  -R, --write-recovery-conf
                         write recovery.conf for replication
  -S, --slot=SLOTNAME    replication slot to use
      --no-slot          prevent creation of temporary replication slot
  -T, --tablespace-mapping=OLDDIR=NEWDIR
                         relocate tablespace in OLDDIR to NEWDIR
  -X, --wal-method=none|fetch|stream
                         include required WAL files with specified method
      --waldir=WALDIR    location for the write-ahead log directory
  -z, --gzip             compress tar output
  -Z, --compress=0-9     compress tar output with given compression level

General options:
  -c, --checkpoint=fast|spread
                         set fast or spread checkpointing
  -l, --label=LABEL      set backup label
  -n, --no-clean         do not clean up after errors
  -N, --no-sync          do not wait for changes to be written safely to disk
  -P, --progress         show progress information
  -v, --verbose          output verbose messages
  -V, --version          output version information, then exit
  -?, --help             show this help, then exit

Connection options:
  -d, --dbname=CONNSTR   connection string
  -h, --host=HOSTNAME    database server host or socket directory
  -p, --port=PORT        database server port number
  -s, --status-interval=INTERVAL
                         time between status packets sent to server (in seconds)
  -U, --username=NAME    connect as specified database user
  -w, --no-password      never prompt for password
  -W, --password         force password prompt (should happen automatically)

Report bugs to <pgsql-bugs@postgresql.org>.
```

L'option `-x` a bien disparu.

On créé à présent un slot de réplication permanent :

```sql
workshop10=# SELECT pg_create_physical_replication_slot('reptest', 't', 'f');
-[ RECORD 1 ]-----------------------+---------------------
pg_create_physical_replication_slot | (reptest,3/B7000C88)
```

On vérifie ensuite qu'il a bien été créé :

```sql
workshop10=# SELECT * FROM pg_replication_slots;
-[ RECORD 1 ]-------+-----------
slot_name           | reptest
plugin              | 
slot_type           | physical
datoid              | 
database            | 
temporary           | f
active              | f
active_pid          | 
xmin                | 
catalog_xmin        | 
restart_lsn         | 3/B7000C88
confirmed_flush_lsn |
```

Et on lance la recopie de la base de données :

```
$ pg_basebackup --progress --verbose --write-recovery-conf \
  --pgdata=10/datanew3/ --slot=reptest
pg_basebackup: initiating base backup, waiting for checkpoint to complete
pg_basebackup: checkpoint completed
pg_basebackup: write-ahead log start point: 3/B3000028 on timeline 1
pg_basebackup: starting background WAL receiver
8946810/8946810 kB (100%), 1/1 tablespace                                         
pg_basebackup: write-ahead log end point: 3/B3000130
pg_basebackup: waiting for background process to finish streaming ...
pg_basebackup: base backup completed
```

Il faut noter que les slots de réplication temporaires sont incompatibles par nature. En effet, le slot sera supprimé après le transfert des données, et il ne sera donc plus utilisable pour les WAL :

```sql
workshop10=# SELECT pg_create_physical_replication_slot('reptest2', 't', 't');
 pg_create_physical_replication_slot 
-------------------------------------
 (reptest2,3/B3000028)
(1 row)
```

Lors du lancement, on obtient :

```
$ pg_basebackup --progress --verbose --write-recovery-conf \
  --pgdata=10/datanew3/ -S reptest2
pg_basebackup: initiating base backup, waiting for checkpoint to complete
pg_basebackup: checkpoint completed
pg_basebackup: write-ahead log start point: 3/B5000028 on timeline 1
pg_basebackup: starting background WAL receiver
pg_basebackup: could not send replication command "START_REPLICATION": 
               ERROR:  replication slot "reptest2" does not exist
[...]
```
</div>

-----

## Parallélisation

<div class="notes">
Dans les 2 instances, on crée les tables `p1` et `p2` :

```sql
workshopXX=# CREATE TABLE p1 AS
   SELECT row_number() OVER() AS id, generate_series%100 AS c_100,
          generate_series%500 AS c_500 FROM generate_series(1,20000000); 
SELECT 20000000 
workshopXX=# ALTER TABLE p1 ADD CONSTRAINT pk_p1 PRIMARY KEY (id); 
ALTER TABLE 
workshopXX=# CREATE INDEX idx_p1 ON p1 (c_100); 
CREATE INDEX
workshopXX=# CREATE TABLE p2 AS
   SELECT row_number() OVER() AS id, generate_series%100 AS c_100,
          generate_series%500 AS c_500 FROM generate_series(1,200000);
SELECT 200000
workshopXX=# ALTER TABLE p2 ADD CONSTRAINT pk_p2 PRIMARY KEY (id); 
ALTER TABLE
workshopXX=# CREATE INDEX idx_p2 ON p2 (c_100);
CREATE INDEX

```

On modifie également le paramètre `max_parallel_workers_per_gather` afin de permettre la parallélisation :

```sql
postgres=# ALTER SYSTEM SET max_parallel_workers_per_gather TO 3;
ALTER SYSTEM

postgres=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

</div>

-----

## Parallélisation : Parallel Bitmap Heap Scan

<div class="notes">

Pour déclencher la parallélisation d'une requête, le table doit être lue avec une technique permettant la parallélisation. En PostgreSQL 9.6, la seule lecture permettant la parallélisation était le `parallel sequential scan`. Le planificateur devait donc choisir entre utiliser la parallélisation et utiliser les index.

En PostgreSQL 10, grâce au `parallel bitmap heap scan`, un processus scanne les index et construit une structure de donnée en mémoire partagée indiquant toutes les pages de la pile devant être lues. Les workers peuvent alors lire les données de façon parallèle.


```sql
workshop96=# EXPLAIN ANALYSE VERBOSE SELECT count(*), c_100 FROM p1
    WHERE c_100 <10 GROUP BY c_100;
                                     QUERY PLAN
----------------------------------------------------------------------------------
 HashAggregate  (cost=180259.56..180260.56 rows=100 width=12)
                (actual time=1203.280..1203.282 rows=10 loops=1)
   Output: count(*), c_100
   Group Key: p1.c_100
   ->  Bitmap Heap Scan on public.p1
                        (cost=37290.48..170299.54 rows=1992005 width=4)
			(actual time=309.612..826.041 rows=2000000 loops=1)
         Output: id, c_100, c_500
         Recheck Cond: (p1.c_100 < 10)
         Heap Blocks: exact=108109
         ->  Bitmap Index Scan on idx_p1
	                      (cost=0.00..36792.47 rows=1992005 width=0)
			      (actual time=276.489..276.489 rows=2000000 loops=1)
               Index Cond: (p1.c_100 < 10)
 Planning time: 0.341 ms
 Execution time: 1203.404 ms
(11 lignes)
```


```sql
workshop10=# EXPLAIN ANALYSE VERBOSE SELECT count(*), c_100 FROM p1
    WHERE c_100 <10 GROUP BY c_100;
                                     QUERY PLAN
--------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=158141.99..158145.24 rows=100 width=12)
                          (actual time=770.753..770.766 rows=10 loops=1)
   Group Key: c_100
   ->  Sort  (cost=158141.99..158142.74 rows=300 width=12)
             (actual time=770.747..770.751 rows=40 loops=1)
         Sort Key: c_100
         Sort Method: quicksort  Memory: 27kB
         ->  Gather  (cost=158098.64..158129.64 rows=300 width=12)
	             (actual time=769.859..770.724 rows=40 loops=1)
               Workers Planned: 3
               Workers Launched: 3
               ->  Partial HashAggregate
	              (cost=157098.64..157099.64 rows=100 width=12)
		      (actual time=765.184..765.188 rows=10 loops=4)
                     Group Key: c_100
                     ->  Parallel Bitmap Heap Scan on p1
		            (cost=37639.11..153855.63 rows=648602 width=4)
			    (actual time=242.999..600.416 rows=500000 loops=4)
                           Recheck Cond: (c_100 < 10)
                           Heap Blocks: exact=31663
                           ->  Bitmap Index Scan on idx_p1
			          (cost=0.00..37136.44 rows=2010667 width=0)
				  (actual time=213.409..213.409 rows=2000000 loops=1)
                                 Index Cond: (c_100 < 10)
 Planning time: 0.118 ms
 Execution time: 780.670 ms
(17 lignes)

```

</div>

-----

## Parallélisation : Parallel Index-Only Scan et Parallel Index Scan

<div class="notes">

Les requêtes parallèles sont maintenant disponibles pour les scan d'index.

**Parallel Index-Only Scan**

Regardons les plans d'exécution renvoyés par :

```sql
EXPLAIN ANALYSE SELECT count(*) FROM p1 WHERE id > 10 AND id < 500000;
```

Sur les deux instances, on vérifie la présence d'un noeud `Gather`.

Regardons à présent les plans d'exécution renvoyés par :

```sql
workshop96=# EXPLAIN ANALYSE SELECT count(*) FROM p1 WHERE id > 10 AND id < 5000000;
                                     QUERY PLAN                                          
--------------------------------------------------------------------------------
 Aggregate  (cost=198337.55..198337.56 rows=1 width=8)
            (actual time=1266.779..1266.779 rows=1 loops=1)
   ->  Index Only Scan using pk_p1 on p1
                              (cost=0.44..185582.54 rows=5102005 width=0)
                              (actual time=0.071..947.370 rows=4999989 loops=1)
         Index Cond: ((id > 10) AND (id < 5000000))
         Heap Fetches: 4999989
 Planning time: 0.334 ms
 Execution time: 1266.849 ms
(6 lignes)
```

```sql
workshop10=# EXPLAIN ANALYSE SELECT count(*) FROM p1 WHERE id > 10 AND id < 5000000;
                                     QUERY PLAN                         
--------------------------------------------------------------------------------
 Finalize Aggregate  (cost=153795.71..153795.72 rows=1 width=8)
                     (actual time=790.310..790.310 rows=1 loops=1)
   ->  Gather  (cost=153795.39..153795.70 rows=3 width=8)
               (actual time=790.079..790.304 rows=4 loops=1)
         Workers Planned: 3
         Workers Launched: 3
         ->  Partial Aggregate  (cost=152795.39..152795.40 rows=1 width=8)
	                        (actual time=785.157..785.157 rows=1 loops=4)
               ->  Parallel Index Only Scan using pk_p1 on p1
	                      (cost=0.44..148742.92 rows=1620987 width=0)
		              (actual time=0.045..616.159 rows=1249997 loops=4)
                     Index Cond: ((id > 10) AND (id < 5000000))
                     Heap Fetches: 1286187
 Planning time: 0.147 ms
 Execution time: 799.842 ms
(10 lignes)
```


**Parallel Index Scan**

Regardons les plans d'exécution renvoyés par :

```sql
EXPLAIN ANALYSE SELECT count(c_100) FROM p1 WHERE id < 5000000;
```


```sql
workshop96=# EXPLAIN ANALYSE SELECT count(c_100) FROM p1 WHERE id < 5000000;
                                     QUERY PLAN 
--------------------------------------------------------------------------------
 Aggregate  (cost=185582.74..185582.75 rows=1 width=8)
            (actual time=1191.432..1191.433 rows=1 loops=1)
   ->  Index Scan using pk_p1 on p1
                              (cost=0.44..172827.70 rows=5102015 width=4)
                              (actual time=0.047..754.709 rows=4999999 loops=1)
         Index Cond: (id < 5000000)
 Planning time: 0.198 ms
 Execution time: 1191.500 ms
(5 lignes)
```


```sql
workshop10=# EXPLAIN ANALYSE SELECT count(c_100) FROM p1 WHERE id < 5000000;
                                     QUERY PLAN          
--------------------------------------------------------------------------------
 Finalize Aggregate  (cost=141233.16..141233.17 rows=1 width=8)
                     (actual time=775.335..775.335 rows=1 loops=1)
   ->  Gather  (cost=141232.84..141233.15 rows=3 width=8)
               (actual time=775.211..775.328 rows=4 loops=1)
         Workers Planned: 3
         Workers Launched: 3
         ->  Partial Aggregate  (cost=140232.84..140232.85 rows=1 width=8)
	                        (actual time=769.012..769.012 rows=1 loops=4)
               ->  Parallel Index Scan using pk_p1 on p1
	                      (cost=0.44..136180.37 rows=1620990 width=4)
			      (actual time=0.051..588.808 rows=1250000 loops=4)
                     Index Cond: (id < 5000000)
 Planning time: 0.344 ms
 Execution time: 784.448 ms
(9 lignes)
```

</div>

-----

## Parallélisation : transmission des requêtes aux workers

<div class="notes">

En effectuant une requête sur une autre session, il est possible en version 10 de lire le texte des requêtes effectuées par les différents workers dans la vue pg_stat_activity :

```sql
workshop96=# SELECT pid,application_name,backend_start,query FROM pg_stat_activity;
-[ RECORD 1 ]----+--------------------------------------------------------------
pid              | 1071
application_name | psql
backend_start    | 2017-08-30 09:50:15.376798-04
query            | EXPLAIN (ANALYZE,BUFFERS,VERBOSE) SELECT COUNT(id) FROM p1;
-[ RECORD 2 ]----+--------------------------------------------------------------
pid              | 1832
application_name | psql
backend_start    | 2017-08-30 10:42:46.235495-04
query            | SELECT pid,application_name,backend_start,query
                 | FROM pg_stat_activity ;
-[ RECORD 3 ]----+--------------------------------------------------------------
pid              | 1855
application_name | psql
backend_start    | 2017-08-30 10:44:27.902368-04
query            | 
-[ RECORD 4 ]----+--------------------------------------------------------------
pid              | 1856
application_name | psql
backend_start    | 2017-08-30 10:44:27.902921-04
query            | 
-[ RECORD 5 ]----+--------------------------------------------------------------
pid              | 1857
application_name | psql
backend_start    | 2017-08-30 10:44:27.903122-04
query       
```
  
```sql
workshop10=# SELECT pid,application_name,backend_start,backend_type,query
FROM pg_stat_activity WHERE state='active';
-[ RECORD 1 ]----+-------------------------------------------------------------
pid              | 3347
application_name | psql
backend_start    | 2017-08-30 13:07:24.958714-04
backend_type     | client backend
query            | EXPLAIN (ANALYZE,BUFFERS,VERBOSE) SELECT COUNT(id) FROM p1;
-[ RECORD 2 ]----+-------------------------------------------------------------
pid              | 4928
application_name | psql
backend_start    | 2017-08-30 15:03:40.525836-04
backend_type     | client backend
query            | SELECT pid,application_name,backend_start,backend_type,query+
                 | FROM pg_stat_activity WHERE state='active';
-[ RECORD 3 ]----+-------------------------------------------------------------
pid              | 4937
application_name | psql
backend_start    | 2017-08-30 15:04:07.385615-04
backend_type     | background worker
query            | EXPLAIN (ANALYZE,BUFFERS,VERBOSE) SELECT COUNT(id) FROM p1;
-[ RECORD 4 ]----+-------------------------------------------------------------
pid              | 4938
application_name | psql
backend_start    | 2017-08-30 15:04:07.385803-04
backend_type     | background worker
query            | EXPLAIN (ANALYZE,BUFFERS,VERBOSE) SELECT COUNT(id) FROM p1;
-[ RECORD 5 ]----+-------------------------------------------------------------
pid              | 4939
application_name | psql
backend_start    | 2017-08-30 15:04:07.386252-04
backend_type     | background worker
query            | EXPLAIN (ANALYZE,BUFFERS,VERBOSE) SELECT COUNT(id) FROM p1;
```

</div>


-----

## Partitionnement : création

<div class="notes">

Nous allons étudier les différences entre la version 9.6 et la version 10 en termes d'utilisation des tables partitionnées.

Nous allons créer une table de mesure des températures suivant le lieu et la date. Nous allons partitionner ces tables pour chaque lieu et chaque mois.

Ordre de création de la table en version 9.6 :

```sql
CREATE TABLE meteo (
   t_id serial,
   lieu text NOT NULL,
   heure_mesure timestamp DEFAULT now(),
   temperature real NOT NULL
 );
CREATE TABLE meteo_lyon_201709 (
   CHECK ( lieu = 'Lyon'
           AND heure_mesure >= TIMESTAMP '2017-09-01 00:00:00'
	   AND heure_mesure < TIMESTAMP '2017-10-01 00:00:00' )
) INHERITS (meteo);
CREATE TABLE meteo_lyon_201710 (
   CHECK ( lieu = 'Lyon'
           AND heure_mesure >= TIMESTAMP '2017-10-01 00:00:00'
	   AND heure_mesure < TIMESTAMP '2017-11-01 00:00:00' )
) INHERITS (meteo);
CREATE TABLE meteo_nantes_201709 (
   CHECK ( lieu = 'Nantes'
           AND heure_mesure >= TIMESTAMP '2017-09-01 00:00:00'
	   AND heure_mesure < TIMESTAMP '2017-10-01 00:00:00' )
) INHERITS (meteo);
CREATE TABLE meteo_nantes_201710 (
   CHECK ( lieu = 'Nantes'
           AND heure_mesure >= TIMESTAMP '2017-10-01 00:00:00'
	   AND heure_mesure < TIMESTAMP '2017-11-01 00:00:00' )
) INHERITS (meteo);
CREATE TABLE meteo_paris_201709 (
   CHECK ( lieu = 'Paris'
           AND heure_mesure >= TIMESTAMP '2017-09-01 00:00:00'
	   AND heure_mesure < TIMESTAMP '2017-10-01 00:00:00' )
) INHERITS (meteo);
CREATE TABLE meteo_paris_201710 (
   CHECK ( lieu = 'Paris'
           AND heure_mesure >= TIMESTAMP '2017-10-01 00:00:00'
	   AND heure_mesure < TIMESTAMP '2017-11-01 00:00:00' )
) INHERITS (meteo);
CREATE OR REPLACE FUNCTION meteo_insert_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF ( NEW.lieu = 'Lyon' ) THEN
      IF ( NEW.heure_mesure >= TIMESTAMP '2017-09-01 00:00:00' AND
           NEW.heure_mesure < TIMESTAMP '2017-10-01 00:00:00' ) THEN
          INSERT INTO meteo_lyon_201709 VALUES (NEW.*);
      ELSIF ( NEW.heure_mesure >= TIMESTAMP '2017-10-01 00:00:00' AND
              NEW.heure_mesure < TIMESTAMP '2017-11-01 00:00:00' ) THEN
          INSERT INTO meteo_lyon_201710 VALUES (NEW.*);
      ELSE
        RAISE EXCEPTION 'Date non prévue dans meteo_insert_trigger(Lyon)';
      END IF;
    ELSIF ( NEW.lieu = 'Nantes' ) THEN
      IF ( NEW.heure_mesure >= TIMESTAMP '2017-09-01 00:00:00' AND
           NEW.heure_mesure < TIMESTAMP '2017-10-01 00:00:00' ) THEN
          INSERT INTO meteo_nantes_201709 VALUES (NEW.*);
      ELSIF ( NEW.heure_mesure >= TIMESTAMP '2017-10-01 00:00:00' AND
              NEW.heure_mesure < TIMESTAMP '2017-11-01 00:00:00' ) THEN
          INSERT INTO meteo_nantes_201710 VALUES (NEW.*);
      ELSE
        RAISE EXCEPTION 'Date non prévue dans meteo_insert_trigger(Nantes)';
      END IF;
    ELSIF ( NEW.lieu = 'Paris' ) THEN
      IF ( NEW.heure_mesure >= TIMESTAMP '2017-09-01 00:00:00' AND
           NEW.heure_mesure < TIMESTAMP '2017-10-01 00:00:00' ) THEN
          INSERT INTO meteo_paris_201709 VALUES (NEW.*);
      ELSIF ( NEW.heure_mesure >= TIMESTAMP '2017-10-01 00:00:00' AND
              NEW.heure_mesure < TIMESTAMP '2017-11-01 00:00:00' ) THEN
          INSERT INTO meteo_paris_201710 VALUES (NEW.*);
      ELSE
        RAISE EXCEPTION 'Date non prévue dans meteo_insert_trigger(Paris)';
      END IF;
    ELSE
        RAISE EXCEPTION 'Lieu non prévu dans meteo_insert_trigger() !';
    END IF;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
CREATE TRIGGER insert_meteo_trigger
    BEFORE INSERT ON meteo
    FOR EACH ROW EXECUTE PROCEDURE meteo_insert_trigger();
```

Ordre de création de la table en version 10 ;

```sql
CREATE TABLE meteo (
   t_id integer GENERATED BY DEFAULT AS IDENTITY,
   lieu text NOT NULL,
   heure_mesure timestamp DEFAULT now(),
   temperature real NOT NULL
 ) PARTITION BY RANGE (lieu, heure_mesure);
CREATE TABLE meteo_lyon_201709 PARTITION of meteo FOR VALUES
   FROM ('Lyon', '2017-09-01 00:00:00') TO ('Lyon', '2017-10-01 00:00:00');
CREATE TABLE meteo_lyon_201710 PARTITION of meteo FOR VALUES
   FROM ('Lyon', '2017-10-01 00:00:00') TO ('Lyon', '2017-11-01 00:00:00');
CREATE TABLE meteo_nantes_201709 PARTITION of meteo FOR VALUES
   FROM ('Nantes', '2017-09-01 00:00:00') TO ('Nantes', '2017-10-01 00:00:00');
CREATE TABLE meteo_nantes_201710 PARTITION of meteo FOR VALUES
   FROM ('Nantes', '2017-10-01 00:00:00') TO ('Nantes', '2017-11-01 00:00:00');
CREATE TABLE meteo_paris_201709 PARTITION of meteo FOR VALUES
   FROM ('Paris', '2017-09-01 00:00:00') TO ('Paris', '2017-10-01 00:00:00');
CREATE TABLE meteo_paris_201710 PARTITION of meteo FOR VALUES
   FROM ('Paris', '2017-10-01 00:00:00') TO ('Paris', '2017-11-01 00:00:00');
```

On remarque que la déclaration est bien plus facile en version 10. Comme nous le verrons le plus fastidieux est de faire évoluer la fonction trigger en version 9.6.

Voici une fonction permettant d'ajouter des entrées aléatoires dans la table :

```sql
CREATE OR REPLACE FUNCTION peuple_meteo()
RETURNS TEXT AS $$
DECLARE
   lieux text[] := '{}';
   v_lieu text;
   v_heure timestamp;
   v_temperature real;
   v_nb_insertions integer := 500000;
   v_insertion integer;
BEGIN
   lieux[0]='Lyon';
   lieux[1]='Nantes';
   lieux[2]='Paris';
   FOR v_insertion IN 1 .. v_nb_insertions LOOP
      v_lieu=lieux[floor((random()*3))::int];
      v_heure='2017-09-01'::timestamp
                   + make_interval(days => floor((random()*60))::int,
                              secs => floor((random()*86400))::int);
      v_temperature:=round(((random()*14))::numeric+10,2);
      IF EXTRACT(MONTH FROM v_heure) = 10 THEN
          v_temperature:=v_temperature-4;
      END IF;
      IF EXTRACT(HOUR FROM v_heure) <= 9
         OR EXTRACT(HOUR FROM v_heure) >= 20 THEN
          v_temperature:=v_temperature-5;
      ELSEIF EXTRACT(HOUR FROM v_heure) >= 12
         AND EXTRACT(HOUR FROM v_heure) <= 17 THEN
          v_temperature:=v_temperature+5;
      END IF;
      INSERT INTO meteo (lieu,heure_mesure,temperature)
        VALUES (v_lieu,v_heure,v_temperature);
   END LOOP;
   RETURN v_nb_insertions||' mesures de température insérées';
END;
$$
LANGUAGE plpgsql;
```

Insérons des lignes dans les 2 tables :

```sql
workshop96=# EXPLAIN ANALYSE SELECT peuple_meteo();
                        QUERY PLAN
-----------------------------------------------------------
 Result  (cost=0.00..0.26 rows=1 width=32)
         (actual time=20154.769..20154.769 rows=1 loops=1)
 Planning time: 0.031 ms
 Execution time: 20154.790 ms
(3 lignes)

workshop10=# EXPLAIN ANALYSE SELECT peuple_meteo();
                        QUERY PLAN
-----------------------------------------------------------
 Result  (cost=0.00..0.26 rows=1 width=32)
         (actual time=15823.882..15823.882 rows=1 loops=1)
 Planning time: 0.042 ms
 Execution time: 15823.920 ms
(3 lignes)
```

Nous constatons un gain de 25% en version 10 sur l'insertion de données.

</div>

-----

## Partitionnement : limitations

<div class="notes">

**Index**

La création d'index n'est toujours pas disponible en version 10 :

```sql
workshop10=# CREATE INDEX meteo_heure_mesure_idx ON meteo (heure_mesure);
ERROR:  cannot create index on partitioned table "meteo"
```

Il est donc toujours impossible de créer une clé primaire, une contrainte unique ou une contrainte d'exclusion pouvant s'appliquer sur toutes les partitions.
De ce fait, il est également impossible de référencer via une clé étrangère une table partitionnée.

Il est cependant possible de créer des index sur chaque partition fille, comme avec la version 9.6 :

```sql
workshop10=# CREATE INDEX meteo_lyon_201710_heure_idx
  ON meteo_lyon_201710 (heure_mesure);
CREATE INDEX
```

**Mise à jour**

Une mise à jour qui déplacerait des enregistrements d'une partition à une autre n'est pas possible par défaut en version 10 :

```sql
workshop10=# UPDATE meteo SET lieu='Nantes' WHERE lieu='Lyon';
ERROR:  new row for relation "meteo_lyon_201709" violates partition constraint
DÉTAIL : Failing row contains (5, Nantes, 2017-09-15 05:09:23, 9.43).
```

**Insertion de données hors limite**

Le partitionnement en version 10 permet de déclarer 

```sql
CREATE TABLE meteo_lyon_ancienne PARTITION of meteo FOR VALUES
   FROM ('Lyon', MINVALUE) TO ('Lyon', '2017-09-01 00:00:00');
CREATE TABLE meteo_nantes_ancienne PARTITION of meteo FOR VALUES
   FROM ('Nantes', MINVALUE) TO ('Nantes', '2017-09-01 00:00:00');
CREATE TABLE meteo_paris_ancienne PARTITION of meteo FOR VALUES
   FROM ('Paris', MINVALUE) TO ('Paris', '2017-09-01 00:00:00');
```

</div>

-----

## Partitionnement : administration

<div class="notes">

Avec les tables partitionnées via l'héritage, il était nécessaire de lister toutes les tables partitionnées pour effectuer des tâches de maintenance.

```sql
workshop96=# SELECT 'VACUUM ANALYZE '||relname AS operation
  FROM pg_stat_user_tables WHERE relname LIKE 'meteo_%';
             operation              
------------------------------------
 VACUUM ANALYZE meteo_lyon_201709
 VACUUM ANALYZE meteo_lyon_201710
 VACUUM ANALYZE meteo_nantes_201709
 VACUUM ANALYZE meteo_nantes_201710
 VACUUM ANALYZE meteo_paris_201709
 VACUUM ANALYZE meteo_paris_201710
(6 lignes)

workshop96=# \gexec
VACUUM
VACUUM
VACUUM
VACUUM
VACUUM
VACUUM
```

Avec la version 10, il est maintenant possible d'effectuer des opérations de VACUUM et ANALYSE sur toutes les tables partitionnées via la table mère.

```sql
workshop10=# VACUUM ANALYZE meteo;
VACUUM
workshop10=# SELECT now() AS date,relname,last_vacuum,last_analyze
  FROM pg_stat_user_tables WHERE relname LIKE 'meteo_nantes%';
-[ RECORD 1 ]+------------------------------
date         | 2017-09-01 08:39:02.052168-04
relname      | meteo_nantes_201709
last_vacuum  | 2017-09-01 08:38:54.068208-04
last_analyze | 2017-09-01 08:38:54.068396-04
-[ RECORD 2 ]+------------------------------
date         | 2017-09-01 08:39:02.052168-04
relname      | meteo_nantes_201710
last_vacuum  | 2017-09-01 08:38:54.068482-04
last_analyze | 2017-09-01 08:38:54.068665-04
```


</div>

-----

## Performances

<div class="notes">
Importer le dump tp_workshop10.dump dans l'instance PostgreSQL 10 :

```
$ wget http://192.168.1.3/dumps/tp_workshop10.dump -P /tmp
$ createdb tp
$ pg_restore -1 -O -d tp  \
     /tmp/tp_workshop10.dump
```

Importer également le dump tp_workshop10.dump dans l'instance PostgreSQL 9.6 :

```
$ createdb -p 5433 tp
$ pg_restore -p 5433 -1 -O -d tp \
     /tmp/tp_workshop10.dump
```

Validez toujours les temps d'exécution en exécutant les requêtes plusieurs
fois. Les temps de réponse peuvent en effet fortement varier en fonction de la
présence ou non des données dans le cache de PostgreSQL et de Linux.


Vérifions le gain de performance sur les tris, en exécutant tout d'abord
la requête suivante sur l'instance 9.6 :

```sql
$ psql -q tp -p 5433
tp=# SET search_path TO magasin;
tp=# EXPLAIN (ANALYZE, BUFFERS, COSTS off)
SELECT type_client,
       code_pays
  FROM commandes c
  JOIN lignes_commandes l
    ON (c.numero_commande = l.numero_commande)
  JOIN clients cl
    ON (c.client_id = cl.client_id)
  JOIN contacts co
    ON (cl.contact_id = co.contact_id)
 WHERE date_commande BETWEEN '2014-01-01' AND '2014-12-31'
 ORDER BY type_client, code_pays;
                         QUERY PLAN
---------------------------------------------------------------
 Sort (actual time=3121.067..3804.446 rows=1226456 loops=1)
   Sort Key: cl.type_client, co.code_pays
   Sort Method: external merge  Disk: 17944kB
(...)
 Planning time: 0.743 ms
 Execution time: 3875.253 ms
```

Voyons maintenant le gain avec PostgreSQL 10, en prenant soin de désactiver le
parallélisme :
```
$ psql -q tp -p 5432
tp=# SET search_path TO magasin;
tp=# SET max_parallel_workers = 0;
tp=# SET max_parallel_workers_per_gather = 0;
tp=# EXPLAIN (ANALYZE, BUFFERS, COSTS off)
SELECT type_client,
       code_pays
  FROM commandes c
  JOIN lignes_commandes l
    ON (c.numero_commande = l.numero_commande)
  JOIN clients cl
    ON (c.client_id = cl.client_id)
  JOIN contacts co
    ON (cl.contact_id = co.contact_id)
 WHERE date_commande BETWEEN '2014-01-01' AND '2014-12-31'
 ORDER BY type_client, code_pays;
                         QUERY PLAN
-------------------------------------------------------------
 Sort (actual time=1850.503..2045.610 rows=1226456 loops=1)
   Sort Key: cl.type_client, co.code_pays
   Sort Method: external merge  Disk: 18024kB
(...)
 Planning time: 0.890 ms
 Execution time: 2085.996 ms
```

Le temps d'exécution de cette requête est quasi doublé en version 9.6. On observe que le tri sur disque (Sort) est réalisé en 195ms en 10, contre 683ms en 9.6.


Maintenant, vérifions le gain de performance sur les GROUPING SETS.

Exécuter la requête suivante sur l'instance 9.6 :

```sql
$ psql -q tp -p 5433
tp=# SET search_path TO magasin;
tp=# EXPLAIN (ANALYZE, BUFFERS, COSTS off)
SELECT GROUPING(type_client,code_pays)::bit(2),
       GROUPING(type_client)::boolean g_type_cli,
       GROUPING(code_pays)::boolean g_code_pays,
       type_client,
       code_pays,
       SUM(quantite*prix_unitaire) AS montant
  FROM commandes c
  JOIN lignes_commandes l
    ON (c.numero_commande = l.numero_commande)
  JOIN clients cl
    ON (c.client_id = cl.client_id)
  JOIN contacts co
    ON (cl.contact_id = co.contact_id)
 WHERE date_commande BETWEEN '2014-01-01' AND '2014-12-31'
GROUP BY CUBE (type_client, code_pays);
                           QUERY PLAN
----------------------------------------------------------------------
 GroupAggregate (actual time=2565.848..5344.539 rows=40 loops=1)
   Group Key: cl.type_client, co.code_pays
   Group Key: cl.type_client
   Group Key: ()
   Sort Key: co.code_pays
     Group Key: co.code_pays
   Buffers: shared hit=14678 read=41752, temp read=32236 written=32218
   ->  Sort (actual time=4066.492..4922.885 rows=1226456 loops=1)
         Sort Key: cl.type_client, co.code_pays
         Sort Method: external merge  Disk: 34664kB
(...)
 Planning time: 1.868 ms
 Execution time: 8177.263 ms
```

On remarque que l'opération de tri est effectué sur disque. Vérifions le temps d'exécution avec un tri en mémoire : 

```sql
$ psql -q tp -p 5433
tp=# SET search_path TO magasin;
tp=# set work_mem='128MB';
tp=# EXPLAIN (ANALYZE, BUFFERS, COSTS off)
SELECT GROUPING(type_client,code_pays)::bit(2),
       GROUPING(type_client)::boolean g_type_cli,
       GROUPING(code_pays)::boolean g_code_pays,
       type_client,
       code_pays,
       SUM(quantite*prix_unitaire) AS montant
  FROM commandes c
  JOIN lignes_commandes l
    ON (c.numero_commande = l.numero_commande)
  JOIN clients cl
    ON (c.client_id = cl.client_id)
  JOIN contacts co
    ON (cl.contact_id = co.contact_id)
 WHERE date_commande BETWEEN '2014-01-01' AND '2014-12-31'
GROUP BY CUBE (type_client, code_pays);
                             QUERY PLAN
------------------------------------------------------------------
 GroupAggregate (actual time=2389.425..4398.910 rows=40 loops=1)
   Group Key: cl.type_client, co.code_pays
   Group Key: cl.type_client
   Group Key: ()
   Sort Key: co.code_pays
     Group Key: co.code_pays
   Buffers: shared hit=14806 read=41624
   ->  Sort (actual time=2387.920..2538.658 rows=1226456 loops=1)
         Sort Key: cl.type_client, co.code_pays
         Sort Method: quicksort  Memory: 126065kB
(...)
 Planning time: 1.298 ms
 Execution time: 4412.666 ms
```


Exécutons la requête suivante sur l'instance 10 :

```sql
$ psql -q tp -p 5432
tp=# SET search_path TO magasin;
tp=# EXPLAIN (ANALYZE, BUFFERS, COSTS off)
SELECT GROUPING(type_client,code_pays)::bit(2),
       GROUPING(type_client)::boolean g_type_cli,
       GROUPING(code_pays)::boolean g_code_pays,
       type_client,
       code_pays,
       SUM(quantite*prix_unitaire) AS montant
  FROM commandes c
  JOIN lignes_commandes l
    ON (c.numero_commande = l.numero_commande)
  JOIN clients cl
    ON (c.client_id = cl.client_id)
  JOIN contacts co
    ON (cl.contact_id = co.contact_id)
 WHERE date_commande BETWEEN '2014-01-01' AND '2014-12-31'
GROUP BY CUBE (type_client, code_pays);
                           QUERY PLAN
-----------------------------------------------------------------
 MixedAggregate (actual time=3014.902..3014.928 rows=40 loops=1)
   Hash Key: cl.type_client, co.code_pays
   Hash Key: cl.type_client
   Hash Key: co.code_pays
   Group Key: ()
(...)
 Planning time: 2.207 ms
 Execution time: 3728.788 ms
```

L'amélioration des performances provient du noeud `MixedAggregate` qui fait son apparition en version 10. Il permet de peupler plusieurs tables de hachages en même temps qu'est effectué le tri des groupes.

Les performances sont évidemment améliorées si suffisamment de mémoire est allouée pour l'opération :

```sql
$ psql -q tp -p 5432
tp=# SET search_path TO magasin;
tp=# SET work_mem = '24MB';
tp=# EXPLAIN (ANALYZE, BUFFERS, COSTS off)
SELECT GROUPING(type_client,code_pays)::bit(2),
       GROUPING(type_client)::boolean g_type_cli,
       GROUPING(code_pays)::boolean g_code_pays,
       type_client,
       code_pays,
       SUM(quantite*prix_unitaire) AS montant
  FROM commandes c
  JOIN lignes_commandes l
    ON (c.numero_commande = l.numero_commande)
  JOIN clients cl
    ON (c.client_id = cl.client_id)
  JOIN contacts co
    ON (cl.contact_id = co.contact_id)
 WHERE date_commande BETWEEN '2014-01-01' AND '2014-12-31'
GROUP BY CUBE (type_client, code_pays);
(...)
 Planning time: 2.205 ms
 Execution time: 3018.079 ms
```

</div>

-----

## Collations ICU

<div class="notes">

La version 10 supporte la librairie [ICU](http://site.icu-project.org/).



Certaines fonctionnalités ne sont cependant disponibles que pour des versions de
la librairie ICU supérieures ou égales à la version 5.4. La version 4.2 est
utilisée par défaut :


```bash
# ldd /usr/pgsql-10/bin/postgres  | grep icu
	libicui18n.so.42 => /usr/lib64/libicui18n.so.42 (0x00007f9351222000)
	libicuuc.so.42 => /usr/lib64/libicuuc.so.42 (0x00007f9350ed0000)
	libicudata.so.42 => /usr/lib64/libicudata.so.42 (0x00007f934d1e1000)
```

Pour permettre le test des fonctionnalités liées aux collations ICU, nous allons
télécharger les sources de la librairie ICU en version 5.8 et recompiler
PostgreSQL en utilisant cette version de la librairie :

```bash
yum groupinstall -y "Development Tools"
yum install -y wget tar flex bison readline-devel zlib-devel git
mkdir test_icu
cd test_icu
wget https://kent.dl.sourceforge.net/project/icu/ICU4C/58.1/icu4c-58_1-src.tgz
tar xf icu4c-58_1-src.tgz
cd icu/source
./configure
make -j3
make install
echo '/usr/local/lib/' > /etc/ld.so.conf.d/local-libs.conf
ldconfig
mkdir ~/pg_src
cd ~/pg_src
git clone git://git.postgresql.org/git/postgresql.git
cd postgresql
./configure ICU_CFLAGS='-I/usr/local/include/unicode/' \
  ICU_LIBS='-L/usr/local/lib -licui18n -licuuc -licudata' --with-icu
make -j3
make install
sudo -iu postgres mkdir -p /var/lib/pgsql/10_icu58/data
sudo -iu postgres /usr/local/pgsql/bin/initdb --data /var/lib/pgsql/10_icu58/data
sed -i "s/#port = 5432/port = 5458/" /var/lib/pgsql/10_icu58/data/postgresql.conf
sudo -iu postgres /usr/local/pgsql/bin/pg_ctl -D /var/lib/pgsql/10_icu58/data \
    -l logfile start
```

Il est maintenant possible de se connecter à la nouvelle instance via la commande :

```bash
sudo -iu postgres /usr/local/pgsql/bin/psql -p 5458
psql (11devel)
Type "help" for help.
```

Voici un premier exemple de changement de collationnement : nous voulons que les chiffres soient placés après les lettres :

```sql
postgres=# SELECT * FROM (
      SELECT '1a' i UNION SELECT '1b' UNION SELECT '1c'
      UNION SELECT 'a1' UNION SELECT 'b2' UNION SELECT 'c3'
   ) j ORDER BY i COLLATE "en-x-icu";
 i  
----
 1a
 1b
 1c
 a1
 b2
 c3
(6 rows)

postgres=# CREATE COLLATION digitlast (provider=icu, locale='en-u-kr-latn-digit');
CREATE COLLATION
postgres=# SELECT * FROM (
     SELECT '1a' i UNION SELECT '1b' UNION SELECT '1c' 
     UNION SELECT 'a1' UNION SELECT 'b2' UNION SELECT 'c3'
  ) j ORDER BY i COLLATE "digitlast";
 i  
----
 a1
 b2
 c3
 1a
 1b
 1c
(6 rows)
```

Nous pouvons également effectuer un changement de collationnement pour classer les majuscules après les minuscules :
```sql
postgres=# SELECT * FROM (
    SELECT 'B' i UNION SELECT 'b' UNION SELECT 'A' UNION SELECT 'a'
  ) j ORDER BY i COLLATE "en-x-icu";
 i 
---
 a
 A
 b
 B
(4 rows)

postgres=# CREATE COLLATION capitalfirst (provider=icu, locale='en-u-kf-upper');
CREATE COLLATION
postgres=# SELECT * FROM (
    SELECT 'B' i UNION SELECT 'b' UNION SELECT 'A' UNION SELECT 'a'
  ) j ORDER BY i COLLATE "capitalfirst";
 i 
---
 A
 a
 B
 b
(4 rows)
```

Nous travaillons en UTF, nous pouvons donc aussi changer l'ordre de classement
des émoticônes  :-)

```sql
SELECT chr(x) FROM generate_series(x'1F634'::int, x'1F643'::int)
    AS _(x) ORDER BY chr(x) COLLATE "en-x-icu";
CREATE COLLATION "und-u-co-emoji-x-icu" (provider = icu, locale = 'und-u-co-emoji');
SELECT chr(x) FROM generate_series(x'1F634'::int, x'1F643'::int)
    AS _(x) ORDER BY chr(x) COLLATE "und-u-co-emoji-x-icu";
```


</div>

-----

## Réplication logique : publication

<div class="notes">

Nous allons créer une base de donnée `souscription` et y répliquer de façon
logique la table partitionnée `meteo` crée précédemment.

Tout d'abord, nous devons nous assurer que notre instance est configurée pour
permettre la réplication logique. Le paramètre `wal_level` doit être fixé à 
`logical` dans le fichier `postgresql.conf`.
Ce paramètre a un impact sur les informations stockées dans les fichiers WAL, un
redémarrage de l'instance est donc nécessaire en cas de changement.

Ensuite, créons la base de donnée `souscription` dans notre instance 10 :

```sql
psql -c "CREATE DATABASE souscription"
```

Dans la base de données `workshop10`, nous allons tenter de créer la publication
sur la table partitionnée :
```sql
workshop10=# CREATE PUBLICATION local_publication FOR TABLE meteo;
ERROR:  "meteo" is a partitioned table
DÉTAIL : Adding partitioned tables to publications is not supported.
ASTUCE : You can add the table partitions individually.
```

Comme précisé dans le cours, il est impossible de publier les tables parents.
Nous allons devoir publier chaque partition. Nous partons du principe que seul
le mois de septembre nous intéresse :
```sql
CREATE PUBLICATION local_publication FOR TABLE
  meteo_lyon_201709, meteo_nantes_201709, meteo_paris_201709;
SELECT * FROM pg_create_logical_replication_slot('local_souscription','pgoutput');
```

Comme nous travaillons en local, il est nécessaire de créer le slot de
réplication manuellement. Il faudra créer la souscription de manière à ce
qu'elle utilise le slot de réplication que nous venons de créer. Si ce n'est pas
fait, nous nous exposons à un blocage de l'ordre de création de souscription. Ce
problème n'arrive pas lorsque l'on travaille sur deux instances séparées.


</div>

-----

## Réplication logique : souscription

<div class="notes">

Après avoir géré la partie publication, passons à la partie souscription.

Nous allons maintenant créer un utilisateur spécifique qui assurera la
réplication logique :

```bash
$ createuser --replication replilogique
```

Lui donner un mot de passe et lui permettre de visualiser les données dans la
base `workshop10` :

```sql
workshop10=# ALTER ROLE replilogique PASSWORD 'pwd';
ALTER ROLE
workshop10=# GRANT SELECT ON ALL TABLES IN SCHEMA public TO replilogique;
GRANT
```

Nous devons également lui autoriser l'accès dans le fichier `pg_hba.conf` de
l'instance :

```
host    all            replilogique    127.0.0.1/32             md5
```

Sans oublier de recharger la configuration :

```sql
workshop10=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 ligne)
```

Dans la base de données `souscription`, créer les tables à répliquer :

```sql
CREATE TABLE meteo (
   t_id integer GENERATED BY DEFAULT AS IDENTITY,
   lieu text NOT NULL,
   heure_mesure timestamp DEFAULT now(),
   temperature real NOT NULL
 ) PARTITION BY RANGE (lieu, heure_mesure);
CREATE TABLE meteo_lyon_201709 PARTITION of meteo FOR VALUES
   FROM ('Lyon', '2017-09-01 00:00:00') TO ('Lyon', '2017-10-01 00:00:00');
CREATE TABLE meteo_nantes_201709 PARTITION of meteo FOR VALUES
   FROM ('Nantes', '2017-09-01 00:00:00') TO ('Nantes', '2017-10-01 00:00:00');
CREATE TABLE meteo_paris_201709 PARTITION of meteo FOR VALUES
   FROM ('Paris', '2017-09-01 00:00:00') TO ('Paris', '2017-10-01 00:00:00');
```

Nous pouvons maintenant créer la souscription à partir de la base de donnée
`souscription` :

```sql
souscription=# CREATE SUBSCRIPTION souscription 
 CONNECTION 'host=127.0.0.1 port=5432 user=replilogique dbname=workshop10 password=pwd'
 PUBLICATION local_publication with (create_slot=false,slot_name='local_souscription');
CREATE SUBSCRIPTION
```

Vérifier que les données ont bien été répliquées sur la base `souscription`.

N'hésitez pas à vérifier dans les logs dans le cas où une opération ne semble pas
fonctionner.

</div>

-----

## Réplication logique : modification des données

<div class="notes">

Maintenant que la réplication logique est établie, nous allons étudier les
possibilités offertes par cette dernière.

Contrairement à la réplication physique, il est possible de modifier les données
de l'instance en souscription :

```sql
souscription=# SELECT * FROM meteo LIMIT 1;
 t_id | lieu |    heure_mesure     | temperature 
------+------+---------------------+-------------
    1 | Lyon | 2017-09-24 04:10:59 |       18.59
(1 ligne)

souscription=# DELETE FROM meteo WHERE t_id=1;
DELETE 1
souscription=# SELECT * FROM meteo WHERE t_id=1;
 t_id | lieu | heure_mesure | temperature 
------+------+--------------+-------------
(0 ligne)
```

Cette suppression n'a pas eu d'impact sur l'instance principale :

```sql
workshop10=# SELECT * FROM meteo WHERE t_id=1;
 t_id | lieu |    heure_mesure     | temperature 
------+------+---------------------+-------------
    1 | Lyon | 2017-09-24 04:10:59 |       18.59
(1 ligne)
```

Essayons maintenant de supprimer ou modifier des données de l'instance
principale :

```sql
workshop10=# UPDATE meteo SET temperature=25 WHERE temperature<15;
ERROR:  cannot update table "meteo_lyon_201709" because it does not have
        replica identity and publishes updates
ASTUCE : To enable updating the table, set REPLICA IDENTITY using ALTER TABLE.

workshop10=# DELETE FROM meteo WHERE temperature < 15;
ERROR:  cannot delete from table "meteo_lyon_201709" because it does not have
        replica identity and publishes deletes
ASTUCE : To enable deleting from the table, set REPLICA IDENTITY using ALTER TABLE.
```

Il nous faut créer un index unique sur les tables répliquées puis déclarer cet
index comme `REPLICA IDENTITY` dans la base de donnée `workshop10` :

```sql
CREATE UNIQUE INDEX meteo_lyon_201709_pkey ON meteo_lyon_201709 (t_id);
CREATE UNIQUE INDEX meteo_nantes_201709_pkey ON meteo_nantes_201709 (t_id);
CREATE UNIQUE INDEX meteo_paris_201709_pkey ON meteo_paris_201709 (t_id);
ALTER TABLE meteo_lyon_201709 REPLICA IDENTITY USING INDEX meteo_lyon_201709_pkey;
ALTER TABLE meteo_nantes_201709 REPLICA IDENTITY USING INDEX meteo_nantes_201709_pkey;
ALTER TABLE meteo_paris_201709 REPLICA IDENTITY USING INDEX meteo_paris_201709_pkey;
```

Vérifions l'effet de nos modifications :
```sql
workshop10=# UPDATE meteo SET temperature=25 WHERE temperature<15;
UPDATE 150310
workshop10=# SELECT count(*) FROM meteo WHERE temperature<15;
 count 
-------
     0
(1 ligne)
```

La mise à jour a été possible sur la base de données principale. Quel effet cela
a-t-il produit sur la base de données répliquée :

```sql
souscription=# SELECT count(*) FROM meteo WHERE temperature<15;
 count 
-------
 75291
(1 ligne)
```

La mise à jour ne semble pas s'être réalisée. Vérifions dans les logs applicatifs :

```
LOG:  logical replication apply worker for subscription "souscription"
      has started
LOG:  starting logical decoding for slot "local_souscription"
DETAIL:  streaming transactions committing after 0/F4FFF450, 
         reading WAL from 0/F33E5B18
LOG:  logical decoding found consistent point at 0/F33E5B18
DETAIL:  There are no running transactions.
ERROR:  logical replication target relation "public.meteo_lyon_201709" has
        neither REPLICA IDENTITY index nor PRIMARY KEY and published relation
	does not have REPLICA IDENTITY FULL
LOG:  could not send data to client: Connection reset by peer
CONTEXT:  slot "local_souscription", output plugin "pgoutput", in the change
          callback, associated LSN 0/F33EC9B0
LOG:  worker process: logical replication worker for subscription 17685
      (PID 3743) exited with exit code 1
```

Les ordres DDL ne sont pas transmis avec la réplication logique. Nous devons
toujours penser à appliquer tous les changements effectués sur l'instance
principale sur l'instance en réplication.

```sql
souscription=# CREATE UNIQUE INDEX meteo_lyon_201709_pkey
   ON meteo_lyon_201709 (t_id);
CREATE INDEX
souscription=# CREATE UNIQUE INDEX meteo_nantes_201709_pkey 
   ON meteo_nantes_201709 (t_id);
CREATE INDEX
souscription=# CREATE UNIQUE INDEX meteo_paris_201709_pkey 
   ON meteo_paris_201709 (t_id);
CREATE INDEX
souscription=# ALTER TABLE meteo_lyon_201709 REPLICA IDENTITY 
   USING INDEX meteo_lyon_201709_pkey;
ALTER TABLE
souscription=# ALTER TABLE meteo_nantes_201709 REPLICA IDENTITY 
   USING INDEX meteo_nantes_201709_pkey;
ALTER TABLE
souscription=# ALTER TABLE meteo_paris_201709 REPLICA IDENTITY 
   USING INDEX meteo_paris_201709_pkey;
ALTER TABLE
```

La réplication logique est de nouveau fonctionnelle. Cependant les modifications
effectuées sur la base principale sont dorénavant perdues :

```sql
souscription=# SELECT count(*) FROM meteo WHERE temperature<15;
 count 
-------
 75291
(1 ligne)
```

Réappliquons la modification sur la base `workshop10` :
```sql
workshop10=# UPDATE meteo SET temperature=25 WHERE temperature<15;
UPDATE 0
```

Vérifions l'effet sur la base de donnée répliquée :
```sql
souscription=# SELECT count(*) FROM meteo WHERE temperature<15;
 count 
-------
     0
(1 ligne)

souscription=# SELECT count(*) FROM meteo WHERE temperature=25;
 count 
-------
 75291
(1 ligne)
```

</div>
