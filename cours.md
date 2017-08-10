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
</div>

<div class="notes">
Dans le cas de la réplication dite « physique », le moteur ne réplique pas les requêtes mais le résultat de celles-ci. Plus précisément, les modifications des blocs de données.

Le serveur secondaire se contente de rejouer les journaux de transaction.

Quelques limitations :
  * on doit répliquer l’intégralité de l’instance
  * il n’est pas possible de faire une réplication entre différentes architectures (x86, ARM…)
  * le secondaire n’accepte aucune requête en écriture. Il n’est dont pas possible de créer des vues personnalisées ou des index.
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
</div>

<div class="notes">
createdb bench
pgbench -i -s 100 bench
pg_dump --schema-only bench > bench-schema.sql
psql -d bench -c "CREATE PUBLICATION bench_pub FOR ALL TABLES ;"
</div>

-----

### Exemple - Création d'une souscription

<div class="slide-content">
</div>

<div class="notes">
createdb bench
psql -f bench-schema.sql --single-transaction bench
psql -d bench -c "CREATE SUBSCRIPTION bench_sub CONNECTION 'host=127.0.0.1 port=5434 user=repuser dbname=bench' PUBLICATION bench_pub;"
</div>

-----

### Exemple - Visualisation de l'état de la réplication

<div class="slide-content">
</div>

<div class="notes">
pgbench -T 300 bench

pg_stat_replication 
pg_publication 
pg_publication_tables 
pg_replication_slot 
pg_subscription
pg_replication_origin_status
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
  * Méthode d'authentification *SCRAM-SHA-256*, plus robuste que *MD5* pour la négociation et le stockage des mots de passe
  * Vue *pg_hba_file_rules*
  * Nouvel attribut pour l'instruction *CREATE POLICY* des *Row Level Security*
    * *PERMISSIVE* : les politiques d’une table sont reliées par des *OR* (valeur par défaut)
    * *RESTRICTIVE* : les politiques d’une table sont reliées par des *AND*
  * Nouveaux rôles de monitoring permettant d'éviter l'attribut *SUPERUSER*

<div class="notes">
PostgreSQL 10 dispose de nouveaux rôles, qui permettront notamment de limiter l'attribution de *SUPERUSER* aux rôles le nécessitant réellement.

| Rôle | Accès autorisé |
| ------------------------ | ------------------------------------------------ |
| pg_read_all_settings | Lit toutes les variables de configuration, y compris celles normalement visibles des seuls super-utilisateurs. |
| pg_read_all_stats | Lit toutes les vues pg_stat_* et utilise plusieurs extensions relatives aux statistiques, y compris celles normalement visibles des seuls super-utilisateurs. |
| pg_stat_scan_tables | Exécute des fonctions de monitoring pouvant prendre des verrous verrous ACCESS SHARE sur les tables, potentiellement pour une longue durée. |
| pg_signal_backend | Envoie des signaux à d'autres processus serveurs (par exemple pour annuler une requête ou fermer une session). |
| pg_monitor | Lit et exécute plusieurs vues et fonctions de monitoring. Ce rôle est membre de pg_read_all_settings, pg_read_all_stats et pg_stat_scan_tables. |
</div>

-----

## Autres nouveautés - Pour les DBA

<div class="slide-content">
  * Statistiques multi-colonnes pour la corrélation et le % de valeurs distinctes (utilisées pour la création des plans d'exécution)
  * Gestion du *failover* dans le protocole *libpq* (on se connecte au premier serveur qui répond)
  * Réplication avec quorum, c'est à dire qu'un *commit* doit par exemple être acquitté par 2 serveurs synchrones.
  * Gestion de la compression dans *pg_receivewal* (via *libz*, avec un ratio entre 0 et 9)
  * Améliorations diverses sur les *FDW* (ex : "SELECT COUNT(\*) FROM foreign_table")
  * Bibliothèque  de collations *ICU* indépendante de l'OS
  * Slots de réplication temporaires
  * pg_log -> log = changement valeur par défaut de log_directory
  * L'extension file_fdw peut utiliser un programme en entrée
</div>

<div class="notes">
Il est désormais possible dans *libpq* de spécifier plusieurs serveurs, ainsi que des attributs qui permettront par exemple de trouver le serveur qui accepte les écritures.

Un slot de réplication (utilisation par la réplication, par *pg_basebackup*, etc.) peut désormais être créé temporairement :

```sql
postgres=# SELECT pg_create_physical_replication_slot('workshop', true, true);
 pg_create_physical_replication_slot 
-------------------------------------
 (workshop,0/1620288)
(1 row)
```

pg_basebackup :
Par défaut, l'envoi des journaux dans le flux de réplication utilise un slot de réplication. Si l'option *-S* n'est pas spécifiée et que le serveur les supporte, un slot de réplication temporaire sera utilisé.
De cette manière, il est certain que le serveur ne supprimera pas les journaux nécessaires entre la fin de la sauvegarde et le début de lancement de la réplication en flux.


Voici par ailleurs deux exemples permettant de définir le quorum  :

  * *synchronous_standby_names* = FIRST 2 (node1,node2);
  * *synchronous_standby_names* = ANY 2 (node1,node2,node3);

Pour compléter ces informations, vous pouvez également consulter :

  * [Implement multivariate n-distinct coefficients](https://dali.bo/waiting-for-postgresql-10-implement-multivariate-n-distinct-coefficients "waiting-for-postgresql-10-implement-multivariate-n-distinct-coefficients")
  * [postgres_fdw: Push down aggregates to remote servers](https://dali.bo/waiting-for-postgresql-10-postgres_fdw-push-down-aggregates-to-remote-servers "waiting-for-postgresql-10-postgres_fdw-push-down-aggregates-to-remote-servers")
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
