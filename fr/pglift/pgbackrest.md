---
subtitle : 'Workshop pgbackrest'
title : 'Sauvegarde et Restauration PITR avec `pgbackrest` et `pglift`'
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

## Rappel d'une Sauvegarde Physique (PITR)

## Présentation de `pgbackrest`

# Installation

## Pré-requis

## Installation de `pgbackrest`

# Sauvegarde locale

## Configuration de `pglift`

## Sauvegarde

## Restauration

# Sauvegarde dans un dépôt distant (`ssh`)

## Installation du dépôt `pgbackrest` distant

## Configuration de `pglift`

## Sauvegarde

## Restauration

# Sauvegarde dans un dépôt distant (`TLS/SSL`)

## Installation du dépôt `pgbackrest` distant

## Configuration de `pglift`

## Sauvegarde

## Restauration
