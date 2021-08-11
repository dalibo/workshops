---
subtitle : 'Workshop 13'
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

---

# Nouveautés de PostgreSQL 13

![](medias/The_Big_Boss_Elephant.jpeg)

<div class="notes">

Photographie de Rad Dougall, licence [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/deed.en),
obtenue sur [wikimedia.org](https://commons.wikimedia.org/wiki/File:The_Big_Boss_Elephant_(190898861).jpeg).


**Participez à ce workshop !**

Pour des précisions, compléments, liens, exemples,
et autres corrections et suggestions, soumettez vos _Pull Requests_ dans notre dépôt :

<https://github.com/dalibo/workshops/tree/master/fr>

Licence : [PostgreSQL](https://github.com/dalibo/workshops/blob/master/LICENSE.md)

Ce workshop sera maintenu encore plusieurs mois après la sortie de la version 13.

</div>

----

\newpage

## Les nouveautés

<div class="slide-content">
  * Administration :
    + maintenance
    + sauvegarde physique
    + divers
  * Réplication physique & logique
  * Supervision
  * Performances
  * Régressions
  * Ateliers
</div>

<div class="notes">

PostgreSQL 13 est sorti le 24 septembre 2020.

Les points principaux sont décrits dans le « [press kit](https://www.postgresql.org/about/press/presskit13/fr/) ».

Nous allons décrire ces nouveautés plus en détail.

<!-- Réf : 
https://git.postgresql.org/gitweb/?p=press.git;a=blob;f=releases/13/en/release.en.md
-->

</div>

----

\newpage

## Administration & maintenance

<div class="slide-content">

  * VACUUM & autovacuum
  * Réindexation parallélisée

</div>

<div class="notes">

</div>

----

### Autovacuum : déclenchement par INSERT

!include include/autovacuum_inserts.md

----

\newpage

### VACUUM : nouveaux workers

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

## Administration : amélioration de la sauvegarde physique

<div class="slide-content">

  * Fichiers manifeste
  * Suivi de la sauvegarde
  * Restauration & `recovery_target` non atteinte

</div>

<div class="notes">

</div>

----

<!--
### Fichiers manifeste
### Nouvel outil pg_verifybackup
-->

!include include/backup_manifests.md

----

\newpage

### Suivi de l'exécution des sauvegardes

!include include/pg_stat_progress_basebackup.md

----

\newpage

### Erreur fatale quand `recovery_target` ne peut être atteinte

!include include/recovery_target.md

----

\newpage

## Administration : divers

<div class="slide-content">

  * Partitionnement : déclencheurs BEFORE
  * Nouveaux paramètres :
    + `ignore_invalid_pages`
    + `maintenance_io_concurrency`
  * `DROP DATABASE` & déconnexion forcée
  * Extensions de confiance
  * Prompt de psql

</div>

<div class="notes">

</div>

----

### Déclencheurs BEFORE sur les partitions

!include include/declencheur_before_partition.md

----

### Nouveau paramètre maintenance_io_concurrency

!include include/maintenance_io_concurrency.md

----

\newpage

### Nouveau paramètre ignore_invalid_pages

!include include/ignore_invalid_pages.md

----

\newpage

### Déconnexion des utilisateurs à la suppression d'une base de données

!include include/drop_database.md

----

\newpage

### Extensions de confiance

!include include/extensions_trusted.md

----

\newpage

### Prompt de psql

!include include/prompt_psql.md

----

\newpage

## Réplication physique

<div class="slide-content">

  * Modification à chaud des paramètres de réplication
  * Slots : volume maximal de journaux (`max_slot_wal_keep_size`)
  * pg_rewind : nouvelles fonctionnalités

</div>

<div class="notes">

</div>

----

### Modification à chaud des paramètres de réplication

!include include/replication_changement_a_chaud.md

----

\newpage

### Volume maximal de journaux conservé par les slots


!include include/max_slot_wal_keep_size.md

----

\newpage

### pg_rewind sait restaurer des journaux

!include include/pg_rewind_restore_command.md

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

<div class="slide-content">

  * Publication de table partitionnée
  * Consommation mémoire des walsenders

</div>

<div class="notes">

</div>

----

### Publication d'une table partitionnée

!include include/logical_replication_partitionning.md

----

### Consommation mémoire du décodage logique

!include include/logical_decoding_work_mem.md

----

\newpage

## Supervision

<div class="slide-content">

  * Journaux & type de processus
  * Échantillonnage des requêtes
  * Requêtes préparées : paramètres
  * pg_stat_statements : temps de planification
  * pg_stat_statements : `leader_pid`
  * Vue `pg_stat_progress_analyze`
  * Vue `pg_shmem_allocations`
  
</div>

<div class="notes">

</div>

----

### Tracer le type de processus dans les journaux

!include include/backendtype.md

----

\newpage

### Échantillonner les requêtes

!include include/statement_sampling_in_logs.md

----

\newpage

### Paramètres des requêtes préparées

!include include/pps_parm_logging.md

----

\newpage

### pg_stat_statements : temps de planification

!include include/pg_stat_statements_planning_stats.md

----

\newpage

### pg_stat_activity : nouveau champ leader_pid

!include include/leader_pid.md

----

\newpage

### Nouvelle vue pg_stat_progress_analyze

!include include/analyze_progression.md

----

\newpage

### Nouvelle vue pg_shmem_allocations

!include include/pg_shmem_allocations.md

----

\newpage

## Performances

<div class="slide-content">

  * B-Tree : déduplication
  * Tri incrémental
  * Statistiques étendues
  <!-- * Utilisation des statistiques étendues pour OR et IN -->
  * Hash Aggregate : débord sur disque
  * Statistiques d'utilisation des WAL
  * EXPLAIN : Utilisation disque du planificateur

</div>

<div class="notes">

</div>

----

### Déduplication des index B-Tree

<!--
More efficiently store duplicates in btree indexes ~ https://gitlab.dalibo.info/formation/workshops/-/issues/59
-->

!include include/btree_index_deduplication.md

----

\newpage

### Tri incrémental

!include include/incremental_sorting.md

----

\newpage

### Paramétrage du détail pour les statistiques étendues

!include include/extended_stats_target.md

----

\newpage

### Hash Aggregate : débord sur disque

!include include/hash_aggregate.md

----

\newpage

### Statistiques d'utilisation des WAL 

!include include/wal_usage_statistics.md

----

\newpage

### EXPLAIN : Utilisation disque du planificateur

!include include/explain_planning_stats.md

----

\newpage

## Régressions

<div class="slide-content">

  * Réplication : `wal_keep_segments` devient `wal_keep_size`
  * `effective_io_concurrency` : changement d'échelle


</div>

<div class="notes">

</div>

----

### wal_keep_segments devient wal_keep_size

!include include/wal_keep_size.md

----

\newpage

### effective_io_concurrency : changement d'échelle

!include include/effective_io_concurrency.md

----

\newpage

# Ateliers


!include include/tp-declencheur_before_partition.md

----

\newpage

!include include/tp-backup_manifests.md

----

\newpage

!include include/tp-leader_pid.md

----

\newpage

!include include/tp-pg_stat_progress_basebackup.md

----

\newpage

!include include/tp-analyze_progression.md

----

\newpage

!include include/tp-hash_aggregate.md

---

\newpage

!include include/tp-wal_usage_statistics.md

----

\newpage

!include include/tp-logical_replication_partitionning.md

----

\newpage

!include include/tp-replication_changement_a_chaud.md

----

\newpage

!include include/tp-max_slot_wal_keep_size.md

----

\newpage

!include include/tp-pg_rewind.md

----

\newpage

!include include/tp-wal_keep_size.md

----

\newpage

!include include/tp-btree_index_deduplication.md

----
