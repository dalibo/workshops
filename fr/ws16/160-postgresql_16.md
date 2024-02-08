---
subtitle : 'Workshop 16'
title : 'Nouveautés de PostgreSQL 16'
keywords:
- postgres
- postgresql
- features
- news
- 16
- workshop
linkcolor:

licence : PostgreSQL
author: Dalibo & Contributors
revision: 16
url : https://dalibo.com/formations
---

## Introduction

<div class="slide-content">

  * Développement depuis l'été 2022
  * 3 versions beta, 1 version RC
  * Version finale : 14 septembre 2023
  * 16.1, le 9 novembre 2023
  * Des centaines de contributeurs

</div>

<div class="notes">

Le développement de la version 16 a suivi l'organisation habituelle : un
démarrage vers la mi-2022, des _Commit Fests_ tous les deux mois, un
_feature freeze_, trois versions beta, une version RC, et enfin la GA.

La version finale est parue le 14 septembre 2023. Une première version
corrective est sortie le 16 novembre 2023.

Son développement est assuré par des centaines de contributeurs répartis partout
dans le monde.

</div>

-----

\newpage

# Utilisation

---

## Prédicats IS JSON

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/224 -->
!include include/224-json-constructor-identity-functions.md

---

## Omission possible de l'alias d'une sous-requête

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/229 -->
!include include/229-allow-subqueries-in-FROM-clause-to-omit-aliases.md

---

## Gestion de triggers TRUNCATE sur des tables externes

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/230 -->
!include include/230-allow-truncate-triggers-on-foreign-tables.md

---

## Ajout de fonctions de vérification de types

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/220 -->
!include include/220-check-functions.md

---

## Possibilité d'utiliser des tirets bas pour des entiers ou valeurs numériques

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/208 -->
!include include/208-underscores-in-constants.md

# Administration

---

## Ajout de la variable SYSTEM_USER

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/203 -->
!include include/203-add-server-variable-system-user.md

---

## `archive_library` et `archive_command` ne peuvent plus être renseignés en même temps

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/204 -->
!include include/204-prevent-archive-file-and-archive-command.md

---

## Réservation de slots de connexion

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/221 -->
!include include/221-reserve-backend-slots.md

---

## Ajout du paramètre `scram_iterations`

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/218 -->
!include include/218-scram-iterations.md

---

## Ajout de la possibilité d'inclure d'autres fichiers ou dossier dans pg_hba.conf et pg_ident.conf

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/214 -->
!include include/214-allow-includes-pghba-pgident.md

---

## Ajout du support des expressions régulières dans le fichier pg_hba.conf

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/209 -->
!include include/209-add-support-for-regular-expression.md

---

## Ajout de la gestion des tables enfants et partitionnées dans pg_dump
<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/212 -->
!include include/212-pgdump-new-options.md

---

## lz4 et zstd peuvent être utilisés avec pg_dump

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/217 -->
!include include/217-lz4-ztd-pgdump.md

---

## Contrôle de l'utilisation de la mémoire partagée par ANALYZE et VACUUM

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/225 -->
!include include/225-buffer-usage-vacuum-analyze.md

---

## Ajout des options `--schema` et `--exclude-schema` dans vacuumdb

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/214 -->
!include include/219-vacuumdb-schema.md

---

## Ajout des options SKIP_DATABASE_STATS et ONLY_DATABASE_STATS

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/231 -->
!include include/231-vacuum-frozenid.md

---

## Optimisation de ANALYZE avec postgres_fdw

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/233 -->
!include include/233-analyze-foreign-postgres-fdw-tables.md

---

## Refonte du système de délégation de droits

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/202 -->
!include include/202-grant-system.md

---

## Nouveau paramètre libpq : require_auth 

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/227 -->
!include include/227-require-auth-libpq.md

---

## Sélection aléatoire des hosts par libpq
!include include/228-allow-multiple-libpq-hosts.md

---

# Réplication

---

## Décodage logique sur les instances secondaires

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/223 -->
!include include/223-allow-logical-decoding-from-standby-servers.md

---

## Parallélisme de l'application des modifications

!include include/235-repllication-logique-parallel-worker.md

---

## Nouveau role pg_create_subscription

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/222 -->
!include include/222-Add-predefined-role-pg_create_subscription.md

---

# Performances

---

## Nouvelle option d'EXPLAIN

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/216 -->
!include include/216-explain-generic.md

---

## Plus d'utilisation du Incremental Sort

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/213 -->
!include include/213-incrementalsort-for-distinct.md

---

## Amélioration des agrégats

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/215 -->
!include include/215-aggregates-having-ORDER-BY-or-DISTINCT.md

---

## Parallélisation des agrégats string_agg et array_agg

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/232 -->
!include include/232_allow_more_aggregate_functions_to_be_parallelized.md

---

## Parallélisation des FULL OUTER JOIN

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/234 -->
!include include/234_allow_parallelization_full_outer_join.md

---

# Supervision

---

## Nouvelle vue pg_stat_io

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/206 -->
!include include/206-new-pg-stat-io-view.md

---

## Horodatage du dernier parcours d'une relation

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/199 -->
!include include/199_record-statistics-on-the-last-scans.md

---

## Nombre d'UPDATE

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/205 -->
!include include/205_record-update-move-to-new-page.md

---

## Amélioration de pg_stat_statements

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/207 -->
!include include/207_pgstatstatements_enhancements.md

---

## Amélioration de auto_explain

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/207 -->
!include include/226_autoexplain_enhancements.md

---

# Régression

---

## Disparition des variables LC_COLLATE et LC_CTYPE

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/200 -->
!include include/200-remove-ro-variables.md

---

# Autres régressions

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/210 -->
!include include/210-regressions.md

---

## Questions ?

<!-- https://gitlab.dalibo.info/formation/workshops/-/issues/193 -->
!include include/193-questions.md


<!--\newpage

# Ateliers

--- -->

<!-- lister les tp ici, un include par tp -->
<!--
<div class="slide-content">
  * TP 1
  * ..
</div>

----

!include include/tp-EXEMPLE.md

----

!include include/tp-EXEMPLE.md

----  -->
