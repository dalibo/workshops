---
subtitle : 'Workshop pg_back'
title : 'Sauvegarde logique de bases de données avec pglift'
keywords:
- postgres
- postgresql
- workshop
- pglift
- ansible
- industrialisation


linkcolor:

licence : PostgreSQL
author: Dalibo & Contributors
revision: 23.08
url : http://dalibo.com/formations

#
# PDF Options
#

#toc: true

## Limiter la profondeur de la table des matières
toc-depth: 4

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
transition: None

transition-speed: fast

# Barre de progression
progress: true

# Affiche N° de slide
slideNumber: true

# Le numero de slide apparait dans la barre d'adresse
history: true

# Defilement des slides avec la roulette
mouseWheel: false

# Annule la transformation uppercase de certains themes
title-transform : none

# Cache l'auteur sur la première slide
# Mettre en commentaire pour désactiver
hide_author_in_slide: true


---

# Introduction

_pglift_ est capable de piloter un outil de sauvegarde logique pour exporter
des bases de données. La restauration est réalisée directement avec `pg_restore`.
Les outils `pg_back` et `pg_dump` seront abordés.

# Présentation de pg_back

`pg_back` est un outil qui peut exporter des bases de données. Il est capable
d'embarquer différents éléments dans sa sauvegarde :

* Bases de données
* Rôles
* Définition des tablespaces

# Installation

L'ensemble des actions de ce workshop sera exécuté sur le nœud `srv-pg1`.

## Pré-requis

### Nettoyage

La section `Nettoyage` du précédent workshop doit avoir été exécutée pour
laisser place à la nouvelle instance de ce workshop.

## Installation de pg_back

Sur `srv-pg1`, installer le paquet RPM `pg_back` en tant que `root` :

```shell
[root@srv-pg1 ~]# dnf install pg_back
```

## Configuration pg_back

Créer le fichier de configuration de `pg_back` :

* `~/.config/pglift/pg_back/pg_back.conf`

Contenant la configuration suivante :

```ini
!include include/pg_back/pg_back.conf.j2
```

## Configuration pglift

La configuration de _pglift_ est également complétée avec une clause `dump_commands`
qui indique à _pglift_ d'utiliser `pg_back` pour réaliser des dumps, et décrit
l'appel de la commande `/usr/bin/pg_back` qui sera utilisé.

```yaml
!include include/pg_back/settings.yaml.j2
```

## Instance pglift

Une nouvelle incarnation de l'instance `main` est à créer selon la nouvelle
configuration de _pglift_.

### Installation de la configuration de site

Installer la nouvelle configuration de site en tant que `postgres` :

```shell
[postgres@srv-pg1 pg_back]$ pglift site-configure install
INFO     installed pglift-postgres_exporter@.service systemd unit at
         /home/postgres/.local/share/systemd/user/pglift-postgres_exporter@.service
INFO     installed pglift-backup@.service systemd unit at
         /home/postgres/.local/share/systemd/user/pglift-backup@.service
INFO     installed pglift-backup@.timer systemd unit at
         /home/postgres/.local/share/systemd/user/pglift-backup@.timer
INFO     installed pglift-postgresql@.service systemd unit at
         /home/postgres/.local/share/systemd/user/pglift-postgresql@.service
INFO     installing base pgbackrest configuration
INFO     creating pgbackrest include directory
INFO     creating pgbackrest repository path
INFO     creating common pgbackrest directories
INFO     creating postgresql log directory
```

### Création d'un instance

Créer l'instance main :

```shell
[postgres@srv-pg1 pg_back]$ pglift instance create main --pgbackrest-stanza=main-app
INFO     initializing PostgreSQL
INFO     configuring PostgreSQL authentication
INFO     configuring PostgreSQL
INFO     starting PostgreSQL 15-main
INFO     creating role 'prometheus'
INFO     creating role 'backup'
INFO     altering role 'backup'
INFO     configuring Prometheus postgresql 15-main
INFO     configuring pgBackRest stanza 'main-app' for pg1-path=/pgdata/15/main/data
INFO     creating pgBackRest stanza main-app
INFO     starting Prometheus postgres_exporter 15-main
```

Charger son environnement dans la session en cours :

```shell
[postgres@srv-pg1 ~]$ export $(pglift instance env main)
```

### Création d'une base de données

Créer la base de données `ws1` :

```shell
[postgres@srv-pg1 pg_back]$ pglift database create ws1
INFO     creating 'ws1' database in 15/main
```

Générer 2 millions de lignes de données fictives.

```
psql -d ws1 <<-EOF
  CREATE TABLE ws1_data (id int primary key, lib text);
  INSERT INTO ws1_data
  SELECT generate_series(1,2000000) AS id, md5(random()::text) AS descr;
  CREATE INDEX ws1_data_idx ON ws1_data (lib);
EOF
```

# Sauvegarde et Restauration

## Sauvegarde Logique

Exécuter `pglift database dump` pour déclencher la sauvegarde logique de la base
de données `ws1` avec `pg_back`.

```shell
[postgres@srv-pg1 pg_back]$ pglift database dump ws1
INFO     backing up database 'ws1' on instance 15/main
```

## Afficher les sauvegardes

La sauvegarde prise à l'étape précédente est trouvable dans le répertoire des
dumps de _pglift_ `/pgdata/backup/dumps` :

```shell
[postgres@srv-pg1 15-main]$ ls -lh /pgdata/backup/dumps/15-main
total 43M
-rw-r--r--. 1 postgres postgres 327 Nov 28 12:38 hba_file_2023-11-28T12:38:39Z.out
-rw-r--r--. 1 postgres postgres 151 Nov 28 12:38 ident_file_2023-11-28T12:38:39Z.out
-rw-r--r--. 1 postgres postgres 699 Nov 28 12:38 pg_globals_2023-11-28T12:38:39Z.sql
-rw-r--r--. 1 postgres postgres 625 Nov 28 12:38 pg_settings_2023-11-28T12:38:39Z.out
-rw-r--r--. 1 postgres postgres 43M Nov 28 12:38 ws1_2023-11-28T12:38:39Z.dump
```

## Restauration d'une base de données

L'utilitaire `pg_back`, contrôlé par _pglift_, n'est utilisé que dans le contexte de
la de sauvegarde. La restauration des dumps est réalisée de manière classique,
avec `pg_restore`.

Supprimer la base de données  `ws1` :

```shell
[postgres@srv-pg1 15-main]$ pglift database drop ws1
INFO     dropping 'ws1' database
```

Exécuter le restore avec `pg_restore` :

```shell
[postgres@srv-pg1 15-main]$ pg_restore -d postgres --create --verbose \ 
/pgdata/backup/dumps/15-main/ws1_2023-11-28T12:38:39Z.dump
pg_restore: connecting to database for restore
pg_restore: creating DATABASE "ws1"
pg_restore: connecting to new database "ws1"
pg_restore: creating TABLE "public.ws1_data"
pg_restore: processing data for table "public.ws1_data"
pg_restore: creating CONSTRAINT "public.ws1_data ws1_data_pkey"
pg_restore: creating INDEX "public.ws1_data_idx"
```

## Restauration d'une instance

Une instance complète peut également être restaurée depuis les sauvegardes
logiques. Cependant, ce type de sauvegarde ne comportant pas la stucture physique de
l'instance, il convient de repartir d'une instance vierge.

Supprimer l'instance `main`, **sans supprimer les sauvegarde logiques** (répondre `n` à la seconde question) :

```shell
[postgres@srv-pg1 15-main]$ pglift instance drop main
INFO     dropping instance 15/main
> Confirm complete deletion of instance 15/main? [y/n] (y): y
INFO     stopping PostgreSQL 15-main
INFO     stopping Prometheus postgres_exporter 15-main
INFO     deconfiguring Prometheus postgres_exporter 15-main
INFO     deconfiguring pgBackRest
> Confirm deletion of database dump(s) for instance 15/main? [y/n] (y): n
INFO     deleting PostgreSQL cluster
```

Créer à nouveau l'instance `main` :

```shell
[postgres@srv-pg1 pg_back]$ pglift instance create main --pgbackrest-stanza=main-app
INFO     initializing PostgreSQL
INFO     configuring PostgreSQL authentication
INFO     configuring PostgreSQL
INFO     starting PostgreSQL 15-main
INFO     creating role 'prometheus'
INFO     creating role 'backup'
INFO     altering role 'backup'
INFO     configuring Prometheus postgresql 15-main
INFO     configuring pgBackRest stanza 'main-app' for pg1-path=/pgdata/15/main/data
INFO     creating pgBackRest stanza main-app
INFO     starting Prometheus postgres_exporter 15-main
```

Importer les objets globaux :

\scriptsize

```
[postgres@srv-pg1 15-main]$ psql -f /pgdata/backup/dumps/15-main/pg_globals_2023-11-28T12:38:39Z.sql
SET
SET
SET
psql:/pgdata/backup/dumps/15-main/pg_globals_2023-11-28T12:38:39Z.sql:14: ERROR:  role "backup" already exists
ALTER ROLE
psql:/pgdata/backup/dumps/15-main/pg_globals_2023-11-28T12:38:39Z.sql:16: ERROR:  role "postgres" already exists
ALTER ROLE
psql:/pgdata/backup/dumps/15-main/pg_globals_2023-11-28T12:38:39Z.sql:18: ERROR:  role "prometheus" already exists
ALTER ROLE
psql:/pgdata/backup/dumps/15-main/pg_globals_2023-11-28T12:38:39Z.sql:30: NOTICE:  role "prometheus" is already a member of role "pg_monitor"
GRANT ROLE
```

\normalsize

:::tip
Les erreurs sur les rôles déjà existants sont normales dans ce cas, car les rôles
pré-configurés par _pglift_ n'ont pas besoin d'être recréés au moment de la restauration.
:::

Restaurer les fichiers de configuration de PostgreSQL si nécessaire :

```
cp /pgdata/backup/dumps/15-main/pg_settings_2023-11-28T12:38:39Z.out \ 
${PGDATA}/postgresql.conf
cp /pgdata/backup/dumps/15-main/hba_file_2023-11-28T12:38:39Z.out \ 
${PGDATA}/pg_hba.conf
cp /pgdata/backup/dumps/15-main/ident_file_2023-11-28T12:38:39Z.out \ 
${PGDATA}/pg_ident.conf
```

Restaurer la base de données `ws1` avec `pg_restore` :

```shell
[postgres@srv-pg1 15-main]$ pg_restore -d postgres --create --verbose \ 
/pgdata/backup/dumps/15-main/ws1_2023-11-28T12:38:39Z.dump
pg_restore: connecting to database for restore
pg_restore: creating DATABASE "ws1"
pg_restore: connecting to new database "ws1"
pg_restore: creating TABLE "public.ws1_data"
pg_restore: processing data for table "public.ws1_data"
pg_restore: creating CONSTRAINT "public.ws1_data ws1_data_pkey"
pg_restore: creating INDEX "public.ws1_data_idx"
```

# Annexe : pg_dump

Si seul le répertoire des dumps est renseigné dans la configuration de _pglift_,
ce dernier utilise l'outil standard `pg_dump` pour réaliser les exports de bases
de données. Cependant, il n'est pas possible de conserver le même niveau de
fonctionnalité qu'avec `pg_back` puisque dans ce cas, seuls les dumps des bases
de données sont réalisés, sans considération pour les objets globaux et fichiers
de configuration.

## Configuration pglift

Retirer la clé `dump_commands` de la configuration de _pglift_ pour revenir à la
configuration par défaut :

```yaml
!include include/pg_back/settings_with_pgdump.yaml.j2
```

## Sauvegarde Logique

Sauvegarder la base de données `ws1` :

```bash
[postgres@srv-pg1 pglift]$ pglift database dump ws1
INFO     backing up database 'ws1' on instance 15/main
```

Vérifier la présence du dump dans le répertoire de sauvegarde :

```bash
[postgres@srv-pg1 ~]$ ls -l /pgdata/backup/dumps/15-main/
total 8
-rw-r--r--. 1 postgres postgres      327 Nov 28 12:38 hba_file_2023-11-28T12:38:39Z.out
-rw-r--r--. 1 postgres postgres      151 Nov 28 12:38 ident_file_2023-11-28T12:38:39Z.out
-rw-r--r--. 1 postgres postgres      699 Nov 28 12:38 pg_globals_2023-11-28T12:38:39Z.sql
-rw-r--r--. 1 postgres postgres      625 Nov 28 12:38 pg_settings_2023-11-28T12:38:39Z.out
-rw-r--r--. 1 postgres postgres 44264834 Nov 28 12:38 ws1_2023-11-28T12:38:39Z.dump
-rw-r--r--. 1 postgres postgres 44264834 Nov 29 10:58 ws1_2023-11-29T10:58:54+00:00.dump
```
:::tip
Le fichier `ws1_2023-11-29T10:58:54+00:00.dump` est le dump réalisé par `pg_dump`.
:::

## Restauration d'une base de données

Supprimer la base de données `ws1` :

```shell
[postgres@srv-pg1 ~]$ pglift database drop ws1
INFO     dropping 'ws1' database
```

Restaurer le dump exporté à l'étape précédente avec `pg_restore` :

```shell
[postgres@srv-pg1 15-main]$ pg_restore -d postgres --create --verbose \ 
/pgdata/backup/dumps/15-main/ws1_2023-11-29T10:58:54+00:00.dump
pg_restore: connecting to database for restore
pg_restore: creating DATABASE "ws1"
pg_restore: connecting to new database "ws1"
pg_restore: creating TABLE "public.ws1_data"
pg_restore: processing data for table "public.ws1_data"
pg_restore: creating CONSTRAINT "public.ws1_data ws1_data_pkey"
pg_restore: creating INDEX "public.ws1_data_idx"
```
