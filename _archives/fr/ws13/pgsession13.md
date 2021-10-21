---
subtitle : 'PGSession 13'
title : 'Nouveautés de PostgreSQL 13'
keywords:
- postgres
- postgresql
- features
- news
- 13
- workshop
linkcolor:


licence : PostgreSQL
author: Dalibo & Contributors
revision: 13
url : https://dalibo.com/formations

#
# PDF Options
#

#toc: true

## Limiter la profondeur de la table des matières
toc-depth: 3

## Mettre les lien http en pieds de page
links-as-notes: true

## Police plus petite dans un bloc de code

code-blocks-fontsize: small

## Filtre : pandoc-latex-env = cadres de couleurs
## OBSOLETE voir pandoc-latex-admonition
latex-environment:
  importantframe: [important]
  warningframe: [warning]
  tipframe: [tip]
  noteframe: [note]
  frshaded: [slide-content]

## Filtre : pandoc-latex-admonition
## order of definition is important
pandoc-latex-admonition:
  - color: LightPink
    classes: [important]
    linewidth: 4
  - color: Khaki
    classes: [warning]
    linewidth: 4
  - color: DarkSeaGreen
    classes: [tip]
    linewidth: 4
  - color: Ivory
    classes: [note]
    linewidth: 4
  - color: DodgerBlue
    classes: [slide-content]
    linewidth: 4

#
# Reveal Options
#

# Taille affichage
width: 1200
height: 768

## beige/blood/moon/simple/solarized/black/league/night/serif/sky/white
theme: white

## None - Fade - Slide - Convex - Concave - Zoom
transition: Convex

transition-speed: fast

# Barre de progression
progress: true

# Affiche N° de slide
slideNumber: true

# Le numero de slide apparait dans la barre d'adresse
history: true

# Defilement des slides avec la roulette
mouseWheel: true

# Annule la transformation uppercase de certains thèmes
title-transform : none

# Cache l'auteur sur la première slide
# Mettre en commentaire pour désactiver
hide_author_in_slide: true

# ![](medias/Ganesha_Bhubaneswar_Odisha.jpg)


---

\newpage

---
# Nouveautés de PostgreSQL 13

![](medias/ganesh_small.jpg){ width=66% }


<div class="slide-content">

</div>

<div class="notes">

Photographie de [Jainswatantra](https://commons.wikimedia.org/w/index.php?title=User:Jainswatantra&action=edit&redlink=1), licence [GNU FREE Documentation Licence](https://en.wikipedia.org/wiki/fr:Licence_de_documentation_libre_GNU),
obtenue sur [wikimedia.org](https://commons.wikimedia.org/wiki/File:Ganesha_Bhubaneswar_Odisha.jpg).


**Participez à ce workshop !**

Pour des précisions, compléments, liens, exemples, et autres corrections et
suggestions, soumettez vos _Pull Requests_ dans notre dépôt :

<https://github.com/dalibo/workshops/tree/master/fr>

Licence : [PostgreSQL](https://github.com/dalibo/workshops/blob/master/LICENSE.md)

</div>

----

\newpage
## La v13

<div class="slide-content">

  * Développement depuis le 1er juillet 2019
  * Sortie le 24 septembre 2020
  * version 13.1 sortie le 12 novembre 2020

</div>

<div class="notes">

</div>

----

\newpage

## Les nouveautés

<div class="slide-content">

  * Administration
  * Réplication physique et logique
  * Supervision
  * Performances
  * Régressions / changements
  * Ateliers

</div>

<div class="notes">

</div>

----

\newpage

## Administration

<div class="slide-content">

  * Maintenance :
    * parallélisation des `vacuum` et `reindex`
    * Autovacuum : déclenchement par _INSERT_
  * Création d'un fichiers manifeste par `pg_basebackup`
  * Déconnexion des utilisateurs à la suppression d'une base de données

</div>

<div class="notes">

</div>

----

\newpage

### VACUUM : nouveaux workers

!include include/vacuum_parallelise.md

----

\newpage

### vacuumdb --parallel

!include include/vacuumdb_parallel.md

----

### reindexdb --jobs

!include include/reindex_parallelise.md

----

\newpage

### Autovacuum : déclenchement par INSERT

!include include/autovacuum_inserts.md

----

\newpage

### Fichiers manifeste pour les sauvegardes

!include include/backup_manifests.md

----

\newpage

### Déconnexion des utilisateurs à la suppression d'une base de données

!include include/drop_database.md

----

\newpage

## Réplication physique

<div class="slide-content">

  * Modification à chaud des paramètres de réplication
  * Volume maximal de journaux conservé par les slots
  * Évolution dans la commande `pg_rewind` :
    * Restauration de WAL archivés via le paramètre `--restore-target-wal`
    * Génération de la configuration de la réplication
    * Récupération automatique d'une instance

</div>

<div class="notes">

</div>

----

\newpage

### pg_rewind sait restaurer des journaux

!include include/pg_rewind_restore_command.md

\newpage

----

\newpage

### pg_rewind récupère automatiquement une instance

!include include/pg_rewind_recovery.md

----

\newpage

### pg_rewind génère la configuration de réplication

!include include/pg_rewind_config.md

----

\newpage

## Réplication logique

!include include/logical_replication_partitionning.md

----

\newpage

## Supervision

<div class="slide-content">

  * Journaux applicatifs :
    * Tracer un échantillon des transactions suivant leur durée
    * Tracer le type de processus
  * Suivi de l'avancée des `ANALYZE`
  * Suivi de l'avancée des sauvegardes par `pg_basebackup`
  * Statistiques d'utilisation des WAL

</div>

<div class="notes">

</div>

----

\newpage

### Tracer un échantillon des requêtes suivant leur durée

!include include/statement_sampling_in_logs.md

----

\newpage

### Tracer le type de processus

!include include/backendtype.md

----

\newpage

### Suivi de l'exécution des `ANALYZE`

!include include/analyze_progression.md

----

\newpage

### Suivi de l'exécution des sauvegardes

!include include/pg_stat_progress_basebackup.md

----

\newpage

### Statistiques d'utilisation des WAL

!include include/wal_usage_statistics.md

----

\newpage

## Performances

<div class="slide-content">

  * Optimisation du stockage des B-Tree
  * Tri incrémental

</div>

<div class="notes">

</div>

----

\newpage

### Optimisation du stockage des B-Tree

!include include/btree_index_deduplication.md

----

\newpage

### Tri incrémental

!include include/incremental_sorting.md

----

\newpage

## Régressions / changements

<div class="slide-content">

  * `wal_keep_segments` devient `wal_keep_size`
  * Changement d'échelle du paramètre `effective_io_concurrency`

</div>

<div class="notes">

</div>

----

\newpage

## Futur (version 14)

<div class="slide-content">

  * Amélioration des performances avec plusieurs milliers de connexions
  * `scram-sha-256` pourrait devenir l'encodage de mot de passe par défaut

</div>

<div class="notes">

</div>

----

\newpage

## Ateliers

<div class="slide-content">

  * Installation de PostgreSQL 13
  * Monitoring : nouvelle colonne dans pg_stat_activity
  * Nouveauté dans les index `b-tree`
  * Nouveautés au niveau du backup
  * Nouveautés dans `pg_rewind`
  * Nouveauté dans la réplication logique

</div>

<div class="notes">

### Installation de PostgreSQL 13

Pour une installation simple, suivre la procédure du site officiel :
  <https://www.postgresql.org/download/linux/redhat/>

Les commandes d'installation sont à effectuer avec l'utilisateur _root_.

#### Installation d'outils et des dépendances

```bash
yum install -y vim nano less rsync
yum -y install https://dl.fedoraproject.org/pub/epel/\
epel-release-latest-7.noarch.rpm
yum install jq -y
```

#### Installation de PostgreSQL et de la première instance

```bash
# Install the repository RPM

yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/\
EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Install PostgreSQL:
yum install -y postgresql13-server

# Initialisation de la base de données et démarrage automatique
/usr/pgsql-13/bin/postgresql-13-setup initdb
systemctl enable postgresql-13
systemctl start postgresql-13
```


#### Initialisation de la seconde instance

* Copie du fichier de configuration systemd des instance PostgreSQL :

```bash
cp /usr/lib/systemd/system/postgresql-13.service \
   /usr/lib/systemd/system/postgresql-13-i2.service
```

* Edition du fichier de configuration systemd de l'instance

Modification de la variable : `Environment=PGDATA=`

```ini
Environment=PGDATA=/var/lib/pgsql/13/instance2/
```

Ceci permet de changer le _PG_DATA_ de l'instance

* Initialisation de l'instance

```bash
/usr/pgsql-13/bin/postgresql-13-setup initdb postgresql-13-i2
```

* Modification du port d'écoute de la nouvelle instance et initialisation :

```bash
sed -ie 's/^#port = 5432/port = 5433/' /var/lib/pgsql/13/instance2/postgresql.conf
systemctl enable postgresql-13-i2
systemctl start postgresql-13-i2
```

Dans le fichier de configuration nous remarquons que « `wal_keep_segments` »
devient « `wal_keep_size` ». Ce paramètre est exprimé en Mo.

```bash
grep wal_keep_ /var/lib/pgsql/13/data/postgresql.conf
```

Génération des données pour le TP (avec l'utilisateur _postgres_) :

```bash
createdb pgbench
/usr/pgsql-13/bin/pgbench -i -s 466 --partitions=4 pgbench
```

Le scale factor (l'option -s) permet de fixer le nombre d'enregistrements dans
la base de données. Un [article
intéressant](https://www.cybertec-postgresql.com/en/a-formula-to-calculate-pgbench-scaling-factor-for-target-db-size/)
permet de faire le lien entre cette valeur et la taille finale de la base de
données.


-------------------------------


### Monitoring : nouvelle colonne dans pg_stat_activity


Une nouvelle colonne fait son apparition dans le catalogue
**pg_stat_activity** elle permet de connaitre le PID du leader pour
l'interrogation parallèle.

**Note :** Les commandes sont à effectuer avec l'utilisateur _postgres_.

* Dans la console _psql_ exécutez :

```sql
SELECT
  COUNT(DISTINCT leader_pid) AS nb_requetes_parallelisees,
  COUNT(leader_pid) AS parallel_workers
FROM pg_stat_activity;
```

ou pour une version plus complète :

```sql
SELECT
  query, leader_pid, array_agg(pid) FILTER (WHERE leader_pid != pid) AS members
FROM pg_stat_activity
WHERE leader_pid IS NOT NULL
GROUP BY query, leader_pid;
```


* Puis utiliser la métacommande `\watch 1` afin de rafraichir l'affichage

```sql
postgres=# \watch 1

Mon Nov 16 13:20:30 2020 (every 1s)

 pid | query | leader_pid | members
-----+-------+------------+---------
(0 rows)

(...)
```


* Se connecter à la base de données pgbench à partir d'un deuxième terminal :

```bash
psql -d pgbench
```

* Exécuter dans la seconde console psql la séquence suivante :

```sql
BEGIN;

SELECT count(*) FROM pgbench_accounts;

-- vous devez apercevoir dans votre première console quelque chose similaire à
--
--                 query                  | leader_pid |    members
-- SELECT count(*) from pgbench_accounts; |      14401 | {16286,16287}
--(1 row)

-- Maintenant nous allons provoquer une erreur dans la transaction
-- afin de vérifier le nouveau comportement de psql

SELECT * FROM error;

ROLLBACK,
```

Lors de cette transaction nous observons que le prompt de _psql_ a changé :

```
pgbench=*#
pgbench=!#
```

* Sur la première console :

```
                 query                  | leader_pid |    members
----------------------------------------+------------+---------------
 select count(*) from pgbench_accounts; |      14401 | {14620,14621}
(1 row)
```

`leader_pid` correspond au PID de la session ayant démarré les workers dans
l'exécution de la requête.


### Nouveauté dans les index `b-tree`

Créer les index suivants dans la base de données pgbench :

```sql
CREATE INDEX index_dup ON pgbench_accounts_1 (abalance) WITH (deduplicate_items = OFF);
CREATE INDEX index_dedup ON pgbench_accounts_1 (abalance) WITH (deduplicate_items = ON);
```


* Comparez la taille des 2 index.

```sql
SELECT pg_size_pretty(pg_relation_size('<nom_index>'));
```

* Créer un nouvel index non dédupliqué sur la clé primaire de la partition
_pgbench_accounts_1_.  Comparer la taille à l'index
_pgbench_accounts_1_pkey_. Que constatez-vous ? Pourquoi ?


### Nouveautés au niveau du backup

Nous allons nous intéresser aux deux nouvelles fonctionnalités suivantes :

* Suivi de l'avancement pg_basebackup
* Fichier de manifest dans pg_basebackup


#### Prérequis pour la suite des exercices

**Ce prérequis est indispensable pour la suite de l'atelier :**

* Créer un slot de réplication. Il sera utilisé pour synchroniser une future
  instance secondaire dans la suite de l'atelier :

```bash
psql -p 5432 -c "SELECT pg_create_physical_replication_slot('secondaire')"
```

#### Suivi de l'avancement d'une sauvegarde par `pg_basebackup`

* Réaliser une sauvegarde physique avec l'outil `pg_basebackup` depuis
  l'utilisateur PostgreSQL :

```bash
/usr/pgsql-13/bin/pg_basebackup --format=t --gzip --pgdata=/tmp/bkp2
```


**Astuce :** Par default l'algorithme de checksum utilisé est CRC32C. Celui-ci
est le plus performant en termes de vitesse. Vous pouvez en définir d'autre qui
sont plus sûr grace au paramètre `--manifest-checksums=algorithm`. Les
algorithmes disponibles sont : `NONE`, `CRC32C`, `SHA224`, `SHA256`, `SHA384`,
ou `SHA512`.


* Depuis une seconde console, utiliser la console _psql_ pour observer la table
  système `pg_stat_progress_basebackup` :

Afin d'obtenir un pourcentage de progression vous nous pouvons utiliser la
requête suivante.

```sql
SELECT *, (backup_streamed / backup_total::float) * 100 AS pct
FROM pg_stat_progress_basebackup ;
\watch 2
```


La vue système `pg_stat_progress_basebackup` permet de connaitre la progression
du backup. Attention, étant donné que la base de données est en ligne, ces
données sont une estimation. Des modifications ou des insertions peuvent
survenir pendant la sauvegarde et augmenter la taille totale à sauvegarder.

#### Fichier de manifest dans pg_basebackup

* Une fois la sauvegarde terminée, lister les fichiers présents dans
  _/tmp/bkp2_.

On observe un fichier `backup_manifest`,

Pour plus de lisibilité, vous pouvez utiliser l'outil `jq` permettant d'afficher
et parser facilement un fichier de type JSON

```bash
jq -C . /tmp/bkp2/backup_manifest|less -R
```

* Visualiser le fichier. Qu'observe-t-on ?

On observe un document de type JSON contenant plusieurs clefs :

* la version du fichier manifeste ;
* une liste de fichiers contenant pour chacun d'eux son nom et son
  emplacement, sa taille, la date de modification, l'algorithme de somme de
  contrôle utilisé, ainsi que la somme de contrôle ;
* en fin de fichier, une clef `WAL-Ranges` qui permet de savoir la _timeline_
  courante et la portion de fichiers WAL indispensables à la sauvegarde
  (position LSN) ;
* et enfin la somme de contrôle du fichier lui-même.

* Vérifier la sauvegarde avec la commande « `pg_verifybackup` »

```bash
/usr/pgsql-13/bin/pg_verifybackup -e /tmp/bkp2/
```

Nous remarquons que l'outil ne permet pas de contrôler les sauvegardes de type
tar. Il faut donc extraire les fichiers pour pouvoir les contrôler.

Il y a 3 fichiers dans cette sauvegarde :
* `backup_manifest`
* `pg_wal.tar.gz`
* `base.tar.gz`

Il nous faut extraire la sauvegarde. Nous allons le faire dans le répertoire
`pg_data` de l'instance n° 2. Cela nous permettra de gagner du temps pour la
création de l'instance secondaire en réplication.

* Arrêter l'instance n°2 avec l'utilisateur _root_ :

```bash
systemctl stop postgresql-13-i2
```


* Contrôler que l'ensemble des fichiers de l'instance n°2 soit bien supprimé :

```bash
rm -rf /var/lib/pgsql/13/instance2/*
ls -alh /var/lib/pgsql/13/instance2/
```

* Décompresser la sauvegarde :

Le fichier `base.tar.gz` sera décompressé dans _/var/lib/pgsql/13/instance2/_
et `pg_wal.tar.gz` dans _/var/lib/pgsql/13/instance2/pg_wal/_ :

```bash
tar -xzvf /tmp/bkp2/base.tar.gz -C /var/lib/pgsql/13/instance2/
tar -xzvf /tmp/bkp2/pg_wal.tar.gz -C /var/lib/pgsql/13/instance2/pg_wal/
```

* Vérifier

Une fois la décompression effectuée, nous allons contrôler que l'ensemble des
fichiers soit bon grâce au manifest de la sauvegarde et grâce à la commande
`pg_verifybackup`.

```bash
/usr/pgsql-13/bin/pg_verifybackup -m /tmp/bkp2/backup_manifest \
     /var/lib/pgsql/13/instance2/
```

**Astuce :** vous pouvez préfixer cette commande avec la commande `time` pour
connaitre le temps d'exécution.

### Mise en réplication

Nous allons maintenant modifier la configuration de l'instance 2 pour la
rattacher en réplication à l'instance 1.

* Créer un fichier qui sera utilisé pour l'instance 2 contenant les
  informations de connexion pour accéder au primaire :

```bash
touch /var/lib/pgsql/.pgpassinstance2
chmod 600 /var/lib/pgsql/.pgpassinstance2
```

* Créer, sur l'instance n°1, l'utilisateur utilisé pour la réplication :

```bash
createuser --replication -P replication
```

Lors du prompt du mot de passe, nous utiliserons le mot de passe « **dalibo** ».

* Préciser le mot de passe pour une connexion sans mot de passe :

```bash
echo '#hostname:port:database:username:password' >> /var/lib/pgsql/.pgpassinstance2
echo '127.0.0.1:5432:replication:replication:dalibo' >> /var/lib/pgsql/.pgpassinstance2
```

* Mettre à jour le fichier _postgresql.conf_ :

Nous allons modifier les paramètres `port`, `primary_conninfo` et `primary_slot_name`
afin de paramétrer la réplication.

```bash
sed -ie 's/^#port = 5432/port = 5433/' /var/lib/pgsql/13/instance2/postgresql.conf

# on renseigne les informations permettant au secondaire d'atteindre le primaire
sed -ie "s%^#primary_conninfo = ''%primary_conninfo = 'user=replication\
 passfile=''/var/lib/pgsql/.pgpassinstance2'' host=127.0.0.1 port=5432\
 sslmode=prefer sslcompression=0'%" /var/lib/pgsql/13/instance2/postgresql.conf

# Nous utiliserons le slot de réplication `secondaire` créé précédemment.
sed -ie "s/^#primary_slot_name = ''/primary_slot_name = 'secondaire'/" \
 /var/lib/pgsql/13/instance2/postgresql.conf
```

* Créer le fichier `standby.signal` pour indiquer à PostgreSQL que
l'instance est un serveur secondaire :

```bash
touch /var/lib/pgsql/13/instance2/standby.signal
```

* Démarrer l'instance secondaire avec l'utilisateur _root_ :

```bash
systemctl start postgresql-13-i2
```

* Contrôler les traces de l'instance dans
`/var/lib/pgsql/13/instance2/log/postgresql-Tue.log` Contrôler rapidement que
la réplication soit bien fonctionnelle.  Nous pouvons utiliser la requête
suivante sur le primaire :

```sql
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn
  FROM pg_stat_replication;

SELECT slot_name, slot_type, active_pid, restart_lsn, wal_status
  FROM pg_replication_slots;
```

Nous avons à disposition une grappe PostgreSQL composée d'une instance primaire et
d'une instance secondaire.

### Nouveautés de `pg_rewind`

#### Mise en place des pré-requis

Afin de pouvoir utiliser `pg_rewind` certains prérequis doivent être mis en place :

* **archivage des WAL**

pg_rewind a besoin de l'archivage des WAL pour pouvoir fonctionner
correctement. Nous allons donc, dans un premier temps, configurer l'archivage
sur les 2 instances primaire et secondaire.

  * Créer les répertoires de destination des archives :

```bash
mkdir -p /var/lib/pgsql/archives/instance1
mkdir -p /var/lib/pgsql/archives/instance2
```

  * Modifier la configuration de l'instance primaire :

```bash
sed -ie 's/^#archive_mode = off/archive_mode = on/'\
 /var/lib/pgsql/13/data/postgresql.conf
sed -ie "s;^#archive_command = '';archive_command =\
 '/usr/bin/rsync -a %p /var/lib/pgsql/archives/instance1/%f';"\
 /var/lib/pgsql/13/data/postgresql.conf
```

  * Modifier la configuration de l'instance secondaire :

```bash
sed -ie 's/^#archive_mode = off/archive_mode = on/'\
 /var/lib/pgsql/13/instance2/postgresql.conf
sed -ie "s;^#archive_command = '';archive_command =\
 '/usr/bin/rsync -a %p /var/lib/pgsql/archives/instance2/%f';"\
 /var/lib/pgsql/13/instance2/postgresql.conf
sed -ie "s;^#restore_command = '';restore_command =\
 '/usr/bin/rsync -a /var/lib/pgsql/archives/instance1/%f %p';"\
 /var/lib/pgsql/13/instance2/postgresql.conf
```

  * Redémarrer les deux instances avec l'utilisateur _root_ :

```bash
systemctl restart postgresql-13
systemctl restart postgresql-13-i2
```

  * Contrôler que l'archivage est bien opérationnel :

```bash
psql -c 'select pg_switch_wal();'
ls /var/lib/pgsql/archives/
```

Si aucun wal n'est archivé, chercher dans les traces PostgreSQL une éventuelle erreur.

* **Activation des `wal_log_hints`**

`pg_rewind` a besoin de l'activation du paramètre `wal_log_hints`. Ce paramètre
fait que, après un checkpoint, le serveur PostgreSQL écrit le contenu entier de
chaque page disque dans les journaux de transactions lors de la première
modification de cette page. Il réalise cette écriture même pour des
modifications non critiques comme les _hint bits_ ou les sommes de contrôle.

  * Activer les `wal_log_hints` sur les deux instances :

```bash
sed -ie 's/^#wal_log_hints = off/wal_log_hints = on/'\
 /var/lib/pgsql/13/data/postgresql.conf
sed -ie 's/^#wal_log_hints = off/wal_log_hints = on/'\
 /var/lib/pgsql/13/instance2/postgresql.conf
```

  * Redémarrer les deux instances avec l'utilisateur _root_ :

```bash
systemctl restart postgresql-13
systemctl restart postgresql-13-i2
```

* Créer un fichier `.pgpass` :

```bash
cp -a /var/lib/pgsql/.pgpassinstance2 /var/lib/pgsql/.pgpass
echo '127.0.0.1:5433:*:replication:dalibo' >> /var/lib/pgsql/.pgpass
```

#### Notation

Pour la suite de l'atelier :

* l'instance n°1 est l'ancienne instance primaire sur `/var/lib/pgsql/13/data`
* l'instance n°2 est l'ancienne instance secondaire sur `/var/lib/pgsql/13/instance2`

#### Promotion de l'instance n°2

* Promouvoir l'instance secondaire :

```bash
/usr/pgsql-13/bin/pg_ctl promote -D /var/lib/pgsql/13/instance2/ -w
```

Le résultat de la commande doit être semblable à :

```
waiting for server to promote.... done
server promoted
```

* Contrôler que l'instance est bien promu :

```bash
psql -p 5433 -c 'SELECT pg_is_in_recovery()'
```

La sortie doit être **f** :

```
pg_is_in_recovery
-------------------
 f
(1 row)
```

À partir de cet instant, il n'est plus possible de raccrocher cette instance
secondaire fraichement promue.

#### Divergence des deux instances

Nous allons en plus ajouter des nouvelles données pour faire diverger encore
plus les deux instances.

* Sur l'instance n°1 :

```bash
psql -p 5432 << EOF
  CREATE TABLE test1 (a int);
  INSERT INTO test1(a) SELECT y FROM generate_series(1, 100) a(y);
EOF
```

* Sur l'instance n°2 :

```bash
psql -p 5433 << EOF
  CREATE TABLE test2 (a int);
  INSERT INTO test2(a) SELECT y FROM generate_series(101, 200) a(y);
EOF
```

Vous pouvez utiliser la fonction `generate_series` pour ajouter encore plus de données.

#### Raccrochage de l'instance n°1 avec `pg_rewind`

Nous allons stopper l'instance n°1 de manière brutale dans le but de la
raccrocher à l'instance n°2 en tant que secondaire.

* Arrêt de l'instance n°1 :

```bash
/usr/pgsql-13/bin/pg_ctl stop -D /var/lib/pgsql/13/data -m immediate -w
```

**Note :** la méthode d'arrêt recommandée est `-m fast`. L'objectif ici est de
mettre en évidence les nouvelles fonctionnalités de `pg_rewind`.

* Donner les autorisations nécessaires à l'utilisateur de réplication, afin
qu'il puisse utiliser `pg_rewind` :

```bash
psql -p 5433 <<_EOF_
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

* Sauvegarder la configuration de l'instance n°1 :

```bash
cp /var/lib/pgsql/13/data/postgresql.conf\
 /var/lib/pgsql/postgresql.conf.backup_instance1
```

Les fichiers de configuration présents dans PGDATA seront écrasés par l'outil.

* Utiliser `pg_rewind` :

Afin d'observer l'ancien fonctionnement par défaut de pg_rewind, utiliser le
paramètre `--no-ensure-shutdown`.

```bash
/usr/pgsql-13/bin/pg_rewind \
 --target-pgdata /var/lib/pgsql/13/data/ \
 --source-server "host=127.0.0.1 port=5433 user=replication dbname=postgres" \
 --write-recovery-conf --no-ensure-shutdown \
 --progress --dry-run
```

Un message d'erreur nous informe que l'instance n'a pas été arrêtée proprement :

```
pg_rewind: connecté au serveur
pg_rewind: fatal : le serveur cible doit être arrêté proprement
```

Relancer `pg_rewind`, sans le paramètre `--no-ensure-shutdown` ni `--dry-run`
(qui empêche de réellement rétablir l'instance), afin d'observer le nouveau
fonctionnement par défaut :


```bash
/usr/pgsql-13/bin/pg_rewind \
 --target-pgdata /var/lib/pgsql/13/data/ \
 --source-server "host=127.0.0.1 port=5433 user=replication dbname=postgres" \
 --write-recovery-conf \
 --progress
```

* Configurer l'instance n°1 restaurée :

Une fois l'opération réussie, restaurer le fichier de configuration d'origine
sur l'ancienne primaire et y ajouter la configuration de la réplication.

```bash
# récupération de la configuration initiale
cp /var/lib/pgsql/postgresql.conf.backup_instance1 \
 /var/lib/pgsql/13/data/postgresql.conf

# on renseigne les informations permettant au secondaire d'atteindre le primaire
sed -ie "s%^#primary_conninfo = ''%primary_conninfo = 'user=replication\
 passfile=''/var/lib/pgsql/.pgpassinstance1'' host=127.0.0.1 port=5433\
 sslmode=prefer sslcompression=0'%" /var/lib/pgsql/13/data/postgresql.conf

# Nous utiliserons le slot de réplication `secondaire`
sed -ie "s/^#primary_slot_name = ''/primary_slot_name = 'secondaire'/" \
 /var/lib/pgsql/13/data/postgresql.conf
```

* Créer le slot de réplication sur l'instance n°2 :

```bash
psql -p 5433 -c "SELECT pg_create_physical_replication_slot('secondaire')"
```

* Relancer l'instance n°1 avec l'utilisateur _root_ :

```bash
systemctl restart postgresql-13
```

* Contrôler dans les journaux applicatifs le déroulé des opérations.

* Révoquer les droits de l'utilisateur _replication_ :

Une fois l'opération terminée, n'oubliez pas de révoquer les droits ajoutés à
l'utilisateur _réplication_.

```bash
psql -p 5433 <<_EOF_
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

#### Possible erreur

L'utilisation de `pg_rewind` peut être compliquée à cause d'un problème
d'accès au WAL.

`pg_rewind` redémarre PostgreSQL en mode mono-utilisateur afin de réaliser
une récupération de l'instance. L'opération échoue, car PostgreSQL n'arrive pas
à trouver les fichiers WAL dans le répertoire _PGDATA/pg_wal_ de l'instance
principale.

`pg_rewind` a besoin des WAL archivés. Il faut contrôler la `restore_command`
de l'instance :

```bash
grep restore_command /var/lib/pgsql/13/data/postgresql.conf
```

Si la `restore_command` n'est pas correctement positionnée, modifiez-la puis
relancer la commande `pg_rewind` avec avec l'option `--restore-target-wal` :

```bash
/usr/pgsql-13/bin/pg_rewind \
 --target-pgdata /var/lib/pgsql/13/data/ \
 --source-server "host=127.0.0.1 port=5433 user=replication dbname=postgres" \
 --write-recovery-conf \
 --restore-target-wal
 --progress
```

</div>


----
