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
</div>

-----

## Installation

<div class="notes">
Les machines de la salle de formation utilisent CentOS 6. L'utilisateur dalibo peut utiliser sudo pour les opérations système.

Le site postgresql.org propose son propre dépôt RPM, nous allons donc l'utiliser pour installer PostgreSQL 10.

On commence par installer le RPM du dépôt `pgdg-centos10-10-1.noarch.rpm` :

```
# yum install https://dali.bo/TniaH
Installing:
 pgdg-centos10                     noarch                     10-1

# yum install postgresql10 postgresql10-server postgresql10-contrib
Installing:
 postgresql10                        x86_64                10.0-beta2_2PGDG.rhel6
 postgresql10-contrib                x86_64                10.0-beta2_2PGDG.rhel6
 postgresql10-server                 x86_64                10.0-beta2_2PGDG.rhel6
Installing for dependencies:
 postgresql10-libs                   x86_64                10.0-beta2_2PGDG.rhel6
```

On peut ensuite initialiser une instance :

```
# service postgresql-10 initdb
Initializing database:                                     [  OK  ]
```

Enfin, on démarre l'instance car ce n'est par défaut pas automatique sous RedHat et CentOS :

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
 PostgreSQL 10beta2 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.4.7 2012031.
.3 (Red Hat 4.4.7-18), 64-bit
(1 row)
```
On répète ensuite le processus d'installation de façon à installer PostgreSQL 9.6 aux côtés de PostgreSQL 10.

Le RPM du dépôt est `pgdg-centos96-9.6-3.noarch.rpm` :

```
# yum install https://dali.bo/ZQIVa
Installing:
 pgdg-centos96                    noarch                    9.6-3

# yum install postgresql96 postgresql96-server postgresql96-contrib
Installing:
 postgresql96                             x86_64                     9.6.3-4PGDG.rhel6
 postgresql96-contrib                     x86_64                     9.6.3-4PGDG.rhel6
 postgresql96-server                      x86_64                     9.6.3-4PGDG.rhel6
Installing for dependencies:
 postgresql96-libs                        x86_64                     9.6.3-4PGDG.rhel6

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

Si on veut modifier l'algorithme par défaut au niveau de la session PostgreSQL, on peut constater que seuls `md5` et `scram-sha-256` sont supportés :

```sql
postgres=# SET password_encryption TO 
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
</div>

-----

## Vue pg_hba_file_rules

<div class="notes">
La vue `pg_hba_file_rules` permet de consulter en lecture les règles d'accès qui sont configurées :

```sql
testseq=# SELECT type,database,user_name,auth_method FROM pg_hba_file_rules;
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
On commence par se connecter à PostgreSQL de façon à créer une base de données de test :

```sql
postgres=# CREATE DATABASE testseq;
CREATE DATABASE

postgres=# \c testseq 
You are now connected to database "testseq" as user "postgres".
```

On peut alors créer deux tables `t1` et `t2` dans les 2 instances en 9.6 et 10 :

```sql
CREATE TABLE t1 (
	id serial,
	data text
);

testseq=# INSERT INTO t1 (data) SELECT 'test' || i FROM generate_series(1,10) i;
INSERT 0 10

testseq=# INSERT INTO t2 (data) SELECT 'test' || i FROM generate_series(1,20) i;
INSERT 0 20
```

et vérifier leurs schémas :

```sql
testseq=# \d t1
                            Table "public.t1"
 Column |  Type   | Collation | Nullable |            Default             
--------+---------+-----------+----------+--------------------------------
 id     | integer |           | not null | nextval('t1_id_seq'::regclass)
 data   | text    |           |          | 

testseq=# \d t2
                            Table "public.t2"
 Column |  Type   | Collation | Nullable |            Default             
--------+---------+-----------+----------+--------------------------------
 id     | integer |           | not null | nextval('t2_id_seq'::regclass)
 data   | text    |           |          | 
```

Dans l'instance utilisant PostgreSQL 9.6, on a uniquement accès aux contenus des séquences :

```sql
testseq=# SELECT * FROM t1_id_seq;
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

testseq=# SELECT * FROM t2_id_seq;
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

Pour avoir une vue aggrégée, il est nécessaire d'utiliser une requête SQL adaptée :

```sql
testseq=#  SELECT * FROM t1_id_seq UNION ALL SELECT * FROM t2_id_seq;
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

Dans l'instance utilisant PostgreSQL 10, on a également accès aux contenus des séquences mais on constate qu'il y a moins d'informations :

```sql
testseq=# SELECT * FROM t1_id_seq;
-[ RECORD 1 ]--
last_value | 10
log_cnt    | 23
is_called  | t

testseq=# SELECT * FROM t2_id_seq;
-[ RECORD 1 ]--
last_value | 20
log_cnt    | 13
is_called  | t
```

Une requête avec un UNION ALL reste possible pour aggréger les résultats mais la vue `pg_sequence` permet d'accéder facilement à de telles informations :

```sql
testseq=# SELECT * FROM pg_sequence;
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

L'option `-X` a bien disparu.

On créé à présent un slot de réplication permanent :

```sql
testseq=# SELECT pg_create_physical_replication_slot('reptest', 't', 'f');
-[ RECORD 1 ]-----------------------+---------------------
pg_create_physical_replication_slot | (reptest,3/B7000C88)
```

On vérifie ensuite qu'il a bien été créé :

```sql
testseq=# SELECT * FROM pg_replication_slots;
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
postgres=# SELECT pg_create_physical_replication_slot('reptest', 't', 't');
 pg_create_physical_replication_slot 
-------------------------------------
 (reptest,3/B3000028)
(1 row)
```

Lors du lancement, on obtient :

```
$ pg_basebackup --progress --verbose --write-recovery-conf \
  --pgdata=10/datanew3/ -S reptest
pg_basebackup: initiating base backup, waiting for checkpoint to complete
pg_basebackup: checkpoint completed
pg_basebackup: write-ahead log start point: 3/B5000028 on timeline 1
pg_basebackup: starting background WAL receiver
pg_basebackup: could not send replication command "START_REPLICATION": ERROR:  replication slot "reptest" does not exist
[...]

```
</div>

-----

## Parallélisation

<div class="notes">
Dans les 2 instances, on ajoute des lignes à `t1` :

```sql
testseq=# INSERT INTO t1 (data) SELECT 'test' || i FROM generate_series(1,51110000) i;
INSERT 0 51110000
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

Regardons les plans d'exécution renvoyés par :

```sql
testseq=# EXPLAIN (ANALYZE,BUFFERS,VERBOSE) SELECT COUNT(id) FROM t1;
```

Sur les deux instances, on observe la présence d'un noeud `Gather`.

Regardons à présent les plans d'exécution renvoyés par :

```sql
testseq=# EXPLAIN (ANALYZE,BUFFERS,VERBOSE) SELECT COUNT(id) FROM t1 WHERE id < 1000000 AND id > 4;
```

Dans le contexte d'un noeud `Index Only Scan`, un noeud `Gather` n'est bien présent que dans l'instance 10.

-----

## Partitionnement

<div class="notes">
FIXME: contenu
</div>

-----

## Performances

<div class="notes">
FIXME: contenu / tri / mail de thomas
</div>
