## TP - wal_keep_segments et wal_keep_size

<div class="slide-content">

  * Simulation de migration du paramétrage.

</div>

<div class="notes">

Nous allons simuler une migration de paramétrage vers PostgreSQL 13.

Ajouter `wal_keep_segments` au `postgresql.conf` :

```
$ cat << _EOF_ >> $PGDATA/postgresql.conf
wal_keep_segments  = 100
_EOF_
```

Essayer de démarrer PostgreSQL :

```
$ pg_ctl start -D $PGDATA -w

waiting for server to start....
LOG:  unrecognized configuration parameter "wal_keep_segments" in
+++ file "/home/benoit/var/lib/postgres/pgsql-13rc1/postgresql.conf" line 781
FATAL:  configuration file "/home/benoit/var/lib/postgres/pgsql-13rc1/postgresql.conf"
+++ contains errors
 stopped waiting
pg_ctl: could not start server
Examine the log output.
```

On constate que l'ancien paramètre n'est plus autorisé.

Pour déterminer la valeur de `wal_keep_size`, il faut multiplier
`wal_keep_segments` par la taille d'un segment qui est généralement 16 Mo.
Cette valeur peut être confirmée en consultant le _control file_.

```
$ pg_controldata $PGDATA | grep "Bytes per WAL segment"
Bytes per WAL segment:                16777216
```

Ou, si PostgreSQL est lancé :

```
# SHOW wal_segment_size ;
 wal_segment_size 
------------------
 16MB
```

Éditer `postgresql.conf` avec la nouvelle valeur (`1600 MB`), puis redémarrer :

```
$ pg_ctl start -D $PGDATA -w
waiting for server to start....
LOG:  starting PostgreSQL 13beta3 on x86_64-pc-linux-gnu, compiled by gcc
+++ (GCC) 9.3.1 20200408 (Red Hat 9.3.1-2), 64-bit
LOG:  listening on IPv6 address "::1", port 5436
LOG:  listening on IPv4 address "127.0.0.1", port 5436
LOG:  listening on Unix socket "/tmp/.s.PGSQL.5436"
LOG:  database system was shut down at 2020-09-14 16:56:26 CEST
LOG:  database system is ready to accept connections
 done
server started
```

Vérifier la valeur de `wal_keep_size` :

```
$ psql << _EOF_
SELECT name, setting, unit
  FROM pg_settings
 WHERE name LIKE 'wal_keep_size';
_EOF_

     name      | setting | unit
---------------+---------+------
 wal_keep_size | 1600    | MB
```

</div>
