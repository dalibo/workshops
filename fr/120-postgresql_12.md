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
# Nouveautés de PostgreSQL 12

![](medias/Etosha_elefant_12.png)

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

!include include/intro.md

\newpage

!include include/dev-sql.md

\newpage

!include include/partitionnement.md

\newpage

!include include/replication.md

\newpage

!include include/monitoring.md

\newpage

!include include/administration.md

\newpage

!include include/index-perf.md

\newpage

!include include/incompatibilites.md

\newpage

!include include/futur.md

# Ateliers

----

!include include/tp-dev-sql-generated-column.md

\newpage

!include include/tp-partitionnement.md

\newpage

!include include/tp-monitoring.md

\newpage

!include include/tp-index-perf-fonctions-support.md

!include include/gfdl.md

