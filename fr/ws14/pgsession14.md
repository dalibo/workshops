---
subtitle : 'PGSession 14'
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
revision: 1
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
# Nouveautés de PostgreSQL 14

![](medias/ws14_Lakshmana_Temple_10.jpg)

<div class="slide-content">

</div>
----

\newpage
## La v14

<div class="slide-content">

  * Développement depuis le 7 juin 2020
  * Sortie le 30 septembre 2021
  * version 13.1 sortie le XXX

</div>

<div class="notes">

</div>

----

\newpage

## Les nouveautés

<div class="slide-content">

  * Administration et maintenance
  * Réplication physique et logique
  * Sharding (en construction)
  * Développement et syntaxe SQL
  * Supervision
  * Performances

</div>

<div class="notes">

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


\newpage

### Partionnement

----

#### Nouveautés sur REINDEX et reindexdb

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/109 -->
!include include/109_add_support_for_partitioned_tables_and_indexes_in_reindex.md

----

\newpage

### Divers

----

#### Compression des toast configurable en : LZ4 et pglz

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/111 -->
!include include/111_allow_configurable_lz4_toast_compression.md

----

\newpage

## Réplication

<div class="slide-content">
  * Réplication physique
  * Réplication logique
</div>

<div class="notes">
</div>

----

\newpage

### Réplication Physique

----

#### Amélioration de `pg_rewind`

<div class="slide-content">
  * La source d’un rewind peut être une instance secondaire 
  * Permet de limiter l’impact des lectures sur la nouvelle instance primaire
</div>

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

## Sharding

----

### Foreign Data Wrapper et Sharding

<div class="slide-content">
  * Évolutions pour les _Foreign Data Wrapper_
  * Vers une architecture distribuée (_sharding_)
</div>

----

#### Lecture asynchrone des tables distantes

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/117 -->
!include include/117_async_append.md

----

\newpage

## Développement et syntaxe SQL

----

### Manipulation du type JSONB

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/121#note_126876 -->
!include include/121-better-jsonb.md

----


### Nouvelle fonction `date_bin`

<div class="slide-content">
  * Nouvelle fonction pour répartir des timestamps dans des intervalles (buckets)
```
SELECT date_bin('1 hour 30 minutes', t, '2021-06-01 00:00:00'::timestamp with time zone),
       id_sonde, avg(mesure)
  FROM sonde GROUP BY 1, 2 ORDER BY 1 ASC;
```
```text
        date_bin        | id_sonde |          avg
------------------------+----------+------------------------
 2021-06-01 00:00:00+02 |        1 |     2.9318518518518519
 2021-06-01 01:30:00+02 |        1 |     8.6712962962962963
 2021-06-01 03:00:00+02 |        1 |    14.1218518518518519
 2021-06-01 04:30:00+02 |        1 |    19.0009259259259259
```
</div>

----


\newpage

## Supervision

----

### Nouvelle vue `pg_stat_wal`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/129 -->
!include include/129_nouvelle_vue_pg_stat_wal.md

----

### Nouveautées dans `pg_stat_statements`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/130 -->
!include include/130_pg_stat_statements_new_features.md

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

### Nettoyage des index BTree 

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/136 -->
!include include/136-ameliorations-des-index-btree.md

----


### Connexions simultanées en lecture seule

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/137 -->
!include include/137_improving_connection_scalability.md

