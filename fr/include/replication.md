## Réplication

<div class="slide-content">

  * Nouveauté des `postgresql.conf`et `recovery.conf`
  * 2 fichiers _trigger_
  * Paramètres modifiables à chaud
  * Fonction `pg_promote()`
  * Copie de slot de réplication
</div>

<div class="notes">


</div>

----

### Nouveauté de `postgresql.conf` et `recovery.conf`

<div class="slide-content">

  * `recovery.conf` disparaît
  * Tous les paramètres dans `postgresql.conf`

</div>

<div class="notes">


Avec la version 12 de PostgreSQL, le fichier `recovery.conf` disparaît. Les paramètres de l'ancien fichier `recovery.conf` sont dans le fichier `postgresql.conf`.

Si le fichier `recovery.conf` est présent, PostgreSQL refuse de démarrer.

```log
FATAL:  using recovery command file "recovery.conf" is not supported
LOG:  startup process (PID 22810) exited with exit code 1
LOG:  aborting startup due to startup process failure
LOG:  database system is shut down
```

Les paramètres de l'ancien `recovery.conf` se retrouvent dans le fichier `postgresql.conf`, dans 2 sections.

Section pour les paramètres concernant le mode de recovery. 

```ini
#------------------------------------------------------------------------------
# WRITE-AHEAD LOG
#------------------------------------------------------------------------------
```

```ini
# - Archive Recovery -
# These are only used in recovery mode.

restore_command = '/opt/pgsql/12b2/bin/pg_standby /opt/pgsql/archives %f %p %r'         
                                # command to use to restore $
                                # placeholders: %p = path of file to restore
                                #               %f = file name only
                                # e.g. 'cp /mnt/server/archivedir/%f %p'
                                # (change requires restart)
archive_cleanup_command = '/opt/pgsql/12b2/bin/pg_archivecleanup 
                             -d /opt/pgsql/archives %r'     
                                # command to execute$

#recovery_end_command = ''      # command to execute at completion of recovery

# - Recovery Target -

# Set these only when performing a targeted recovery.

#recovery_target = ''           # 'immediate' to end recovery as soon as a
								# consistent state is reached
								# (change requires restart)
#recovery_target_name = ''      # the named restore point to which recovery will proceed
								# (change requires restart)
#recovery_target_time = ''      # the time stamp up to which recovery will proceed
								# (change requires restart)
#recovery_target_xid = ''       # the transaction ID up to which recovery will proceed
								# (change requires restart)
#recovery_target_lsn = ''       # the WAL LSN up to which recovery will proceed
								# (change requires restart)
#recovery_target_inclusive = on # Specifies whether to stop:
								# just after the specified recovery target (on)
								# just before the recovery target (off)
								# (change requires restart)
#recovery_target_timeline = 'latest'    # 'current', 'latest', or timeline ID
										# (change requires restart)
#recovery_target_action = 'pause'       # 'pause', 'promote', 'shutdown'
										# (change requires restart)
```



Section pour les paramètres concernant la configuration des réplicats.



``` ini
#------------------------------------------------------------------------------
# REPLICATION
#------------------------------------------------------------------------------
```

```ini
# - Standby Servers -
# These settings are ignored on a master server.

#primary_conninfo = ''                  # connection string to sending server
										# (change requires restart)
#primary_slot_name = ''                 # replication slot on sending server
										# (change requires restart)
#promote_trigger_file = ''              # file name whose presence ends recovery
#hot_standby = on                       # "off" disallows queries during recovery
										# (change requires restart)
#max_standby_archive_delay = 30s        # max delay before canceling queries
										# when reading WAL from archive;
										# -1 allows indefinite delay
#max_standby_streaming_delay = 30s      # max delay before canceling queries
										# when reading streaming WAL;
										# -1 allows indefinite delay
#wal_receiver_status_interval = 10s     # send replies at least this often
										# 0 disables
#hot_standby_feedback = off             # send info from standby to prevent
										# query conflicts
#wal_receiver_timeout = 60s             # time that receiver waits for
										# communication from master
										# in milliseconds; 0 disables
#wal_retrieve_retry_interval = 5s       # time to wait before retrying to
										# retrieve WAL after a failed attempt
#recovery_min_apply_delay = 0           # minimum delay for applying changes during recovery
```



Paramètres renommés ou supprimés : 

- `standby_mode` a été supprimé des paramètres et est remplacé par un fichier trigger sur disque.
- `trigger_file` a été renommé en `promote_trigger_file`.

</div>

----

### 2 fichiers _trigger_

<div class="slide-content">

  * `standby.signal`
  * `recovery.signal`

</div>

<div class="notes">


Pour que PostgreSQL démarre en mode **standby** ou **recovery**, 2 fichiers trigger sont utilisés, ils sont à positionner à la racine de l'instance PostgreSQL. 

- `standby.signal` : (remplace le paramètre `standby_mode=on`) permet de configurer l'instance en instance de secours. 
- `recovery.signal` : permet de configurer l'instance en mode récupération (exemple : restauration PITR).

</div>

----

### Paramètres modifiables à chaud

<div class="slide-content">

  * `archive_cleanup_command`
  * `recovery_end_command`
  * `recovery_min_apply_delay`
  * `promote_trigger_file`

</div>

<div class="notes">

Les paramètres suivants, sont modifiables à chaud : 

- `archive_cleanup_command` : permet de nettoyer les WAL qui ont été rejoués sur l'instance secondaire.
- `recovery_end_command` : permet de spécifier une commande (shell) à exécuter une fois l'instance restaurée.
- `recovery_min_apply_delay` : permet de différer l'application des WAL sur l'instance secondaire
- `promote_trigger_file` : permet de spécifier le chemin du fichier dont la présence déclenche la promotion de l'instance en standby.

</div>

----

### Fonction pg_promote()

<div class="slide-content">

  * `pg_promote`
</div>

<div class="notes">


PostgreSQL 12 offre la possibilité de promouvoir une instance standby (hot_standby) à l'aide d'une fonction `psql`. 

Rappel des 2 possibilités de promotion en version 11 : 

- commande système : `pg_ctl promote`
- création du fichier "trigger" en commande shell, en ayant préalablement configuré le paramètre `trigger_file` dans le fichier `recovery.conf`.

Dans les 2 cas, il faut avoir accès au système de fichiers avec les droits `postgres`.

PostgreSQL 12 offre un troisième moyen de déclencher une promotion avec une fonction système SQL. 

Énorme avantage : il n'est pas nécessaire de se connecter physiquement au serveur pour déclencher la promotion d'une standby.
On notera que cela nécessite que le serveur soit en capacité d'accepter des connexions et donc accessible en lecture (hot_standby).

Par défaut, la fonction `pg_promote()` attend la fin de la promotion pour renvoyer le résultat à l'appelant, avec un timeout max de 60 secondes.
La fonction `pg_promote()` accepte 2 paramètres optionnels :

- `wait` (booléen) : permet de ne pas attendre le résultat de la promotion (true par défaut)
- `wait_seconds` : permet de renvoyer le résultat après ce délai (par défaut : 60 secondes)

La fonction renvoie `true`, si la promotion s'est bien déroulée et `false` sinon.

**Exemple d'utilisation :**

```sql
-- Par défaut sans paramètres 
postgres=# SELECT pg_promote();
 pg_promote 
------------
 t
-- Attend au plus 10 secondes
postgres=# SELECT pg_promote(true,10);
-- Pas d'attente
postgres=# SELECT pg_promote(false);
```



L'accès à la fonction `pg_promote()` est limité aux super-utilisateurs. À noter qu'il est  possible de déléguer les droits à un autre utilisateur ou un autre rôle : 

```sql
postgres=# GRANT EXECUTE ON FUNCTION pg_promote TO mon_role;
GRANT
```

La fonction exécutée sur une instance non standby renvoie une erreur.

```sql
postgres=# select pg_promote(true,10);
psql: ERROR:  recovery is not in progress
HINT:  Recovery control functions can only be executed during recovery.
```

</div>

----

### Copie de slot de réplication

<div class="slide-content">

  * `pg_copy_physical_replication_slot('slot1','slot2')`
</div>


<div class="notes">


Rappel historique des slots de réplication : 

- Introduction du slot de réplication physique en version 9.4 pour éviter la suppression des WAL sur l'instance primaire alors qu'un réplicat est arrêté ou trop en retard sur sa réplication.
- Le slot de réplication logique a été introduit en version PostgreSQL 10.
- PostgreSQL 12 permet grâce à 2 fonctions de copier les slots de réplications. 

**<u>Cas d'usage de ces fonctions :</u>** 

Attacher 2 réplicats à la même instance principale en utilisant 2 slots de réplication physique différents. Les réplicats sont réalisés à partir du même backup, pour gagner du temps et de la place, et commencent par le même LSN.

L'utilitaire `pg_basebackup` est utilisé pour créer la sauvegarde et les slots de réplication en même temps.

Note : l'argument `--write-recovery-conf` en version PostgreSQL 12 créera un fichier `standby.signal` et modifiera le fichier `postgresql.auto.conf`. 

```shell
postgres@workshop12:~/12/data$ mkdir -p /opt/pgsql/backups
postgres@workshop12:~/12/data$ pg_basebackup --slot physical_slot1 \ 
--create-slot --write-recovery-conf -D /opt/pgsql/backups/

postgres@workshop12:~/12/data$ psql -x -c \
"SELECT * FROM pg_replication_slots"

-[ RECORD 1 ]-------+---------------
slot_name           | physical_slot1
plugin              | 
slot_type           | physical
datoid              | 
database            | 
temporary           | f
active              | f
active_pid          | 
xmin                | 
catalog_xmin        | 
restart_lsn         | 0/9000000
confirmed_flush_lsn | 
```



<u>**Copie du slot de réplication**</u>

```shell
postgres@workshop12:~/12/repl_1$ psql -c \
"SELECT pg_copy_physical_replication_slot('physical_slot1','physical_slot2')"

pg_copy_physical_replication_slot 
------------
 (physical_slot2,)
```



```shell
postgres@workshop12:~/12/repl_1$ psql -c \
"select slot_name,restart_lsn,slot_type,active from pg_replication_slots"

   slot_name    | restart_lsn | slot_type | active 
----------------+-------------+-----------+--------
 physical_slot1 | 0/9000000   | physical  | f
 physical_slot2 | 0/9000000   | physical  | f
(2 rows)
```

```shell
rsync -r -p /opt/pgsql/backups/ /opt/pgsql/12/repl_1

rsync -r -p /opt/pgsql/backups/ /opt/pgsql/12/repl_2
```

Modification du slot de réplication sur le réplicat 2 en éditant le fichier `postgresql.auto.conf` et en modifiant le nom du slot.

```ini
primary_slot_name = 'physical_slot2'
```

Changer les ports des réplicats en éditant les fichiers `postgresql.conf`.

```ini
port=5434 # pour le premier réplicat
port=5435 # pour le second réplicat
```

Démarrage des instances répliquées.

```shell
postgres@workshop12:~/12$ pg_ctl -D /opt/pgsql/12/repl_1 start 
```

Vérification des slots sur le primaire : on voit ici que le premier réplicat est actif avec le LSN A000148

```shell
postgres@workshop12:~/12$ psql -c \
"select slot_name,restart_lsn,slot_type,active from pg_replication_slots"

   slot_name    | restart_lsn | slot_type | active 
----------------+-------------+-----------+--------
 physical_slot1 | 0/A000148   | physical  | t
 physical_slot2 | 0/9000000   | physical  | f
```

Vérification de l'accès au réplicat 1.

```shell
workshop12:~/12$ psql -p5434 -c "select pg_is_in_recovery()"
pg_is_in_recovery 
------------
 t
```

Même chose pour le réplicat 2 .

Démarrage de l'instance 

```shell
postgres@workshop12:~/12$ pg_ctl -D /opt/pgsql/12/repl_2 start
```

Vérification sur le primaire : on voit ici que le réplicat 2 est maintenant actif avec le même LSN que le réplicat 1.

```shell
postgres@workshop12:~/12$ psql -c \
"select slot_name,restart_lsn,slot_type,active from pg_replication_slots"

   slot_name    | restart_lsn | slot_type | active 
----------------+-------------+-----------+--------
 physical_slot1 | 0/A000148   | physical  | t
 physical_slot2 | 0/A000148   | physical  | t
```

Vérification de l'accès au réplicat 2.

```shell
postgres@workshop12:~/12$ psql -p5435 -c \
"select pg_is_in_recovery()"

pg_is_in_recovery 
------------
 t
```

</div>

----
















