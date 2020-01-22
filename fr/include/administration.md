## Administration

<div class="slide-content">

  * Nouveautés sur le `VACUUM`
  * Recyclage des _WAL_
  * Environnement client : `PG_COLORS`, `EXPLAIN SETTINGS`
  * Outils : `pg_upgrade`, `pg_ctl`, `pg_checksums`
  * Paramètres de `postgresql.conf`

</div>

<div class="notes">

</div>

----

### Nouveautés du VACUUM

<div class="slide-content">

  * `VACUUM TRUNCATE`
  * `SKIP_LOCKED`
  * `INDEX_CLEANUP`
  * Nouvelles options de `vacuumdb`

</div>

<div class="notes"></div>
----

### VACUUM TRUNCATE

<div class="slide-content">

  * Indique si l'espace en fin de table doit être libéré
  * Évite un verrou exclusif en fin de traitement
  * Nouvel attribut de table : `VACUUM_TRUNCATE`
  * Nouvelle option de la commande : `VACUUM (TRUNCATE on)`
  * Non disponible pour `vacuumdb`

</div>

<div class="notes">
Cette nouvelle fonctionnalité de `VACUUM` permet de contrôler si l'opération doit tronquer
l'espace vide en fin de la table. C'est le fonctionnement historique de `VACUUM` et il
est par conséquent conservé par défaut.

Tronquer une table en fin de commande est extrêmement rapide, mais nécessite
que la commande VACUUM acquiert un verrou exclusif sur la table le temps
d'effectuer l'opération. Cette prise de verrou est parfois impossible à
cause de l'activité sur la table ou peut être jugée trop gênante lors
d'une maintenance ponctuelle effectuée par l'administrateur.

Ce comportement peut être modifié indépendamment pour chaque table grâce à l'attribut
`VACUUM_TRUNCATE`. Par exemple:

```sql
ALTER TABLE matable SET (VACUUM_TRUNCATE=OFF);
```

L'option `TRUNCATE` a également été ajoutée à la commande SQL `VACUUM`. L'exemple suivant
permet de ne pas tronquer la table à la fin du `vacuum`.

```sql
pg12=# VACUUM (TRUNCATE OFF) t1;
VACUUM
```

Il n'existe pour le moment pas d'argument équivalent pour la commande `vacuumdb`.
</div>

----

### SKIP_LOCK

<div class="slide-content">

  * Plus d'attente de verrou
  * Concerne `VACUUM` et `ANALYZE`

</div>

<div class="notes">

Jusqu'en version 11, en cas de conflit de verrous sur une table, les commandes `VACUUM`
ou `ANALYZE` attendaient que le verrou conflictuel soit levé pour débuter leur traitement.

Depuis la version 12 l'option `SKIP_LOCKED` permet d'ignorer les tables sur
lesquelles un des verrous présents empêche l'exécution immédiate de la
commande. Si une table est ignorée pour cette raison, un message d'avertissement
( `WARNING` ) est émis.

**Exemple :**

```sql
pg12=# VACUUM (SKIP_LOCKED ON) t1;
psql: WARNING:  skipping vacuum of "t1" --- lock not available
VACUUM
```
</div>

----

### VACUUM INDEX CLEANUP

<div class="slide-content">

  * Nouvel attribut permettant de ne pas nettoyer les index
</div>

<div class="notes">


Sur la commande `VACUUM`, l'option `INDEX_CLEANUP OFF` permet de désactiver
le parcours des index lors du vacuum. Dans le cas où l'option n'est pas spécifiée, le
processus prendra en compte le paramètre `VACUUM_INDEX_CLEANUP` de la table.
Par défaut `VACUUM_INDEX_CLEANUP` est à `on`.

Cette option est surtout utile pour effectuer des opérations ponctuelles où
la commande VACUUM doit être la plus rapide et légère possible. Par exemple,
pour mettre à jour la visibility map ou effectuer un freeze de la table. Il
est déconseillé de désactiver cette option durablement sur des tables, au
risque de voir les performances de leurs index décroître fortement avec le
temps.

Voici un exemple d'utilisation:

```sql
bench=# VACUUM (VERBOSE ON, INDEX_CLEANUP OFF) pgbench_accounts ;
INFO:  vacuuming "public.pgbench_accounts"
INFO:  "pgbench_accounts": found 0 removable, 497543 nonremovable row versions 
in 8169 out of 16406 pages
DETAIL:  0 dead row versions cannot be removed yet, oldest xmin: 1253
There were 0 unused item identifiers.
Skipped 0 pages due to buffer pins, 0 frozen pages.
0 pages are entirely empty.
CPU: user: 0.11 s, system: 0.01 s, elapsed: 0.13 s.
VACUUM
Time: 146,705 ms


bench=# VACUUM (VERBOSE ON, INDEX_CLEANUP ON) pgbench_accounts ;
INFO:  vacuuming "public.pgbench_accounts"
INFO:  scanned index "pgbench_accounts_pkey" to remove 735 row versions
DETAIL:  CPU: user: 0.09 s, system: 0.00 s, elapsed: 0.09 s
INFO:  "pgbench_accounts": removed 735 row versions in 735 pages
DETAIL:  CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
INFO:  index "pgbench_accounts_pkey" now contains 1000000 row versions in 2745 pages
DETAIL:  735 index row versions were removed.
0 index pages have been deleted, 0 are currently reusable.
CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s.
INFO:  "pgbench_accounts": found 0 removable, 497543 nonremovable row versions 
in 8169 out of 16406 pages
DETAIL:  0 dead row versions cannot be removed yet, oldest xmin: 1256
There were 0 unused item identifiers.
Skipped 0 pages due to buffer pins, 0 frozen pages.
0 pages are entirely empty.
CPU: user: 0.22 s, system: 0.01 s, elapsed: 0.23 s.
VACUUM
```

Le paramètre `VACUUM_INDEX_CLEANUP` peut être configuré à `OFF` sur une
table pour désactiver les parcours d'index lors des vacuum.

```sql
pg12=# ALTER TABLE t1 SET (VACUUM_INDEX_CLEANUP=OFF);
ALTER TABLE
pg12=# \d+ t1
                                    Table "public.t1"
 Column |  Type   | Collation | Nullable | Default | Storage | Stats target | Description
--------+---------+-----------+----------+---------+---------+--------------+-------------
 id     | integer |           |          |         | plain   |              |
Access method: heap
Options: vacuum_index_cleanup=off
```

Il n'est pas possible de désactiver ce parcours du vacuum index par index.
</div>

----

### Nouvelles Options de vacuumdb

<div class="slide-content">

  * `--min-xid-age`
  * `--min-mxid-age`
  * `--disable-page-skipping`
  * `--skip-locked`

</div>

<div class="notes">


PostgreSQL 12 offre 4 nouveaux arguments pour la commande `vacuumdb`:

- `--min-xid-age=XID_AGE`

  Permet à l'administrateur de traiter en priorité les
  tables dont l'age s'approche de la valeur de `autovacuum_freeze_max_age`.
  Cette action évite que l'opération ne soit traitée avec un `vacuum to
  prevent wraparound` à l'initiative de l'autovacuum.

- `--min-mxid-age=MXID_AGE`

  Permet à l'administrateur de traiter en priorité les
  tables dont l'age de la plus ancienne multixact s'approche de la valeur de
  `autovacuum_multixact_freeze_max_age`. Cette action évite que l'opération
  ne soit traitée avec un `vacuum to prevent wraparound` à l'initiative de
  l'autovacuum.

- `--disable-page-skipping`

  Permet de lancer un `VACUUM (DISABLE_PAGE_SKIPPING ON)` à partir de la ligne
  de commande (versions 9.6 et supérieures de PostgreSQL). Dans ce mode, on
  effectuera un nettoyage de tous les tuples, y compris s'ils sont freezés,
  visibles par toutes les transactions ou verrouillés. Ce mode est à utiliser
  en cas de suspicion de corruption des données.

- `--skip-locked`

  Ignore les tables verrouillées (version PostgreSQL 12 et supérieur).
</div>

----

### Journaux de transaction

<div class="slide-content">

Nouvelles options pour les journaux de transactions:

  * `wal_recycle`
  * `wal_init_zero`

</div>

<div class="notes">

- `wal_recycle` (défaut = `on`)

  Les fichiers _WAL_ sont recyclés en renommant les anciens WAL évitant
  ainsi la création de nouveaux fichiers, opération souvent plus lente.
  Configurer le paramètre `wal_recycle` à `off` permet d'obliger PostgreSQL à créer de
  nouveaux fichiers lors du recyclage des WAL et à supprimer les anciens. Ce
  mode est plus performant sur certains systèmes de fichiers de type
  Copy-On-Write (eg. ZFS ou BTRFS).

- `wal_init_zero` (défaut = `on`)

  Les nouveaux fichiers WAL sont remplis de zéros à la création. Cela
  garantit que l'espace est alloué pour le fichier WAL avant d'écrire dedans.
  Si `wal_init_zero` est à `off`, seul l'octet final est écrit afin de
  s'assurer que le fichier a bien la taille requise.

</div>

----

### Environnement Client

<div class="slide-content">

  * Variables d'environnement `PG_COLOR` et `PG_COLORS`
  * Formatage _CSV_ en sortie de `psql`
  * `EXPLAIN (SETTINGS)`

</div>

<div class="notes">


### Variables d'environnement PG_COLOR et PG_COLORS

Les nouvelles variables d'environnement (client) `PG_COLOR` et `PG_COLORS`
permettent d'ajouter et de personnaliser une coloration des erreurs, warning et 
mots clés à la sortie de la commande `psql`.

- PG_COLOR permet de configurer la coloration des messages.

Les valeurs possibles pour `PG_COLOR` sont `always`, `auto`, `never`.

Exemple : 

```shell
$ export PG_COLOR=always
```

- PG_COLORS permet de  personnaliser la couleur des messages en fonction de leur catégorie.

Les valeurs par défaut des couleurs sont : 

| Catégorie | Valeur par défaut |
| --------- | ----------------- |
| error     | 01;31 (rouge)     |
| warning   | 01;35 (mauve)     |
| locus     | 01 (gras)         |

Pour modifier les couleurs, la syntaxe est la suivante : 

```shell
$ export PG_COLORS='error=01;33:warning=01;31:locus=03'
```

Cet exemple permet de colorer les `error` en vert et les `warning` en bleu, et les mots clés en italique.



### Format CSV

PostgreSQL 12 permet de formater la sortie de la commande psql au format CSV.

Il existe 2 façons de changer le format de sortie :

1 - Ajouter l'argument `--csv` à la ligne de commande `psql`

**Exemple :**

```bash
$ psql --csv -c "select name,setting,source,boot_val from pg_settings limit 1"
name,setting,source,boot_val
allow_system_table_mods,off,default,off
```

2 - Exécuter `\pset format csv` dans l'interpréteur `psql`.

**Exemple :**

```sql
pg12=# select name,setting,source,boot_val from pg_settings limit 1;
          name           | setting | source  | boot_val
-------------------------+---------+---------+----------
 allow_system_table_mods | off     | default | off
(1 row)

pg12=# \pset format csv
Output format is csv.

pg12=# select name,setting,source,boot_val from pg_settings limit 1;
name,setting,source,boot_val
allow_system_table_mods,off,default,off
```

### Option SETTINGS pour EXPLAIN

L'option `SETTINGS ON` spécifiée lors de l'instruction `EXPLAIN` permet de
générer des informations sur les paramètres modifiés au cours de la session
ou de la transaction et qui influencent l'exécution de la requête étudiée.

```sql
pg12=# SET enable_sort = off;
SET
pg12=# EXPLAIN (SETTINGS ON) SELECT * FROM t1 WHERE id = 50;
                    QUERY PLAN
--------------------------------------------------
 Seq Scan on t1  (cost=0.00..2.25 rows=1 width=4)
   Filter: (id = 50)
 Settings: enable_sort = 'off'
```

</div>

----


### Outils

<div class="slide-content">

  * `pg_upgrade --clone` et `pg_upgrade --socketdir`
  * Rotation des logs avec `pg_ctl logrotate`
  * `pg_checksums`, anciennement `pg_verify_checksums`

</div>

<div class="notes">


### Nouveautés de pg_upgrade

Deux nouvelles options ont été ajoutées à la commande `pg_upgrade`.

- `--clone`

  Ce paramètre permet à la commande `pg_upgrade` d'effectuer un clonage à
  l'aide des liens _reflink_. L'utilisation de ce paramètre dépend du
  système d'exploitation et du système de fichiers.

- `--socketdir` ou `-s`

  Ce paramètre permet de spécifier un répertoire pour la création d'une socket locale.

### Rotation des traces avec pg_ctl

Jusqu'en version 11, la rotation des traces se faisait en envoyant un signal
`SIGUP` au processus `logger` ou grâce à la fonction SQL `pg_rotate_logfile()`.

Depuis PostgreSQL 12, le mode `logrotate` a été ajouté à la commande `pg_ctl`.

**Exemple :**

```bash
postgres@workshop12:~/12/data$ pg_ctl -D /opt/pgsql/12/data logrotate
server signaled to rotate log file
```

</div>

----

### Outil pg_checksums

<div class="slide-content">

  * `pg_verify_checksum` renommée en `pg_checksums`
  * Activation, désactivation des _checksums_

</div>

<div class="notes">

La commande `pg_verify_checksums` (ajoutée en version 11) est renommée en
`pg_checksums`. Cette commande permet de vérifier l'intégrité de la
totalité des fichiers de l'instance PostgreSQL.

À partir de la version 12, cette commande possède également les arguments
`--enable` et `--disable` permettant d'activer ou de désactiver les sommes de contrôle
dans l'instance. Jusqu'en version 11, il était impossible de changer ce
paramètre sans récréer une nouvelle instance.

**Attention, l'instance doit être arrêtée pour toutes actions de la commande `pg_checksums`.**

**Exemple :**

```bash
postgres@workshop12:~/12/data$ pg_checksums
pg_checksums: error: cluster must be shut down

postgres@workshop12:~/12/data$ pg_ctl -D /opt/pgsql/12/data/ stop
waiting for server to shut down.... done
server stopped

postgres@workshop12:~/12/data$ pg_checksums
Checksum operation completed
Files scanned:  1563
Blocks scanned: 4759
Bad checksums:  0
Data checksum version: 1

postgres@workshop12:~/12/data$ pg_checksums --disable
pg_checksums: syncing data directory
pg_checksums: updating control file
Checksums disabled in cluster

postgres@workshop12:~/12/data$ pg_checksums
pg_checksums: error: data checksums are not enabled in cluster

postgres@workshop12:~/12/data$ pg_checksums --enable
Checksum operation completed
Files scanned:  1563
Blocks scanned: 4759
pg_checksums: syncing data directory
pg_checksums: updating control file
Checksums enabled in cluster
```

</div>

----

### Paramètres de configuration

<div class="slide-content">

  * Nouveaux paramètres
  * Disparition du fichier `recovery.conf`
  * Paramètres modifiés
  * Paramètres dont la valeur par défaut a été modifiée

</div>

<div class="notes">

**Nouveaux paramètres**

> Les paramètres par défaut sont entre parenthèses.

|             Paramètre              |                      Commentaire                      |  Contexte  |
| ---------------------------------- | ----------------------------------------------------- | ---------- |
| archive_cleanup_command            | Anciennement dans le fichier recovery.conf            | sighup     |
| default_table_access_method (heap) | Spécifie la méthode d'accès aux tables par            |            |
|                                    | défaut à utiliser lors de la création de tables.      |            |
| log_transaction_sample_rate (0)    |                                                       | superuser  |
| plan_cache_mode (auto)             | Change le comportement du cache des plans d'exécution | user       |
|                                    | (auto`, `force_custom_plan, force_generic_plan)       |            |
| primary_conninfo                   | Anciennement dans le fichier recovery.conf            | postmaster |
| primary_slot_name                  | Anciennement dans le fichier recovery.conf            | postmaster |
| promote_trigger_file               | Anciennement dans le fichier recovery.conf            | sighup     |
| recovery_end_command               | Anciennement dans le fichier recovery.conf            | sighup     |
| recovery_min_apply_delay (0)       | Anciennement dans le fichier recovery.conf            | sighup     |
| recovery_target                    | Anciennement dans le fichier recovery.conf            | postmaster |
| recovery_target_action (pause)     | Anciennement dans le fichier recovery.conf            | postmaster |
| recovery_target_inclusive (on)     | Anciennement dans le fichier recovery.conf            | postmaster |
| recovery_target_lsn                | Anciennement dans le fichier recovery.conf            | postmaster |
| recovery_target_name               | Anciennement dans le fichier recovery.conf            | postmaster |
| recovery_target_time               | Anciennement dans le fichier recovery.conf            | postmaster |
| recovery_target_timeline (lastest) | Anciennement dans le fichier recovery.conf            | postmaster |
| recovery_target_xid                | Anciennement dans le fichier recovery.conf            | postmaster |
| restore_comand                     | Anciennement dans le fichier recovery.conf            | postmaster |
| shared_memory_type                 | Type de mémoire partagée, les valeurs possibles       | postmaster |
|                                    | dépendent du système d'exploitation                   |            |
| ssl_library                        | Nom de la librairie fournissant les fonctions SSL     | internal   |
| ssl_max_protocol_version           | Version max du protocole SSL supporté                 | sighup     |
| ssl_min_protocol_version (TLSv1)   | Version min du protocole SSL supporté                 | sighup     |
| tcp_user_timeout (0)               |                                                       | user       |
| wal_init_zero (on)                 | Remplit les nouveaux fichiers WAL de zéros             | superuser  |
| wal_recycle (on)                   | Recycle les WAL                                       | superuser  |


**Paramètres modifiés**


|          Paramètre           |                      Changements                        |
| ---------------------------- | ------------------------------------------------------- |
| autovacuum_vacuum_cost_delay | Le type change de _integer_ à _real_                    |
| default_with_oids            | Existe toujours mais ne peut pas être à « _on_ »        |
|                              | (suppression des OID)                                   |
| dynamic_shared_memory_type   | Option « none » supprimée                               |
| log_autovacuum_min_duration  | Contenu du journal applicatif change en                 |
|                              | fonction de l'exécution du vacuum                       |
| log_connections              | L'« application_name » est ajoutée dans les lignes du   |
|                              | journal applicatif                                      |
| recovery_target_timeline     | L'option « current » a été ajoutée et la nouvelle       |
|                              | valeur par défaut est « latest »                        |
| vacuum_cost_delay            | Le type change de integer à real                        |
| wal_level                    | Le démarrage de l'instance vérifie si le paramètre      |
|                              | wal_level est bien renseigné                            |
| wal_sender_timeout           | Contexte de modification passe de « sighup » à « user » |


**Paramètres ayant une nouvelle valeur par défaut.**


| Paramètre                    | PostgreSQL 11 | PostgreSQL 12  |
| ---------------------------- | ------------- | -------------- |
| autovacuum_vacuum_cost_delay | 20            | 2              |
| extra_float_digits           | 0             | 1              |
| jit                          | OFF           | ON             |
| recovery_target_timeline     |               | latest         |
| transaction_isolation        | default       | read committed |


</div>

----

