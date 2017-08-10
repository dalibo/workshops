# Nouveautés de PostgreSQL 10

![PostgreSQL](medias/elephant-rock-valley-of-fire.jpg)

<div class="notes">
Photographie obtenue sur [urltarget.com](http://www.urltarget.com/elephant-rock-valley-of-fire.html "elephant-rock-valley-of-fire").

Public Domain CC0.
</div>

-----

## Introduction

<div class="slide-content">
  * Développement depuis août 2016
  * Version beta 1 sortie le 18 mai
  * Version beta 2 sortie le 13 juillet
  * Sortie de la release prévue deuxième moitié 2017
  * Plus de 1,4 millions de lignes de code *C*
  * Des centaines de contributeurs
</div>


<div class="notes">
Le développement de la version 10 a suivi l'organisation habituelle : un démarrage mi 2016, des Commit Fests tous les deux mois, un Feature Freeze en mars, une première version beta mi-mai. Le travail est actuellement à la stabilisation du code, la suppression des bugs, l'amélioration de la documentation. La version finale est prévue fin septembre/début octobre.

La version 10 de PostgreSQL contient plus de 1,4 millions de lignes de code *C*. Son développement est assuré par des centaines de contributeurs répartis partout dans le monde.

Si vous voulez en savoir plus sur le fonctionnement de la communauté PostgreSQL, une présentation récente de *Daniel Vérité* est disponible en ligne :

  * [Vidéo](https://youtu.be/NPRw0oJETGQ)
  * [Slides](https://dali.bo/daniel-verite-communaute-dev-pgday)
</div>

-----

### Au menu

<div class="slide-content">
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
PostgreSQL 10 apporte un grand nombre de nouvelles fonctionnalités, qui sont d'ores et déjà détaillées dans de nombreux articles. Voici 3 liens vers des articles en anglais :

  * [New in postgres 10](https://dali.bo/new-in-postgres-10 "new-in-postgres-10") du projet PostgreSQL
  * [New Features Coming in PostgreSQL 10](https://dali.bo/new-features-coming-in-postgresql-10 "new-features-coming-in-postgresql-10") de *Robert Haas*
  * [PostgreSQL 10 New Features With examples](https://dali.bo/hp-new-features-pg10 "hp-new-features-pg10") de *HP*

Actuellement, deux versions, [Beta1](https://dali.bo/pg10-beta1-changes "pg10-beta1-changes") et [Beta2](https://dali.bo/pg10-beta2-changes "pg10-beta2-changes"), ont été publiées.
</div>

-----

## Changements importants

<div class="slide-content">
  * Changement de la numérotation
  * Changement de noms
  * Changement de *pg_basebackup*
</div>

<div class="notes">
</div>

-----

### Nouveau système de numérotation des versions

<div class="slide-content">
Ancienne numérotation composée de 3 nombres :

```
  9 . 6 . 3 
  Majeure1 . Majeure2 . Mineure
```

Nouvelle numérotation exprimée sur 2 nombres uniquement :

```
  10 . 2
  Majeure . Mineure
```
</div>

<div class="notes">
La sortie de PostgreSQL 10 inaugure un nouveau système de numérotation des versions. Auparavant, chaque version était désignée par 3 nombres, comme *9.6.3*. La nouvelle numérotation sera désormais exprimée sur 2 nombres, *10.3* sera par exemple la troisième version mineure de la version majeure *10*.

L'ancienne numérotation posait problème aux utilisateurs, mais aussi aux développeurs. Pour les développeurs, à chaque nouvelle version majeure, la question se posait de changer le premier nombre ou les deux premiers nombres.  Ceci générait de grosses discussions et beaucoup de frustrations. En passant à un seul nombre pour la version majeure, ce problème disparait et les développeurs peuvent se concentrer sur un travail plus productif.

Pour les utilisateurs, principalement les nouveaux, cela apportait une confusion peu utile sur les mises à jour.

Vous trouverez plus de détails dans l'article de Josh Berkus disponible sur son [blog](https://dali.bo/changing-postgresql-version-numbering "changing-postgresql-version-numbering").
</div>

-----

### XLOG devient WAL

<div class="slide-content">
  * Au niveau des répertoires
    * *pg_xlog* -> *pg_wal*
    * *pg_clog* -> *pg_xact*
  * Au niveau des fonctions
    * *xlog* -> *wal*
    * *location* -> *lsn*
  * Au niveau des outils
    * *xlog* -> *wal*
</div>

<div class="notes">
Afin de clarifier le rôle de ces répertoires qui contiennent non pas des *logs* mais des journaux de transaction ou de commits, les deux renommages ont été effectués dans $PGDATA ainsi qu'au niveau des fonctions :

Voici le contenu actuel d'un répertoire de données PostgreSQL, tout de suite
après son initialisation :

```
drwx------. 5 postgres postgres  4096 Aug  3 17:24 base
drwx------. 2 postgres postgres  4096 Aug  3 17:24 global
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_commit_ts
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_dynshmem
-rw-------. 1 postgres postgres  4513 Aug  3 17:24 pg_hba.conf
-rw-------. 1 postgres postgres  1636 Aug  3 17:24 pg_ident.conf
drwx------. 4 postgres postgres  4096 Aug  3 17:24 pg_logical
drwx------. 4 postgres postgres  4096 Aug  3 17:24 pg_multixact
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_notify
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_replslot
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_serial
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_snapshots
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_stat
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_stat_tmp
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_subtrans
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_tblspc
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_twophase
-rw-------. 1 postgres postgres     3 Aug  3 17:24 PG_VERSION
drwx------. 3 postgres postgres  4096 Aug  3 17:24 pg_wal
drwx------. 2 postgres postgres  4096 Aug  3 17:24 pg_xact
-rw-------. 1 postgres postgres    88 Aug  3 17:24 postgresql.auto.conf
-rw-------. 1 postgres postgres 22746 Aug  3 17:24 postgresql.conf
```

De même pour les fonctions :

```
postgres=# select proname from pg_proc where proname like '%wal%' order by proname;
          proname
---------------------------
 pg_current_wal_flush_lsn
 pg_current_wal_insert_lsn
 pg_current_wal_lsn
 pg_is_wal_replay_paused
 pg_last_wal_receive_lsn
 pg_last_wal_replay_lsn
 pg_ls_waldir
 pg_stat_get_wal_receiver
 pg_stat_get_wal_senders
 pg_switch_wal
 pg_wal_lsn_diff
 pg_wal_replay_pause
 pg_wal_replay_resume
 pg_walfile_name
 pg_walfile_name_offset
(15 rows)
```

Pour les outils, cela concerne :

```
$ ls -l *wal*
-rwxr-xr-x. 1 postgres postgres 248832 Aug  2 11:09 pg_receivewal
-rwxr-xr-x. 1 postgres postgres 149576 Aug  2 11:09 pg_resetwal
-rwxr-xr-x. 1 postgres postgres 482344 Aug  2 11:09 pg_waldump
```

L'ensemble des contributions de l'écosystème PostgreSQL devra également s'adapter à ces changements de nommage. Il sera donc nécessaire avant de migrer à cette nouvelle version de vérifier que les outils d'administration, de maintenance et de supervision ont bien été rendus compatibles pour cette version.

Pour en savoir plus sur le sujet, vous pouvez consulter l'article intitulé [Rename “pg_xlog” directory to “pg_wal](https://dali.bo/waiting-for-postgresql-10-rename-pg_xlog-directory-to-pg_wal "waiting-for-postgresql-10-rename-pg_xlog-directory-to-pg_wal").
</div>

-----

### Changements dans pg_basebackup

<div class="slide-content">
  * Suppression de l'option *-x*
  * Modification de la méthode de transfert des WAL par défaut
    * *none* : pas de récupération des WAL
    * *fetch* : récupération des WAL à la fin de la copie des données
    * *stream* : streaming (par défaut)
  * Nommage des arguments longs
    * --xlog-method -> --wal-method
    * --xlogdir -> --waldir
</div>

<div class="notes">
Le projet PostgreSQL a considéré que dans la majeure partie des cas, les utilisateurs de *pg_basebackup* souhaitaient obtenir une copie cohérente des données, sans dépendre de l'archivage. La méthode *stream* est donc devenue le choix par défaut.
</div>

-----

## Partitionnement

<div class="slide-content">
  * Petit rappel sur l'ancien partitionnement
  * Nouveau partitionnement
  * Nouvelle syntaxe
  * Quelques limitations
</div>

<div class="notes">
</div>

-----

### Ancien partitionnement

<div class="slide-content">
  * Le partitionnement par héritage se base sur
    * la notion d'héritage (1 table mère et des tables filles)
    * des triggers pour orienter les insertions vers les tables filles
    * des contraintes d’exclusion pour optimiser les requêtes
  * Disponible depuis longtemps
</div>

<div class="notes">
Cette méthode ne répond pas à toutes les attentes du partitionnement, mais permet tout de même d'orienter les lignes en fonction de certains critères.

Elle permet également d'ajouter des colonnes dans les tables filles.
</div>

-----

### Nouveau partitionnement

<div class="slide-content">
  * Mise en place et administration simplifiée
    * car directement intégrée au moteur
  * Plus de trigger
    * insertions plus rapides
    * routage des données insérées dans la bonne partition
    * erreur si aucune partition destinataire
  * Partition
    * attacher/détacher une partition
    * contrainte implicite de partitionnement
    * expression possible pour la clé de partitionnement
    * sous-partitions possibles
  * Changement du catalogue système
    * nouvelles colonnes dans *pg_class*
    * nouveau catalogue *pg_partioned_table*
</div>

<div class="notes">
La version *10* apporte un nouveau système de partitionnement se basant sur de l'infrastructure qui existait déjà dans PostgreSQL.

Le but est de simplifier la mise en place et l'administration des tables
partitionnées. Des clauses spécialisées ont été ajoutées aux ordres SQL déjà
existant, comme *CREATE TABLE* et *ALTER TABLE*, pour ajouter, attacher,
détacher des partitions.

Au niveau de la simplification de la mise en place, on peut noter qu'il n'est
plus nécessaire de créer une fonction trigger et d'ajouter des triggers pour
gérer les insertions et mises à jour. Le routage est géré de façon automatique
par rapport à la définition des partitions. Si les données insérées ne
trouvent pas de partition cible, les données ne sont pas insérées dans la
table mère. L'insertion est tout simplement en erreur. Du fait de ce routage
automatique, les insertions se révèlent aussi plus rapides.

Le catalogue *pg_class* a été modifié et indique désormais :

  * si une table est en rapport avec le partitionnement (*relispartition = 't'* pour les deux)
  * si une table est partitionnée (*relkind = 'p'*) ou s'il s'agit d'une partition (*relkind = 'r'*)
  * la représentation interne des bornes du partitionnement (relpartbound)

Le catalogue *pg_partitioned_table* contient quant à lui les colonnes suivantes :

| Colonne       | Contenu                                                                                                                |
| ------------- | ---------------------------------------------------------------------------------------------------------------------- |
| partrelid     | OID de la table partitionnée référencé dans *pg_class*                                                                 |
| partstrat     | Stratégie de partitionnement ; l = partitionnement par liste, r = partitionnement par intervalle                       |
| partnatts     | Nombre de colonnes de la clé de partitionnement                                                                        |
| partattrs     | Tableau de partnatts valeurs indiquant les colonnes de la table faisant partie de la clé de partitionnement            |
| partclass     | Pour chaque colonne de la clé de partitionnement, contient l'OID de la classe d'opérateur à utiliser                   |
| partcollation | Pour chaque colonne de la clé de partitionnement, contient l'OID du collationnement à utiliser pour le partitionnement |
| partexprs     | Arbres d'expression pour les colonnes de la clé de partitionnement qui ne sont pas des simples références de colonne   |

Si on souhaite vérifier que la table partitionnée ne contient effectivement pas de données, on peut utiliser la clause *ONLY*, comme celà se faisait déjà avec l'héritage.

Lors de la déclaration des partitions, *FROM x TO y* indique que les données *supérieures ou égales à x* et *inférieures à y* (mais pas égales !) seront concernées.
</div>

-----

### Exemple de partitionnement liste

<div class="slide-content">
  * Créer une table partitionnée `create table t1(c1 integer, c2 text) partition by list (c1);`
  * Ajouter une partition `create table t1_a partition of t1 for values in (1, 2, 3);`
  * Détacher la partition `alter table t1 detach partition t1_a;`
</div>

<div class="notes">
Exemple complet :

```
postgres=# create table t1(c1 integer, c2 text) partition by list (c1);
CREATE TABLE
postgres=# create table t1_a partition of t1 for values in (1, 2, 3);
CREATE TABLE
postgres=# create table t1_b partition of t1 for values in (4, 5);
CREATE TABLE
postgres=# insert into t1 values (0);
ERROR:  no partition of relation "t1" found for row
DETAIL:  Partition key of the failing row contains (c1) = (0).
postgres=# insert into t1 values (1);
INSERT 0 1
postgres=# insert into t1 values (2);
INSERT 0 1
postgres=# insert into t1 values (5);
INSERT 0 1
postgres=# insert into t1 values (6);
ERROR:  no partition of relation "t1" found for row
DETAIL:  Partition key of the failing row contains (c1) = (6).
```
</div>

-----

### Exemple de partitionnement intervalle

<div class="slide-content">
  * Créer une table partitionnée `create table t2(c1 integer, c2 text) partition by range (c1);`
  * Ajouter une partition `create table t2_a partition of t2 for values from (1) to (100);`
  * Détacher la partition `alter table t2 detach partition t2_a;`
</div>

<div class="notes">
Exemple complet :

```
postgres=# create table t2(c1 integer, c2 text) partition by range (c1);
CREATE TABLE
postgres=# create table t2_a partition of t2 for values from (1) to (100);
CREATE TABLE
postgres=# insert into t2 values (0);
ERROR:  no partition of relation "t2" found for row
DETAIL:  Partition key of the failing row contains (c1) = (0).
postgres=# insert into t2 values (1);
INSERT 0 1
postgres=# insert into t2 values (2);
INSERT 0 1
postgres=# insert into t2 values (5);
INSERT 0 1
postgres=# insert into t2 values (101);
ERROR:  no partition of relation "t2" found for row
DETAIL:  Partition key of the failing row contains (c1) = (101).
```
</div>

-----

### Performances en insertion

<div class="slide-content">
```
postgres=# insert into t1 select i, 'toto' from generate_series(0, 9999999) i;
INSERT 0 10000000
Time: 10097.098 ms (00:10.097)
postgres=# checkpoint;
CHECKPOINT
Time: 501.660 ms
postgres=# insert into t2 select i, 'toto' from generate_series(0, 9999999) i;
INSERT 0 10000000
Time: 11448.867 ms (00:11.449)
postgres=# checkpoint;
CHECKPOINT
Time: 501.212 ms
postgres=# insert into t3 select i, 'toto' from generate_series(0, 9999999) i;
INSERT 0 0
Time: 125351.918 ms (02:05.352)
postgres=# checkpoint;
CHECKPOINT
Time: 802.073 ms
```
</div>

<div class="notes">
La table *t1* est une table non partitionnée :

```
CREATE TABLE t1 (c1 integer, c2 text);
```

La table *t2* est une table partitionnée utilisant les nouvelles
fonctionnalités de la version 10 :

```
create table t2 (c1 integer, c2 text) partition by range (c1);
create table t2_1 partition of t2 for values from (      0) to ( 1000000);
create table t2_2 partition of t2 for values from (1000000) to ( 2000000);
create table t2_3 partition of t2 for values from (2000000) to ( 3000000);
create table t2_4 partition of t2 for values from (3000000) to ( 4000000);
create table t2_5 partition of t2 for values from (4000000) to ( 5000000);
create table t2_6 partition of t2 for values from (5000000) to ( 6000000);
create table t2_7 partition of t2 for values from (6000000) to ( 7000000);
create table t2_8 partition of t2 for values from (7000000) to ( 8000000);
create table t2_9 partition of t2 for values from (8000000) to ( 9000000);
create table t2_0 partition of t2 for values from (9000000) to (10000000);
```

Enfin, la table *t3* est une table utilisant l'ancienne méthode de
partitionnement :

```
CREATE TABLE t3 (c1 integer, c2 text);
CREATE TABLE t3_1 (CHECK (c1 BETWEEN       0 AND  1000000)) INHERITS (t3);
CREATE TABLE t3_2 (CHECK (c1 BETWEEN 1000000 AND  2000000)) INHERITS (t3);
CREATE TABLE t3_3 (CHECK (c1 BETWEEN 2000000 AND  3000000)) INHERITS (t3);
CREATE TABLE t3_4 (CHECK (c1 BETWEEN 3000000 AND  4000000)) INHERITS (t3);
CREATE TABLE t3_5 (CHECK (c1 BETWEEN 4000000 AND  5000000)) INHERITS (t3);
CREATE TABLE t3_6 (CHECK (c1 BETWEEN 5000000 AND  6000000)) INHERITS (t3);
CREATE TABLE t3_7 (CHECK (c1 BETWEEN 6000000 AND  7000000)) INHERITS (t3);
CREATE TABLE t3_8 (CHECK (c1 BETWEEN 7000000 AND  8000000)) INHERITS (t3);
CREATE TABLE t3_9 (CHECK (c1 BETWEEN 8000000 AND  9000000)) INHERITS (t3);
CREATE TABLE t3_0 (CHECK (c1 BETWEEN 9000000 AND 10000000)) INHERITS (t3);

CREATE OR REPLACE FUNCTION insert_into() RETURNS TRIGGER
LANGUAGE plpgsql
AS $FUNC$
BEGIN
  IF NEW.c1    BETWEEN       0 AND  1000000 THEN
    INSERT INTO t3_1 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 1000000 AND  2000000 THEN
    INSERT INTO t3_2 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 2000000 AND  3000000 THEN
    INSERT INTO t3_3 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 3000000 AND  4000000 THEN
    INSERT INTO t3_4 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 4000000 AND  5000000 THEN
    INSERT INTO t3_5 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 5000000 AND  6000000 THEN
    INSERT INTO t3_6 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 6000000 AND  7000000 THEN
    INSERT INTO t3_7 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 7000000 AND  8000000 THEN
    INSERT INTO t3_8 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 8000000 AND  9000000 THEN
    INSERT INTO t3_9 VALUES (NEW.*);
  ELSIF NEW.c1 BETWEEN 9000000 AND 10000000 THEN
    INSERT INTO t3_0 VALUES (NEW.*);
  END IF;
  RETURN NULL;
END;
$FUNC$;

CREATE TRIGGER tr_insert_t3 BEFORE INSERT ON t3 FOR EACH ROW EXECUTE PROCEDURE insert_into();
```
</div>

-----

### Limitations

<div class="slide-content">
  * La table mère ne peut pas avoir de données
  * La table mère ne peut pas avoir d'index
    * ni PK, ni UK, ni FK pointant vers elle
  * Les partitions ne peuvent pas avoir de colonnes additionnelles
  * L'héritage multiple n'est pas permis
  * Les partitions n'acceptent les valeurs nulles que si la table partitionnée le permet
  * Les partitions distantes ne sont pour l'instant pas supportées
  * En cas d'attachement d'une partition
    * vérification du respect de la contrainte avec un parcours complet de la table
    * sauf si ajout au préalable d'une contrainte *CHECK* identique
</div>

<div class="notes">
FIXME: remplacement de UNBOUNDED par MINVALUE et MAXVALUE dans la beta3 ?

Toute donnée doit pouvoir être placée dans une partition. Dans le cas
contraire, la donnée ne sera pas placée dans la table mère (contrairement au
partitionnement traditionnel). À la place, une erreur sera générée :

ERROR:  no partition of relation "t2" found for row

De même, il n'est pas possible d'ajouter un index à la table mère, sous peine
de voir l'erreur suivante apparaître :

ERROR:  cannot create index on partitioned table "t1"

Ceci sous-entend qu'il n'est toujours pas possible de mettre une clé primaire,
et une contrainte unique sur ce type de table. De ce fait, il n'est pas non
plus possible de faire pointer une clé étrangère vers ce type de table.

Vous pouvez également consulter 4 articles avec des explications ainsi que des exemples concrets :

  * [Partitionnement et transaction autonomes avec PostgreSQL](https://dali.bo/pgday-2017-partitionnement "pgday-2017-partitionnement")
  * [Cool Stuff in PostgreSQL 10: Partitioned Audit Table](https://dali.bo/cool-stuff-in-postgresql-10-partitioned "cool-stuff-in-postgresql-10-partitioned")
  * [PostgreSQL 10 Built-in Partitioning](https://dali.bo/postgresql-10-built-in-partitioning "postgresql-10-built-in-partitioning")
  * [Implement table partitioning](https://dali.bo/waiting-for-postgresql-10-implement-table-partitioning "waiting-for-postgresql-10-implement-table-partitioning")

Enfin, si PostgreSQL apporte de nombreuses fonctionnalités nativement, il peut néanmoins être également pertinent d'utiliser l'extension [pg_partman](https://dali.bo/pg-partman "pg-partman").
</div>

-----

## Réplication logique

<div class="slide-content">
  * Petit rappel sur la réplication physique
  * Qu'est-ce que la réplication logique ?
  * Fonctionnement
  * Supervision
  * Exemples
</div>

<div class="notes">
</div>

-----

### Réplication physique

<div class="slide-content">
  * Réplication de toute l'instance
    * au niveau bloc
    * par rejeu des journaux de transactions
  * Quelques limitations :
    * on doit répliquer l’intégralité de l’instance
    * réplication impossible entre différentes architectures (x86, ARM…)
    * pas de requête en écriture sur le secondaire, donc impossible de créer des objets personnalisés
</div>

<div class="notes">
Dans le cas de la réplication dite « physique », le moteur ne réplique pas les requêtes mais le résultat de celles-ci. Plus précisément, les modifications des blocs de données.

Le serveur secondaire se contente de rejouer les journaux de transaction.
</div>

-----

### Réplication logique - Principe

<div class="slide-content">
  * Réutilisation de l'infrastructure existante
    * réplication en flux
    * slots de réplication
  * Réplique les changements sur une seule base de données
    * d'un ensemble de tables défini
  * Uniquement INSERT/UPDATE/DELETE
    * Pas les DDL, ni les TRUNCATE
</div>

<div class="notes">
Contrairement à la réplication physique, la réplication logique ne réplique pas les blocs de données. Elle décode le résultat des requêtes qui sont transmis au secondaire. Celui-ci applique les modifications SQL issues du flux de réplication logique.

La réplication logique utilise un système de publication/abonnement avec un ou plusieurs abonnés qui s'abonnent à une ou plusieurs publications d'un nœud particulier.

Une publication peut être définie sur n'importe quel serveur primaire de réplication physique. Le nœud sur laquelle la publication est définie est nommé éditeur. Le nœud où un abonnement a été défini est nommé abonné.

Une publication est un ensemble de modifications générées par une table ou un groupe de table. Chaque publication existe au sein d'une seule base de données.

Un abonnement définit la connexion à une autre base de données et un ensemble de publications (une ou plus) auxquelles l'abonné veut souscrire.
</div>

-----

### Fonctionnement

<div class="slide-content">
![Schema](medias/z100-schema-repli-logique.png)
</div>

<div class="notes">
Schéma obtenu sur [blog.anayrat.info](https://blog.anayrat.info/wp-content/uploads/2017/07/schema-repli-logique.png).

  * Une publication est créée sur le serveur éditeur.
  * L'abonné souscrit à cette publication, c’est un « souscripteur ».
  * Un processus spécial est lancé : le  « bgworker logical replication ». Il va se connecter à un slot de réplication sur le serveur éditeur.
  * Le serveur éditeur va procéder à un décodage logique des journaux de transaction pour extraire les résultats des ordres SQL.
  * Le flux logique est transmis à l'abonné qui les applique sur les tables.
</div>

-----

### Supervision

<div class="slide-content">
  * Nouveaux catalogues
    * pg_publication*
    * pg_subscription*
    * pg_stat_subscription
</div>

<div class="notes">
De nouveaux catalogues ont été ajoutés pour permettre la supervision de la réplication logique.

Notamment :
| pg_publication | informations sur les publications |
| pg_publication_tables | correspondance entre les publications et les tables qu'elles contiennent |
| pg_stat_subscription | état des journaux de transactions reçus en souscription |
| pg_subscription | informations sur les souscriptions existantes |
| pg_subscription_rel | contient l'état de chaque relation répliquée dans chaque souscription |

D'autres catalogues déjà existants peuvent également être utiles :
| pg_stat_replication | une ligne par processus d'envoi de WAL, montrant les statistiques sur la réplication vers le serveur standby connecté au processus |
| pg_replication_slot | liste des slots de réplication qui existent actuellement sur l'instance, avec leur état courant |
| pg_replication_origin_status | informations sur l'avancement du rejeu des transactions sur l'instance répliquée |
</div>

-----

### Exemple - Création d'une publication

<div class="slide-content">
  * Définir wal_level à logical
  * Initialiser une base de données et sauvegarder son schéma
  * Créer une publication `CREATE PUBLICATION ma_publication FOR ALL TABLES;`
</div>

<div class="notes">
**Exemple complet :**

Définir le paramètre `wal_level = logical` dans le fichier `postgresql.conf` des serveurs éditeurs et abonnés.

Initialiser une base de données :

```bash
$ createdb bench
$ pgbench -i -s 100 bench
```

Sauvegarder son schéma :

```bash
$ pg_dump --schema-only bench > bench-schema.sql
```

Créer la publication :

```
postgres@bench=# CREATE PUBLICATION ma_publication FOR ALL TABLES;
CREATE PUBLICATION
```

Une publication doit être créée par base de données. 

Elle liste les tables dont la réplication est souhaitée. 

L'attribut `FOR ALL TABLES` permet de ne pas spécifier cette liste. Pour utiliser cet attribut, il faut être super-utilisateur.

Créer ensuite l'utilisateur qui servira pour la réplication :

```bash
$ createuser --replication repliuser
```

Lui autoriser l'accès dans le fichier `pg_hba.conf` et lui permettre de visualiser les données dans la base :

```
postgres@bench=# GRANT SELECT ON ALL TABLES IN SCHEMA public TO repliuser;
GRANT
```
</div>


-----

### Exemple - Création d'une souscription

<div class="slide-content">
  * Initialiser une base de données et importer son schéma
  * Créer l'abonnement `CREATE SUBSCRIPTION ma_souscription CONNECTION 'host=127.0.0.1 port=5433 user=repliuser dbname=bench' PUBLICATION ma_publication;`
</div>

<div class="notes">
**Exemple complet :**

Initialiser la base de données et son schéma :

```bash
$ createdb bench
$ psql -f bench-schema.sql --single-transaction bench
```

Créer l'utilisateur pour la réplication :

```bash
createuser --replication repliuser
```

En tant que super-utilisateur, créer l'abonnement :

```
postgres@bench=# CREATE SUBSCRIPTION ma_souscription CONNECTION 'host=127.0.0.1 port=5433 user=repliuser dbname=bench' PUBLICATION ma_publication;
NOTICE:  created replication slot "ma_souscription" on publisher
CREATE SUBSCRIPTION
```
</div>

-----

### Exemple - Visualisation de l'état de la réplication

<div class="slide-content">
  * Sur l'éditeur
    * état de la réplication `select * from pg_stat_replication;`
    * slot de réplication `select * from pg_replication_slots;`
    * état de la publication `select * from pg_publication;`
    * contenu de la publication `select * from pg_publication_tables;`
  * Sur l'abonné
    * état de l'abonnement `select * from pg_subscription;`
    * état de la réplication `select * from pg_replication_origin_status;`
</div>

<div class="notes">
*pg_stat_replication*

```
postgres@bench=# select * from pg_stat_replication;
-[ RECORD 1 ]----+-----------------------------
pid              | 10299
usesysid         | 16407
usename          | repliuser
application_name | ma_souscription
client_addr      | 127.0.0.1
client_hostname  | 
client_port      | 49936
backend_start    | 2017-08-08 10:28:14.49455+02
backend_xmin     | 
state            | streaming
sent_lsn         | 0/4E3BCD08
write_lsn        | 0/4E3BCD08
flush_lsn        | 0/4E3BCD08
replay_lsn       | 0/4E3BCD08
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
```

*pg_replication_slots*

```
postgres@bench=# select * from pg_replication_slots;
    slot_name    |  plugin  | slot_type | datoid | database | temporary | active | active_pid | xmin | catalog_xmin | restart_lsn | confirmed_flush_lsn 
-----------------+----------+-----------+--------+----------+-----------+--------+------------+------+--------------+-------------+---------------------
 ma_souscription | pgoutput | logical   |  16384 | bench    | f         | t      |      10299 |      |          581 | 0/4E3BCCD0  | 0/4E3BCD08
(1 row)
```

*pg_publication*

```
postgres@bench=# select * from pg_publication;
    pubname     | pubowner | puballtables | pubinsert | pubupdate | pubdelete 
----------------+----------+--------------+-----------+-----------+-----------
 ma_publication |       10 | t            | t         | t         | t
(1 row)
```

*pg_publication_tables*

```
postgres@bench=# select * from pg_publication_tables;
    pubname     | schemaname |    tablename     
----------------+------------+------------------
 ma_publication | public     | pgbench_history
 ma_publication | public     | pgbench_tellers
 ma_publication | public     | pgbench_branches
 ma_publication | public     | pgbench_accounts
(4 rows)
```

*pg_subscription*

```
postgres@bench=# select * from pg_subscription;
 subdbid |     subname     | subowner | subenabled |                     subconninfo                      |   subslotname   | subsynccommit | subpublications  
---------+-----------------+----------+------------+------------------------------------------------------+-----------------+---------------+------------------
   16406 | ma_souscription |       10 | t          | host=127.0.0.1 port=5433 user=repliuser dbname=bench | ma_souscription | off           | {ma_publication}
(1 row)
```

*pg_replication_origin_status*

```
postgres@bench=# select * from pg_replication_origin_status;
 local_id | external_id | remote_lsn | local_lsn  
----------+-------------+------------+------------
        1 | pg_16425    | 0/0        | 0/D07ACA48
(1 row)
```


**Exemple de suivi de l'évolution de la réplication :**

Simuler de l'activité :

```bash
$ pgbench -T 300 bench
```

Sur l'éditeur :

```
postgres@bench=# select * from pg_stat_replication;
-[ RECORD 1 ]----+-----------------------------
pid              | 10299
usesysid         | 16407
usename          | repliuser
application_name | ma_souscription
client_addr      | 127.0.0.1
client_hostname  | 
client_port      | 49936
backend_start    | 2017-08-08 10:28:14.49455+02
backend_xmin     | 
state            | streaming
sent_lsn         | 0/5D549928
write_lsn        | 0/5D547768
flush_lsn        | 0/5D5323B0
replay_lsn       | 0/5D547768
write_lag        | 
flush_lag        | 00:00:00.011534
replay_lag       | 
sync_priority    | 0
sync_state       | async
```

Sur l'abonné :

```
postgres@bench=# select * from pg_replication_origin_status;
 local_id | external_id | remote_lsn | local_lsn  
----------+-------------+------------+------------
        1 | pg_16425    | 0/5DED5628 | 0/DFC90780
(1 row)
```
</div>

-----

## Performances

<div class="slide-content">
  * Tris
  * Agrégats
  * Parallélisme
</div>

<div class="notes">
</div>

-----

### Tris

<div class="slide-content">
  * Gains très significatifs au niveau des performances
  * Exemple avec les tris, à vérifier avec votre environnement...

```sql
postgres=# EXPLAIN (analyze, buffers) SELECT i FROM test ORDER BY i DESC;
```

Avec PostgreSQL 9.6 :

```
Execution time: 2645.577 ms
```

Avec PostgreSQL 10 :

```
Execution time: 1285.398 ms
```
</div>

<div class="notes">
Création de la table de test, du jeu de données, et calcul des statistiques :

```sql
CREATE TABLE test AS SELECT i FROM generate_series(1, 1000000) i;
INSERT INTO test SELECT i FROM test;
INSERT INTO test SELECT i FROM test;
VACUUM ANALYZE test;
```

Requête avec PostgreSQL 9.6 :

```sql
postgres=# EXPLAIN (analyze, buffers) SELECT i FROM test ORDER BY i DESC;
                                                      QUERY PLAN

----------------------------------------------------------------------------------------------------------------------
 Sort  (cost=551018.87..561018.87 rows=4000000 width=4) (actual
time=1359.623..2437.687 rows=4000000 loops=1)
   Sort Key: i DESC
   Sort Method: external merge  Disk: 54680kB
   Buffers: shared hit=17700, temp read=6850 written=6850
   ->  Seq Scan on test  (cost=0.00..57700.00 rows=4000000 width=4)
(actual time=0.009..329.761 rows=4000000 loops=1)
         Buffers: shared hit=17700
 Planning time: 0.090 ms
 Execution time: 2645.577 ms
(8 lignes)
```

Requête avec PostgreSQL 10 :

```sql
postgres=# EXPLAIN (analyze, buffers) SELECT i FROM test ORDER BY i DESC;
                                                      QUERY PLAN

----------------------------------------------------------------------------------------------------------------------
 Sort  (cost=605706.37..615706.37 rows=4000000 width=4) (actual
time=836.725..1161.973 rows=4000000 loops=1)
   Sort Key: i DESC
   Sort Method: external merge  Disk: 54872kB
   Buffers: shared hit=15611 read=2089, temp read=14287 written=14358
   ->  Seq Scan on test  (cost=0.00..57700.00 rows=4000000 width=4)
(actual time=0.081..179.833 rows=4000000 loops=1)
         Buffers: shared hit=15611 read=2089
 Planning time: 0.161 ms
 Execution time: 1285.398 ms
```
</div>

-----

### Agrégats

<div class="slide-content">
  * Les noeuds *HashAggregate* ont été améliorés
  * Dans l'exemple fournit, on passe de 6985.745 ms à 2122.746 ms
</div>

<div class="notes">
```sql
# EXPLAIN (ANALYZE, BUFFERS) SELECT
GROUPING(type_client,code_pays)::bit(2),
       GROUPING(type_client)::boolean g_type_cli,
       GROUPING(code_pays)::boolean g_code_pays,
       type_client,
       code_pays,
       SUM(quantite*prix_unitaire) AS montant
  FROM commandes c
  JOIN lignes_commandes l
    ON (c.numero_commande = l.numero_commande)
  JOIN clients cl
    ON (c.client_id = cl.client_id)
  JOIN contacts co
    ON (cl.contact_id = co.contact_id)
 WHERE date_commande BETWEEN '2014-01-01' AND '2014-12-31'
GROUP BY CUBE (type_client, code_pays);
```

Avec PostgreSQL 9.6, on termine par un noeud de type *GroupAggregate* et :

```sql

Planning time: 2.346 ms
Execution time: 6985.745 ms

Avec PostgreSQL 10, on termine par un noeud de type *MixedAggregate* et :
```

```sql
Planning time: 1.471 ms
Execution time: 2122.746 ms
```
</div>

-----

### Parallélisme

<div class="slide-content">
Les noeuds suivants sont désormais gérés :

  * *Parallel Bitmap Heap Scan*
  * *Parallel Index Scan*
  * *Gather Merge*
  * *Parallel Merge Join*

À noter également :

  * Différentes améliorations
  * Davantage de fonctions en langage procédural (*PL/pgsql*)
  * Le GUC *max_parallel_workers*
</div>

<div class="notes">
Pour en savoir plus sur le sujet du parallèlisme, le lecteur pourra consulter l'article [Parallel Query v2](https://dali.bo/parallel-query-v2 "parallel-query-v2") de *Robert Haas*.
</div>

-----

## Sécurité

<div class="slide-content">
  * pg_hba.conf
  * Row-Level Security
  * Nouveaux rôles
</div>

<div class="notes">
</div>

-----

### pg_hba.conf

<div class="slide-content">
  * Vue *pg_hba_file_rules*
  * Par défaut, connexion locale de réplication à *trust*
  * Nouvelle méthode d'authentification *SCRAM-SHA-256*
</div>

<div class="notes">
La vue `pg_hba_file_rules` fournit un résumé du contenu du fichier de configuration `pg_hba.conf`. Une ligne apparaît dans cette vue pour chaque ligne non vide et qui n'est pas un commentaire, avec des annotations indiquant si la règle a pu être appliquée avec succès. 

```
 line_number | type  |   database    | user_name |  address  |                 netmask                 | auth_method | options | error 
-------------+-------+---------------+-----------+-----------+-----------------------------------------+-------------+---------+-------
          84 | local | {all}         | {all}     |           |                                         | trust       |         | 
          86 | host  | {all}         | {all}     | 127.0.0.1 | 255.255.255.255                         | trust       |         | 
          88 | host  | {all}         | {all}     | ::1       | ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff | trust       |         | 
          91 | local | {replication} | {all}     |           |                                         | trust       |         | 
          92 | host  | {replication} | {all}     | 127.0.0.1 | 255.255.255.255                         | trust       |         | 
          93 | host  | {replication} | {all}     | ::1       | ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff | trust       |         | 
(6 rows)
```

Les valeurs par défaut relatives à la réplication, contenues dans le fichier `pg_hba.conf` ont été modifiée. Par défaut, les connexions locales ont comme méthode d'authentification *trust*.

Une nouvelle méthode d'authentification, *SCRAM-SHA-256*, fait également son apparition. Il s'agit de l'implémentation du **Salted Challenge Response Authentication Mechanism**. Ceci est basé sur un schéma de type question-réponse, qui empêche le _sniffing_ de mot de passe sur les connexions non fiables. Cette méthode est plus sûre que la méthode md5, mais peut ne pas être supportée par d'anciens clients. 
</div>

-----

### Row-Level Security

<div class="slide-content">
  * Politique de sécurité pour l'accès aux lignes d'une table
  * Nouvel attribut pour l'instruction *CREATE POLICY*
    * *PERMISSIVE* : les politiques d’une table sont reliées par des *OR* (valeur par défaut)
    * *RESTRICTIVE* : les politiques d’une table sont reliées par des *AND*
</div>

<div class="notes">
Les tables peuvent avoir des politiques de sécurité pour l'accès aux lignes qui restreignent, utilisateur par utilisateur, les lignes qui peuvent être renvoyées par les requêtes d'extraction ou les commandes d'insertions, de mises à jour ou de suppressions. Cette fonctionnalité est aussi connue sous le nom de `Row-Level Security`.

Lorsque la protection des lignes est activée sur une table, tous les accès classiques à la table pour sélectionner ou modifier des lignes doivent être autorisés par une politique de sécurité. 

Cependant, le propriétaire de la table n'est typiquement pas soumis aux politiques de sécurité. Si aucune politique n'existe pour la table, une politique de rejet est utilisé par défaut, ce qui signifie qu'aucune ligne n'est visible ou ne peut être modifiée.

Par défaut, les politiques sont permissives, ce qui veut dire que quand plusieurs politiques sont appliquées elles sont combinées en utilisant l'opérateur booléen *OR*. Il est depuis la version 10 possible de combiner des politiques permissives avec des politiques restrictives (combinées en utilisant l'opérateur booléen *AND*).

**Exemple :**

Soit 2 utilisateurs :

```
postgres@postgres=# CREATE ROLE toto WITH LOGIN;
CREATE ROLE

postgres@postgres=# CREATE ROLE toto2 WITH LOGIN;
CREATE ROLE
```

Créons une table *comptes*, insérons-y des données et permettons aux utilisateurs d'accéder à ces données :

```
toto@totodb=> CREATE TABLE comptes (admin text, societe text, contact_email text);
CREATE TABLE

toto@totodb=> INSERT INTO comptes VALUES ('toto', 'dalibo', 'toto@dalibo.com');
INSERT 0 1

toto@totodb=> INSERT INTO comptes VALUES ('toto2', 'dalibo', 'toto2@dalibo.com');
INSERT 0 1

toto@totodb=> INSERT INTO comptes VALUES ('toto3', 'paris', 'toto2@paris.fr');
INSERT 0 1

toto@totodb=> GRANT SELECT ON comptes TO toto2;
GRANT
```

Activons maintenant deux politiques permissives :

```
toto@totodb=> ALTER TABLE comptes ENABLE ROW LEVEL SECURITY;
ALTER TABLE

toto@totodb=> CREATE POLICY compte_admins ON comptes USING (admin = current_user);
CREATE POLICY

toto@totodb=> SELECT * FROM comptes;
 admin | societe |  contact_email   
-------+---------+------------------
 toto  | dalibo  | toto@dalibo.com
 toto2 | dalibo  | toto2@dalibo.com
(2 rows)

toto2@totodb=> SELECT * FROM comptes;
 admin | societe |  contact_email   
-------+---------+------------------
 toto2 | dalibo  | toto2@dalibo.com
(1 row)

toto@totodb=> CREATE POLICY pol_societe ON comptes USING (societe = 'paris');
CREATE POLICY

toto2@totodb=> SELECT * FROM comptes;
 admin | societe |  contact_email   
-------+---------+------------------
 toto2 | dalibo  | toto2@dalibo.com
 toto3 | paris   | toto2@paris.fr
(2 rows)
```

*toto* étant propriétaire de cette table, les politiques ne s'appliquent pas à lui, au contraire de *toto2*.

Comme le montre ce plan d'exécution, les deux politiques permissives se combinent bien en utilisant l'opérateur booléen *OR* :

```
toto2@totodb=> EXPLAIN(ANALYZE) SELECT * FROM comptes;
                                            QUERY PLAN                                             
---------------------------------------------------------------------------------------------------
 Seq Scan on comptes  (cost=0.00..21.38 rows=6 width=96) (actual time=0.022..0.024 rows=2 loops=1)
   Filter: ((societe = 'paris'::text) OR (admin = (CURRENT_USER)::text))
   Rows Removed by Filter: 1
```

Remplaçons maintenant l'une de ces politiques permissives par une politique restrictive :

```
toto@totodb=> DROP POLICY compte_admins ON comptes;
DROP POLICY

toto@totodb=> DROP POLICY pol_societe ON comptes;
DROP POLICY

toto@totodb=> CREATE POLICY compte_admins ON comptes AS RESTRICTIVE USING (admin = current_user);
CREATE POLICY

toto@totodb=> CREATE POLICY pol_societe ON comptes USING (societe = 'dalibo');
CREATE POLICY

toto2@totodb=> SELECT * FROM comptes;
 admin | societe |  contact_email   
-------+---------+------------------
 toto2 | dalibo  | toto2@dalibo.com
(1 row)

toto2@totodb=> EXPLAIN(ANALYZE) SELECT * FROM comptes;
                                            QUERY PLAN                                             
---------------------------------------------------------------------------------------------------
 Seq Scan on comptes  (cost=0.00..21.38 rows=1 width=96) (actual time=0.040..0.043 rows=1 loops=1)
   Filter: ((societe = 'dalibo'::text) AND (admin = (CURRENT_USER)::text))
   Rows Removed by Filter: 2
```

Le plan d'exécution indique bien l'application de l'opérateur booléen *AND*.
</div>

-----

### Nouveaux rôles

<div class="slide-content">
  * Supervision normalement réservée aux super-utilisateurs
  * Nouveaux rôles
    * pg_monitor
    * pg_read_all_settings
    * pg_read_all_stats
    * pg_stat_scan_tables
</div>

<div class="notes">
PostgreSQL fournit une série de rôles par défaut qui donnent accès à certaines informations et fonctionnalités privilégiées, habituellement nécessaires. Les administrateurs peuvent autoriser ces rôles à des utilisateurs et/ou à d'autres rôles de leurs environnements, fournissant à ces utilisateurs les fonctionnalités et les informations spécifiées. 

Ils accordent un ensemble de privilèges permettant au rôle de lire plusieurs paramètres de configuration, statistiques et information système normalement réservés aux super-utilisateurs. 

La version 10 implémente les nouveaux rôles suivants :

| Rôle | Accès autorisé |
| ------------------------ | ------------------------------------------------ |
| pg_monitor | Lit et exécute plusieurs vues et fonctions de monitoring. Ce rôle est membre de pg_read_all_settings, pg_read_all_stats et pg_stat_scan_tables. |
| pg_read_all_settings | Lit toutes les variables de configuration, y compris celles normalement visibles des seuls super-utilisateurs. |
| pg_read_all_stats | Lit toutes les vues pg_stat_* et utilise plusieurs extensions relatives aux statistiques, y compris celles normalement visibles des seuls super-utilisateurs. |
| pg_stat_scan_tables | Exécute des fonctions de monitoring pouvant prendre des verrous verrous ACCESS SHARE sur les tables, potentiellement pour une longue durée. |
</div>

-----

## Autres nouveautés - Pour les DBA

<div class="slide-content">
  * pg_stat_activity
  * Architecture
  * FDW
  * Divers
</div>

<div class="notes">
</div>

-----

### pg_stat_activity

<div class="slide-content">
  * Affichage des processus auxiliaires
    * nouvelle colonne *backend_type*
  * Nouveaux types d'événements pour lesquels le processus est en attente
    * Activity
    * Extension
    * Client
    * IPC
    * Timeout
    * IO
  * Renommage des types LWLockNamed et LWLockTranche en LWLock
</div>

<div class="notes">
Affichage des processus auxiliaires dans la nouvelle colonne *backend_type*.

Les types possibles sont : autovacuum launcher, autovacuum worker, background worker, background writer, client backend, checkpointer, startup, walreceiver, walsender et walwriter.

```
postgres@postgres=# SELECT pid, application_name, wait_event_type, wait_event, backend_type FROM pg_stat_activity ;
 pid  | application_name | wait_event_type |     wait_event      |    backend_type     
------+------------------+-----------------+---------------------+---------------------
 4938 |                  | Activity        | AutoVacuumMain      | autovacuum launcher
 4940 |                  | Activity        | LogicalLauncherMain | background worker
 4956 | psql             |                 |                     | client backend
 4936 |                  | Activity        | BgWriterHibernate   | background writer
 4935 |                  | Activity        | CheckpointerMain    | checkpointer
 4937 |                  | Activity        | WalWriterMain       | walwriter
```

De nouveaux types d'événements pour lesquels le processus est en attente apparaissent :
  * Activity : The server process is idle. This is used by system processes waiting for activity in their main processing loop.
  * Extension : The server process is waiting for activity in an extension module. This category is useful for modules to track custom waiting points. 
  * Client : The server process is waiting for some activity on a socket from user applications, and that the server expects something to happen that is independent from its internal processes.
  * IPC : The server process is waiting for some activity from another process in the server.
  * Timeout :  The server process is waiting for a timeout to expire.
  * IO : The server process is waiting for a IO to complete.

[FIXME - utiliser les traductions de la doc dès que disponible]

Les types d'événements LWLockNamed et LWLockTranche ont été renommés en LWLock.
</div>

-----

### Architecture

<div class="slide-content">
  * Architecture
    * Amélioration de la librairie libpq
    * Changement de la valeur par défaut de log_directory de pg_log à log
    * Slots de réplication temporaires
    * Support de la librairie ICU pour la gestion des collations
</div>

<div class="notes">
**Amélioration de la librairie libpq**

Il est possible de spécifier plusieurs instances aux options de connexions host et port.

Exemple avec psql :

```bash
$ psql --host=127.0.0.1,127.0.0.1 --port=5432,5433
psql: could not connect to server: Connection refused
  Is the server running on host "127.0.0.1" and accepting
  TCP/IP connections on port 5432?
could not connect to server: Connection refused
  Is the server running on host "127.0.0.1" and accepting
  TCP/IP connections on port 5433?
```

Il est également désormais possible de fournir l'attribut target_session_attrs à l'URI de connexion afin de spécifier si l'on souhaite seulement une connexion dans laquelle une transaction *read-write* est possible ou n'importe quel type de transaction (*any*).

Cela peu s'avérer utile pour établir une chaîne de connexion entre plusieurs instances en réplication et permettre l'exécution des requêtes en écriture sur le serveur primaire.

Exemple avec psql :

```bash
$ psql --dbname="postgresql://127.0.0.1:5432,127.0.0.1:5433/ma_db?target_session_attrs=any"

```

**Slots de réplication temporaires**

Un slot de réplication (utilisation par la réplication, par *pg_basebackup*,...) peut désormais être créé temporairement :

```sql
postgres=# SELECT pg_create_physical_replication_slot('workshop', true, true);
pg_create_physical_replication_slot 
-------------------------------------
(workshop,0/1620288)
(1 row)
```

Remarque pour *pg_basebackup* :

Par défaut, l'envoi des journaux dans le flux de réplication utilise un slot de réplication. Si l'option *-S* n'est pas spécifiée et que le serveur les supporte, un slot de réplication temporaire sera utilisé.
De cette manière, il est certain que le serveur ne supprimera pas les journaux nécessaires entre la fin de la sauvegarde et le début de lancement de la réplication en flux.

**Support de la librairie ICU**

Une collation est un objet du catalogue dont le nom au niveau SQL correspond à une locale fournie par les bibliothèques installées sur le système. Une définition de la collation a un fournisseur spécifiant quelle bibliothèque fournit les données locales. L'un des fournisseurs standards est libc, qui utilise les locales fournies par la bibliothèque C du système. Ce sont les locales les plus utilisées par des outils du système.

La version 10 permet l'utilisation des locales ICU si le support d'ICU a été configuré lors de la construction de PostgreSQL via l'option de configuration *--with-icu*.
</div>

-----

### FDW

<div class="slide-content">
  * file_fdw peut exécuter des programmes sur le serveur et lire leur sortie
  * postgres_fdw exécute les agrégations et jointures (*FULL JOIN*) sur le serveur distant
</div>

<div class="notes">
postgres_fdw exécute désormais ses agrégations et jointures (*FULL JOIN*) sur le serveur distant au lieu de ramener toutes les données et les traiter localement.

Pour plus d'information à ce sujet, vous pouvez consulter : 
[postgres_fdw: Push down aggregates to remote servers](https://dali.bo/waiting-for-postgresql-10-postgres_fdw-push-down-aggregates-to-remote-servers "waiting-for-postgresql-10-postgres_fdw-push-down-aggregates-to-remote-servers")
</div>

-----

### Divers

<div class="slide-content">
  * Réplication synchrone basée sur un quorum
  * Gestion de la compression dans *pg_receivewal*
  * Statistiques multi-colonnes
</div>

<div class="notes">
**Réplication synchrone basée sur un quorum**

Il est possible d'appliquer arbitrairement une réplication synchrone à un sous-ensemble d'un groupe d'instances grâce au paramètre suivant : *synchronous_standby_names = [FIRST]|[ANY] num_sync (node1, node2,...)*.

Le mot-clé *FIRST*, utilisé avec *num_sync*, spécifie une réplication synchrone basée sur la priorité, si bien que chaque validation de transaction attendra jusqu'à ce que les enregistrements des WAL soient répliqués de manière synchrone sur *num_sync* serveurs secondaires, choisis en fonction de leur priorités. 

Par exemple, utiliser la valeur *FIRST 3 (s1, s2, s3, s4)* forcera chaque commit à attendre la réponse de trois serveurs secondaire de plus haute priorité choisis parmi les serveurs secondaires s1, s2, s3 et s4. Si l'un des serveurs secondaires actuellement synchrones se déconnecte pour quelque raison que ce soit, il sera remplacé par le serveur secondaire de priorité la plus proche.

Le mot-clé *ANY*, utilisé avec *num_sync*, spécifie une réplication synchrone basée sur un quorum, si bien que chaque validation de transaction attendra jusqu'à ce que les enregistrements des WAL soient répliqués de manière synchrone sur au moins *num_sync* des serveurs secondaires listés. 

Par exemple, utiliser la valeur *ANY 3 (s1, s2, s3, s4)* ne bloquera chaque commit que le temps qu'au moins trois des serveurs de la liste s1, s2, s3 and s4 aient répondu, quels qu'ils soient. 

**Gestion de la compression dans *pg_receivewal* **

L'option -Z/--compress active la compression des journaux de transaction, et spécifie le niveau de compression (de 0 à 9, 0 étant l'absence de compression et 9 étant la meilleure compression). Le suffixe .gz sera automatiquement ajouté à tous les noms de fichiers.

**Statistiques multi-colonnes**

Il est désormais possible de créer des statistiques sur plusieurs colonnes d'une même table. Cela améliore les estimations des plans d'exécution dans le cas de colonnes fortement corrélées.

Par exemple :

```
postgres=# CREATE TABLE t1 (a int, b int);
CREATE TABLE

postgres=# INSERT INTO t1 SELECT i/100, i/500 FROM generate_series(1,10000000) s(i);
INSERT 0 10000000

postgres=# ANALYZE t1;
ANALYZE

postgres=# EXPLAIN(ANALYZE,BUFFERS) SELECT * FROM t1 WHERE (a = 1) AND (b = 0);
                                                     QUERY PLAN                                                      
---------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..107747.96 rows=1 width=8) (actual time=0.863..380.714 rows=100 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=16306 read=28044 dirtied=10513 written=9062
   ->  Parallel Seq Scan on t1  (cost=0.00..106747.86 rows=1 width=8) (actual time=246.324..372.866 rows=33 loops=3)
         Filter: ((a = 1) AND (b = 0))
         Rows Removed by Filter: 3333300
         Buffers: shared hit=16212 read=28036 dirtied=10513 written=9062
 Planning time: 0.364 ms
 Execution time: 384.013 ms
(10 rows)

postgres=# CREATE STATISTICS s1 (dependencies) ON a, b FROM t1;
CREATE STATISTICS

postgres=# ANALYZE t1;
ANALYZE

postgres=# EXPLAIN(ANALYZE,BUFFERS) SELECT * FROM t1 WHERE (a = 1) AND (b = 0);
                                                      QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..107761.66 rows=138 width=8) (actual time=0.418..321.794 rows=100 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=16272 read=28078
   ->  Parallel Seq Scan on t1  (cost=0.00..106747.86 rows=58 width=8) (actual time=210.955..318.026 rows=33 loops=3)
         Filter: ((a = 1) AND (b = 0))
         Rows Removed by Filter: 3333300
         Buffers: shared hit=16170 read=28078
 Planning time: 0.191 ms
 Execution time: 325.278 ms
(10 rows)
```

Pour compléter ces informations, vous pouvez également consulter :
[Implement multivariate n-distinct coefficients](https://dali.bo/waiting-for-postgresql-10-implement-multivariate-n-distinct-coefficients "waiting-for-postgresql-10-implement-multivariate-n-distinct-coefficients")
</div>

-----

## Autres nouveautés - Pour les développeurs

<div class="slide-content">
  * *Full Text Search* sur des colonnes de type *JSON* et *JSONB*
  * Possibilité de renommer les valeurs des types énumérations (*ALTER TYPE ... RENAME VALUE*)
  * Nouveau catalogue *pg_sequence*
  * *XMLTABLE*
  * Tables de transition pour les triggers de type AFTER et de niveau STATEMENT, ils peuvent voir les lignes avant et/ou après modification
  * Gestion des séquences conforme à la norme SQL
  * Les index *hash* sont utilisables !
  * Scripting conditionnel
  * \\GX
</div>

<div class="notes">
Quelques informations sur *XMLTABLE* :

  * Norme *SQL/XML*
  * Permet de voir des éléments de documents *XML* sous forme de table relationnelle
  * Une clause *XMLTABLE* dans la clause FROM définit le mapping entre éléments XML et colonnes

Pour ce qui est des séquences :

  * Colonne SERIAL => INT GENERATED BY DEFAULT AS IDENTITY
  * Utilisation plus souple pour
    * la gestion de la séquence (permissions, RESTART, ajout et suppression du DEFAULT par ALTER TABLE)
    * les copies de tables
  * On peut forcer l’usage de la séquence avec GENERATED ALWAYS AS IDENTITY

Du côté des indexes hash :

  * Journalisés => "crash safe" + réplicables
  * Amélioration des performances
  * Supportés par la contribution *pageinspect*

Pour en savoir plus :

  * [Full Text Search support for json and jsonb](https://dali.bo/waiting-for-postgresql-10-full-text-search-support-for-json-and-jsonb "waiting-for-postgresql-10-full-text-search-support-for-json-and-jsonb")
  * [Add pg_sequence system catalog](https://dali.bo/waiting-for-postgresql-10-add-pg_sequence-system-catalog "waiting-for-postgresql-10-add-pg_sequence-system-catalog")
  * [Support XMLTABLE query expression](https://dali.bo/waiting-for-postgresql-10-support-xmltable-query-expression "waiting-for-postgresql-10-support-xmltable-query-expression")
  * [Implement syntax for transition tables in AFTER triggers](https://dali.bo/waiting-for-postgresql-10-implement-syntax-for-transition-tables-in-after-triggers "waiting-for-postgresql-10-implement-syntax-for-transition-tables-in-after-triggers")
  * [Identity columns](https://dali.bo/waiting-for-postgresql-10-identity-columns "waiting-for-postgresql-10-identity-columns")
  * [hash indexing vs. WAL](https://dali.bo/waiting-for-postgresql-10-hash-indexing-vs-wal "waiting-for-postgresql-10-hash-indexing-vs-wal")
  * [Support \\if … \\elif … \\else … \\endif in psql scripting](https://dali.bo/waiting-for-postgresql-10-support-if-elif-else-endif-in-psql-scripting "waiting-for-postgresql-10-support-if-elif-else-endif-in-psql-scripting")
  * [psql: Add \\gx command](https://dali.bo/waiting-for-postgresql-10-psql-add-gx-command "waiting-for-postgresql-10-psql-add-gx-command")
  * [Cool Stuff in PostgreSQL 10: Transition Table Triggers](https://dali.bo/cool-stuff-in-postgresql-10-transition "cool-stuff-in-postgresql-10-transition")
  * [ALTER TYPE](https://www.postgresql.org/docs/10/static/sql-altertype.html)
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
Changements de comportement :

  * *pg_ctl* attend désormais que l'instance soit démarrée avant de rendre la main (identique au comportement à l'arrêt)

Fin de support ou suppression :

  * Type *floating point timestamp*
  * Contribution *tsearch2*
  * Support des BDD < 8.0 dans *pg_dump*
  * Protocole client/serveur 1.0
  * Clause *UNENCRYPTED* pour les mots de passe
</div>

<div class="notes">
Chaque version majeure introduit son lot d'incompatibilités, et il demeure important d'opérer régulièrement, en fonction des contraintes métier, des mises à jour de PostgreSQL.
</div>

-----

### Les outils de la sphère Dalibo

<div class="slide-content">
Quelques outils Dalibo d'ores et déjà compatibles. **Patches are welcome !**

| Outil | Compatibilité avec PostgreSQL 10 |
| ------------ | ------------------------------------ |
| pgBadger| Oui |
| pgCluu| Oui, depuis 2.6 |
| ora2Pg| Oui (support du partitionnement déclaratif) |
| pg_stat_kcache | Oui, depuis 2.0.3 |
| ldap2pg | Oui |
</div>

<div class="notes">
FIXME: Barman et autres outils

Voici une grille de compatibilité des outils Dalibo :

| Outil | Compatibilité avec PostgreSQL 10 |
| ------------ | ------------------------------------ |
| pg_activity | À venir dans 1.3.2 |
| check_pgactivity | À venir dans 2.3 (plusieurs PR ont été intégrées) |
| pgBadger| Oui |
| pgCluu| Oui, depuis 2.6 |
| ora2Pg| Oui (support du partitionnement déclaratif) |
| powa-archivist | À venir dans 3.1.1 |
| pg_qualstats | À venir dans 1.0.3 |
| pg_stat_kcache | Oui, depuis 2.0.3 |
| hypopg | À venir dans 1.1.0 |
| PAF | À venir dans 2.2 (beta1 sortie) |
| temboard | À venir dans 1.0a3 |
| ldap2pg | Oui |

La version 10 de PostgreSQL n'étant pas encore terminée, on imagine très bien que des changements peuvent encore avoir lieu, et que le support de cette version par les outils de l'éco-système est encore jeune.
</div>

-----


## Futur

<div class="slide-content">
FIXME: PostgreSQL 11
</div>

<div class="notes">
Attention, les utilisateurs des versions Beta doivent considérer que les mises à jour concernent des versions majeures. Ceci permettra notamment de pouvoir contourner toutes les incompatibilités ou changements de comportement dû au fait que PostgreSQL 10 est toujours en développement.

La [roadmap](https://dali.bo/pg-roadmap "pg-roadmap") du projet détaille les prochaines grandes étapes.
</div>

-----

## Questions

<div class="slide-content">
```sql
SELECT * FROM questions;
```
</div>

-----
