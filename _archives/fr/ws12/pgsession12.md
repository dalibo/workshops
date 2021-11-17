---
subtitle : 'Workshop 12'
title : 'Nouveautés de PostgreSQL 12'
keywords:
- postgres
- postgresql
- features
- news
- 12
- workshop
linkcolor:


licence : PostgreSQL
author: Dalibo & Contributors
revision: 12
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

---
# Nouveautés de PostgreSQL 12

![](medias/Etosha_elefant_12.png)

<div class="slide-content">

</div>

<div class="notes">

Photographie de [Ikiwaner](https://commons.wikimedia.org/wiki/User:Ikiwaner), licence [GNU FREE Documentation Licence](https://en.wikipedia.org/wiki/fr:Licence_de_documentation_libre_GNU),
obtenue sur [wikimedia.org](https://fr.wikipedia.org/wiki/Fichier:Etosha_elefant.jpg).


**Participez à ce workshop !**

 Pour des précisions, compléments, liens, exemples, 
et autres corrections et suggestions, soumettez vos _Pull Requests_ dans notre dépôt :

<https://github.com/dalibo/workshops/tree/master/fr>

Licence : [PostgreSQL](https://github.com/dalibo/workshops/blob/master/LICENSE.md)

Ce workshop sera maintenu encore plusieurs mois après la sortie de la version 12.

</div>

----

\newpage
## La v12

<div class="slide-content">

  * Développement depuis le 30 juin 2018
  * sortie le 3 octobre 2019
  * v12.1 sortie le 14/11/2019
  
</div>

<div class="notes">

</div>

----

\newpage

## Les nouveautés

<div class="slide-content">

  * Développement SQL 
  * Partitionnement 
  * Réplication
  * Monitoring
  * Administration
  * Performances : index
  * Incompatibilités
  * Fonctionnalités futures
  * Ateliers
</div>

<div class="notes">

</div>

----

\newpage

## Développement / SQL

<div class="slide-content">

  * Colonnes générées par une expression `IMMUTABLE`
  * Colonne `OID` supprimée
  * `COMMIT` ou `ROLLBACK AND CHAIN`
  * `COPY FROM WHERE`

</div>

<div class="notes">

</div>

----


\newpage

## Partitionnement

<div class="slide-content">

  * Clés étrangères
  * Fonctions d'information : 
    * `pg_partition_root` renvoie la partition mère d'une partition,
    * `pg_partition_ancestors` renvoie la partition mère ainsi que la partition concernée
    * `pg_partition_tree` renvoie tout l'arbre de la partition sous forme de tuples
  * Commande `\dP`

</div>  

<div class="notes">

</div>

----

\newpage


\newpage

## Réplication

<div class="slide-content">

  * Nouveauté des `postgresql.conf`et `recovery.conf`
  * 2 fichiers _trigger_
  * Paramètres modifiables à chaud
  * Fonction `pg_promote()`
  * Copie de slot de réplication
</div>

<div class="notes">


</div>

----

\newpage

## Monitoring

<div class="slide-content">

  * Échantillon des requêtes dans les logs
  * Vues de progression pour `CREATE INDEX`, `CLUSTER`, `VACUUM`
  * Listing : 
    *  des fichiers dans les répertoires `status` des archives des _wals_ 
    *  des fichiers temporaires
  * `pg_stat_replication` : timestamp du dernier message reçu du secondaire

</div>

<div class="notes">


</div>

-----

\newpage


## Administration

<div class="slide-content">

  * Nouveautés sur le `VACUUM`
    * `VACUUM (TRUNCATE on)` : _lock_ et libération de l'espace de fin de table 
    * `VACUUM (SKIP_LOCKED ON)`
    * `VACUUM (INDEX_CLEANUP OFF)` : favoriser les `VACUUM FREEZE` 
    * Nouvelles options de `vacuumdb`
  * Recyclage des _WALs_
    * `wal_recycle`
    * `wal_init_zero`
  * Outils : `pg_upgrade`, `pg_ctl`, `pg_checksums`
  * Paramètres de `postgresql.conf`

</div>

<div class="notes">

</div>

----

\newpage

### Environnement Client

<div class="slide-content">

  * Formatage _CSV_ en sortie de `psql`
  * `EXPLAIN (SETTINGS)`

</div>

<div class="notes">

</div>

----

\newpage

### Outils

<div class="slide-content">

  * `pg_upgrade --clone`: clonage à l'aide de _reflink_
  * Rotation des logs avec `pg_ctl logrotate`
  * `pg_verify_checksums` devient `pg_checksums`
  * `pg_checksums --enable | --disable`
</div>

<div class="notes">

</div>

----

\newpage

### Paramètres de configuration

<div class="slide-content">

  * Nouveaux paramètres
  * disparition du fichier `recovery.conf`
  * valeur par défaut modifiée

</div>

<div class="notes">

</div>

----

\newpage

## Performances

<div class="slide-content">

  * `REINDEX CONCURRENTLY`
  * `CREATE STATISTICS` pour les distributions non-uniformes
  * paramètre `plan_cache_mode`
  * fonctions d'appui : pour améliorer les estimations de coût des fonctions
  * _JIT_ par défaut
  * Optimisation _CTE_ : `MATERIALIZED` / `NOT MATERIALIZED`
  * Meilleures performances sur le partitionnement
</div>  

<div class="notes"></div>

----

\newpage

### REINDEX CONCURRENTLY

<div class="slide-content">

* `REINDEX CONCURRENTLY`

</div>

<div class="notes">

</div>

----

\newpage

### CREATE STATISTICS mcv

<div class="slide-content">

  * Nouveau type `MCV` pour la commande `CREATE STATISTICS`
  * MCV signifie _Most Common Values_
  * collecte les valeurs les plus communes pour un ensemble de colonnes
</div>

<div class="notes">

</div>

----


\newpage

### Méthode de mise en cache des plans d'exécution 

<div class="slide-content">
  
  * Transactions **préparées**
  * `plan_cache_mode auto`
  * Trois modes:
    * `auto`
    * `force_custom_plan`
    * `force_generic_plan`
</div>

<div class="notes">

</div>

----

\newpage

### Fonctions d'appui (_support functions_)

<div class="slide-content"> 

  * Améliore la visibilité du planificateur sur les fonctions
  * possibilité d'associer à une fonction une fonction « de support »
  * produit dynamiquement des informations sur:
    * la sélectivité
    * le nombre de ligne produit
    * son coût d'exécution
  * La fonction doit être écrite en C
</div>

<div class="notes">

</div>

----

\newpage

### JIT par défaut

<div class="slide-content">

  * JIT (Just-In-time) est maintenant activé par défaut 
</div>

<div class="notes">

</div>

----

\newpage

### Modification du comportement par défaut des requêtes _CTE_ 

<div class="slide-content">

* Les _CTE_ ne sont plus des barrières d'optimisation
* Modification du comportement par défaut des CTE
  * `MATERIALIZED`
  * `NOT MATERIALIZED` (par défaut)
* requêtes non récursives
* requêtes référencées une seule fois 
* requêtes n'ayant aucun effet de bord
</div>

<div class="notes">


</div>

----

\newpage

### Performances du partitionnement

<div class="slide-content">

  * Performances accrues avec un grand nombre de partitions
  * Verrous lors des manipulations de partitions
  * support des clés étrangères vers une table partitionnée
  * Amélioration du chargement de données

</div>


<div class="notes">

</div>

----

\newpage

## Incompatibilités

<div class="slide-content">

  * Disparition du `recovery.conf`
  * `max_wal_senders` n'est plus inclus dans `max_connections`
  * Noms des clés étrangères
  * Tables `WITH OIDS` n'existent plus
  * Types de données supprimés
  * Fonctions `to_timestamp` et `to_date`
  * Outil `pg_checksums`

</div>

<div class="notes">

</div>

----

\newpage

### `pg_verify_checksums` renommée en `pg_checkums`

<div class="slide-content">

  * `pg_verify_checksums` devient `pg_checkums`

</div>

<div class="notes">

</div>

----

\newpage


## Fonctionnalités futures

<div class="slide-content">

  * _Pluggable storage_
    * _HEAP storage_
    * _column storage_
    * _Zed Heap_
    * _blackhole_
</div>

<div class="notes">

</div>

----

\newpage

### Pluggable storage 

#### HEAP storage

<div class="slide-content">
  * `HEAP storage`
  * méthode de stockage par défaut
  * seule méthode supportée pour le moment
</div>

<div class="notes">

</div>

----

\newpage

#### Zedstore: Column storage

<div class="slide-content">

  * méthode orientée colonne
  * données compressées
  * nom temporaire !
</div>


<div class="notes">

</div>

----

\newpage

#### zHeap

<div class="slide-content">

  * _UNDO_ plutôt que _REDO_
  * meilleur contrôle du _bloat_
  * réduction de l'amplification des écritures
  * réduction de la taille des entêtes
  * méthode basée sur les différences 
  
</div>

<div class="notes">

</div>

----

#### Méthode d'accès _Blackhole_

<div class="slide-content">

  * sert de base pour créer une extension _Access Method_
  * toute donnée ajoutée est envoyée dans le néant
  
</div>

<div class="notes">

</div>

----
