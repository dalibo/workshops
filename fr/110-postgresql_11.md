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

## Limiter la profondeur de la table des matières
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
  * Version beta 1 sortie 24 Mai 2018
  * 2e bêta sortie le 28 Juin 2018
  * Sortie de la version final : Fin 2018
  * Est composé de plus de 1,5 millions de lige de code (1,509,660)
  * Des centaines de contributeurs
</div>

<div class="notes">

FIXME
Le développement de la version 11 a suivi l'organisation habituelle : un
démarrage mi 2017, des Commit Fests tous les deux mois, un Feature Freeze en
mars, une première version beta fin mai.

La version finale est sortie le XX octobre 2018.

La version 11 de PostgreSQL contient plus de 1,5 millions de lignes de code *C*.
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
  * Partitionnement
  * Performances
  * Sécurité et intégrité
  * Instructions SQL
  * Outils
  * Réplication
  * Compatibilité FIXME à garder ???
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

## Nouveautés sur le partitionnement
<div class="slide-content">
 
  * Partitionnment par hachage
  * Création d'index automatique
  * Support de clé primaires et clé étrangères
  * Mise à jour de la clé de partition
  * Partitionnement par défaut
  * Amélioration des performances
  * Clause `INSERT ON CONFLICT`
  * Trigger `FOR EACH ROW`

</div>

<div class="notes">
Le partitionnement natif était une fonctionnalité très attendu de PostgreSQL 10. Cependant, elle souffrait de plusieurs limitations qui pouvaient dissuader de l'utilisation de celui ci.
La version 11 apporte plusieurs améliorations au niveau du partitionnement et corrige certaines limites impactant la version 10.

</div>

-----

### Partitionnement par hachage
<div class="slide-content">
  * répartition des données suivant la valeur de hachage de la clé de partition
  * très utile pour les partitions destinées à grandir
  * accéleration des `VACUUM`
</div>

<div class="notes">
Le partitionnement par hachage permet de répartir les données sur plusieurs partitions selon la valeur de hachage de la clé de partition.
Il va être utile pour les partitions destinées à s’agrandir et pour rendre plus rapide les opérations de VACUUM.

FIXME précision sur si et comment on peut étendre davantage les données en créant une nouvelle partition ?

</div>

-----

### Exemple de partitionnement par hachage
<div class="slide-content">
  * Créer une table partitionnée : 
  ```CREATE TABLE t1(c1 int) PARTITION BY HASH (c1)```
  * Ajouter une partition :
  ```CREATE TABLE t1_a PARTITION OF t1 FOR VALUES WITH (modulus 3,remainder 0)```
</div>

<div class="note">
</div>

-----

### Création d'INDEX automatique
<div class="slide-content">
  * création d'un index sur une table partitionnée possible
  * l'index est créé sur chaque partition
  * création automatique sur toute nouvelle partition
  * mise à jour de l'index possible (???)

</div>

<div class="notes">
En version 10 Il n'était pas possible de créer un index sur une table partitionnée.

FIXME ajout d'un exemple en version 10

En version 11 FIXME

Création d'index sur une table partitionnée :
```sql
b1=# \d articles_a
                  Table "public.articles_a"
 Column  |       Type        | Collation | Nullable | Default
---------+-------------------+-----------+----------+---------
 title   | character varying |           |          |
 content | text              |           |          |
Partition of: articles FOR VALUES IN ('title1', 'title2', 'title3')
Indexes:
    "articles_a_title_idx" btree (title)

```
</div>

-----

### Support des clés primaires
<div class="slide-content">
  * Support des index `UNIQUE`
  * Permet la création de clés primaires
</div>

<div class="notes">

Création de contrainte unique sur une table partitionnée :

FIXME comparaison v10 et ordre de création ?
```sql
\d logs
                            Table "public.logs"
   Column   |            Type             | Collation | Nullable | Default
------------+-----------------------------+-----------+----------+---------
 created_at | timestamp without time zone |           |          |
 content    | text                        |           |          |
Partition key: RANGE (created_at)
Indexes:
    "logs_created_at_content_key" UNIQUE CONSTRAINT, btree (created_at, content)
Number of partitions: 0

Permet la création de clés primaires.

</div>

-----

### Support des clés étrangères
<div class="slide-content">
  * Support de clé étrangère vers une table non partitionnée
  * Une clé étrangère d'une colonne d'une table partitionnée est toujours
  impossible

</div>

<div class="notes">

FIXME définition de la table livre ?

En version 10 les clés étrangères ne sont pas supportées dans une partition :
```sql

CREATE TABLE auteur (nom text, num_livre int REFERENCES livres(num)) PARTITION BY LIST (nom);
ERROR:  foreign key constraints are not supported on partitioned tables
LIGNE 1 : CREATE TABLE auteur (nom text, num_livre int REFERENCES livr...

```

La version 11 supporte les clées étrangères sur les partitions.
```sql
CREATE TABLE auteur (nom text, num_livre int REFERENCES livres(num)) PARTITION BY LIST (nom);
CREATE TABLE
```


FIXME clés étrangères vers une table partitionnée toujours impossible

</div>

-----

### Mise à jour d'une valeur de la clé de partition
<div class="slide-content">

  * En version 10 : `DELETE` puis `INSERT`
  * En version 11, la mise à jour fonctionne avec la commande UPDATE
  * la ligne est alors déplacée dans une nouvelle partition

</div>

<div class="notes">

En version 10 il n'était pas possible de mettre à jour une clé de partition entre deux partition différentes avec la commande UPDATE, il était nécessaire de faire un DELETE puis un INSERT

</div>

-----

### Partition par défaut
<div class="slide-content">

  * contiendra toutes les données n'appartenant à aucune des autres partitions
  ```CREATE TABLE articles_default PARTITION OF articles DEFAULT;```

</div>

<div class="notes">

En version 10 PostgreSQL générait une erreur lorsque les données n'appartenaient à aucune partitions.

FIXME que se passe-t-il quand on crée une partition correspondant à des lignescontenues dans la parition par défaut ?


</div>

-----
### Meilleures performances des SELECT
<div class="slide-content">
  * Élagage dynamique des partitions
  * Control Partition Pruning
</div>

<div class="notes">
FIXME
</div>

-----

### Autres nouveautés du partitionnement
<div class="slide-content">
  * Clause `INSERT ON CONFLICT`
  * _Partition-Wise Aggregate_
  * `FOR EACH ROW trigger`
</div>


<div class="notes">

En version 10, la clause **ON CONFLICT** n'était pas supporté sur le partitionnement :
```sql
b1=# insert into articles values ('title2') on conflict do nothing;
ERREUR:  la clause ON CONFLICT n'est pas supporté avec les tables partitionnées
```

En version 11 la clause fonctionne :
```sql
b1=# insert into articles values ('title2') on conflict do nothing;
INSERT 0 1
```
</div>

-----

## Performances

<div class="slide-content">
  * compilation Just In Time (JIT)
  * parallélisme

</div>

<div class="notes">
</div>

-----


### JIT
<div class="slide-content">

  * Support de la compilation Just In Time
  * Diminue le temps d’exécution des requêtes

</div>

<div class="notes">
</div>

-----

### Parallélisation
<div class="slide-content">

**Améliorations du parallélisme**

  * Parallélisation sur les types de jointures Hash
  * Parallélisation des types de noeud Append
  * CREATE TABLE AS SELECT statement
  * CREATE MATERIALIZED VIEW
  * SELECT INTO statement
  * CREATE INDEX statement
</div>

<div class="notes">
</div>

-----

## Sécurité et intégrité

<div class="slide-content">

  * SCRAM
  * Nouveaux rôles
  * Vérification d'intégrité

</div>

-----

### SCRAM
<div class="slide-content">

  * Agrégation de canaux sur l'authentification **SCRAM**
  * Permet d'éviter des attaques de type **Man in the midddle**

</div>

<div class="notes">
</div>

-----

### Nouveaux rôles
<div class="slide-content">
  * **pg_read_server_files** : permet la lecture de fichier sur le serveur
  * **pg_write_server_files** : permet la modification de fichier sur le serveur
  * **pg_execute_server_program** : permet l'execution de fichier sur le serveur

</div>

<div class="notes">
Ajout de nouveaux rôles... FIXME

</div>

-----

### Vérification d'intégrité
<div class="slide-content">
  * nouvelle commande `pg_verify_checksums`
  * vérification des sommes de contrôles dans `pg_basebackup`
  * nouveau module `amcheck`
</div>

<div class="notes">
commande `pg_verify_checksums` est à froid.

`amcheck` vérifie que chaque ligne possède une entrée dans les index.

</div>

-----


## Instructions SQL
<div class="slide-content">

  * Index couvrants
    * `CREATE INDEX ... INCLUDE`
  * VACUUM tables multiples
    * VACUUM t1, t2;
  * support fonction fenêtrage SQL:2011
  * LOCK VIEW
  * objets PROCEDURES
  * Définir le seuil de conversion en TOAST depuis l'ordre CREATE TABLE
  * Opérateur ^@ similaire à LIKE

</div>

<div class="notes">
</div>

### Fonctions de fenêtrage

<div class="slide-content">
    * Support de l'intégralité des fonctions de fenêtrage de la norme **SQL:2011**
      * https://www.depesz.com/2018/02/13/waiting-for-postgresql-11-support-all-sql2011-options-for-window-frame-clauses/
</div>

-----

### PL/pgSQL
<div class="slide-content">
  * Création d'objets **PROCEDURES**
    * Similaires au fonctions mais ne retournant aucune valeur.
  * Ajout d'une clause **CONSTANT** à une variable
  * Contrainte **NOT NULL** à une variable
  * Ordre `SET TRANSACTION` dans un bloc

</div>

-----

### JSON

<div class="slide-content">
  * Index Surjectif
  * TRANSFORM FOR TYPE Json
  * LOCK TABLE view
</div>

-----

## Outils
<div class="slide-content">

  * `psql`
  * `initdb`
  * `pg_dump` et `pg_dumpall`
  * `pg_basebackup`
  * `pg_rewind`

</div>

-----

### psql
<div class="slide-content">
 
  * `SELECT ... FROM ... \gdesc`
    * types des colonnes
    * ou `\gdesc` seul après exécution
  * Variables de suivi des erreurs de requêtes
    * `ERROR`, `SQLSTATE` et `ROW_COUNT`
  * `exit` et `quit` à la place de `\q` pour quitter psql
  * fonctionnalités psql, donc utilisable sur des bases < 11

</div>
<div class="notes">
PostgreSQL 11 apporte quelques améliorations notables au niveau des commandes psql.

La commande `\gdesc` retourne le nom et le type des colonnes de la dernière requête exécutée.
```sql
workshop11=# select * from t1;
 c1 
----
  1
  2
  3
  4
  5
  6
  7
  8
  9
 10
(10 rows)

workshop11=# \gdesc
 Column |  Type   
--------+---------
 c1     | integer
(1 row)
```

On peut aussi tester les types retournés par une requête sans l'exécuter :
```sql
workshop11=# select 3.0/2 as ratio, now() as maintenant \gdesc
   Column   |           Type           
------------+--------------------------
 ratio      | numeric
 maintenant | timestamp with time zone
```

Les variables `ERROR`, `SQLSTATE` et `ROW_COUNT` permettent de suivre l'état de la dernière requête exécutée. 
```sql
workshop11=# \d t1
                 Table "public.t1"
 Column |  Type   | Collation | Nullable | Default 
--------+---------+-----------+----------+---------
 c1     | integer |           |          | 

workshop11=# select c2 from t1;
ERROR:  column "c2" does not exist
```

La variable `ERROR` renvoie une valeur booléenne précisant si la dernière requête exécutée a bien reçu un message d'erreur. 
```sql
workshop11=# \echo :ERROR
true
```

La variable `SQLSTATE` retourne le code de l'erreur ou 00000 s'il n'y a pas d'erreur. 
```sql
workshop11=# \echo :SQLSTATE 
42703
```

La variable `ROW_COUNT` renvoie le nombre de lignes retournées lors de l’exécution de la dernière requête. 
```sql
workshop11=# \echo :ROW_COUNT 
0
```

Il existe aussi les variable `LAST_ERROR_MESSAGE` et `LAST_ERROR_SQLSTATE` qui renvoient le dernier message d'erreur retourné et le code de la dernière erreur. 
```sql
workshop11=# \echo :LAST_ERROR_MESSAGE
column "c2" does not exist

workshop11=# \echo :LAST_ERROR_SQLSTATE 
42703
```

Les commandes `exit` et `quit` ont été ajoutées pour quitter psql afin que cela soit plus intuitif pour les nouveaux utilisateurs.

Toutes ces fonctionnalités sont liées à l'outil client psql, donc peuvent être utilisées même si le serveur reste dans une version antérieure.

</div>
-----

### initdb
<div class="slide-content">
  * option `--wal-segsize` : 
    * spécifie la taille des fichier WAL à l'initialisation (1 Mo à 1 Go)
  * option `--allow-group-access` :
    * Droits de lecture et d’exécution au groupe auquel appartient l'utilisateur initialisant l'instance.
    * Droit sur les fichiers : `drwxr-x---`
</div>


<div class="notes">
L'option `--wal-segsize` permet de spécifier la taille des fichiers WAL lors de l'initialisation de l'instance (et uniquement à ce moment). Toujours par défaut à 16 Mo, ils peuvent à présent aller de 1 Mo à 1 Go. Cela permet d'ajuster la taille en fonction de l'activité, principalement pour les instances générant beaucoup de journaux, surtout s'il faut les archiver.

Exemple pour des WAL de 1 Go  :
```bash
initdb -D /var/lib/postgresql/11/workshop --wal-segsize=1024
```

L'option `--allow-group-access` autorise les droits de lecture et d’exécution au groupe auquel appartient l'utilisateur initialisant l'instance. Droit sur les fichiers : `drwxr-x---`. Cela peut servir pour ne donner que des droits de lecture à un outil de sauvegarde.

</div>

-----

### Sauvegardes et restauration
<div class="slide-content">
  * `pg_dumpall`
    * option `--encoding` pour spécifier l'encodage de sortie
    * l'option `-g` ne charge plus les permissions et les configurations de variables
  * `pg_dump` et `pg_restore` gèrent maintenant les permissions et les configurations de variables
  * `pg_basebackup`
    * option `--create-slot` pour créer un slot de réplication.

</div>

<div class="notes">
Les permissions par `GRANT` et `REVOKE` et les configurations de variables par `ALTER DATABASE SET` et `ALTER ROLE IN DATABASE SET` sont gérées par `pg_dump`  et `pg_restore` et non plus par `pg_dumpall`.

`pg_dumpall` bénéficie d'une nouvelle option permettant de spécifier l'encodage de sortie d'un dump. 

Une nouvelle option `--create-slot` est disponible dans `pg_basebackup` permettant de créer directement un slot de réplication. Elle doit donc être utilisée en complément de l'option `--slot`. Le slot de réplication est conservé après la fin de la sauvegarde. Si le slot de réplication existe déjà, la commande `pg_basebackup` s’interrompt et affiche un message d'erreur.  
</div>

-----

### pg_rewind
<div class="slide-content">
  * `pg_rewind` : optimisations de fichiers inutiles
  * interdit en tant que root
  * possible avec un accès non-superuser sur le maître

</div>

<div class="notes">
`pg_rewind` est un outil permettant de reconstruire une instance secondaire qui a
« décroché » sans la reconstruire complètement, à partir d'un primaire.

Quelques fichiers inutiles sont à présent ignorés. La sécurité pour certains
environnements a été améliorée en interdisant le fonctionnement du binaire sous
root, et en permettant au besoin de n'utiliser qu'un utilisateur « normal »
sur le serveur primaire
(voir le blog de [Michael Paquier](https://paquier.xyz/postgresql-2/postgres-11-superuser-rewind/).
</div>

-----

## Réplication 
<div class="slide-content">
  * Réplication Logique
  * WAL et Checkpoint
</div>

<div class="notes">

</div>

-----

### Réplication Logique
<div class="slide-content">

  * Réplication des commandes `TRUNCATE`
  * Réduction de l'empreinte mémoire

</div>

<div class="notes">

Add a generational memory allocator which is optimized for serial allocation/deallocation (Tomas Vondra). This reduces memory usage for logical decoding.

</div>

-----

### WAL et Checkpoint
<div class="slide-content">
  * Suppression du second checkpoint
  * Remplissage des portions de WAL non utilisés par des 0
</div>

<div class="notes">
https://paquier.xyz/postgresql-2/postgres-11-secondary-checkpoint/

En cas de changement forcé de fichier WAL, la portion de WAL non utilisée est replie par des 0. Cela permet une meilleure compression des fichiers en cas d'archivage.
</div>

-----


## Compatibilité

<div class="slide-content">
  * Changements dans les outils (¿¿ à garder ??)
  * Les outils de la sphère Dalibo
</div>

<div class="notes">
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
  * septembre 2018 : <https://commitfest.postgresql.org/14/?status=4>
  * novembre : <https://commitfest.postgresql.org/15/?status=4>
  * janvier 2019 : <https://commitfest.postgresql.org/16/?status=4>
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
  * Mise à jour PostgreSQL 10 vers 11 avec la réplication Logique.
  * Mise à jour d'une partition avec un `UPDATE`.
  * Tester le support de `TRUNCATE` avec la réplication logique.
  * Création d'un partitionnement par `hachage`.
  * Tester les nouveaux rôles
  * Création de slot avec pg_basebackup
  * Parallélisation
  * Index couvrants
  * Élagage de partition

</div>

-----

## Installation

<div class="notes">
Les machines de la salle de formation utilisent CentOS 6. L'utilisateur dalibo
peut utiliser sudo pour les opérations système.

FIXME toujours en beta2 ?

Le site postgresql.org propose son propre dépôt RPM, nous allons donc
l'utiliser pour installer PostgreSQL 11.

On commence par installer le RPM du dépôt `pgdg-centos11-11-2.noarch.rpm` :

```
# pgdg_yum=https://download.postgresql.org/pub/repos/yum/
# pgdg_yum+=testing/11/redhat/rhel-6.9-x86_64/pgdg-centos11-11-2.noarch.rpm
# yum install -y $pgdg_yum
Installed:
  pgdg-centos11.noarch 0:11-2

# yum install -y postgresql11 postgresql11-contrib postgresql11-server

Installed:
  postgresql11.x86_64 0:11.0-beta2_1PGDG.rhel6                  postgresql11-contrib.x86_64 0:11.0-beta2_1PGDG.rhel6                  postgresql11-server.x86_64 0:11.0-beta2_1PGDG.rhel6                 
Dependency Installed:
  libicu.x86_64 0:4.2.1-14.el6                               libxslt.x86_64 0:1.1.26-2.el6_3.1                               postgresql11-libs.x86_64 0:11.0-beta2_1PGDG.rhel6
```

On peut ensuite initialiser une instance :

```
# service postgresql-11 initdb
Initializing database:                                     [  OK  ]
```

Enfin, on démarre l'instance, car ce n'est par défaut pas automatique sous
RedHat et CentOS :

```
# service postgresql-11 start
Starting postgresql-11 service:                            [  OK  ]
```

Pour se connecter à l'instance sans modifier `pg_hba.conf` :

```
# sudo -iu postgres /usr/pgsql-11/bin/psql
```

Enfin, on vérifie la version :

```sql
postgres=# select version();
                                                  version                                                   
------------------------------------------------------------------------------------------------------------
 PostgreSQL 11beta2 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.4.7 20120313 (Red Hat 4.4.7-18), 64-bit
```

On répète ensuite le processus d'installation de façon à installer PostgreSQL
10 aux côtés de PostgreSQL 11.

Le RPM du dépôt est `pgdg-centos10-10-2.noarch.rpm` :

```
# pgdg_yum=https://download.postgresql.org/pub/repos/yum/
# pgdg_yum+=/10/redhat/rhel-6.9-x86_64/pgdg-centos10-10-2.noarch.rpm
# yum install -y $pgdg_yum 

Installed:
  pgdg-centos10.noarch 0:10-2     


# yum install -y postgresql10 postgresql10-contrib postgresql10-server
Installed:
  postgresql10.x86_64 0:10.4-1PGDG.rhel6                        postgresql10-contrib.x86_64 0:10.4-1PGDG.rhel6                        postgresql10-server.x86_64 0:10.4-1PGDG.rhel6                       

Dependency Installed:
  postgresql10-libs.x86_64 0:10.4-1PGDG.rhel6

# service postgresql-10 initdb
Initializing database:                                     [  OK  ]

# sed -i "s/#port = 5432/port = 5433/" \
  /var/lib/pgsql/10/data/postgresql.conf

# service postgresql-10 start
Starting postgresql-10 service:                           [  OK  ]

# sudo -iu postgres /usr/pgsql-10/bin/psql -p 5433
```

Dans cet atelier, les différentes sorties des commandes `psql` utilisent :

```
\pset columns 80
\pset format wrapped
```
</div>

-----

## Tester le support de TRUNCATE avec la réplication logique

<div class="notes">
Le test se déroulera à partir de deux instances :
L'instance `data` est en écoute sur le port 5435.
L'instance `data2` est en écoute sur le port 5436.


Sur la première instance `data` dans la base `workshop11`,
création de la table `t1` et insertion de quelques valeurs :

```sql
workshop11=# CREATE TABLE t1 (c1 int);
CREATE TABLE
workshop11=# INSERT INTO t1 SELECT generate_series(1,10);
INSERT 0 10
workshop11=# SELECT * FROM t1;
 c1 
----
  1
  2
  3
  4
  5
  6
  7
  8
  9
 10
(10 rows)
```

Création de la publication `p1` :

```sql
workshop11=# CREATE PUBLICATION p1 FOR TAABLE t1;
CREATE PUBLICATION
```

Sur la deuxième instance `data2` dans la base `workshop11_2`,
création d'une table `t1` sans aucune donnée. 

```sql
workshop11_2=# CREATE TABLE t1 (c1 int);
CREATE TABLE
```
Création de la souscription `s1` : 
```sql
workshop11_2=# CREATE SUBSCRIPTION s1
               CONNECTION  'host=/tmp/ port=5435 dbname=workshop11' PUBLICATION p1;
NOTICE:  created replication slot "s1" on publisher
CREATE SUBSCRIPTION

```
Vérification de la réplication des données :

```sql
workshop11_2=# SELECT * FROM t1;
 c1 
----
  1
  2
  3
  4
  5
  6
  7
  8
  9
 10
(10 rows)
```
Sur l'instance `data` nous vidons la table avec la commande `TRUNCATE` :

```sql
workshop11=# TRUNCATE t1;
TRUNCATE TABLE 
```

La table `t1` est vide :

```sql
workshop11=# select * from t1;
 c1 
----
(0 rows)
```

Sur l'instance `data2` nous vérifions que la réplication a été effectuée et que la table a bien été vidée : 

```
workshop11_2=# select * from t1;
 c1 
----
(0 rows)
```

</div>

-----

## Index couvrants

<div class="notes">


Soit une table avec des données et une contrainte d'unicité sur 2 colonnes :
```sql
v11=# CREATE TABLE t2 (a int, b int, c varchar(10));
CREATE TABLE
v11=# INSERT INTO t2 (SELECT i, 2*i, substr(md5(i::text), 1, 10)
        FROM generate_series(1,10000000) AS i);
INSERT 0 10000000
v11=# CREATE UNIQUE INDEX t2_a_b_unique_idx ON t2 (a,b);
CREATE INDEX
```

Pour simplifier les plans, on désactive le parallélisme :
```sql
SET max_parallel_workers_per_gather TO 0 ;
```

En cas de recherche sur la colonne _a_, on va pouvoir récupérer les colonnes
_a_ et _b_ grâce à un _Index Only Scan_ :
```sql
v11=# EXPLAIN ANALYSE SELECT a,b FROM t2 WHERE a>110000 and a<158000;
                   QUERY PLAN
-----------------------------------------------------
 Index Only Scan using t2_a_b_unique_idx on t2
     (cost=0.43..1953.87 rows=1100 width=8)
     (actual time=0.078..28.066 rows=47999 loops=1)
   Index Cond: ((a > 1000) AND (a < 2000))
   Heap Fetches: 0
 Planning Time: 0.225 ms
 Execution Time: 12.628 ms
(5 lignes)
```

Cependant, si on veut récupérer également la colonne _c_, on passera par un
_Index Scan_ et un accès à la table :
```sql
v11=# EXPLAIN ANALYSE SELECT a,b,c FROM t2 WHERE a>110000 and a<158000;
                   QUERY PLAN
-----------------------------------------------------
 Index Scan using t2_a_b_unique_idx on t2
     (cost=0.43..61372.04 rows=46652 width=19)
     (actual time=0.063..13.073 rows=47999 loops=1)
   Index Cond: ((a > 110000) AND (a < 158000))
 Planning Time: 0.223 ms
 Execution Time: 16.034 ms
(4 lignes)
```

Dans notre exemple, le temps réel n'est pas vraiment différent entre les 2
requêtes. Si l'optimisation de cette requête est cependant cruciale, nous
pouvons créer un index spécifique incluant la colonne _c_ et permettre
l'utilisation d'un _Index Only Scan_ :
```sql
v11=# CREATE INDEX t2_a_b_c_idx ON t2 (a,b,c);
CREATE INDEX
v11=# EXPLAIN ANALYZE SELECT a,b,c FROM t2 WHERE a>110000 and a<158000;
                   QUERY PLAN
-----------------------------------------------------
 Index Only Scan using t2_a_b_c_idx on t2
     (cost=0.56..1861.60 rows=46652 width=19)
     (actual time=0.048..11.241 rows=47999 loops=1)
   Index Cond: ((a > 110000) AND (a < 158000))
   Heap Fetches: 0
 Planning Time: 0.265 ms
 Execution Time: 14.329 ms
(5 lignes)
```

La taille cumulée de nos index est de 602 Mo :
```sql
v11=# SELECT pg_size_pretty(pg_relation_size('t2_a_b_unique_idx'));
 pg_size_pretty 
----------------
 214 MB
(1 ligne)

v11=# SELECT pg_size_pretty(pg_relation_size('t2_a_b_c_idx'));
 pg_size_pretty 
----------------
 387 MB
(1 ligne)
```

En v11 nous pouvons utiliser à la place un seul index appliquant toujours la
contrainte d'unicité sur les colonnes _a_ et _b_ **et** couvrant la colonne
_c_ :
```sql
v11=# CREATE UNIQUE INDEX t2_a_b_unique_covering_c_idx ON t2 (a,b) INCLUDE (c);
CREATE INDEX
v11=# EXPLAIN ANALYZE SELECT a,b,c FROM t2 WHERE a>110000 and a<158000;
                   QUERY PLAN
----------------------------------------------------------
 Index Only Scan using t2_a_b_unique_covering_c_idx on t2
     (cost=0.43..1857.47 rows=46652 width=19)
     (actual time=0.045..11.945 rows=47999 loops=1)
   Index Cond: ((a > 110000) AND (a < 158000))
   Heap Fetches: 0
 Planning Time: 0.228 ms
 Execution Time: 14.263 ms
(5 lignes)
v11=# SELECT pg_size_pretty(pg_relation_size('t2_a_b_unique_covering_c_idx'));
 pg_size_pretty 
----------------
 386 MB
(1 ligne)
```

La nouvelle fonctionnalité sur les index couvrants nous a permit d'éviter la
création de 2 index pour un gain de 35% d'espace disque !

Noter que la colonne `c` est renseignée depuis l'index, mais elle n'est pas
triée (comme dans un index normal), et donc un `ORDER BY` n'en profite pas
(étape _Sort_ nécessaire) :
```sql
v11=# EXPLAIN SELECT * FROM t2 ORDER BY a,b ;
                   QUERY PLAN
----------------------------------------------------------
 Index Only Scan using t2_a_b_unique_covering_c_idx on t2 
             (cost=0.43..347752.43 rows=10000000 width=19)
```

```sql
v11=# EXPLAIN SELECT * FROM t2 ORDER BY a,b,c ;
                   QUERY PLAN
----------------------------------------------------------
 Sort  (cost=1736527.83..1761527.83 rows=10000000 width=19)
   Sort Key: a, b, c
   ->  Seq Scan on t2  (cost=0.00..163695.00 rows=10000000 width=19)
```


Les performances en insertion vont également être meilleures car un seul index
doit être maintenu :
```sql
v11=# EXPLAIN ANALYSE INSERT INTO t2 (SELECT i, 2*i, substr(md5(i::text), 1, 10)
        FROM generate_series(10000001,10100000) AS i);
                   QUERY PLAN
-------------------------------------------------------------
 Insert on t2
     (cost=0.00..25.00 rows=1000 width=46)
     (actual time=502.111..502.111 rows=0 loops=1)
   ->  Function Scan on generate_series i
           (cost=0.00..25.00 rows=1000 width=46)
	   (actual time=14.356..107.205 rows=100000 loops=1)
 Planning Time: 0.132 ms
 Execution Time: 502.594 ms
(4 lignes)
```

Si on supprime l'index couvrant et que l'on recrée les 2 index :
```sql
v11=# DROP INDEX t2_a_b_unique_covering_c_idx ;
DROP INDEX
v11=# CREATE UNIQUE INDEX t2_a_b_unique_idx ON t2 (a,b);
CREATE INDEX
v11=# CREATE INDEX t2_a_b_c_idx ON t2 (a,b,c);
CREATE INDEX
v11=# EXPLAIN ANALYSE INSERT INTO t2 (SELECT i, 2*i, substr(md5(i::text), 1, 10)
        FROM generate_series(10100001,10200000) AS i);
                   QUERY PLAN
-------------------------------------------------------------
 Insert on t2
     (cost=0.00..25.00 rows=1000 width=46)
     (actual time=842.455..842.455 rows=0 loops=1)
   ->  Function Scan on generate_series i
           (cost=0.00..25.00 rows=1000 width=46)
	   (actual time=14.708..127.441 rows=100000 loops=1)
 Planning Time: 0.155 ms
 Execution Time: 843.147 ms
(4 lignes)
```

On a un gain de performance à l'insertion de 40%.

</notes>
