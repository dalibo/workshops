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

![](medias/ws14/ws14_Lakshmana_Temple_10.jpg)

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
    * Sécurité
    * Outils clients
    * Partitionnement
    * Divers
    * Contributions
  * Réplication (logique ou physique) & sharding/FDW
    * Réplication physique
    * Réplication logique
    * Foreing Data Wrapper et sharding
  * Développement + Changement syntaxe SQL
  * Supervision
  * Performances
    * Index
    * Recovery
    * Divers
  * Régressions
</div>

<div class="notes">

PostgreSQL 14 est sorti le FIXME

Les points principaux sont décrits dans le « [press kit](FIXME) ».

Nous allons décrire ces nouveautés plus en détail.

</div>

----

\newpage

## Administration et maintenance

<div class="slide-content">
</div>

<div class="notes">
</div>

----

\newpage

### Sécurité

<div class="slide-content">
  * L'authentication repose par défaut sur SCRAM-SHA-256
  * Nouveaux rôles prédéfinis
</div>

<div class="notes">
</div>

----

#### Authentification SCRAM-SHA-256 par défaut

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/75 --> 
!include include/ws14/scram-par-defaut.md

----

#### Nouveaux rôles prédéfinis

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/99 -->
!include include/ws14/99_new_roles.md

----

\newpage

### Nouveautés de configuration (GUC)

<div class="slide-content">
  * Nouveaux caractères d'échappement pour `log_line_prefix`
  * Temps d'attente maximal pour une session inactive (`idle_session_timeout`)
  * Modification à chaud du paramètre `restore_command`
  * Détection des déconnexions pendant l'exécution d'une requête
</div>

<div class="notes">
</div>

----

\newpage

#### Nouveaux caractères d'échappement pour log_line_prefix

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/100 -->
!include include/ws14/100_parallel_leader_wildcard_to_log_line_prefix.md

----

#### Temps d'attente maximal pour une session inactive

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/101 -->
!include include/ws14/101_idle_session_timeout.md

----

#### Modification à chaud de la restore_command

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/102 -->
!include include/ws14/102_restore_command_on_reload.md

----

#### Détection des déconnexions pendant l'exécution d'une requête

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/103 -->
!include include/ws14/103_client_connection_check_interval.md

----

\newpage

### Outils clients

<div class="slide-content">
  * pg_dump/pg_restore : Possibilité d'exporter et restaurer des partitions individuellement
  * pg_dump : Nouvelle option pour exporter les extensions
  * reindexdb : Nouvelle option --tablespace
</div>

<div class="notes">
</div>

----

#### pg_dump/pg_restore : Possibilité d'exporter et restaurer des partitions individuellement

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/105 -->
!include include/ws14/105_dump_attach_partition.md

----

#### pg_dump : Nouvelle option pour exporter les extensions  

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/106 -->
!include include/ws14/EXEMPLE.md

----

\newpage

### Partionnement

<div class="slide-content">
  * ALTER TABLE ... DETACH PARTITION ... CONCURRENTLY
  * Nouveautées sur REINDEX et reindexdb
  * autovacuum gère désormais correctement les statistiques sur les tables paritionnées
</div>

<div class="notes">
</div>

----

#### ALTER TABLE ... DETACH PARTITION ... CONCURRENTLY

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/108 -->
!include include/ws14/EXEMPLE.md

----

#### Nouveautées sur REINDEX et reindexdb

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/109 -->
!include include/ws14/EXEMPLE.md

----

#### autovacuum gère désormais correctement les statistiques sur les tables paritionnées

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/110 -->
!include include/ws14/EXEMPLE.md

----

\newpage

### Divers

<div class="slide-content">
  * Compression des toast configuratble en : LZ4 et pglz
  * Nouvelle option pour VACUUM : PROCESS_TOAST
  * Nouvelle option pour REINDEX : TABLESPACE
  * Nouvelle fonction pour attendre lorsque l'on arrête un backend
</div>

<div class="notes">
</div>

----

#### Compression des toast configuratble en : LZ4 et pglz

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/111 -->
!include include/ws14/EXEMPLE.md

----

#### Nouvelle option pour VACUUM : PROCESS_TOAST

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/112 -->
!include include/ws14/EXEMPLE.md

----

#### Nouvelle option pour REINDEX : TABLESPACE

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/107 -->
!include include/ws14/107_add_tablespace_option_to_reindex.md

----

#### Nouvelle fonction pour attendre lorsque l'on arrête un backend

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/113 -->
!include include/ws14/113_add_functions_to_wait_for_backend_termination.md

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

<div class="slide-content">
  * Autorise pg_rewind a utiliser une standby comme source
  * Nouveaux paramètre de connexion dans libpq
</div>

<div class="notes">
</div>

----

#### Autorise pg_rewind a utiliser une standby comme source

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/104 -->
!include include/ws14/EXEMPLE.md

----

#### Nouveaux paramètre de connexion dans libpq

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/114 -->
!include include/ws14/EXEMPLE.md

----

### Réplication Logique - slide commun (#115)

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/114
     * logical streaming of large in-progress transactions
     * Logical Replication - detail message with names of missing columns
     * Support ALTER SUBSCRIPTION ... ADD/DROP PUBLICATION ... syntax
-->
!include include/ws14/EXEMPLE.md

----

\newpage

### Foreign Data Wrapper et Sharding

<div class="slide-content">
  * Support du `TRUNCATE` sur les tables distantes
  * Lecture asynchrone des tables distantes
</div>

<div class="notes">
Deux évolutions majeures sont apparues dans la gestion des tables distantes à
travers l'API _Foreign Data Wrapper_, portées dans l'extension `postgres_fdw`.
Nous verrons que l'architecture distribuée, dites _sharding_, devient alors
possible.
</div>

----

#### Support du TRUNCATE sur les tables distantes

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/116 -->
!include include/ws14/116_truncate_on_foreign_table.md

----


#### Lecture asynchrone des tables distantes

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/117 -->
!include include/ws14/117_async_append.md

----

\newpage

## Développement + Changement syntaxe SQL

<div class="slide-content">
  * Fonction string_to_table
  * Nouvelle syntaxe OR REPLACE pour la re-création d'un trigger
  * PL/pgSQL : assignation pour les types complexes
  * Nouveaux types `multirange` et nouvelles fonctions d'agrégats
  * GROUP BY DISTINCT
  * Corps de routines respectant le standard SQL
  * Nouvelles clauses SEARCH et CYCLE
  * Nouvelle fonction date_bin
  * Possiblité d'attacher un alias à un JOIN .. USING
</div>

<div class="notes">
</div>

----

### Fonction string_to_table

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/118 -->
!include include/ws14/118_function_string_to_table.md

----

### Nouvelle syntaxe OR REPLACE pour la re-création d'un trigger

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/119 -->
!include include/ws14/119_create_or_replace_trigger.md

----

### Support des paramètres OUT dans les procédures

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/120 -->
!include include/ws14/120_support_for_out_parameters_in_procedures.md

----

### PL/pgSQL : assignation pour les types complexes

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/121 -->
!include include/ws14/121-plpgsql-assignment-parsing.md

----

### Nouveaux types `multirange` et nouvelles fonctions d'agrégats

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/122 -->
!include include/ws14/122_range_agg_multiranges.md

----

### GROUP BY DISTINCT

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/123 -->
!include include/ws14/123_group_by_distinct.md

----

### Corps de routines respectant le standard SQL

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/124 -->
!include include/ws14/124-sql-standard-function-body.md

----

### Nouvelles clauses SEARCH et CYCLE

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/125 -->
!include include/ws14/EXEMPLE.md

----

### Nouvelle fonction date_bin

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/126 -->
!include include/ws14/126-truncating-timestamps-on-arbitrary-intervals-fct-date_bin.md

----

### Possiblité d'attacher un alias à un JOIN .. USING

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/127 -->
!include include/ws14/127_allow_an_alias_to_be_attached_directly_to_a_join_using.md

----

\newpage

## Supervision

<div class="slide-content">
  * Nouvelle vue pg_stat_wal
  * Nouvelle vue pg_stat_progress_copy
  * Nouvelle vue pg_stat_replication_slots
  * Nouveautées dans pg_stat_statements
  * Ajout de statistiques sur les sessions dans pg_stat_database
  * Identifiant pour les requêtes normalisées
  * Ajout de la colonne wait_start dans pg_locks

</div>

<div class="notes">
</div>

----

### Nouvelle vue pg_stat_wal

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/129 -->
!include include/ws14/EXEMPLE.md

----

### Nouvelle vue pg_stat_progress_copy

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/133 -->
!include include/ws14/EXEMPLE.md

----

### Nouvelle vue pg_stat_replication_slots

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/134 -->
!include include/ws14/EXEMPLE.md

----

### Nouveautées dans pg_stat_statements

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/130 -->
!include include/ws14/EXEMPLE.md

----

### Ajout de statistiques sur les sessions dans pg_stat_database

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/131 -->
!include include/ws14/EXEMPLE.md

----

### Identifiant pour les requêtes normalisées

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/132 -->
!include include/ws14/132_compute_query_id.md

----

### Ajout de la colonne wait_start dans pg_locks

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/134 -->
!include include/ws14/EXEMPLE.md

----

\newpage

## Performances

<div class="slide-content">
  * Amélioration de l'indexation
  * Amélioration des performances avec un grand nombre de connexions read-only
  * Amélioration des performances de la recovery
  * Autres améliorations
</div>

<div class="notes">
</div>

----

### Améliorations de l'indexation

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/136 -->
!include include/ws14/EXEMPLE.md

----

### Amélioration des performances avec un grand nombre de connexions read-only

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/137 -->
!include include/ws14/EXEMPLE.md

----

### Amélioration des performances de la recovery

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/138 -->
!include include/ws14/EXEMPLE.md

----

### Autres améliorations

!include include/ws14/EXEMPLE.md

----

# Ateliers

<!-- lister les tp ici, un include par tp -->

<div class="slide-content">
  * Nouveaux rôles prédéfinis
  * Mise en place d'un sharding minimal
</div>

----

!include include/ws14/tp-99_new_roles.md

----

!include include/ws14/tp-117_async_append.md

----

!include include/ws14/tp-EXEMPLE.md

----
