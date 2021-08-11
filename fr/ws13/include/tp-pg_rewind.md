## TP - Outil pg_rewind

<div class="slide-content">

  * Création d'une instance primaire ;
  * Mettre en place la réplication ;
  * Simulation d'un failover ;
  * Utilisation de pg_rewind.

</div>

<div class="notes">

### Création d'une instance primaire

Nous créons pour cette démonstration des instances temporaires dans le
répertoire `/tmp/rewind` :

```
export DATADIRS=/tmp/rewind
mkdir -p /tmp/rewind/archives
```

Créer une instance primaire en activant les checkpoints :

```
initdb --data-checksums --data-checksums $DATADIRS/pgrw_srv1 -U postgres
```

Note: Pour utiliser pg_rewind, il est nécessaire d'activer le paramètre
`wal_log_hints` dans le `postgresql.conf` ou les sommes de contrôles au niveau
de l'instance.

Configurer PostgreSQL :

```
cat <<_EOF_ >> $DATADIRS/pgrw_srv1/postgresql.conf
port = 5636
listen_addresses = '*'
logging_collector = on
archive_mode = on
archive_command = '/usr/bin/rsync -a %p $DATADIRS/archives/%f'
restore_command = '/usr/bin/rsync -a $DATADIRS/archives/%f %p'
_EOF_
```

Démarrer l'instance et y créer une base de données :

```
pg_ctl start -D $DATADIRS/pgrw_srv1 -w
psql -p 5636 -c "CREATE DATABASE bench;"
```

### Mettre en place la réplication

Créer un utilisateur pour la réplication et ajouter le mot de passe au
fichier `.pgpass` :

```
psql -p 5636 << _EOF_
CREATE ROLE replication
  WITH LOGIN REPLICATION PASSWORD 'replication';
_EOF_

cat << _EOF_ >> ~/.pgpass
*:5636:replication:replication:replication
*:5637:replication:replication:replication
_EOF_
chmod 600 ~/.pgpass
```

Créer une instance secondaire :

```
pg_basebackup -D $DATADIRS/pgrw_srv2 -p 5636 --progress --username=replication
```

Modifier la configuration :

```
touch $DATADIRS/pgrw_srv2/standby.signal

cat << _EOF_ >> $DATADIRS/pgrw_srv2/postgresql.conf
port = 5637
primary_conninfo =  'port=5636 user=replication application_name=replication'
_EOF_
```

Démarrer l'instance secondaire :

```
pg_ctl start -D $DATADIRS/pgrw_srv2 -w
```

La requête suivante doit renvoyer une ligne sur l'instance primaire :

```
psql -p 5636 -xc "SELECT * FROM pg_stat_replication;"
```

### Simulation d'un failover

Promouvoir l'instance secondaire :

```
pg_ctl promote -D $DATADIRS/pgrw_srv2 -w
psql -p 5637 -c CHECKPOINT
```

Ajouter des données aux deux instances afin de les faire diverger :

```
pgbench -p 5636 -i -s 20 bench;
pgbench -p 5637 -i -s 20 bench;
```

Les deux instances ont maintenant divergé. Sans action supplémentaire, il n'est
donc pas possible de raccrocher l'ancienne primaire à la nouvelle.

Stopper l'ancienne instance primaire de manière brutale pour simuler une panne :

```
pg_ctl stop -D $DATADIRS/pgrw_srv1 -m immediate -w
```

Note : la méthode d'arrêt recommandée est `-m fast`. L'objectif ici est de
mettre en évidence les nouvelles fonctionnalités de `pg_rewind`.

### Utilisation de pg_rewind

Donner les autorisations à l'utilisateur de réplication, afin qu'il puisse
utiliser `pg_rewind` :

```
psql -p 5637 <<_EOF_
GRANT EXECUTE
  ON function pg_catalog.pg_ls_dir(text, boolean, boolean)
  TO replication;
GRANT EXECUTE
  ON function pg_catalog.pg_stat_file(text, boolean)
  TO replication;
GRANT EXECUTE
  ON function pg_catalog.pg_read_binary_file(text)
  TO replication;
GRANT EXECUTE
  ON function pg_catalog.pg_read_binary_file(text, bigint, bigint, boolean)
  TO replication;
_EOF_
```

Sauvegarder la configuration de l'ancienne instance primaire. En effet, les
fichiers de configuration présents dans `PGDATA` seront écrasés par l'outil :

```
cp $DATADIRS/pgrw_srv1/postgresql.conf /tmp
```

Afin d'observer l'ancien fonctionnement par défaut de `pg_rewind`, utiliser le
paramètre `--no-ensure-shutdown` :

```
$ pg_rewind --target-pgdata $DATADIRS/pgrw_srv1                          \
            --source-server "port=5637 user=replication dbname=postgres" \
            --write-recovery-conf --no-ensure-shutdown                   \
            --progress --dry-run

pg_rewind: connected to server
pg_rewind: fatal: target server must be shut down cleanly
```

Un message d'erreur nous informe que l'instance n'a pas été arrêtée proprement.

Relancer `pg_rewind`, sans le paramètre `--no-ensure-shutdown` ni `--dry-run`
(qui empêche de réellement rétablir l'instance), afin d'observer le nouveau
fonctionnement par défaut :

```
$ pg_rewind --target-pgdata $DATADIRS/pgrw_srv1                          \
            --source-server "port=5637 user=replication dbname=postgres" \
            --write-recovery-conf --progress
pg_rewind: connected to server
pg_rewind: executing
+++"XXX/bin/postgres" for target server to complete crash recovery
LOG:  database system was interrupted; last known up at 2020-09-01 17:18:26 CEST
LOG:  database system was not properly shut down; automatic recovery in progress
LOG:  redo starts at 0/4000028
LOG:  invalid record length at 0/CB20E30: wanted 24, got 0
LOG:  redo done at 0/CB20D08

PostgreSQL stand-alone backend 13.0
backend> pg_rewind: servers diverged at WAL location 0/3000000 on timeline 1
pg_rewind: error: could not open file
+++ "XXX/pgrw_srv1/pg_wal/000000010000000000000005": No such file or directory
pg_rewind: fatal: could not find previous WAL record at 0/5000060
```

On constate que :

* pg_rewind a redémarré le cluster en mode mono-utilisateur afin de réaliser
  une récupération de l'instance ;
* l'opération échoue car PostgreSQL n'arrive pas à trouver un WAL dans
  `PGDATA/pg_wal`.

Vérifier la configuration de la `restore_command` dans le fichier de
configuration de la cible :

```
$ postgres -D /tmp/rewind/pgrw_srv1/ -C restore_command
/usr/bin/rsync -a $DATADIRS/archives/%f %p
```

Relancer la commande pg_rewind avec l'option `--restore-target-wal` :

```
$ pg_rewind --target-pgdata $DATADIRS/pgrw_srv1                        \
          --source-server "port=5637 user=replication dbname=postgres" \
          --write-recovery-conf --progress --restore-target-wal
pg_rewind: connected to server
pg_rewind: servers diverged at WAL location 0/3000000 on timeline 1
pg_rewind: rewinding from last common checkpoint at 0/2000060 on timeline 1
pg_rewind: reading source file list
pg_rewind: reading target file list
pg_rewind: reading WAL in target
pg_rewind: need to copy 282 MB (total source directory size is 308 MB)
     0/289512 kB (0%) copied
289512/289512 kB (100%) copied
pg_rewind: creating backup label and updating control file
pg_rewind: syncing target data directory
pg_rewind: Done!
```

Une fois l'opération réussie, restaurer le fichier de configuration d'origine sur
l'ancienne primaire et y ajouter la configuration de la réplication :

```
cp /tmp/postgresql.conf $DATADIRS/pgrw_srv1
```

Le paramètre `--write-recovery-conf` permet de générer le fichier
`PGDATA/standby.signal` et ajoute le paramètre `primary_conninfo` au fichier
`PGDATA/postgresql.auto.conf`. Vérifier leur présence.

```
$ ls $DATADIRS/pgrw_srv1/standby.signal
XXX/pgrw_srv1/standby.signal

$ postgres -D /tmp/rewind/pgrw_srv1/ -C primary_conninfo
primary_conninfo = 'user=replication passfile=''PATH_TO_HOME/.pgpass''
+++  channel_binding=disable host=''/tmp'' port=5637 sslmode=prefer
+++  sslcompression=0 ssl_min_protocol_version=TLSv1.2 gssencmode=disable
+++  krbsrvname=postgres target_session_attrs=any'
```

On constate que l'utilisateur mis en place dans la commande est celui utilisé
pour faire le `pg_rewind`.

Démarrer l'ancienne primaire :

```
pg_ctl start -D $DATADIRS/pgrw_srv1 -w
```

Contrôler que la réplication fonctionne en vérifiant que la requête suivante
renvoie une ligne sur la nouvelle instance primaire :

```
psql -p 5637 -xc "SELECT * FROM pg_stat_replication;"
```

À l'issue de l'opération, les droits donnés à l'utilisateur de réplication
peuvent être révoqués :

```
psql -p 5637 <<_EOF_
REVOKE EXECUTE
  ON function pg_catalog.pg_ls_dir(text, boolean, boolean)
  FROM  replication;
REVOKE EXECUTE
  ON function pg_catalog.pg_stat_file(text, boolean)
  FROM replication;
REVOKE EXECUTE
  ON function pg_catalog.pg_read_binary_file(text)
  FROM replication;
REVOKE EXECUTE
  ON function pg_catalog.pg_read_binary_file(text, bigint, bigint, boolean)
  FROM replication;
_EOF_
```

</div>
