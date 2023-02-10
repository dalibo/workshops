---
subtitle : 'Workshop 15'
title : 'Nouveautés de PostgreSQL 15'
keywords:
- postgres
- postgresql
- features
- news
- 15
- workshop
linkcolor:

licence : PostgreSQL
author: Dalibo & Contributors
revision: 15
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

\newpage

# Administration

## Fonctionnement interne

### Lancement du background writer et du checkpointer lors d'une récupération suite à un crash

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/178 -->
!include include/178-lancement-du-background-writer-et-du-checkpointer-lors-d-une-recuperation-suite-a-un-crash.md

---

### Plus de checkpoint lors de la création d'une database

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/177 -->
!include include/177-plus-de-checkpoint-lors-de-la-creation-d-une-database.md

---

### Statistiques d'activité en mémoire partagée

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/148 -->
!include include/148-ws15-statistiques-d-activite.md

---

### Préservation de l'OID des relfilenodes, tablespaces, et bases de données après une migration pg_upgrade

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/179 -->
!include include/179-preservation-de-l-oid-des-relfilenodes-dans-pg_upgrade.md

---

\newpage

## psql

### Optimisation des performances de la commande `\copy`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/151 -->
!include include/151-psql-copy-performance.md

---

### Nouvelles commandes `\getenv` et `\dconfig`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/153 -->
!include include/153-psql-nouvelles-commandes.md

---

### Diverses améliorations sur l'auto-complétion

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/154 -->
!include include/154-psql-auto-completion.md

---

\newpage

## Sauvegarde et restauration

### Fin des backups exclusifs

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/183 -->
!include include/183-fin-des-backups-exclusifs.md

---

### Archive_library & module "basic archive"

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/150 -->
!include include/150-archive_library-module-basic-archive.md

---

### Permettre le pre-fetch du contenu des fichiers WAL pendant le recovery

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### pg_basebackup `--target`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/152 -->
!include include/152-backup-targets.md

---

### Ajout de nouveaux algorithmes de compression

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/155 -->
!include include/155-compression-lz4-et-zstandard.md

---

### pg_dump

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/188 -->
!include include/188-pg_dump-amelioration-des-performances-avec-de-nombreux-objets.md

---

\newpage

## Nouvelles vues et paramètres

### Ajout de la vue système pg_ident_file_mappings pour reporter les informations du fichier pg_ident.conf

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/159 -->
!include include/159_nouvelle_vue_pg_ident_file_mappings.md

---

### Ajout de la vue système pg_stat_subscription_stats pour reporter l'activité d'un souscripteur (cf. Réplication logique)

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/161 -->
!include include/161_nouvelle_vue_pg_stat_subscription_stats.md

---

### Ajout de nouvelles variables serveur _shared_memory_size_ et _shared_memory_size_in_huge_pages_

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/145 -->
!include include/160_guc_shared_memory_size_and_shared_memory_size_in_huge_pages.md

---

\newpage

## Partitionnement

### Les triggers pour les clés étrangères sont maintenant créés sur les tables partitionnées et sur les partitions

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Amélioration du comportement des clés étrangère lors de mises à jour qui déplacent des lignes entres les partitions

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/171 -->
!include include/171-amelioration-du-comportement-des-cles-etrangere-lors-de-mises-a-jour-qui-deplacent-des.md

---

\newpage


## Traces

### Activation de la journalisation des CHECKPOINT et opérations de VACUUM lentes

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/156 -->
!include include/156-journalisation_checkpoints_et_autovacuum.md

---

### Format de sortie JSON pour les traces

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/157 -->
!include include/157-traces-au-format-json.md

---

### Informations supplémentaires dans VACUUM VERBOSE

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/158 -->
!include include/158-informations-supplementaires-dans-vacuum-verbose.md

---

\newpage


## Divers

### Possibilité de donner/restreindre les droits aux commandes SET / ALTER SYSTEM pour les utilisateurs non privilégiés

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/162 -->
!include include/162_grant_pour_parametrage_via_set_et_alter_system.md

---

### Révocation du droit par défaut CREATE sur le schéma public pour le groupe PUBLIC

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/163 -->
!include include/163_revocation_du_droit_par_defaut_create_on_schema_public_to_public.md

---

### Ajout de la possibilité de créer des séquences UNLOGGED

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/164 -->
!include include/164_sequences_unlogged.md

---

### Nouvelle variable d'environnement PSQL_WATCH_PAGER

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/165 -->
!include include/165_nouvelle_variable_d_environnement_psql_watch_pager.md

---

### Collation icu déclarées globalement

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/149 -->
!include include/149-icu.md

---

### Ajout de l'option --config-file à pg_rewind

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/167 -->
!include include/167-ws15-ajout-de-l-option-config-file-a-pg_rewind.md

---

\newpage

# Performances

## Permettre les statistiques étendues d'enregistrer des informations pour la table parente et ses partitions filles

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## Exécution en parallèle des requêtes SELECT DISTINCT

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/182 -->
!include include/182-execution-en-parallele-des-requetes-select-distinct.md

---

## pg_stat_statements


<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/181

[pg_stat_statements] Ajout de métriques supplémentaires pour JIT
[pg_stat_statements] Ajout de métriques supplémentaires sur l'utilisateur des fichiers temporaires
--> 
!include include/181-pg_stat_statements-ajout-de-metriques-supplementaires-pour-jit.md

---

\newpage

# Réplication logique

## Nouvelle option `TABLES IN SCHEMA`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/166 -->
!include include/166_une_publication_peut_contenir_toutes_les_tables_d_un_schema.md

---

## Les données publiées peuvent être filtrées

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/168 -->
!include include/168_les_donnees_publiees_peuvent_etre_filtrees_avec_une_clause_where.md

---

## Ajout de la vue système pg_stat_subscription_stats pour reporter l'activité d'un souscripteur

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/161 -->
!include include/161_nouvelle_vue_pg_stat_subscription_stats.md

---

\newpage

# Développement + Changement syntaxe SQL

## Ajout de la commande SQL MERGE

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/172 -->
!include include/172-ajout-de-la-commande-sql-merge.md

---

## Permettre l'usage d'index pour les condition basées sur ^@ et starts_with()

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/173 -->
!include include/173-w15-permettre-l-usage-d-index-pour-les-condition-basees-sur-et-starts_with.md

---

## Ajout de fonctions d'expression régulières pour la compatibilité avec d'autres SGBD

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/175 -->
!include include/175-ajout-de-fonctions-d-expression-regulieres-pour-la-compatibilite-avec-d-autres-sgbd.md

---

## [MINEUR] Possibilité de mettre une échelle négative ou supérieure à précision pour le type NUMERIC

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## [MINEUR] Ajout des fonctions min() et max() pour le type xid8

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## [MINEUR] Égalité des valeurs NULL dans les contraintes uniques configurable via UNIQUE [ NULLS [ NOT ] DISTINCT ]

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

\newpage

# Régressions

## Retrait du support des instances de versions 9.1 et antérieures

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/186 -->
!include include/186-psql-ne-supporte-plus-9-1-et-versions-anterieures.md

---

## Python2 déprécié : Retrait des langages plpython2u et plpythonu

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/190 -->
!include include/190-python2-deprecie.md

---

\newpage

# Ateliers

<!-- lister les tp ici, un include par tp -->

<div class="slide-content">
  * TP 1
  * ..
</div>

----

!include include/tp-EXEMPLE.md

----

!include include/tp-EXEMPLE.md

----
