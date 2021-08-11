## TP - Changement à chaud des informations de réplication

<div class="slide-content">

  * Mise en place d'une réplication ;
  * Changement de mot de passe ;
  * Utilisateur dédié et mot de passe dans `.pgpass` sans redémarrage.

</div>

<div class="notes">

### Mise en place du primaire

Sur une machine CentOS 7 ou 8 où les binaires de PostgreSQL sont installés,
créer une instance primaire, si elle n'existe pas déjà, qui écoute sur le port
5432, et une instance secondaire accessible sur le port 5433.

<!-- Pillé de l'annexe d'installation des manuels -->
En tant que root :

```console
# export PGSETUP_INITDB_OPTIONS='--data-checksums --lc-messages=C'
# /usr/pgsql-13/bin/postgresql-13-setup initdb
# systemctl start postgresql-13
# sudo -iu postgres psql -c "ALTER ROLE postgres PASSWORD 'elephant' ;"
```

Vérifier que la réplication est bien autorisée sur localhost, avec un mot de passe :

```console
# tail -3 ~postgres/13/data/pg_hba.conf
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
```

Si ce n'est pas le cas, ou si le serveur secondaire est sur une autre machine,
adapter `pg_hba.conf`.

Ajouter un peu de volumétrie :

```console
# sudo -iu postgres /usr/pgsql-13/bin/pgbench -i -s30 --no-vacuum
```

### Mise en place du secondaire

Répertoire et paramétrage systemd :

```console
# install -o postgres -g postgres -m 0700 -d /var/lib/pgsql/13/secondaire

# cp /lib/systemd/system/postgresql-13.service \
    /etc/systemd/system/postgresql-13-secondaire.service

# cat <<EOF | EDITOR=tee systemctl edit postgresql-13-secondaire.service
[Service]
Environment=PGDATA=/var/lib/pgsql/13/secondaire
EOF
```

Mise en place de la réplication :

```console
# sudo -iu postgres pg_basebackup -h localhost -U postgres \
  -D /var/lib/pgsql/13/secondaire --checkpoint=fast        \
  --create-slot  --slot='secondaire'                       \
  --write-recovery-conf --progress --verbose
# echo "port=5433" >> /var/lib/pgsql/13/secondaire/postgresql.conf
```

L'outil `pg_basebackup` demande de saisir le mot de passe de l'utilisateur
`postgres`.

Il crée le slot (`--create-slot`), crée le fichier `standby.signal` et
renseigne le paramétrage de réplication dans `postgresql.auto.conf`.

```console
# tail -2 ~postgres/13/secondaire/postgresql.auto.conf
primary_conninfo = 'user=postgres password=elephant channel_binding=prefer
                    host=localhost port=5432
                    sslmode=prefer sslcompression=0 ssl_min_protocol_version=TLSv1.2
                    gssencmode=prefer krbsrvname=postgres target_session_attrs=any'
primary_slot_name = 'secondaire'
```

Par ailleurs, nous constatons que le mot de passe y est renseigné en clair,
ainsi que de nombreuses options de réplication par défaut.

Démarrer le secondaire et vérifier la connexion :

```console
# systemctl start postgresql-13-secondaire
# sudo -iu postgres psql -p5433 -c \\d
              List of relations
 Schema |       Name       | Type  |  Owner
--------+------------------+-------+----------
 public | pgbench_accounts | table | postgres
 public | pgbench_branches | table | postgres
 public | pgbench_history  | table | postgres
 public | pgbench_tellers  | table | postgres
```

Vérifier sur le primaire que tout fonctionne :

```console
# sudo -iu postgres psql -xc 'TABLE pg_stat_replication'
-[ RECORD 1 ]----+------------------------------
pid              | 23986
usesysid         | 10
usename          | postgres
application_name | walreceiver
client_addr      | ::1
client_hostname  |
client_port      | 39892
backend_start    | 2020-10-15 17:36:55.207321+00
backend_xmin     |
state            | streaming
sent_lsn         | 0/2B000148
write_lsn        | 0/2B000148
flush_lsn        | 0/2B000148
replay_lsn       | 0/2B000148
write_lag        |
flush_lag        |
replay_lag       |
sync_priority    | 0
sync_state       | async
reply_time       | 2020-10-15 18:39:00.30708+00
```

Notez que sur le secondaire, le mot de passe est visible de tout
superutilisateur connecté avec un simple `SHOW primary_conninfo` !


### Activité sur le secondaire

Dans deux sessions séparées, lancer de l'activité en écriture sur le primaire,
et en lecture sur le secondaire.

```console
# sudo -iu postgres /usr/pgsql-13/bin/pgbench --no-vacuum --rate 10 -T3600

```

```console
# sudo -iu postgres /usr/pgsql-13/bin/pgbench --no-vacuum --rate 10 -T3600 \
    -p5433 --select
```

Nous allons étudier l'impact de différentes actions
sur cette dernière session.


### Modification des informations de connexion et redémarrage

Le mot de passe est beaucoup trop simple. Nous décidons de le modifier sur le
primaire :

```console
# sudo -iu postgres psql \
  -c "ALTER ROLE postgres PASSWORD 'aixohph8Pienoxaec6nohp2oh' ;"
```

La connexion du standby au primaire est déjà établie et reste en place.

Toute nouvelle connexion est néanmoins refusée au prochain redémarrage du
secondaire, parfois longtemps après :

```console
# systemctl restart postgresql-13-secondaire
```

En conséquence du redémarrage, le pgbench sur le secondaire est évidemment
coupé :

```
pgbench: fatal: Run was aborted; the above results are incomplete.
```

Le relancer :

```console
# sudo -iu postgres /usr/pgsql-13/bin/pgbench --no-vacuum --rate 10 -T3600 \
    -p5433 --select
```

Dans les journaux du secondaire `~postgres/13/secondaire/log/postgresql-*.log`,
l'erreur de connexion apparaît :

```
2020-10-16 07:20:14.288 UTC [25189] FATAL:  could not connect to the primary server:
      FATAL:  password authentication failed for user "postgres"
```

Corriger la chaîne de connexion qui contient le mot de passe sur le secondaire :

```console
# sudo -iu postgres psql -p5433
postgres=# ALTER SYSTEM SET primary_conninfo TO
  'user=postgres password=aixohph8Pienoxaec6nohp2oh host=localhost port=5432' ;
postgres=# SELECT pg_reload_conf() ;
```

Le pgbench n'est pas interrompu et le secondaire a repris la réplication sans
redémarrage :

```
2020-10-16 07:29:16.333 UTC [25583] LOG:  started streaming WAL from primary
                                          at 0/49000000 on timeline 1
```

### Utilisateur dédié et .pgpass

Il est plus propre et plus sûr de dédier un utilisateur à la réplication,
dont le mot de passe est beaucoup moins sujet au changement.
De plus, sur le secondaire, le mot de passe ne doit figurer que dans le
fichier `.pgpass` lisible uniquement par l'utilisateur système **postgres**.

Sur le primaire :

```console
postgres=# CREATE ROLE replicator LOGIN REPLICATION PASSWORD 'evuzahs3ien0bah2haiJ' ;
```

Suite à la configuration mise en place plus haut, il n'y a pas besoin de
modifier `pg_hba.conf`.

Sur le secondaire :

```console
# echo "localhost:5432:replication:replicator:evuzahs3ien0bah2haiJ" \
  > ~postgres/.pgpass
# chown postgres: ~postgres/.pgpass
# chmod 600 ~postgres/.pgpass

# cat <<EOS | sudo -iu postgres psql -p 5433

ALTER SYSTEM SET primary_conninfo
  TO 'user=replicator host=localhost port=5432';

SELECT pg_reload_conf();

EOS
```

Notez que nous utilisons la pseudo-base `replication` dans le fichier `.pgpass`.

Pendant ces dernières opérations, le pgbench sur le secondaire n'a pas été
interrompu... même si les données n'étaient pas de première fraîcheur lorsque la
réplication était bloquée.


### Changement d'instance principale

Nous créons dans cet exercice une nouvelle instance secondaire nommée `ter` et
basculons la production dessus, sans coupure de service pour
`postgresql-13-secondaire`.

Création de la nouvelle instance :

~~~console

# install -o postgres -g postgres -m 0700 -d /var/lib/pgsql/13/ter

# cp /lib/systemd/system/postgresql-13.service \
    /etc/systemd/system/postgresql-13-ter.service

# cat <<EOF | EDITOR=tee systemctl edit postgresql-13-ter.service
[Service]
Environment=PGDATA=/var/lib/pgsql/13/ter
EOF

# sudo -iu postgres pg_basebackup -h localhost -U replicator \
  -D /var/lib/pgsql/13/ter --checkpoint=fast                 \
  --create-slot  --slot='ter'                                \
  --write-recovery-conf --progress --verbose

# echo "port=5434" >> /var/lib/pgsql/13/ter/postgresql.conf

# systemctl start postgresql-13-ter
# sudo -iu postgres psql -p5434 -c \\d
              List of relations
 Schema |       Name       | Type  |  Owner
--------+------------------+-------+----------
 public | pgbench_accounts | table | postgres
 public | pgbench_branches | table | postgres
 public | pgbench_history  | table | postgres
 public | pgbench_tellers  | table | postgres
~~~

Vérifier sur le primaire que tout fonctionne :

~~~console
# sudo -iu postgres psql -Atc 'SELECT count(*) FROM pg_stat_replication'
2
~~~

Bascule de l'instance primaire vers `ter`. Il est nécessaire pour cela
d'interrompre l'instance primaire actuelle (1), vérifier la niveau de
réplication (2), puis de promouvoir `ter` (3) :

\newpage
~~~console
## (1)
# systemctl stop postgresql-13

## (2)
# /usr/pgsql-13/bin/pg_controldata ~postgres/13/data/|grep 'REDO location'
Latest checkpoint's REDO location:    0/2D416C60

# sudo -iu postgres psql -qp 5434 -c checkpoint

# /usr/pgsql-13/bin/pg_controldata ~postgres/13/ter/|grep 'REDO location'
Latest checkpoint's REDO location:    0/2D416C60

## (3)
# sudo -iu postgres psql -Atp 5434 -c "SELECT pg_promote(true)"
t
~~~

L'instance secondaire a perdu la connexion à l'instance primaire.

~~~console
# sudo -iu postgres psql -p5433 -Atc "SELECT count(*) FROM pg_stat_wal_receiver"
0
~~~

L'étape suivante consiste à établir la connexion vers la nouvelle instance :

~~~console
# sudo -iu postgres psql -p5434 -At \
    -c "SELECT pg_create_physical_replication_slot('secondaire')"
(secondaire,)

# cat <<EOS | sudo -iu postgres psql -p 5433

ALTER SYSTEM SET primary_conninfo
  TO 'user=replicator host=localhost port=5434';

SELECT pg_reload_conf();

EOS
~~~

La précédente ligne du fichier `.pgpass` est limitée au seul port 5432. Nous le
modifions afin de fournir un mot de passe quelque soit le port de connexion :

~~~console
# echo "localhost:*:replication:replicator:evuzahs3ien0bah2haiJ" \
  > ~postgres/.pgpass
~~~

Peu de temps après, l'instance secondaire entre en réplication avec la nouvelle
instance primaire `ter` :

~~~console
# sudo -iu postgres psql -p5434 \
    -c "select pid, state, sent_lsn from pg_stat_replication"
 pid  |   state   |  sent_lsn
------+-----------+------------
 7639 | streaming | 0/2D416E28


# sudo -iu postgres psql -p5433 \
    -c "select pid, status, flushed_lsn from pg_stat_wal_receiver"
 pid  |  status   | flushed_lsn
------+-----------+-------------
 7638 | streaming | 0/2D416E28
~~~

</div>
