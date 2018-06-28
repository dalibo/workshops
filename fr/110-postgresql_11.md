---
subtitle : 'Workshop 11'
title : 'Nouveautés de PostgreSQL 11'
keywords:
- postgres
- postgresql
- features
- news
- 11
- workshop
linkcolor:

                                                                      
licence : PostgreSQL                                                            
author: Dalibo & Contributors                                                   
revision: 18.09
url : https://dalibo.com/formations

#
# PDF Options
#

#toc: true

## Limiter la profondeur de la table des matiÃ¨res
toc-depth: 2

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

# Annule la transformation uppercase de certains thÃ¨mes
title-transform : none

# Cache l'auteur sur la première slide
# Mettre en commentaire pour désactiver
hide_author_in_slide: true


---

# Nouveautés de PostgreSQL 11

![PostgreSQL](medias/elephant-rock-valley-of-fire.jpg)

<div class="notes">
Photographie obtenue sur [urltarget.com](http://www.urltarget.com/elephant-rock-valley-of-fire.html).

Public Domain CC0.
</div>

-----

## Introduction

<div class="slide-content">
  * Développement depuis...
  * Version beta 1 sortie ... FIXME
  * Sortie de la version finale...
  * Plus de FIXME million de lignes de code *C*
  * Des centaines de contributeurs
</div>

<div class="notes">

FIXME
Le développement de la version 10 a suivi l'organisation habituelle : un
démarrage mi 2016, des Commit Fests tous les deux mois, un Feature Freeze en
mars, une première version beta mi-mai.

La version finale est sortie le 5 octobre 2017.

La version 10 de PostgreSQL contient plus de 1,4 millions de lignes de code *C*.
Son développement est assuré par des centaines de contributeurs répartis partout
dans le monde.

Si vous voulez en savoir plus sur le fonctionnement de la communauté PostgreSQL,
une présentation récente de *Daniel Vérité* est disponible en ligne :

  * [Vidéo](https://youtu.be/NPRw0oJETGQ)
  * [Slides](https://dali.bo/daniel-verite-communaute-dev-pgday)
</div>

-----

### Au menu

<div class="slide-content">
  * FIXME
  * Changements importants
  * Partitionnement
  * Réplication logique
  * Performances
  * Sécurité
  * Autres nouveautés
  * Compatibilité
  * Futur
</div>

<div class="notes">
PostgreSQL 11 apporte un grand nombre de nouvelles fonctionnalités, qui sont
d'ores et déjà détaillées dans de nombreux articles. Voici quelques liens vers
des articles en anglais :

  * [New in postgres 11](https://dali.bo/new-in-postgres-11) du projet PostgreSQL
  * ...
</div>

-----


## Performances

<div class="slide-content">
  * FIXME
  * Tris
  * Agrégats
  * Parallélisme
</div>

<div class="notes">
</div>

-----

## Sécurité

<div class="slide-content">
  * FIXME
</div>

<div class="notes">
</div>

-----

## Administration

<div class="slide-content">
  * FIXME
<div class="notes">
</div>

-----


## Compatibilité

<div class="slide-content">
  * Changements dans les outils
  * Les outils de la sphère Dalibo
</div>

<div class="notes">
</div>

-----

### Changements dans les outils

<div class="slide-content">
  * Changements de comportement :
    * FIXME

  * Fin de support ou suppression :
    * FIXME
</div>

<div class="notes">
Chaque version majeure introduit son lot d'incompatibilités, et il demeure
important d'opérer régulièrement, en fonction des contraintes métier, des mises
à jour de PostgreSQL.
</div>

-----

### Les outils de la sphère Dalibo

<div class="slide-content">
Les outils Dalibo sont en cours de mise à jour :

+----------------------+------------------------------------------------------+ 
| Outil                | Compatibilité avec PostgreSQL 11 |
+======================+======================================================+
| pgBadger             | ? |
+----------------------+------------------------------------------------------+
| pgCluu               | ? |
+----------------------+-----------------------------------------------------+
| ora2Pg               | ? |
+----------------------+------------------------------------------------------+
| pg_stat_kcache       | ? |
+----------------------+------------------------------------------------------+
| ldap2pg              | ? |
+----------------------+------------------------------------------------------+ 

</div>

<div class="notes">

Voici une grille de compatibilité des outils Dalibo au FIXME :

+----------------------+------------------------------------------------------+ 
| Outil                | Compatibilité avec PostgreSQL 11 |
+======================+======================================================+ 
| pg_activity          | ? |
+----------------------+------------------------------------------------------+
| check_pgactivity     | ? |
+----------------------+------------------------------------------------------+
| pgBadger             | ? |
+----------------------+------------------------------------------------------+
| pgCluu               | ? |
+----------------------+------------------------------------------------------+
| ora2Pg               | ? |
+----------------------+------------------------------------------------------+
| powa-archivist       | ? |
+----------------------+------------------------------------------------------+
| pg_qualstats         | ? |
+----------------------+------------------------------------------------------+
| pg_stat_kcache       | ? |
+----------------------+------------------------------------------------------+
| hypopg               | ? |
+----------------------+------------------------------------------------------+
| PAF                  | ? |
+----------------------+------------------------------------------------------+
| temboard             | ? |
+----------------------+------------------------------------------------------+
| ldap2pg              | ? |
+----------------------+------------------------------------------------------+ 

</div>

-----

## Futur

<div class="slide-content">
  * Branche de développement de la version 12 créée le FIXME
    * ... quelques améliorations déjà présentes
    * FIXME
</div>

<div class="notes">
La [roadmap](https://dali.bo/pg-roadmap) du projet détaille les prochaines
grandes étapes.

Les développements de la version 12 ont commencé. Les premiers commit fests
nous laissent entrevoir une continuité dans l'évolution des thèmes principaux
suivants : parallélisme, partitionnement et réplication logique. FIXME ?

Un bon nombre de commits ont déjà eu lieu, que vous pouvez consulter :
 FIXME 
  * septembre 2017  : <https://commitfest.postgresql.org/14/?status=4>
  * novembre : <https://commitfest.postgresql.org/15/?status=4>
  * janvier 2018 : <https://commitfest.postgresql.org/16/?status=4>
  * mars : <https://commitfest.postgresql.org/17/?status=4>

</div>

-----

## Questions

<div class="slide-content">
`SELECT * FROM questions;`
</div>

-----
# Atelier

<div class="slide-content">
À présent, place à l'atelier...

  * Installation
  * Découverte de PostgreSQL 11
  * TODO
</div>

-----

## Installation

<div class="notes">
Les machines de la salle de formation utilisent CentOS 6. L'utilisateur dalibo 
peut utiliser sudo pour les opérations système.

FIXME

Le site postgresql.org propose son propre dépôt RPM, nous allons donc 
l'utiliser pour installer PostgreSQL 11.

On commence par installer le RPM du dépôt `pgdg-centos10-10-1.noarch.rpm` :

```
# export pgdg_yum=https://download.postgresql.org/pub/repos/yum/
# wget $pgdg_yum/testing/10/redhat/rhel-6-x86_64/pgdg-centos10-10-1.noarch.rpm
# yum install -y pgdg-centos10-10-1.noarch.rpm
Installing:
 pgdg-centos10                     noarch                     10-1

# yum install -y postgresql10 postgresql10-server postgresql10-contrib
Installing:
 postgresql10                        x86_64                10.0-beta4_1PGDG.rhel6
 postgresql10-contrib                x86_64                10.0-beta4_1PGDG.rhel6
 postgresql10-server                 x86_64                10.0-beta4_1PGDG.rhel6
Installing for dependencies:
 postgresql10-libs                   x86_64                10.0-beta4_1PGDG.rhel6
```

On peut ensuite initialiser une instance :

```
# service postgresql-10 initdb
Initializing database:                                     [  OK  ]
```

Enfin, on démarre l'instance, car ce n'est par défaut pas automatique sous 
RedHat et CentOS :

```
# service postgresql-10 start
Starting postgresql-10 service:                            [  OK  ]
```

Pour se connecter à l'instance sans modifier `pg_hba.conf` :

```
# sudo -iu postgres /usr/pgsql-10/bin/psql
```

Enfin, on vérifie la version :

```sql
postgres=# SELECT version();
                                      version
--------------------------------------------------------------------------------
 PostgreSQL 10beta4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.4.7 20120313
 (Red Hat 4.4.7-18), 64-bit
(1 ligne)
```

On répète ensuite le processus d'installation de façon à installer PostgreSQL 
9.6 aux côtés de PostgreSQL 10.

Le RPM du dépôt est `pgdg-centos96-9.6-3.noarch.rpm` :

```
# export pgdg_yum=https://download.postgresql.org/pub/repos/yum/
# wget $pgdg_yum/9.6/redhat/rhel-6-x86_64/pgdg-centos96-9.6-3.noarch.rpm
# yum install -y pgdg-centos96-9.6-3.noarch.rpm
Installing:
 pgdg-centos96                    noarch                    9.6-3

# yum install -y postgresql96 postgresql96-server postgresql96-contrib
Installing:
 postgresql96                      x86_64        9.6.5-1PGDG.rhel6
 postgresql96-contrib              x86_64        9.6.5-1PGDG.rhel6
 postgresql96-server               x86_64        9.6.5-1PGDG.rhel6
Installing for dependencies:
 postgresql96-libs                 x86_64        9.6.5-1PGDG.rhel6

# service postgresql-9.6 initdb
Initializing database:                                     [  OK  ]

# sed -i "s/#port = 5432/port = 5433/" \
  /var/lib/pgsql/9.6/data/postgresql.conf

# service postgresql-9.6 start
Starting postgresql-9.6 service:                           [  OK  ]

# sudo -iu postgres /usr/pgsql-9.6/bin/psql -p 5433
```

Dans cet atelier, les différentes sorties des commandes `psql` utilisent :

```
\pset columns 80
\pset format wrapped 
```
</div>

-----

## Ici un TP...

<div class="notes">



</div>

