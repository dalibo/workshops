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

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Plus de checkpoint lors de la création d'une database

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Statistiques d'activité en mémoire partagée

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Préservation de l'OID des relfilenodes, tablespaces, et bases de données après une migration pg_upgrade

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

\newpage

## psql

### Optimisation des performances de la commande \copy

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Nouvelles commandes \getenv et \dconfig

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Diverses améliorations sur l'auto-complétion

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

\newpage

## Sauvegarde et restauration

### Fin des backups exclusifs

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Archive_library & module "basic archive"

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Permettre le pre-fetch du contenu des fichiers WAL pendant le recovery

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Permettre aux membres du role pg_write_server_files d'effectuer des sauvegardes server-side

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### pg_basebackup --target 

[pg_base_backup] Module contrib basebackup_to_shell
[pg_base_backup] Nouvelle option --target

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### [pg_base_backup] Ajout du support des algorithmes LZ4 et Zstandard pour les sauvegardes et les WAL (pg_receivewal)

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### pg_dump

[pg_dump] Export du propriétaire du schéma public et des security labels
[pg_dump] Amélioration des performances d'export de bases de données avec de nombreux objets
[pg_dump] Amélioration des performances d'export parallélisé de tables TOAST

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

\newpage

## Nouvelles vues et paramètres

### Ajout de la vue système pg_ident_file_mappings pour reporter les informations du fichier pg_ident.conf

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Ajout de la vue système pg_stat_subscription_stats pour reporter l'activité d'un souscripteur (cf. Réplication logique)

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Ajout de la variable serveur shared_memory_size pour obtenir la mémoire allouée en mémoire partagée

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Ajout de la variable serveur shared_memory_size_in_huge_pages pour déterminer le nombre de huge page nécessaires

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

\newpage

## Partitionnement

### Les triggers pour les clés étrangères sont maintenant créés sur les tables partitionnées et sur les partitions

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Amélioration du comportement des clés étrangère lors de mises à jour qui déplacent des lignes entres les partitions

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

\newpage


## Traces

### Activation de la journalisation des CHECKPOINT et opérations de VACUUM lentes

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Format de sortie JSON pour les traces

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### VACUUM VERBOSE et autovacuum sont plus détaillés sur l'état d'avancement de relfrozenxid et de relminmxid

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

\newpage


## Divers

### Possibilité de donner/restreindre les droits aux commandes SET / ALTER SYSTEM pour les utilisateurs non privilégiés

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/162 -->
!include include/162_grant_pour_parametrage_via_set_et_alter_system.md

---

### Révocation du droit par défaut CREATE ON SCHEMA public TO public

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Ajout de la possibilité de créer des séquences UNLOGGED

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Nouvelle variable d'environnement PSQL_WATCH_PAGER pour définir un pager à la commande \watch

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Les collations ICU peuvent être définies par défaut pour les instances et les bases de données
+ La collation de chaque base de données est enregistrée et vérifiée

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

### Ajout de l'option --config-file à pg_rewind

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

\newpage

# Performances

## Permettre les statistiques étendues d'enregistrer des informations pour la table parente et ses partitions filles

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## Exécution en parallèle des requêtes SELECT DISTINCT

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## pg_stat_statements

[pg_stat_statements] Ajout de métriques supplémentaires pour JIT
[pg_stat_statements] Ajout de métriques supplémentaires sur l'utilisateur des fichiers temporaires

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

\newpage

# Réplication logique

## Une publication peut contenir toutes les tables d'un schéma

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## Les données publiées peuvent être filtrées avec une clause WHERE

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## Ajout de la vue système pg_stat_subscription_stats pour reporter l'activité d'un souscripteur

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

\newpage

# Développement + Changement syntaxe SQL

## Ajout de la commande SQL MERGE

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## Fonctions JSON JSON_ARRAY(), JSON_ARRAYAGG(), JSON_OBJECT(), JSON_OBJECTAGG()

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## Fonctions SQL/JSON

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## Fonction JSON_TABLE()

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## Permettre l'usage d'index pour les condition basées sur ^@ et starts_with()

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## Ajout de fonctions d'expression régulières pour la compatibilité avec d'autres SGBD

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

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

## Option du postmaster --forkboot renommée en --forkaux

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## psql en version 15 ne supporte plus les versions 9.2 et antérieures

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## PostgreSQL 15 ou ultérieur ne supporte plus le dump de données depuis les versions 9.2 ou antérieures. La restauration de vieilles archives n'est pas garantie.

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

---

## Python2 dépréciée : plus de build possible en python2, retrait des langages plpython2u et plpythonu

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/NUMERO_ISSUE -->
!include include/EXEMPLE.md

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
