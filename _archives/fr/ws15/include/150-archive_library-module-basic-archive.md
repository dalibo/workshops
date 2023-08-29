<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/E1nFhTB-0006Ib-DD@gemulon.postgresql.org

Discussion

* http://postgr.es/m/20220202224433.GA1036711@nathanxps13

-->

<div class="slide-content">

 * Option de remplacement pour l'`archive_command`
 * Nouveau paramètre `archive_library`
 * Module `basic_archive` :
   + `basic_archive.archive_directory`

</div>

<div class="notes">

Il est désormais possible d'utiliser des modules pour l'archivage plutôt que
l'`archive_command`. Cela simplifie la mise en place de l'archivage, permet de
rendre cette opération plus sécurisée et robuste, et aussi plus performante.
Ces modules peuvent accéder à des fonctionnalités avancées de PostgreSQL comme
la création des paramètres configuration ou de _background workers_.

On peut s'attendre à un gain de performance dû au fait que, plutôt de créer un
processus pour l'exécution de chaque `archive_command`, PostgreSQL va utiliser
le module qui a été chargé en mémoire une fois pour toutes.

On peut imaginer que des gains similaires pourront être fait pour
l'établissement d'une connexion à un serveur distant. Il pourrait également
être possible d'invoquer des _background workers_ en réaction à une
accumulation de WAL en attente d'archivage.

L'écriture d'un module d'archivage est décrite dans la documentation. Il faut
pour cela écrire un programme en C. En plus de nécessiter des compétences
particulières, les chances de planter le serveur sont grandes en cas de bug. Il
semble donc plus raisonnable de s'appuyer et de participer à des projets
communautaires. Les outils de sauvegardes comme pgBackRest ou Barman vont sans
doute également s'emparer du sujet.

Un nouveau paramètre `archive_library` a été ajouté à la configuration et
permet de charger le module. Comme pour l'`archive_command`, le serveur
n'effectuera la suppression ou le recyclage des WAL que lorsque le module
indique que les WAL ont été archivés. Ce nouveau paramètre peut être rechargé à
chaud.

```sh
=# \dconfig+ archive_library
                List of configuration parameters
    Parameter    | Value |  Type  | Context | Access privileges
-----------------+-------+--------+---------+-------------------
 archive_library |       | string | sighup  |
(1 row)
```

Si l'`archive_library` n'est pas remplie, PostgreSQL utilisera
l'`archive_command`. En version 15, si les deux paramètres sont remplis,
PostgreSQL favorisera l'`archive_library`. Ce comportement va changer en v16 ou
les deux paramètres ne pourront pas être définis en même temps.

<!--
https://www.postgresql.org/message-id/9ee5d180-2c32-a1ca-d3d7-63a723f68d9a%40enterprisedb.com
-->

Le [module d'exemple](https://www.postgresql.org/docs/15/basic-archive.html)
`basic_archive` a également été mis à disposition pour tester la fonctionnalité
et donner un exemple d'implémentation pour ce genre de module. Pour l'utiliser,
il suffit d'activer l'archivage, d'ajouter le module à l'archive_library et de
configurer le répertoire cible pour l'archivage. Il faut ensuite redémarrer
l'instance.

Afin d'observer le fonctionnement de ce module, nous allons créer une instance
neuve :

```bash
ARCHIVE=$HOME/archives
PGDATA=$HOME/data
PGPORT=5656
PGUSER=$USER

mkdir -p $ARCHIVE $PGDATA

initdb --data-checksum $PGDATA

cat << __EOF__ >> $PGDATA/postgresql.conf
port = $PGPORT
listen_addresses = '*'
cluster_name = 'test_archiver'
archive_mode = on
archive_library = 'basic_archive'
basic_archive.archive_directory = '$ARCHIVE'
__EOF__

pg_ctl start -D $PGDATA
```

Si on force un archivage, on voit que PostgreSQL a bien archivé dans la vue
`pg_stat_archiver` :

```bash
psql -c "SELECT pg_create_restore_point('Forcer une ecriture dans les WAL.')"
psql -c "SELECT pg_switch_wal()"
psql -xc "SELECT * FROM pg_stat_archiver";
```
```sh
-[ RECORD 1 ]------+------------------------------
archived_count     | 1
last_archived_wal  | 000000010000000000000001
last_archived_time | 2022-07-06 17:39:33.632029+02
failed_count       | 0
last_failed_wal    | ¤
last_failed_time   | ¤
stats_reset        | 2022-07-06 17:39:23.287479+02
```

On peut vérifier la présence du fichier dans le répertoire :

```sql
SELECT file.name, stats.*
  FROM current_setting('basic_archive.archive_directory') AS archive(directory)
     , LATERAL pg_ls_dir(archive.directory) AS file(name)
     , LATERAL pg_stat_file(archive.directory || '/' || file.name) AS stats
```
```sh
-[ RECORD 1 ]+-------------------------
name         | 000000010000000000000001
size         | 16777216
access       | 2022-07-06 17:39:33+02
modification | 2022-07-06 17:39:33+02
change       | 2022-07-06 17:39:33+02
creation     | ¤
isdir        | f
```

Le module `basic_archive` copie le WAL à archiver vers un fichier temporaire,
le synchronise sur disque, puis le renomme. Si le fichier archivé existe déjà
dans le répertoire cible et est identique, l'archivage est considéré comme un
succès. Si le serveur plante, il est possible que des fichiers temporaires qui
commencent par `archtemp` soient présents. Il est conseillé de les supprimer
avant de démarrer PostgreSQL. Il est possible de les supprimer à chaud mais il
faut s'assurer qu'il ne s'agisse pas d'un fichier en cours d'utilisation.

En cas d'échec de l'archivage, il est possible que l'erreur ne soit pas visible
dans le titre du processus ou la vue `pg_stat_archiver`. C'est par exemple le
cas si une erreur de configuration empêche le chargement du module. Les traces
de PostgreSQL contiennent alors les informations nécessaires pour résoudre le
problème.

Au moment de l'écriture de cet article, les paramètres des modules d'archivage
ne sont pas visibles depuis `pg_settings` ou depuis la nouvelle méta-commande
`\dconfig+` qui utilise cette vue.

Ce comportement s'explique par cette ligne de la [documentation de la vue
`pg_settings`](https://www.postgresql.org/docs/current/view-pg-settings.html) :

> This view does not display customized options until the extension module that
> defines them has been loaded.

C'est le processus d'archivage qui charge le module d'archivage, les paramètres
qui y sont définis ne sont donc pas visibles des autres processus.

Plusieurs alternatives sont possibles pour consulter leurs valeurs :

* charger la librairie dans la session :

  ```sql
  LOAD 'basic_archive';
  SELECT name, setting FROM pg_settings WHERE name = 'basic_archive.archive_directory';
  ```
  ```sh
                name               |                      setting
  ---------------------------------+---------------------------------------------------
   basic_archive.archive_directory | /home/benoit/var/lib/postgres/archives/pgsql-15b3
  (1 row)
  ```

* consulter les valeurs des paramètres directement avec la commande `SHOW` de
  psql :

  ```sql
  SHOW basic_archive.archive_directory;
  ```
  ```sh
   basic_archive.archive_directory 
  ---------------------------------
   /home/benoit/archives
  ```

* voir les paramètres renseignés dans le fichier de configuration dans la vue
  `pg_file_settings` :

  ```sql
  SELECT *
    FROM pg_file_settings
   WHERE name = 'basic_archive.archive_directory' \gx
  ```
  ```sh
  -[ RECORD 1 ]-----------------------------------------
  sourcefile | /home/benoit/data/postgresql.conf
  sourceline | 820
  seqno      | 27
  name       | basic_archive.archive_directory
  setting    | /home/benoit/archives
  applied    | t
  error      | ¤
  ```

</div>
