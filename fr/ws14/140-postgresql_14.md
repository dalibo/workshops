---
subtitle : 'Workshop 14'
title : 'Nouveautés de PostgreSQL 14'
keywords:
- postgres
- postgresql
- features
- news
- 14
- workshop
linkcolor:

licence : PostgreSQL
author: Dalibo & Contributors
revision: 14
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

# Nouveautés de PostgreSQL 14

![](medias/ws14_Lakshmana_Temple_10.jpg)

<div class="notes">

Photographie d'Antoine Taveneaux, licence [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/deed.en),
obtenue sur [wikimedia.org](https://commons.wikimedia.org/wiki/File:Lakshmana_Temple_10.jpg).


**Participez à ce workshop !**

Pour des précisions, compléments, liens, exemples,
et autres corrections et suggestions, soumettez vos _Pull Requests_ dans notre dépôt :

<https://github.com/dalibo/workshops/tree/master/fr>

Licence : [PostgreSQL](https://github.com/dalibo/workshops/blob/master/LICENSE.md)

Ce workshop sera maintenu encore plusieurs mois après la sortie de la version 14.

</div>

----

\newpage

## Les nouveautés

<div class="slide-content">
  * Administration
  * Réplication
  * Développement et syntaxe SQL
  * Supervision
  * Performances
</div>

<div class="notes">

PostgreSQL 14 est sorti le 30 septembre 2021.

Les points principaux sont décrits dans le « [press kit](https://www.postgresql.org/about/press/presskit14/) ».

Nous allons décrire ces nouveautés plus en détail.

</div>

----

\newpage

## Administration et maintenance

<div class="slide-content">

  * Sécurité
  * Configuration
  * Outils clients
  * Partitionnement
  * Divers

</div>

<div class="notes">
</div>

----

\newpage

### Sécurité

----

#### Authentification SCRAM-SHA-256 par défaut

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/75 --> 
!include include/scram-par-defaut.md

----

#### Nouveaux rôles prédéfinis

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/99 -->
!include include/99_new_roles.md

----

\newpage

### Nouveautés de configuration (GUC)

----

#### Nouveaux caractères d'échappement pour `log_line_prefix`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/100 -->
!include include/100_parallel_leader_wildcard_to_log_line_prefix.md

----

#### Temps d'attente maximal pour une session inactive

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/101 -->
!include include/101_idle_session_timeout.md

----

#### Modification à chaud de la restore_command

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/102 -->
!include include/102_restore_command_on_reload.md

----

#### Détection des déconnexions pendant l'exécution d'une requête

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/103 -->
!include include/103_client_connection_check_interval.md

----

#### Changements mineurs de configuration

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/141 -->
!include include/141_changements_mineurs_de_la_configuration.md

----

\newpage

### Outils clients

----

#### pg_dump/pg_restore : Possibilité d'exporter et restaurer des partitions individuellement

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/105 -->
!include include/105_dump_attach_partition.md

----

#### pg_dump : Nouvelle option pour exporter les extensions  

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/106 -->
!include include/106-add-support-for-extension-in-pg_dump.md

----

\newpage

### Partionnement

----

#### ALTER TABLE ... DETACH PARTITION ... CONCURRENTLY

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/108 -->
!include include/108_alter_table_detach_partition_concurrently.md

----

#### Nouveautés sur REINDEX et reindexdb

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/109 -->
!include include/109_add_support_for_partitioned_tables_and_indexes_in_reindex.md

----

#### Collecte automatique des statistiques de tables partitionnées

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/110 -->
!include include/110_autovacuum_handle_analyze_for_partitioned_tables.md

----

\newpage

### Divers

----

#### Compression des toast configurable en : LZ4 et pglz

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/111 -->
!include include/111_allow_configurable_lz4_toast_compression.md

----

#### Nouvelle option pour VACUUM : PROCESS_TOAST

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/112 -->
!include include/112_add_option_process_toast_to_vacuum.md

----

#### Nouvelle option pour REINDEX : TABLESPACE

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/107 -->
!include include/107_add_tablespace_option_to_reindex.md

----

#### Nouvelle fonction pour attendre lorsque l'on arrête un backend

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/113 -->
!include include/113_add_functions_to_wait_for_backend_termination.md

----

\newpage

## Réplication et Sharding

<div class="slide-content">
  * Réplication physique
  * Réplication logique
  * Évolutions pour les _Foreign Data Wrapper_
    * Vers une architecture distribuée (_sharding_)
</div>

<div class="notes">
</div>

----

\newpage

### Réplication Physique

----

#### Autorise `pg_rewind` a utiliser un secondaire comme source

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/104 -->
!include include/104_allow_pg_rewind_to_use_a_standby_server_as_the_source_system.md

----

#### Nouveau paramètre de connexion dans libpq

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/114 -->
!include include/114_new_libpq_option_to_prefer_standby_for_connection.md

----

\newpage

### Réplication logique

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/115 -->
!include include/115_logical_replication_feature_in_pg14.md

----

\newpage

### Foreign Data Wrapper et Sharding

<div class="notes">
Deux évolutions majeures sont apparues dans la gestion des tables distantes à
travers l'API _Foreign Data Wrapper_, portées dans l'extension `postgres_fdw`.
Nous verrons que l'architecture distribuée, dites _sharding_, devient alors
possible.
</div>

----

#### Support du TRUNCATE sur les tables distantes

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/116 -->
!include include/116_truncate_on_foreign_table.md

----


#### Lecture asynchrone des tables distantes

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/117 -->
!include include/117_async_append.md

----

\newpage

## Développement et syntaxe SQL

----

### Fonction `string_to_table`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/118 -->
!include include/118_function_string_to_table.md

----

### Nouvelle syntaxe OR REPLACE pour la modification d'un trigger

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/119 -->
!include include/119_create_or_replace_trigger.md

----

### Support des paramètres OUT dans les procédures

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/120 -->
!include include/120_support_for_out_parameters_in_procedures.md

----

### PL/pgSQL : assignation pour les types complexes

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/121 -->
!include include/121-plpgsql-assignment-parsing.md

----

### Nouveaux types `multirange` et nouvelles fonctions d'agrégats

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/122 -->
!include include/122_range_agg_multiranges.md

----

### GROUP BY DISTINCT

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/123 -->
!include include/123_group_by_distinct.md

----

### Corps de routines respectant le standard SQL

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/124 -->
!include include/124-sql-standard-function-body.md

----

### Nouvelles clauses SEARCH et CYCLE

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/125 -->
!include include/125_search_and_cycle.md

----

### Nouvelle fonction `date_bin`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/126 -->
!include include/126-truncating-timestamps-on-arbitrary-intervals-fct-date_bin.md

----

### Possibilité d'attacher un alias à un JOIN .. USING

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/127 -->
!include include/127_allow_an_alias_to_be_attached_directly_to_a_join_using.md

----

\newpage

## Supervision

----

### Nouvelle vue `pg_stat_wal`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/129 -->
!include include/129_nouvelle_vue_pg_stat_wal.md

----

### Nouvelle vue `pg_stat_progress_copy`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/133 -->
!include include/133_simple_progress_reporting_for_copy_command.md

----

### Nouvelle vue `pg_stat_replication_slots`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/134 -->
!include include/135-pg_stat_replicaton_slots.md

----

### Nouveautées dans `pg_stat_statements`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/130 -->
!include include/EXEMPLE.md

----

### Ajout de statistiques sur les sessions dans `pg_stat_database`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/131 -->
!include include/131_add_session_statistics_to_pg_stat_database.md

----

### Identifiant pour les requêtes normalisées

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/132 -->
!include include/132_compute_query_id.md

----

### Nouveauté dans `pg_locks`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/134 -->
!include include/134_add_wait_start_column_to_pg_locks.md

----

\newpage

## Performances

----

### Améliorations de l'indexation

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/136 -->
!include include/EXEMPLE.md

----

### Amélioration des performances avec un grand nombre de connexions en lecture seule

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/137 -->
!include include/EXEMPLE.md

----

### Amélioration des performances de la restauration

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/138 -->
!include include/EXEMPLE.md

----

### Autres améliorations

!include include/EXEMPLE.md

----

# Ateliers

<!-- lister les tp ici, un include par tp -->

<div class="slide-content">
  * Découvrir les nouveaux rôles prédéfinis
  * Mise en place d'un sharding minimal
  * Outil pg_rewind
</div>

----

!include include/tp-99_new_roles.md

----

!include include/tp-117_async_append.md

----

!include include/tp-104_allow_pg_rewind_to_use_a_standby_server_as_the_source_system.md

----

!include include/tp-EXEMPLE.md

----
