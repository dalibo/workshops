---
subtitle : 'Workshop PgBouncer'
title : 'Déployer un pooler de connexion pour PostgreSQL'
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

Ce module aborde le déploiement, la configuration et l'exploitation de _PgBouncer_.

# Présentation de PgBouncer

_PgBouncer_ est un outil spécialisé conçu avec des objectifs clairs et précis.
Son rôle principal est de fonctionner comme un _pool_ de connexions, une tâche qu'il accomplit avec un souci
constant d'efficacité. _PgBouncer_ se distingue par sa légèreté, une caractéristique essentielle qui lui permet
d'offrir des performances optimales. Cependant, cette recherche de légèreté n'entrave pas sa capacité à
intégrer un large éventail de fonctionnalités pertinentes. _PgBouncer_ réussit à fournir un service hautement
spécialisé et efficace, ce qui en fait un choix privilégié pour la gestion des connexions PostgreSQL.

# Installation

## Pré-requis

- Avoir le dépôt **PGDG** (PostgreSQL Global Development Group) de configuré 
- PostgreSQL et _pglift_ (consulter le _workshop Compréhension et utilisation de pglift_)
- Déployer une instance PostgreSQL avec _pglift_

## Installation de pgbouncer

Installer le paquet `pgbouncer` :

```bash
$ dnf install pgbouncer
```

# Configuration de PostgreSQL

Les connexions se font avec l’utilisateur `pooler` que nous allons créer :
```bash
pglift role create --login pooler --password Passw0rd
```

Ajouter cette ligne dans le fichier `pg_hba.conf` :
```
host    all      pooler      127.0.0.1/32     scram-sha-256
```

Recharger la configuration de PostgreSQL :
```bash
pglift instance reload main
```

# Configuration de PgBouncer

La configuration se fait dans `/etc/pgbouncer/pgbouncer.ini`.

Dans la section `[databases]` on spécifie la chaîne de connexion à l’instance, pour toutes les bases de données :
```ini
* = host=127.0.0.1 port=5432
```

De plus il faut préciser dans `pgbouncer.ini`, que l'authentification est de type `scram-sha-256` :
```ini
auth_type = scram-sha-256
```

Ensuite ajouter l’utilisateur `pooler` au fichier `/etc/pgbouncer/userlist.txt` sous la forme
`"user" "hachage du mot de passe"`.

Pour récupérer le hachage du mot de passe, interroger la vue pg_shadow de l’instance PostgreSQL :
\scriptsize

```
postgres=# SELECT usename,passwd FROM pg_shadow WHERE usename = 'pooler';
 usename |                                                                passwd                                                                 
---------+---------------------------------------------------------------------------------------------------------------------------------------
 pooler  | SCRAM-SHA-256$4096:Zi2AnxTlUYbVRyjfVKZqsQ==$3y3mGmiw4ZRXeo2SKOpnuM0MtKecA4soVAvtwvL51YE=:YQiYvNyVRmAd+JjYNAuBmhdNbSaOQEvLOQLmbXer7io=
(1 row)
```

\normalsize

Le fichier `/etc/pgbouncer/userlist.txt` contiendra donc :

\scriptsize

```
"pooler" "SCRAM-SHA-256$4096:Zi2AnxTlUYbVRyjfVKZqsQ==$3y3mGmiw4ZRXeo2SKOpnuM0MtKecA4soVAvtwvL51YE=:YQiYvNyVRmAd+JjYNAuBmhdNbSaOQEvLOQLmbXer7io="
```

\normalsize

# Démarrage de PgBouncer

Le démarrage de _PgBouncer_ se fait à l'aide de `systemctl` :  
```bash
sudo systemctl start pgbouncer
```

Après son démarrage, vérifier le statut du service `pgbouncer` :
```bash
sudo systemctl status pgbouncer
```

La connexion à l'instance PostgreSQL directement depuis le _pooler_ doit fonctionner :
```bash
psql -h 127.0.0.1 -p 6432 -U pooler -d postgres
```

# Administration de PgBouncer

Dans le fichier `pgbouncer.ini`, activer l’accès à la pseudo-base `pgbouncer` pour les utilisateurs `postgres` et `pooler` :
```
;; comma-separated list of users who are allowed to change settings
admin_users = postgres, pooler

;; comma-separated list of users who are just allowed to use SHOW command
stats_users = stats, postgres, pooler
```

Recharger la configuration de _PgBouncer_:
```bash
$ systemctl reload pgbouncer
```

Si une connexion via _PgBouncer_ est ouverte par ailleurs, on la retrouve ici :
```
$ psql -h 127.0.0.1 -p 6432 -U pooler -d pgbouncer

pgbouncer=# SHOW POOLS\gx
-[ RECORD 1 ]---------+----------
database              | pgbouncer
user                  | pgbouncer
cl_active             | 1
cl_waiting            | 0
cl_active_cancel_req  | 0
cl_waiting_cancel_req | 0
sv_active             | 0
sv_active_cancel      | 0
sv_being_canceled     | 0
sv_idle               | 0
sv_used               | 0
sv_tested             | 0
sv_login              | 0
maxwait               | 0
maxwait_us            | 0
pool_mode             | statement
-[ RECORD 2 ]---------+----------
database              | postgres
user                  | pooler
cl_active             | 0
cl_waiting            | 0
cl_active_cancel_req  | 0
cl_waiting_cancel_req | 0
sv_active             | 0
sv_active_cancel      | 0
sv_being_canceled     | 0
sv_idle               | 0
sv_used               | 1
sv_tested             | 0
sv_login              | 0
maxwait               | 0
maxwait_us            | 0
pool_mode             | session
```

# Pooling

## Par session

Le _pooling_ par session est le mode par défaut de _PgBouncer_.

Réaliser 2 connexions à via _PgBouncer_ depuis deux sessions différentes :
```
$ psql -h 127.0.0.1 -p 6432 -U pooler -d postgres
```bash
# à faire dans deux sessions différentes
$ psql -h 127.0.0.1 -p 6432 -U pooler -d postgres
```

À l'aide de la vue `pg_stat_activity`, consulter le nombre de connexions avec le rôle
`pooler` :
```
postgres=> SELECT COUNT(*) FROM pg_stat_activity
WHERE backend_type='client backend' AND usename='pooler' ;
 count
-------
     2
(1 row)
```

_PgBouncer_ a donc bien ouvert autant de connexions côté serveur que côté _pooler_.

## Par transaction

Dans le fichier `pgbouncer.ini`, modifier le paramètre `pool_mode` :
```
;; When server connection is released back to pool:
;;   session      - after client disconnects (default)
;;   transaction  - after transaction finishes
;;   statement    - after statement finishes
pool_mode = transaction
```

Il est également possible de le modifier dans la définition des connexions :
```
* = host=127.0.0.1 port=5432 pool_mode=transaction
```

Redémarrer le service `pgbouncer`:
```bash
$ systemctl restart pgbouncer
```

Créer une base de données `db1` avec le rôle `pooler` comme propriétaire :
```bash
$ pglift database create db1 --owner pooler
```

Successivement et à chaque fois dans une transaction, créer une table dans une des
sessions ouvertes, puis dans l’autre insérer des données.

Dans une première connexion :
```
$ psql -h 127.0.0.1 -p 6432 -U pooler -d db1

db1=> BEGIN;
db1=*> CREATE TABLE log (i timestamptz) ;
db1=*> COMMIT ;
```

Dans la deuxième :
```
$ psql -h 127.0.0.1 -p 6432 -U pooler -d db1
db1=> BEGIN ;
db1=*> INSERT INTO log SELECT now() ;
db1=*> COMMIT ;
```

Maintenant, commencer la seconde transaction avant la fin de la première.

Session 1 :
```
db1=> BEGIN ; INSERT INTO log SELECT now() ;
```

Session 2 :
```
db1=> BEGIN ; INSERT INTO log SELECT now() ;
```

De manière transparente, une deuxième connexion au serveur a été créée :
```
$ psql -h 127.0.0.1 -p 6432 -U pooler -d pgbouncer

pgbouncer=# SHOW POOLS \gx

-[ RECORD 1 ]---------+------------
database              | db1
user                  | pooler
cl_active             | 2
cl_waiting            | 0
cl_active_cancel_req  | 0
cl_waiting_cancel_req | 0
sv_active             | 2
sv_active_cancel      | 0
sv_being_canceled     | 0
sv_idle               | 0
sv_used               | 0
sv_tested             | 0
sv_login              | 0
maxwait               | 0
maxwait_us            | 0
pool_mode             | transaction
```

On s'aperçoit que deux connexions sont utilisées pour les deux transactions passées.

Commiter les transactions sur chaque session :
```
db1=*> COMMIT;
```

## Par requête

Dans le fichier `pgbouncer.ini`, modifier le paramètre `pool_mode` à `statement`:

```
;; When server connection is released back to pool:
;;   session      - after client disconnects (default)
;;   transaction  - after transaction finishes
;;   statement    - after statement finishes
pool_mode = statement
```

Redémarrer le service `pgbouncer`:
```bash
$ sudo systemctl restart pgbouncer
```

Tenter d'initialiser une transaction :
```
$ psql -h 127.0.0.1 -p 6432 -U pooler -d db1

db1=> BEGIN;
FATAL:  transaction blocks not allowed in statement pooling mode
server closed the connection unexpectedly
        This probably means the server terminated abnormally
        before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
```

Le _pooling_ par requête empêche l’utilisation de transactions.
