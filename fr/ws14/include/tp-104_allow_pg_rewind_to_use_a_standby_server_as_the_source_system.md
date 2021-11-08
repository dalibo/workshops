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

* Ouvrir un terminal puis emprunter l'identité de l'utilisateur `postgres` sur votre machine.

```bash
sudo su - postgres
```

Pour cet atelier, nous créons des instances temporaires dans le répertoire
`~/tmp/rewind` :

* Configurer la variable `DATADIRS`.

```bash
export DATADIRS=~/tmp/rewind
```

* Créer le répertoire `~/tmp/rewind` et le répertoire `~/tmp/rewind/archives`.

```bash
mkdir --parents ${DATADIRS}/archives
```

### Création d'une instance primaire

* Configurer les variables d'environnement pour l'instance à déployer.

```bash
export PGNAME=srv1
export PGDATA=$DATADIRS/$PGNAME
export PGPORT=5636
```

* Créer le répertoire `~/tmp/rewind/srv1`.

```bash
mkdir --parents ${DATADIRS}/${PGNAME}
```

* Créer une instance primaire dans le dossier `~/tmp/rewind/srv1` en activant les sommes de contrôle.

```bash
/usr/pgsql-14/bin/initdb --data-checksums --pgdata=${PGDATA} --username=postgres
```

> Note: Pour utiliser `pg_rewind`, il est nécessaire d'activer le paramètre
> `wal_log_hints` dans le `postgresql.conf` ou les sommes de contrôles au niveau
> de l'instance.

* Configurer PostgreSQL.

```bash
cat <<_EOF_ >> ${PGDATA}/postgresql.conf
port = ${PGPORT}
listen_addresses = '*'
logging_collector = on
archive_mode = on
archive_command = '/usr/bin/rsync -a %p ${DATADIRS}/archives/%f'
restore_command = '/usr/bin/rsync -a ${DATADIRS}/archives/%f %p'
cluster_name = '${PGNAME}'
_EOF_
```

* Démarrer l'instance primaire.

```bash
/usr/pgsql-14/bin/pg_ctl start --pgdata=${PGDATA} --wait
```

* Créer une base de données `pgbench`.

```bash
psql --port=${PGPORT} --command="CREATE DATABASE pgbench;"
```

* Initialiser la base de données `pgbench` avec la commande **pgbench**.

```bash
/usr/pgsql-14/bin/pgbench --port=${PGPORT} --initialize --scale=10 pgbench
```

* Créer un utilisateur 'replication' avec le mot de passe `replication` pour la réplication PostgreSQL.

```bash
psql --port=${PGPORT} --command="CREATE ROLE replication WITH LOGIN REPLICATION PASSWORD 'replication';"
```

*  Ajouter le mot de passe au fichier `.pgpass`.

```bash
cat << _EOF_ >> ~/.pgpass
*:5636:replication:replication:replication # srv1
*:5637:replication:replication:replication # srv2
*:5638:replication:replication:replication # srv3
_EOF_
chmod 600 ~/.pgpass
```

### Mettre en place la réplication sur deux secondaires

* Configurer les variables d'environnement pour l'instance à déployer.

```bash
export PGNAME=srv2
export PGDATA=${DATADIRS}/${PGNAME}
export PGPORT=5637
```

* Créer une instance secondaire à l'aide de l'outil `pg_basebackup`.

```bash
pg_basebackup --pgdata=${PGDATA} --port=5636 --progress --username=replication --checkpoint=fast
```

* Ajouter un fichier `standby.signal` dans le répertoire de données de l'instance
**srv2**.

```bash
touch ${PGDATA}/standby.signal
```

* Modifier la configuration.

```bash
cat << _EOF_ >> ${PGDATA}/postgresql.conf
port = ${PGPORT}
primary_conninfo = 'port=5636 user=replication application_name=${PGNAME}'
cluster_name = '${PGNAME}'
_EOF_
```

* Démarrer l'instance secondaire.

```bash
/usr/pgsql-14/bin/pg_ctl start --pgdata=${PGDATA} --wait
```

La requête suivante doit renvoyer un nombre de lignes égal au nombre
d'instances secondaires. Elle doit être exécutée depuis l'instance primaire
**srv1** :

```bash
psql --port=5636 --expanded --command="SELECT * FROM pg_stat_replication;"
```

* Faire les mêmes opérations pour construire une troisième instance.

```bash
export PGNAME=srv3
export PGDATA=${DATADIRS}/${PGNAME}
export PGPORT=5638
```

### Décrochage volontaire de l'instance secondaire **srv3**

* Faire un checkpoint sur l'instance **srv3**.

```bash
psql --port=5638 --command="CHECKPOINT;"
```

* Promouvoir l'instance secondaire **srv3**.

```bash
/usr/pgsql-14/bin/pg_ctl promote --pgdata=${DATADIRS}/srv3 --wait
```

* Ajouter des données aux instances **srv1** et **srv3** afin de les faire
diverger (une minute d'attente par instance).

```bash
# Simulation d'une activité normale sur l'instance srv1
/usr/pgsql-14/bin/pgbench --port=5636 --client=10 --time=60 --no-vacuum pgbench
# Simulation d'une activité normale sur l'instance srv3
/usr/pgsql-14/bin/pgbench --port=5638 --client=10 --time=60 --no-vacuum pgbench
```

Les deux instances ont maintenant divergé. Sans action supplémentaire, il n'est
donc pas possible de raccrocher l'ancienne instance secondaire **srv3** à l'instance
primaire **srv1**.

* Stopper l'instance **srv3** proprement.

```bash
/usr/pgsql-14/bin/pg_ctl stop --pgdata=${DATADIRS}/srv3 --mode=fast --wait
```

### Utilisation de pg_rewind

* Donner les autorisations à l'utilisateur `replication` sur les fonctions
`pg_ls_dir`, `pg_stat_file`, `pg_read_binary_file` et `pg_read_binary_file` du
schéma `pg_catalog` afin qu'il puisse utiliser `pg_rewind`.

```bash
psql --port=5636 <<_EOF_
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

* Sauvegarder la configuration qui diffère entre **srv1** et **srv3** (ici
`postgresql.conf`) car les fichiers de **srv1** vont écraser ceux de **srv3**
pendant le _rewind_.

```bash
cp ${DATADIRS}/srv3/postgresql.conf ${DATADIRS}/postgresql.srv3.conf
```

* Utiliser `pg_rewind` pour reconstruire l'instance **srv3** depuis l'instance
**srv2** (commencer par un passage à blanc `--dry-run`).

```bash
/usr/pgsql-14/bin/pg_rewind --target-pgdata ${DATADIRS}/srv3           \
          --source-server "port=5637 user=replication dbname=postgres" \
          --restore-target-wal                                         \
          --progress                                                   \
          --dry-run
```

Une fois le résultat validé, relancer `pg_rewind` sans `--dry-run`.

```bash
/usr/pgsql-14/bin/pg_rewind --target-pgdata ${DATADIRS}/srv3           \
          --source-server "port=5637 user=replication dbname=postgres" \
          --restore-target-wal                                         \
          --progress
```

* Restaurer le postgresql.conf de **srv3**.

```bash
cp ${DATADIRS}/postgresql.srv3.conf ${DATADIRS}/srv3/postgresql.conf
```

À l'issue de l'opération, les droits donnés à l'utilisateur de réplication
peuvent être révoqués :

```bash
psql --port=5636 <<_EOF_
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

* Mettre à jour la configuration de **srv3** pour en faire une instance
secondaire.

```bash
touch ${DATADIRS}/srv3/standby.signal

cat <<_EOF_ >> ${DATADIRS}/srv3/postgresql.conf
recovery_target_timeline = 1 # Forcer la même timeline que le maître pour la recovery
_EOF_
```

* Redémarrer l'instance **srv3**.

```bash
/usr/pgsql-14/bin/pg_ctl start --pgdata=${DATADIRS}/srv3 --wait
```

La requête suivante doit renvoyer un nombre de lignes égal au nombre
d'instances secondaires. Elle doit être exécutée depuis l'instance primaire
**srv1** :

```bash
psql --port=5636 --expanded --command="SELECT * FROM pg_stat_replication;"
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
