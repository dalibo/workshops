## Outil pg_rewind

<div class="slide-content">

  * Création d'une instance primaire ;
  * Mise en place de la réplication sur deux secondaires ;
  * Promotion d'un secondaire pour réaliser des tests ;
  * Utilisation de `pg_rewind` pour raccrocher l'instance secondaire à la
    réplication.

</div>

<div class="notes">

### Mise en place de l'environnement

Pour cet atelier, nous créons des instances temporaires dans le répertoire
`~/tmp/rewind` :

> Créer le répertoire `~/tmp/rewind`.

```sh
mkdir -p ~/tmp/rewind
```

### Création d'une instance primaire

> Créer une instance primaire en activant les sommes de contrôle.

```bash
initdb --data-checksums $DATADIRS/$PGNAME -U postgres
```

Note: Pour utiliser `pg_rewind`, il est nécessaire d'activer le paramètre
`wal_log_hints` dans le `postgresql.conf` ou les sommes de contrôles au niveau
de l'instance.

> Configurer PostgreSQL.

```bash
cat <<_EOF_ >> $DATADIRS/${PGNAME}/postgresql.conf
port = 5636
listen_addresses = '*'
logging_collector = on
archive_mode = on
archive_command = '/usr/bin/rsync -a %p $DATADIRS/archives/%f'
restore_command = '/usr/bin/rsync -a $DATADIRS/archives/%f %p'
cluster_name = '${PGNAME}'
_EOF_
```

> Démarrer l'instance, y créer une base de données et initialiser une base
> **pgbench**.

```bash
pg_ctl start -D $DATADIRS/$PGNAME -w
psql -p 5636 -c "CREATE DATABASE bench;"
pgbench -p 5636 -i -s 10 bench
```

> Créer un utilisateur pour la réplication et ajouter le mot de passe au
> fichier `.pgpass`.

```bash
psql -p 5636 << _EOF_
CREATE ROLE replication
  WITH LOGIN REPLICATION PASSWORD 'replication';
_EOF_

cat << _EOF_ >> ~/.pgpass
*:5636:replication:replication:replication # srv1
*:5637:replication:replication:replication # srv2
*:5638:replication:replication:replication # srv3
_EOF_
chmod 600 ~/.pgpass
```

### Mettre en place la réplication sur deux secondaires

> Configurer les variables d'environnement pour l'instance à déployer.

```bash
export PGNAME=srv2
export PGDATA=$DATADIRS/$PGNAME
export PGPORT=5637
```

> Créer une instance secondaire.

```bash
pg_basebackup -D $PGDATA -p 5636 --progress --username=replication --checkpoint=fast
```

> Modifier la configuration.

```bash
touch $PGDATA/standby.signal

cat << _EOF_ >> $PGDATA/postgresql.conf
port = $PGPORT
primary_conninfo = 'port=5636 user=replication application_name=${PGNAME}'
cluster_name = '${PGNAME}'
_EOF_
```

> Démarrer l'instance secondaire.

```bash
pg_ctl start -D $PGDATA -w
```

La requête suivante doit renvoyer un nombre de lignes égal au nombre
d'instances secondaires. Elle doit être exécutée depuis l'instance primaire
**srv1** :

```bash
psql -p 5636 -xc "SELECT * FROM pg_stat_replication;"
```

> Faire les mêmes opérations pour construire une troisième instance.

```bash
export PGNAME=srv3
export PGDATA=$DATADIRS/$PGNAME
export PGPORT=5638
```

### Décrochage volontaire de l'instance secondaire **srv3**

> Promouvoir l'instance secondaire **srv3**.

```bash
pg_ctl promote -D $DATADIRS/srv3 -w
psql -p 5638 -c CHECKPOINT
```

> Ajouter des données aux instances **srv1** et **srv3** afin de les faire
> diverger (une minute d'attente par instance).

```bash
pgbench -p 5636 -c 10 -T 60 -n bench # Simulation d'une activité normale sur l'instance srv1
pgbench -p 5638 -c 10 -T 60 -n bench # Simulation d'un traitement spécifique sur l'instance srv3
```

Les deux instances ont maintenant divergé. Sans action supplémentaire, il n'est
donc pas possible de raccrocher l'ancienne instance secondaire **srv3** à l'instance
primaire **srv1**.

> Stopper l'instance **srv3** proprement.

```bash
pg_ctl stop -D $DATADIRS/srv3 -m fast -w
```

### Utilisation de pg_rewind

> Donner les autorisations à l'utilisateur de réplication, afin qu'il puisse
> utiliser `pg_rewind`.

```sql
psql -p 5636 <<_EOF_
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

> Sauvegarder la configuration qui diffère entre **srv1** et **srv3** (ici
> `postgresql.conf`) car les fichiers de **srv1** vont écraser ceux de **srv3**
> pendant le _rewind_.

```bash
cp $DATADIRS/srv3/postgresql.conf $DATADIRS
```

> Utiliser `pg_rewind` pour reconstruire l'instance **srv3** depuis l'instance
> **srv2** (commencer par un passage à blanc `--dry-run`).

```bash
pg_rewind --target-pgdata $DATADIRS/srv3                               \
          --source-server "port=5637 user=replication dbname=postgres" \
          --restore-target-wal                                         \
          --progress                                                   \
          --dry-run
```

Une fois le résultat validé, relancer `pg_rewind` sans `--dry-run`.

> Restaurer le postgresql.conf de **srv3**.

```bash
cp $DATADIRS/postgresql.conf $DATADIRS/srv3
```

À l'issue de l'opération, les droits donnés à l'utilisateur de réplication
peuvent être révoqués :

```sql
psql -p 5636 <<_EOF_
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

### Redémarrer srv3

> Mettre à jour de la configuration de **srv3** pour en faire une instance
> secondaire.

```bash
touch $DATADIRS/srv3/standby.signal

cat <<_EOF_ >> $DATADIRS/srv3/postgresql.conf
recovery_target_timeline = 1 # Forcer la même timeline que le maître pour la recovery
_EOF_
```

> Redémarrer l'instance **srv3**.

```bash
pg_ctl start -D $DATADIRS/srv3 -w
```

La requête suivante doit renvoyer un nombre de lignes égal au nombre
d'instances secondaires. Elle doit être exécutée depuis l'instance primaire
**srv1** :

```bash
psql -p 5636 -xc "SELECT * FROM pg_stat_replication;"
```

### Remarques

Commenter le paramètre `recovery_target_timeline` de la configuration de
l'instance **srv3**, car elle pourrait poser des problèmes par la suite.

Avec la procédure décrite dans cet atelier, le serveur **srv3** archive dans le
même répertoire que le serveur **srv1**. Il serait préférable d'archiver dans un
répertoire différent. Cela introduit de la complexité. En effet, `pg_rewind`
aura besoin des _WAL_ avant la divergence (répertoire de **srv3**) et ceux
générés depuis le dernier checkpoint précédent la _divergence_ (répertoire de
**srv1**).

</div>
