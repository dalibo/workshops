# Nouveautés de PostgreSQL 10

![PostgreSQL](medias/elephant-rock-valley-of-fire.jpg)

<div class="notes">
Photographie obtenue sur [urltarget.com](http://www.urltarget.com/elephant-rock-valley-of-fire.html).

Public Domain CC0.
</div>

-----

## Introduction

<div class="slide-content">
  * Développement depuis août 2016
  * Version beta 1 sortie le 18 mai
  * Version beta 2 sortie le 13 juillet
  * Version beta 3 sortie le 10 août
  * Sortie de la release prévue deuxième moitié 2017
  * Plus de 1,4 millions de lignes de code *C*
  * Des centaines de contributeurs
</div>

<div class="notes">
Le développement de la version 10 a suivi l'organisation habituelle : un démarrage mi 2016, des Commit Fests tous les deux mois, un Feature Freeze en mars, une première version beta mi-mai. Le travail est actuellement à la stabilisation du code, la suppression des bugs, l'amélioration de la documentation. La version finale est prévue fin septembre / début octobre 2017.

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
PostgreSQL 10 apporte un grand nombre de nouvelles fonctionnalités, qui sont d'ores et déjà détaillées dans de nombreux articles. Voici quelques liens vers des articles en anglais :

  * [New in postgres 10](https://dali.bo/new-in-postgres-10) du projet PostgreSQL
  * [New Features Coming in PostgreSQL 10](https://dali.bo/new-features-coming-in-postgresql-10) de *Robert Haas*
  * [PostgreSQL 10 New Features With examples](https://dali.bo/hp-new-features-pg10) de *HP*
</div>

-----

## Changements importants

<div class="slide-content">
  * Changement de la numérotation
  * Changement de nommage
  * Changement de configuration par défaut
</div>

<div class="notes">
</div>

-----

### Numérotation des versions

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

L'ancienne numérotation posait problème aux utilisateurs, mais aussi aux développeurs. Pour les développeurs, à chaque nouvelle version majeure, la question se posait de changer les deux premiers nombres ou seulement le second ("Est-ce une version 9.6 ou 10.0 ?").  Ceci générait de grosses discussions et beaucoup de frustrations. En passant à un seul nombre pour la version majeure, ce problème disparaît et les développeurs peuvent se concentrer sur un travail plus productif.

Pour les utilisateurs, principalement les nouveaux, cela apportait une confusion peu utile sur les mises à jour.

Vous trouverez plus de détails dans cet [article](https://dali.bo/changing-postgresql-version-numbering) de Josh Berkus.
</div>

-----

### Nommage

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
Afin de clarifier le rôle des répertoires *pg_xlog* et *pg_clog* qui contiennent non pas des *logs* mais des journaux de transaction ou de commits, les deux renommages ont été effectués dans $PGDATA. Les fonctions dont les noms y faisaient référence ont également été renommées.

Ainsi, voici le contenu actuel d'un répertoire de données PostgreSQL après son initialisation :

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

Si on regarde les fonctions contenant le mot clé *wal* :

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

L'ensemble des contributions de l'écosystème PostgreSQL devra également s'adapter à ces changements de nommage. Il sera donc nécessaire avant de migrer sur cette nouvelle version de vérifier que les outils d'administration, de maintenance et de supervision ont bien été rendus compatibles pour cette version.

Pour en savoir plus sur le sujet, vous pouvez consulter l'article intitulé [Rename “pg_xlog” directory to “pg_wal](https://dali.bo/waiting-for-postgresql-10-rename-pg_xlog-directory-to-pg_wal).
</div>

-----

### Configuration

<div class="slide-content">
Changement des valeurs par défaut

  * postgresql.conf
    * log_destination
    * wal_level
    * max_wal_senders
    * max_replication_slots
    * hot_standby

  * pg_hba.conf
    * connexions de réplication autorisées sur localhost
</div>

<div class="notes">
Certains paramètres ont vu leur valeur par défaut modifiée. Ceci est
principalement en relation avec la réplication, l'idée étant qu'il ne soit
plus nécessaire de redémarrer l'instance pour activer la réplication.

  * wal_level minimal à replica
  * max_wal_senders 0 à 10
  * max_replication_slots 0 à 10
  * hot_standby off à on
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
PostgreSQL dispose d'un contournement permettant de partitionner certaines
tables. La mise en place et la maintenance de ce contournement étaient
complexes. La version 10 améliore cela en proposant une intégration bien plus
poussée du partitionnement.
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
L'ancien partitionnement dans PostgreSQL se base sur un contournement de la
fonctionnalité d'héritage. L'idée est de créer des tables filles d'une table
parent par le biais de l'héritage. De ce fait, une lecture de la table mère
provoquera une lecture des données des tables filles. Un ajout ultérieur à
PostgreSQL a permis de faire en sorte que certaines tables filles ne soient
pas lues si une contrainte CHECK permet de s'assurer qu'elles ne contiennent
pas les données recherchées. Les lectures étaient donc assurées par le biais
de l'optimiseur.

Il n'en allait pas de même pour les écritures. Une insertion dans la table
mère n'était pas redirigée automatiquement dans la bonne table fille. Pour
cela, il fallait ajouter un trigger qui annulait l'insertion sur la table mère
pour la réaliser sur la bonne table fille. Les mises à jour étaient gérées
tant qu'on ne mettait pas à jour les colonnes de la clé de partitionnement.
Enfin, les suppressions étaient gérées correctement de façon automatique.

Tout ceci générait un gros travail de mise en place. La maintenance n'était
pas forcément plus aisée car il fallait s'assurer de créer les partitions en
avance, à moins de laisser ce travail au trigger sur insertion.

D'autres inconvénients étaient présents, notamment au niveau des index. Comme
il n'est pas possible de créer un index global (ie, sur plusieurs tables), il
n'est pas possible d'ajouter une clé primaire globale pour la table
partitionnée. En fait, toute contrainte unique est impossible.

En d'autres termes, ce contournement pouvait être intéressant dans certains
cas très particuliers et il fallait bien s'assurer que cela ne générait pas
d'autres soucis, notamment en terme de performances. Dans tous les autres cas,
il était préférable de s'en passer.
</div>

-----

### Nouveau partitionnement

<div class="slide-content">
  * Mise en place et administration simplifiées car intégrées au moteur
  * Plus de trigger
    * insertions plus rapides
    * routage des données insérées dans la bonne partition
    * erreur si aucune partition destinataire
  * Partitions
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
en fonction de la définition des partitions. Si les données insérées ne
trouvent pas de partition cible, l'insertion est tout simplement en erreur.
Du fait de ce routage automatique, les insertions se révèlent aussi plus rapides.

Le catalogue *pg_class* a été modifié et indique désormais :

  * si une table est une partition (dans ce cas : *relispartition = 't'*)
  * si une table est partitionnée (*relkind = 'p'*) ou si elle est ordinaire (*relkind = 'r'*)
  * la représentation interne des bornes de partitionnement (relpartbound)

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

Si on souhaite vérifier que la table partitionnée ne contient effectivement pas de données, on peut utiliser la clause *ONLY*, comme cela se faisait déjà avec l'héritage.
</div>

-----

### Exemple de partitionnement liste

<div class="slide-content">
  * Créer une table partitionnée :

    `CREATE TABLE t1(c1 integer, c2 text) PARTITION BY LIST (c1);`

  * Ajouter une partition :

    `CREATE TABLE t1_a PARTITION of t1 FOR VALUES IN (1, 2, 3);`

  * Détacher la partition :

    `ALTER TABLE t1 DETACH PARTITION t1_a;`

  * Attacher la partition :

    `ALTER TABLE t1 ATTACH PARTITION t1_a FOR VALUES IN (1, 2, 3);`
</div>

<div class="notes">
**Exemple complet :**

Création de la table principale et des partitions :

```sql
postgres=# CREATE TABLE t1(c1 integer, c2 text) PARTITION BY LIST (c1);
CREATE TABLE

postgres=# CREATE TABLE t1_a PARTITION OF t1 FOR VALUES IN (1, 2, 3);
CREATE TABLE

postgres=# CREATE TABLE t1_b PARTITION OF t1 FOR VALUES IN (4, 5);
CREATE TABLE
```

Insertion de données :

```sql
postgres=# INSERT INTO t1 VALUES (0);
ERROR:  no PARTITION OF relation "t1" found for row
DETAIL:  Partition key of the failing row contains (c1) = (0).

postgres=# INSERT INTO t1 VALUES (1);
INSERT 0 1

postgres=# INSERT INTO t1 VALUES (2);
INSERT 0 1

postgres=# INSERT INTO t1 VALUES (5);
INSERT 0 1

postgres=# INSERT INTO t1 VALUES (6);
ERROR:  no PARTITION OF relation "t1" found for row
DETAIL:  Partition key of the failing row contains (c1) = (6).
```

Lors de l'insertion, les données sont correctement redirigées vers leurs partitions. 

Si aucune partition correspondant à la clé insérée n'est trouvée, une erreur se produit.
</div>

-----

### Exemple de partitionnement intervalle

<div class="slide-content">
  * Créer une table partitionnée :

    `CREATE TABLE t2(c1 integer, c2 text) PARTITION BY RANGE (c1);`

  * Ajouter une partition :

    `CREATE TABLE t2_1 PARTITION OF t2 FOR VALUES FROM (1) TO (100);`

  * Détacher une partition :

    `ALTER TABLE t2 DETACH PARTITION t2_1;`
</div>

<div class="notes">
**Exemple complet :**

Création de la table principale et d'une partition :

```sql
postgres=# CREATE TABLE t2(c1 integer, c2 text) PARTITION BY RANGE (c1);
CREATE TABLE

postgres=# CREATE TABLE t2_1 PARTITION OF t2 FOR VALUES FROM (1) to (100);
CREATE TABLE
```

Insertion de données :

```sql
postgres=# INSERT INTO t2 VALUES (0);
ERROR:  no PARTITION OF relation "t2" found for row
DETAIL:  Partition key of the failing row contains (c1) = (0).

postgres=# INSERT INTO t2 VALUES (1);
INSERT 0 1

postgres=# INSERT INTO t2 VALUES (2);
INSERT 0 1

postgres=# INSERT INTO t2 VALUES (5);
INSERT 0 1

postgres=# INSERT INTO t2 VALUES (101);
ERROR:  no PARTITION OF relation "t2" found for row
DETAIL:  Partition key of the failing row contains (c1) = (101).
```

Lors de l'insertion, les données sont correctement redirigées vers leurs partitions. 

Si aucune partition correspondant à la clé insérée n'est trouvée, une erreur se produit.
</div>

-----

### Clé de partitionnement multi-colonnes

<div class="slide-content">
  * Clé sur plusieurs colonnes acceptée
    * uniquement pour le partitionnement par intervalle

  * Créer une table partitionnée avec une clé multi-colonnes :

    `CREATE TABLE t1(c1 integer, c2 text, c3 date) PARTITION BY RANGE (c1, c3);`

  * Ajouter une partition :

    `CREATE TABLE t1_a PARTITION of t1 FOR VALUES FROM (1,'2017-08-10') `
    `TO (100, '2017-08-11');`
</div>

<div class="notes">
Quand on utilise le partitionnement par intervalle, il est possible de créer les partitions en utilisant plusieurs colonnes.

On profitera de l'exemple ci-dessous pour montrer l'utilisation conjointe de tablespaces différents.

Commençons par créer les tablespaces :

```sql
postgres=# CREATE TABLESPACE ts0 LOCATION '/tablespaces/ts0';
CREATE TABLESPACE

postgres=# CREATE TABLESPACE ts1 LOCATION '/tablespaces/ts1';
CREATE TABLESPACE

postgres=# CREATE TABLESPACE ts2 LOCATION '/tablespaces/ts2';
CREATE TABLESPACE

postgres=# CREATE TABLESPACE ts3 LOCATION '/tablespaces/ts3';
CREATE TABLESPACE
```

Créons maintenant la table partitionnée et deux partitions :

```sql
postgres=# CREATE TABLE t2(c1 integer, c2 text, c3 date not null)
       PARTITION BY RANGE (c1, c3);
CREATE TABLE

postgres=# CREATE TABLE t2_1 PARTITION OF t2
       FOR VALUES FROM (1,'2017-08-10') TO (100, '2017-08-11')
       TABLESPACE ts1;
CREATE TABLE

postgres=# CREATE TABLE t2_2 PARTITION OF t2
       FOR VALUES FROM (100,'2017-08-11') TO (200, '2017-08-12')
       TABLESPACE ts2;
CREATE TABLE
```

Si les valeurs sont bien comprises dans les bornes :

```sql
postgres=# INSERT INTO t2 VALUES (1, 'test', '2017-08-10');
INSERT 0 1

postgres=# INSERT INTO t2 VALUES (150, 'test2', '2017-08-11');        
INSERT 0 1
```

Si la valeur pour `c1` est trop petite :

```sql
postgres=# INSERT INTO t2 VALUES (0, 'test', '2017-08-10');
ERROR:  no partition of relation "t2" found for row
DÉTAIL : Partition key of the failing row contains (c1, c3) = (0, 2017-08-10).
```

Si la valeur pour `c3` (colonne de type date) est antérieure :

```sql
postgres=# INSERT INTO t2 VALUES (1, 'test', '2017-08-09');
ERROR:  no partition of relation "t2" found for row
DÉTAIL : Partition key of the failing row contains (c1, c3) = (1, 2017-08-09).
```

Les valeurs spéciales  *MINVALUE* et *MAXVALUE* permettent de ne pas indiquer de valeur de seuil limite. Les partitions `t2_0` et `t2_3` pourront par exemple être déclarées comme suit et permettront d'insérer les lignes qui étaient ci-dessus en erreur. Attention, certains articles en ligne ont été créés avant la sortie de la version *beta3* et ils utilisent la valeur spéciale *UNBOUNDED* qui a été remplacée par *MINVALUE* et *MAXVALUE*.

```sql
postgres=# CREATE TABLE t2_0 PARTITION OF t2
       FOR VALUES FROM (MINVALUE, MINVALUE) TO (1,'2017-08-10')
       TABLESPACE ts0;

postgres=# CREATE TABLE t2_3 PARTITION OF t2
       FOR VALUES FROM (200,'2017-08-12') TO (MAXVALUE, MAXVALUE)
       TABLESPACE ts3;
```

Enfin, on peut consulter la table `pg_class` afin de vérifier la présence des différentes partitions :

```sql
postgres=# ANALYZE t2;
ANALYZE

postgres=# SELECT relname,relispartition,relkind,reltuples
           FROM pg_class WHERE relname LIKE 't2%';
 relname | relispartition | relkind | reltuples 
---------+----------------+---------+-----------
 t2      | f              | p       |         0
 t2_0    | t              | r       |         2
 t2_1    | t              | r       |         1
 t2_2    | t              | r       |         1
 t2_3    | t              | r       |         0
(5 lignes)
```
</div>

-----

### Performances en insertion

<div class="slide-content">
t1 (non partitionnée) :

```
INSERT INTO t1 select i, 'toto'
  FROM generate_series(0, 9999999) i;
Time: 10097.098 ms (00:10.097)
CHECKPOINT;
Time: 501.660 ms
```

t2 (partitionnement déclaratif) :

```
INSERT INTO t2 select i, 'toto'
  FROM generate_series(0, 9999999) i;
Time: 11448.867 ms (00:11.449)
CHECKPOINT;
Time: 501.212 ms
```

t3 (partitionnement par héritage) :

```
INSERT INTO t3 select i, 'toto'
  FROM generate_series(0, 9999999) i;
Time: 125351.918 ms (02:05.352)
CHECKPOINT;
Time: 802.073 ms
```
</div>

<div class="notes">
La table *t1* est une table non partitionnée. Elle a été créée comme suit :

```sql
CREATE TABLE t1 (c1 integer, c2 text);
```

La table *t2* est une table partitionnée utilisant les nouvelles
fonctionnalités de la version 10 de PostgreSQL :

```sql
CREATE TABLE t2 (c1 integer, c2 text) PARTITION BY RANGE (c1);
CREATE TABLE t2_1 PARTITION OF t2 FOR VALUES FROM (      0) TO ( 1000000);
CREATE TABLE t2_2 PARTITION OF t2 FOR VALUES FROM (1000000) TO ( 2000000);
CREATE TABLE t2_3 PARTITION OF t2 FOR VALUES FROM (2000000) TO ( 3000000);
CREATE TABLE t2_4 PARTITION OF t2 FOR VALUES FROM (3000000) TO ( 4000000);
CREATE TABLE t2_5 PARTITION OF t2 FOR VALUES FROM (4000000) TO ( 5000000);
CREATE TABLE t2_6 PARTITION OF t2 FOR VALUES FROM (5000000) TO ( 6000000);
CREATE TABLE t2_7 PARTITION OF t2 FOR VALUES FROM (6000000) TO ( 7000000);
CREATE TABLE t2_8 PARTITION OF t2 FOR VALUES FROM (7000000) TO ( 8000000);
CREATE TABLE t2_9 PARTITION OF t2 FOR VALUES FROM (8000000) TO ( 9000000);
CREATE TABLE t2_0 PARTITION OF t2 FOR VALUES FROM (9000000) TO (10000000);
```

Enfin, la table *t3* est une table utilisant l'ancienne méthode de
partitionnement :

```sql
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
Toute donnée doit pouvoir être placée dans une partition. Dans le cas
contraire, la donnée ne sera pas placée dans la table mère (contrairement au
partitionnement traditionnel). À la place, une erreur sera générée :

```
ERROR:  no partition of relation "t2" found for row
```

De même, il n'est pas possible d'ajouter un index à la table mère, sous peine
de voir l'erreur suivante apparaître :

```
ERROR:  cannot create index on partitioned table "t1"
```

Ceci sous-entend qu'il n'est toujours pas possible de mettre une clé primaire,
et une contrainte unique sur ce type de table. De ce fait, il n'est pas non
plus possible de faire pointer une clé étrangère vers ce type de table.

Plusieurs articles contiennent des explications et des exemples concrets, comme par exemple :

  * [Partitionnement et transaction autonomes avec PostgreSQL](https://dali.bo/pgday-2017-partitionnement)
  * [Cool Stuff in PostgreSQL 10: Partitioned Audit Table](https://dali.bo/cool-stuff-in-postgresql-10-partitioned)

Enfin, si PostgreSQL apporte de nombreuses fonctionnalités nativement, il peut néanmoins être également pertinent d'utiliser les extensions [pg_partman](https://dali.bo/pg-partman) et / ou [pg_pathman](https://dali.bo/pg-pathman).
</div>

-----

## Réplication logique

<div class="slide-content">
  * Petit rappel sur la réplication physique
  * Qu'est-ce que la réplication logique ?
  * Fonctionnement
  * Limitations
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
    * intégralité de l’instance
    * même architecture (x86, ARM…)
    * même version majeure
    * pas de requête en écriture sur le secondaire
</div>

<div class="notes">
Dans le cas de la réplication dite « physique », le moteur ne réplique pas les requêtes mais le résultat de celles-ci, plus précisément les modifications des blocs de données. Le serveur secondaire se contente de rejouer les journaux de transaction.

Cela impose certaines limitations. Les journaux de transactions ne contenant
comme information que le nom des fichiers (pas les noms et/ou type des objets
SQL impliqués), il n'est pas possible de ne rejouer qu'une partie. De ce fait,
on réplique l'intégralité de l'instance.

La façon dont les données sont codées dans les fichiers dépend de
l'architecture matérielle (32/64 bits, little/big endian) et des composants
logiciels du système d'exploitation (tri des données, pour les index). De
ceci, il en découle que chaque instance du cluster de réplication doit
fonctionner sur un matériel dont l'architecture est identique à celle des
autres instances et sur un système d'exploitation qui trie les données de la
même façon.

Les versions majeures ne codent pas forcément les données de la même façon,
notamment dans les journaux de transactions. Chaque instance du cluster de
réplication doit donc être de la même version majeure.

Enfin, les secondaires sont en lecture seule. Cela signifie (et c'est bien)
qu'on ne peut pas insérer/modifier/supprimer de données sur les tables
répliquées. Mais on ne peut pas non plus ajouter des index supplémentaires ou
des tables de travail, ce qui est bien dommage dans certains cas.
</div>

-----

### Réplication logique - Principe

<div class="slide-content">
  * Réutilisation de l'infrastructure existante
    * réplication en flux
    * slots de réplication
  * Réplique les changements sur une seule base de données
    * d'un ensemble de tables défini
  * Uniquement INSERT / UPDATE / DELETE
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

![Schema du fonctionnement de la réplication logique](medias/z100-schema-repli-logique.png)

<div class="notes">
Schéma obtenu sur [blog.anayrat.info](https://blog.anayrat.info/wp-content/uploads/2017/07/schema-repli-logique.png).

  * Une publication est créée sur le serveur éditeur.
  * L'abonné souscrit à cette publication, c’est un « souscripteur ».
  * Un processus spécial est lancé : le  « bgworker logical replication ». Il va se connecter à un slot de réplication sur le serveur éditeur.
  * Le serveur éditeur va procéder à un décodage logique des journaux de transaction pour extraire les résultats des ordres SQL.
  * Le flux logique est transmis à l'abonné qui les applique sur les tables.
</div>

-----

### Limitations

<div class="slide-content">
  * Non répliqué :
    * Schéma
    * Séquences
    * *Large objects*

  * Pas de publication des tables parents du partitionnement
  * Ne convient pas comme fail-over
</div>

<div class="notes">
Le schéma de la base de données ainsi que les commandes *DDL* ne sont pas répliquées, ci-inclus l'ordre *TRUNCATE*. Le schéma initial peut être créé en utilisant par exemple *pg_dump --schema-only*. Il faudra dès lors répliquer manuellement les changements de structure.

Il n'est pas obligatoire de conserver strictement la même structure des deux côtés. Afin de conserver sa cohérence, la réplication s'arrêtera en cas de conflit.

Il est d'ailleurs nécessaire d'avoir des contraintes de type *PRIMARY KEY* ou *UNIQUE* et *NOT NULL* pour permettre la propagation des ordres *UPDATE* et *DELETE*.

Les triggers des tables abonnées ne seront pas déclenchés par les modifications reçues via la réplication.

En cas d'utilisation du partitionnement, il n'est pas possible d'ajouter des tables parents dans la publication.

Les séquences et *large objects* ne sont pas répliqués.

De manière générale, il serait possible d'utiliser la réplication logique en cas de fail-over en propageant manuellement les mises à jour de séquences et de schéma. La réplication physique est cependant plus appropriée pour cela.

La réplication logique vise d'autres objectifs, tels la génération de rapports ou la mise à jour de version majeure de PostgreSQL.
</div>

-----

### Supervision

<div class="slide-content">
  * Nouveaux catalogues
    * pg_publication*
    * pg_subscription*
    * pg_stat_subscription
  * Anciens catalogues
    * pg_stat_replication
	* pg_replication_slot
	* pg_replication_origin_status
</div>

<div class="notes">
De nouveaux catalogues ont été ajoutés pour permettre la supervision de la réplication logique. En voici la liste :

| Catalogue                    | Commentaires                                                      |
| ---------------------------- | ----------------------------------------------------------------- |
| pg_publication               | Informations sur les publications |
| pg_publication_tables        | Correspondance entre les publications et les tables qu'elles contiennent |
| pg_stat_subscription         | État des journaux de transactions reçus en souscription |
| pg_subscription              | Informations sur les souscriptions existantes |
| pg_subscription_rel          | Contient l'état de chaque relation répliquée dans chaque souscription |

D'autres catalogues déjà existants peuvent également être utiles :

| Catalogue                    | Commentaires                                                      |
| ---------------------------- | ----------------------------------------------------------------- |
| pg_stat_replication          | Une ligne par processus d'envoi de WAL, montrant les statistiques sur la réplication vers le serveur standby connecté au processus |
| pg_replication_slot          | Liste des slots de réplication qui existent actuellement sur l'instance, avec leur état courant |
| pg_replication_origin_status | Informations sur l'avancement du rejeu des transactions sur l'instance répliquée |
</div>

-----

### Exemple - Création d'une publication

<div class="slide-content">
  * Définir wal_level à logical
  * Initialiser une base de données et sauvegarder son schéma
  * Créer une publication pour toutes les tables

    `CREATE PUBLICATION ma_publication FOR ALL TABLES;`
  * Créer une publication pour une table

    `CREATE PUBLICATION ma_publication FOR TABLE t1;`
</div>

<div class="notes">
**Exemple complet :**

Définir le paramètre `wal_level` à la valeur `logical` dans le fichier `postgresql.conf` des serveurs éditeur et abonné.

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

```sql
postgres@bench=# CREATE PUBLICATION ma_publication FOR ALL TABLES;
CREATE PUBLICATION
```

Une publication doit être créée par base de données. Elle liste les tables dont la réplication est souhaitée. L'attribut `FOR ALL TABLES` permet de ne pas spécifier cette liste. Pour utiliser cet attribut, il faut être super-utilisateur.

Créer ensuite l'utilisateur qui servira pour la réplication :

```bash
$ createuser --replication repliuser
```

Lui autoriser l'accès dans le fichier `pg_hba.conf` du serveur éditeur et lui permettre de visualiser les données dans la base :

```sql
postgres@bench=# GRANT SELECT ON ALL TABLES IN SCHEMA public TO repliuser;
GRANT
```
</div>


-----

### Exemple - Création d'une souscription

<div class="slide-content">
  * Initialiser une base de données et importer son schéma
  * Créer l'abonnement :

    `CREATE SUBSCRIPTION ma_souscription CONNECTION 'host=127.0.0.1`
    `port=5433 user=repliuser dbname=bench' PUBLICATION ma_publication;`
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
$ createuser --replication repliuser
```

En tant que super-utilisateur, créer l'abonnement :

```sql
postgres@bench=# CREATE SUBSCRIPTION ma_souscription
  CONNECTION 'host=127.0.0.1 port=5433 user=repliuser dbname=bench'
  PUBLICATION ma_publication;
NOTICE:  created replication slot "ma_souscription" on publisher
CREATE SUBSCRIPTION
```
</div>

-----

### Exemple - Visualisation de l'état de la réplication

<div class="slide-content">
  * Sur l'éditeur
    * état de la réplication dans `pg_stat_replication;`
    * slot de réplication dans `pg_replication_slots;`
    * état de la publication dans `pg_publication;`
    * contenu de la publication dans `pg_publication_tables;`
  * Sur l'abonné
    * état de l'abonnement dans `pg_subscription;`
    * état de la réplication dans `pg_replication_origin_status;`
</div>

<div class="notes">

De nouvelles colonnes ont été ajoutées à *pg_stat_replication* pour mesurer les délais de réplication :

```sql
postgres@bench=# SELECT * FROM pg_stat_replication;
-[ RECORD 1 ]----+------------------------------
pid              | 26537
usesysid         | 16405
usename          | repliuser
application_name | ma_souscription
client_addr      | 127.0.0.1
client_hostname  | 
client_port      | 59272
backend_start    | 2017-08-11 16:15:01.505706+02
backend_xmin     | 
state            | streaming
sent_lsn         | 0/9CA63FA0
write_lsn        | 0/9CA63FA0
flush_lsn        | 0/9CA63FA0
replay_lsn       | 0/9CA63FA0
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
```

Ces trois nouvelles informations concernent la réplication synchrone.

*write_lag* mesure le délais en cas de *synchronous_commit* à *remote_write*. Cette configuration fera que chaque `COMMIT` attendra la confirmation de la réception en mémoire de l'enregistrement du `COMMIT` par le standby et son écriture via la système d'exploitation, sans que les données du cache du système ne soient vidées sur disque au niveau du serveur en standby.

*flush_lag* mesure le délais jusqu'à confirmation que les données modifiées soient bien écrites sur disque au niveau du serveur en standby.

*replay_lag* mesure le délais en cas de *synchronous_commit* à *remote_apply*. Cette configuration fera en sorte que chaque `COMMIT` devra attendre le retour des standbys synchrones actuels indiquant qu'ils ont bien rejoué la transaction, la rendant visible aux requêtes des utilisateurs. 


*pg_replication_slots* nous permet de savoir si un slot de réplication est temporaire ou non (*temporary*) :

```sql
postgres@bench=# SELECT * FROM pg_replication_slots;
-[ RECORD 1 ]-------+----------------
slot_name           | ma_souscription
plugin              | pgoutput
slot_type           | logical
datoid              | 16384
database            | bench
temporary           | f
active              | t
active_pid          | 26537
xmin                | 
catalog_xmin        | 115734
restart_lsn         | 0/9CA63F68
confirmed_flush_lsn | 0/9CA63FA0
```


De nouvelles vues ont été créées afin de connaître l'état et le contenu des publications :

```sql
postgres@bench=# SELECT * FROM pg_publication;
-[ RECORD 1 ]+---------------
pubname      | ma_publication
pubowner     | 10
puballtables | t
pubinsert    | t
pubupdate    | t
pubdelete    | t

postgres@bench=# SELECT * FROM pg_publication_tables;
    pubname     | schemaname |    tablename     
----------------+------------+------------------
 ma_publication | public     | pgbench_history
 ma_publication | public     | pgbench_tellers
 ma_publication | public     | pgbench_branches
 ma_publication | public     | pgbench_accounts
(4 rows)
```

De même, une nouvelle vue est disponible pour connaître l'état des abonnements :

```sql
postgres@bench=# SELECT * FROM pg_subscription;
-[ RECORD 1 ]---+-----------------------------------------------------
subdbid         | 16384
subname         | ma_souscription
subowner        | 10
subenabled      | t
subconninfo     | host=127.0.0.1 port=5433 user=repliuser dbname=bench
subslotname     | ma_souscription
subsynccommit   | off
subpublications | {ma_publication}

```


**Exemple de suivi de l'évolution de la réplication :**

Simulation de l'activité :

```bash
$ pgbench -T 300 bench
```

On peut suivre l'évolution des *lsn* (*Log Sequence Number* ou *Numéro de Séquence de Journal*, pointeur vers une position dans les journaux de transactions) envoyés et reçus.

Sur l'éditeur grâce à *pg_stat_replication* :

```sql
postgres@bench=# SELECT * FROM pg_stat_replication;
-[ RECORD 1 ]----+------------------------------
pid              | 26537
usesysid         | 16405
usename          | repliuser
application_name | ma_souscription
client_addr      | 127.0.0.1
client_hostname  | 
client_port      | 59272
backend_start    | 2017-08-11 16:15:01.505706+02
backend_xmin     | 
state            | streaming
sent_lsn         | 0/A6131DA0
write_lsn        | 0/A6131DA0
flush_lsn        | 0/A611DA10
replay_lsn       | 0/A6131DA0
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
```

Sur l'abonné grâce à *pg_replication_origin_status* :

```sql
postgres@bench=# SELECT * FROM pg_replication_origin_status;
 local_id | external_id | remote_lsn | local_lsn  
----------+-------------+------------+------------
        1 | pg_16404    | 0/A6A96110 | 0/C730EBB8
(1 row)
```
</div>

-----

## Performances

<div class="slide-content">
  * Tris
  * Agrégats
  * Statistiques multi-colonnes
  * Parallélisme
</div>

<div class="notes">
</div>

-----

### Gain sur les tris

<div class="slide-content">
  * Gains significatifs pour les tris sur disque
    * noeud *Sort Method: external merge*
  * Test avec installation par défaut et disques SSD :
    * 9.6 : 2,2 secondes
    * 10 : 1,6 secondes
</div>

<div class="notes">
Commençons par créer la table de test, peuplons la avec un jeu de données, et
calculons les statistiques sur ses données :

```sql
CREATE TABLE test AS SELECT i FROM generate_series(1, 1000000) i;
INSERT INTO test SELECT i FROM test;
INSERT INTO test SELECT i FROM test;
VACUUM ANALYZE test;
```

Requête avec PostgreSQL 9.6 :

```sql
postgres=# EXPLAIN (ANALYZE, BUFFERS, COSTS off) SELECT i FROM test ORDER BY i DESC;
                                QUERY PLAN                                
--------------------------------------------------------------------------
 Sort (actual time=1506.804..2093.048 rows=4000000 loops=1)
   Sort Key: i DESC
   Sort Method: external merge  Disk: 54752kB
   Buffers: shared hit=15419 read=2281, temp read=15264 written=15264
   ->  Seq Scan on test (actual time=0.023..225.907 rows=4000000 loops=1)
         Buffers: shared hit=15419 read=2281
 Planning time: 0.062 ms
 Execution time: 2236.924 ms
(8 rows)
```

Requête avec PostgreSQL 10 :

```sql
postgres=# EXPLAIN (ANALYZE, BUFFERS, COSTS off) SELECT i FROM test ORDER BY i DESC;
                                QUERY PLAN                                
--------------------------------------------------------------------------
 Sort (actual time=1170.566..1547.257 rows=4000000 loops=1)
   Sort Key: i DESC
   Sort Method: external merge  Disk: 54872kB
   Buffers: shared hit=15419 read=2281, temp read=14287 written=14358
   ->  Seq Scan on test (actual time=0.057..220.840 rows=4000000 loops=1)
         Buffers: shared hit=15419 read=2281
 Planning time: 0.289 ms
 Execution time: 1691.378 ms
(8 rows)
```
</div>

-----

### Gain sur les agrégats

<div class="slide-content">
  * Exécution d'un agrégat par hachage (HashAggregate)
    * lors de l'utilisation d'un ensemble de regroupement 
      (par exemple, un GROUP BY)
  * Test avec installation par défaut et disques SSD :
    * 9.6 : 4,9 secondes
    * 10 : 2,6 secondes
</div>

<div class="notes">
L'exemple ci-dessous provient de la formation SQL2.

FIXME
```bash
$ createdb sql2
$ createuser anayrat
$ pg_restore formation/formation/sql2/base_tp_sql2_avec_schemas.dump -d sql2 -1
$ psql
sql2=# SET search_path TO magasin;
```

```sql
postgres=# EXPLAIN (ANALYZE, BUFFERS, COSTS off) SELECT
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

Avec PostgreSQL 9.6, on termine par un nœud de type *GroupAggregate* :

```sql
                             QUERY PLAN
--------------------------------------------------------------------------------
 GroupAggregate  (actual time=2720.032..4971.515 rows=40 loops=1)
   Group Key: cl.type_client, co.code_pays
   Group Key: cl.type_client
   Group Key: ()
   Sort Key: co.code_pays
     Group Key: co.code_pays
   Buffers: shared hit=8551 read=47879, temp read=32236 written=32218
   ->  Sort  (actual time=2718.534..3167.936 rows=1226456 loops=1)
         Sort Key: cl.type_client, co.code_pays
         Sort Method: external merge  Disk: 34664kB
         Buffers: shared hit=8551 read=47879, temp read=25050 written=25032
         ->  Hash Join  (actual time=525.656..1862.380 rows=1226456 loops=1)
               Hash Cond: (l.numero_commande = c.numero_commande)
               Buffers: shared hit=8551 read=47879, temp read=17777 written=17759
               ->  Seq Scan on lignes_commandes l  
                     (actual time=0.091..438.819 rows=3141967 loops=1)
                     Buffers: shared hit=2241 read=39961
               ->  Hash  (actual time=523.476..523.476 rows=390331 loops=1)
                     Buckets: 131072  Batches: 8  Memory Usage: 3162kB
                     Buffers: shared hit=6310 read=7918, temp read=1611 written=2979
                     ->  Hash Join  
                           (actual time=152.778..457.347 rows=390331 loops=1)
                           Hash Cond: (c.client_id = cl.client_id)
                           Buffers: shared hit=6310 read=7918, temp read=1611 written=1607
                           ->  Seq Scan on commandes c  
                                 (actual time=10.810..132.984 rows=390331 loops=1)
                                 Filter: ((date_commande >= '2014-01-01'::date)
                                           AND (date_commande <= '2014-12-31'::date))
                                 Rows Removed by Filter: 609669
                                 Buffers: shared hit=2241 read=7918
                           ->  Hash  (actual time=139.381..139.381 rows=100000 loops=1)
                                 Buckets: 131072  Batches: 2  Memory Usage: 3522kB
                                 Buffers: shared hit=4069, temp read=515 written=750
                                 ->  Hash Join  
                                     (actual time=61.976..119.724 rows=100000 loops=1)
                                     Hash Cond: (co.contact_id = cl.contact_id)
                                     Buffers: shared hit=4069, temp read=515 written=513
                                     ->  Seq Scan on contacts co  
                                           (actual time=0.051..18.025 rows=110005 loops=1)
                                           Buffers: shared hit=3043
                                     ->  Hash  
                                           (actual time=57.926..57.926 rows=100000 loops=1)
                                           Buckets: 65536  Batches: 2  Memory Usage: 3242kB
                                           Buffers: shared hit=1026, temp written=269
                                           ->  Seq Scan on clients cl  
                                                 (actual time=0.060..21.896 rows=100000 loops=1)
                                                 Buffers: shared hit=1026
 Planning time: 1.739 ms
 Execution time: 4985.385 ms
(41 rows)
```

Avec PostgreSQL 10, on note l'apparition d'un nœud *MixedAggregate* qui utilise bien un hachage :

```sql
                             QUERY PLAN
--------------------------------------------------------------------------------
 MixedAggregate  (actual time=2640.531..2640.561 rows=40 loops=1)
   Hash Key: cl.type_client, co.code_pays
   Hash Key: cl.type_client
   Hash Key: co.code_pays
   Group Key: ()
   Buffers: shared hit=8418 read=48015, temp read=17777 written=17759
   ->  Hash Join  (actual time=494.339..1813.743 rows=1226456 loops=1)
       Hash Cond: (l.numero_commande = c.numero_commande)
       Buffers: shared hit=8418 read=48015, temp read=17777 written=17759
       ->  Seq Scan on lignes_commandes l  (actual time=0.019..417.992 rows=3141967 loops=1)
             Buffers: shared hit=2137 read=40065
       ->  Hash  (actual time=493.558..493.558 rows=390331 loops=1)
             Buckets: 131072  Batches: 8  Memory Usage: 3162kB
             Buffers: shared hit=6278 read=7950, temp read=1611 written=2979
             ->  Hash Join  (actual time=159.207..429.528 rows=390331 loops=1)
                   Hash Cond: (c.client_id = cl.client_id)
                   Buffers: shared hit=6278 read=7950, temp read=1611 written=1607
                   ->  Seq Scan on commandes c  (actual time=2.562..103.812 rows=390331 loops=1)
                         Filter: ((date_commande >= '2014-01-01'::date)
                                   AND (date_commande <= '2014-12-31'::date))
                         Rows Removed by Filter: 609669
                         Buffers: shared hit=2209 read=7950
                   ->  Hash  (actual time=155.728..155.728 rows=100000 loops=1)
                         Buckets: 131072  Batches: 2  Memory Usage: 3522kB
                         Buffers: shared hit=4069, temp read=515 written=750
                         ->  Hash Join  (actual time=73.906..135.779 rows=100000 loops=1)
                               Hash Cond: (co.contact_id = cl.contact_id)
                               Buffers: shared hit=4069, temp read=515 written=513
                               ->  Seq Scan on contacts co  
                                     (actual time=0.011..18.347 rows=110005 loops=1)
                                     Buffers: shared hit=3043
                               ->  Hash  (actual time=70.006..70.006 rows=100000 loops=1)
                                     Buckets: 65536  Batches: 2  Memory Usage: 3242kB
                                     Buffers: shared hit=1026, temp written=269
                                     ->  Seq Scan on clients cl  
                                           (actual time=0.014..26.689 rows=100000 loops=1)
                                           Buffers: shared hit=1026
 Planning time: 1.910 ms
 Execution time: 2642.349 ms
(36 rows)
```
</div>

-----

### Statistiques multi-colonnes

<div class="slide-content">
  * *CREATE STATISTICS* permet de créer des statistiques sur plusieurs colonnes d'une même table
  * Corrige les erreurs d'estimation en cas de colonnes fortement corrélées
</div>

<div class="notes">
Il est désormais possible de créer des statistiques sur plusieurs colonnes d'une même table. Cela améliore les estimations des plans d'exécution dans le cas de colonnes fortement corrélées.

Par exemple :

```sql
postgres=# CREATE TABLE t (a INT, b INT);
CREATE TABLE

postgres=# INSERT INTO t SELECT i % 100, i % 100 FROM generate_series(1, 10000) s(i);
INSERT 0 10000

postgres=# ANALYZE t;
ANALYZE
```

La distribution des données est très simple; il n'y a que 100 valeurs différentes dans chaque colonne, distribuées de manière uniforme.

L'exemple suivant montre le résultat de l'estimation d'une condition `WHERE` sur la colonne a : 

```sql
postgres=# EXPLAIN (ANALYZE, TIMING OFF) SELECT * FROM t WHERE a = 1;
                                  QUERY PLAN                                   
-------------------------------------------------------------------------------
 Seq Scan on t  (cost=0.00..170.00 rows=100 width=8) (actual rows=100 loops=1)
   Filter: (a = 1)
   Rows Removed by Filter: 9900
 Planning time: 0.293 ms
 Execution time: 2.570 ms
(5 rows)
```
L'optimiseur examine la condition et détermine que la sélectivité de cette clause est d'1% (`rows=100` parmi les 10000 lignes insérées).

Une estimation similaire peut être obtenue pour la colonne b.

Appliquons maintenant la même condition sur chacune des colonnes en les combinant avec *AND* :

```sql
postgres=# EXPLAIN (ANALYZE, TIMING OFF) SELECT * FROM t WHERE a = 1 AND b = 1;
                                 QUERY PLAN                                  
-----------------------------------------------------------------------------
 Seq Scan on t  (cost=0.00..195.00 rows=1 width=8) (actual rows=100 loops=1)
   Filter: ((a = 1) AND (b = 1))
   Rows Removed by Filter: 9900
 Planning time: 0.201 ms
 Execution time: 4.413 ms
(5 rows)
```

L'optimiseur estime la sélectivité pour chaque condition individuellement, en arrivant à la même estimation d'1% comme au dessus. Puis, il part du principe que les conditions sont indépendantes et multiple donc leurs sélectivités. L'estimation de sélectivité finale est donc d'uniquement 0.01%, ce qui est une sous-estimation importante (différence entre `cost` et `actual`).

Pour améliorer l'estimation, il est désormais possible de créer des statistiques multi-colonnes :

```sql
postgres=# CREATE STATISTICS s1 (dependencies) ON a, b FROM t;
CREATE STATISTICS

postgres=# ANALYZE t;
ANALYZE
```

Vérifions ensuite :

```sql
postgres=# EXPLAIN (ANALYZE, TIMING OFF) SELECT * FROM t WHERE a = 1 AND b = 1;
                                  QUERY PLAN                                   
-------------------------------------------------------------------------------
 Seq Scan on t  (cost=0.00..195.00 rows=100 width=8) (actual rows=100 loops=1)
   Filter: ((a = 1) AND (b = 1))
   Rows Removed by Filter: 9900
 Planning time: 0.400 ms
 Execution time: 3.816 ms
(5 rows)
```

Pour compléter ces informations, vous pouvez également consulter : [Implement multivariate n-distinct coefficients](https://dali.bo/waiting-for-postgresql-10-implement-multivariate-n-distinct-coefficients).
</div>

-----

### Parallélisme - nouvelles opérations supportées

<div class="slide-content">
  * Nœuds désormais gérés :
    * Parcours d'index (*Index Scan* et *Index Only Scan*)
    * Jointure-union (*Merge Join*)

  * Nouveau nœud :
    * Collecte de résultats en préservant l'ordre de tri (*Gather Merge*)

  * Support également des :
    * requêtes préparées
    * sous-requêtes non-corrélées
</div>

<div class="notes">
La version 9.6 intègre la parallélisation pour différentes opérations : les
parcours séquentiels, les jointures et les agrégats. Mais attention, cela ne
concerne que les requêtes en lecture : pas les `INSERT`/`UPDATE`/`DELETE`, pas les CTE en
écriture, pas les opérations de maintenance (`CREATE INDEX`, `VACUUM`, `ANALYZE`).

La version 10 propose la parallélisation de nouvelles opérations :

  * parcours d'index (*Index Scan* et *Index Only Scan*)
  * jointure-union (*Merge Join*)
  * collecte de résultats en préservant l'ordre de tri (*Gather Merge*)
  * requêtes préparées
  * sous-requêtes non-corrélées

La jointure-union (*Merge Join*) est fondée sur le principe d'ordonner les tables gauche et droite et ensuite de les comparer en parallèle.

Le nœud *Gather* introduit en 9.6 collecte les résultats de tous les *workers* dans un ordre arbitraire. Si chaque *worker* retourne des résultats triés, le nœud *Gather Merge* préservera l'ordre de ces résultats déjà triés.

Pour en savoir plus sur le sujet du parallélisme, le lecteur pourra consulter l'article [Parallel Query v2](https://dali.bo/parallel-query-v2) de *Robert Haas*.
</div>

-----

### Parallélisme - paramétrage

<div class="slide-content">
  * nouveaux paramètres *min_parallel_table_scan_size* et *min_parallel_index_scan_size*
  * suppression de *min_parallel_relation_size*, jugé trop générique
  * *max_parallel_workers* : nombre maximum de workers que le système peut supporter pour le besoin des requêtes parallèles
</div>

<div class="notes">
*min_parallel_table_scan_size* spécifie la quantité minimale de données de la table qui doit être parcourue pour qu'un parcours parallèle soit envisagé. 

*min_parallel_index_scan_size* spécifie la quantité minimale de données d'index qui doit être parcourue pour qu'un parcours parallèle soit envisagé.

*max_parallel_workers* positionne le nombre maximum de workers que le système peut supporter pour le besoin des requêtes parallèles. La valeur par défaut est 8. Lorsque cette valeur est augmentée ou diminuée, pensez également à modifier *max_parallel_workers_per_gather*.

Pour rappel, *max_parallel_workers_per_gather* configure le nombre maximum de processus parallèles pouvant être lancé par un seul noeud Gather. La valeur par défaut est 2. Positionner cette valeur à 0 désactive l'exécution parallélisée de requête.
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
  * Nouvelle méthode d'authentification *SCRAM-SHA-256*
  * Vue *pg_hba_file_rules*
  * Par défaut, connexion locale de réplication à *trust*
</div>

<div class="notes">
La vue `pg_hba_file_rules` fournit un résumé du contenu du fichier de configuration `pg_hba.conf`. Une ligne apparaît dans cette vue pour chaque ligne non vide et qui n'est pas un commentaire, avec des annotations indiquant si la règle a pu être appliquée avec succès.

```sql
postgres=# SELECT type,database,user_name,auth_method FROM pg_hba_file_rules;

 line_number | type  |   database    | user_name | auth_method 
-------------+-------+---------------+-----------+-------------
          84 | local | {all}         | {all}     | trust       
          86 | host  | {all}         | {all}     | trust       
          88 | host  | {all}         | {all}     | trust       
          91 | local | {replication} | {all}     | trust       
          92 | host  | {replication} | {all}     | trust       
          93 | host  | {replication} | {all}     | trust       
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
    * *PERMISSIVE* : politiques d’une table reliées par des *OR*
    * *RESTRICTIVE* : politiques d’une table reliées par des *AND*
  * *PERMISSIVE* par défaut
</div>

<div class="notes">
Les tables peuvent avoir des politiques de sécurité pour l'accès aux lignes qui restreignent, utilisateur par utilisateur, les lignes qui peuvent être renvoyées par les requêtes d'extraction ou les commandes d'insertions, de mises à jour ou de suppressions. Cette fonctionnalité est aussi connue sous le nom de `Row-Level Security`.

Lorsque la protection des lignes est activée sur une table, tous les accès classiques à la table pour sélectionner ou modifier des lignes doivent être autorisés par une politique de sécurité. 

Cependant, le propriétaire de la table n'est typiquement pas soumis aux politiques de sécurité. Si aucune politique n'existe pour la table, une politique de rejet est utilisé par défaut, ce qui signifie qu'aucune ligne n'est visible ou ne peut être modifiée.

Par défaut, les politiques sont permissives, ce qui veut dire que quand plusieurs politiques sont appliquées elles sont combinées en utilisant l'opérateur booléen *OR*. Depuis la version 10, il est possible de combiner des politiques permissives avec des politiques restrictives (combinées en utilisant l'opérateur booléen *AND*).

**Remarque** 

Afin de rendre l'exemple suivant plus lisible, le prompt psql a été modifié avec la commande suivante :

```
\set PROMPT1 '%n@%/%R%# '
```

Il est possible de rendre ce changement permanent en ajoutant la commande ci-dessus dans le fichier *~/.psqlrc*.

**Exemple**

Soit 2 utilisateurs :

```sql
postgres@postgres=# CREATE ROLE u1 WITH LOGIN;
CREATE ROLE

postgres@postgres=# CREATE ROLE u2 WITH LOGIN;
CREATE ROLE
```

Créons une table *comptes*, insérons-y des données et permettons aux utilisateurs d'accéder à ces données :

```sql
u1@db1=> CREATE TABLE comptes (admin text, societe text, contact_email text);
CREATE TABLE

u1@db1=> INSERT INTO comptes VALUES ('u1', 'dalibo', 'u1@dalibo.com');
INSERT 0 1

u1@db1=> INSERT INTO comptes VALUES ('u2', 'dalibo', 'u2@dalibo.com');
INSERT 0 1

u1@db1=> INSERT INTO comptes VALUES ('u3', 'paris', 'u3@paris.fr');
INSERT 0 1

u1@db1=> GRANT SELECT ON comptes TO u2;
GRANT
```

Activons maintenant une première politique permissive :

```sql
u1@db1=> ALTER TABLE comptes ENABLE ROW LEVEL SECURITY;
ALTER TABLE

u1@db1=> CREATE POLICY compte_admins ON comptes USING (admin = current_user);
CREATE POLICY

u1@db1=> SELECT * FROM comptes;
 admin | societe | contact_email 
-------+---------+---------------
 u1    | dalibo  | u1@dalibo.com
 u2    | dalibo  | u2@dalibo.com
 u3    | paris   | u3@paris.fr
(3 rows)
```

Connectons-nous avec l'utilisateur *u2* et vérifions que la politique est bien appliquée :

```sql
u1@db1=> \c db1 u2
You are now connected to database "db1" as user "u2".

u2@db1=> SELECT * FROM comptes;
 admin | societe | contact_email 
-------+---------+---------------
 u2    | dalibo  | u2@dalibo.com
(1 row)
```

Créons une autre politique de sécurité permissive :

```sql
u2@db1=> \c db1 u1
You are now connected to database "db1" as user "u1".

u1@db1=> CREATE POLICY pol_societe ON comptes USING (societe = 'paris');
CREATE POLICY
```

Vérifions maintenant comment elle s'applique à l'utilisateur *u2* :

```sql
u1@db1=> \c db1 u2
You are now connected to database "db1" as user "u2".

u2@db1=> SELECT * FROM comptes;
 admin | societe | contact_email 
-------+---------+---------------
 u2    | dalibo  | u2@dalibo.com
 u3    | paris   | u3@paris.fr
(2 rows)

```

*u1* étant propriétaire de cette table, les politiques ne s'appliquent pas à lui, au contraire de *u2*.

Comme le montre ce plan d'exécution, les deux politiques permissives se combinent bien en utilisant l'opérateur booléen *OR* :

```sql
u2@db1=> EXPLAIN(COSTS off) SELECT * FROM comptes;
                               QUERY PLAN                                
-------------------------------------------------------------------------
 Seq Scan on comptes
   Filter: ((societe = 'paris'::text) OR (admin = (CURRENT_USER)::text))
(2 rows)
```

Remplaçons maintenant l'une de ces politiques permissives par une politique restrictive :

```sql
u2@db1=> \c db1 u1
You are now connected to database "db1" as user "u1".

u1@db1=> DROP POLICY compte_admins ON comptes;
DROP POLICY

u1@db1=> DROP POLICY pol_societe ON comptes;
DROP POLICY

u1@db1=> CREATE POLICY compte_admins ON comptes AS RESTRICTIVE USING (admin = current_user);
CREATE POLICY

u1@db1=> CREATE POLICY pol_societe ON comptes USING (societe = 'dalibo');
CREATE POLICY
```

Vérifions enfin avec l'utilisateur *u2* :
```sql
u1@db1=> \c db1 u2
You are now connected to database "db1" as user "u2".

u2@db1=> SELECT * FROM comptes;
 admin | societe | contact_email 
-------+---------+---------------
 u2    | dalibo  | u2@dalibo.com
(1 row)

u2@db1=> EXPLAIN(COSTS off) SELECT * FROM comptes;
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 Seq Scan on comptes
   Filter: ((societe = 'dalibo'::text) AND (admin = (CURRENT_USER)::text))
(2 rows)
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
PostgreSQL fournit une série de rôles par défaut qui donnent accès à certaines informations et fonctionnalités privilégiées, pour lesquelles il est habituellement nécessaire d'être super-utilisateur pour en profiter. Les administrateurs peuvent autoriser ces rôles à des utilisateurs et/ou à d'autres rôles de leurs environnements, fournissant à ces utilisateurs les fonctionnalités et les informations spécifiées. 

Ils accordent un ensemble de privilèges permettant au rôle de lire les paramètres de configuration, les statistiques et les informations systèmes normalement réservés aux super-utilisateurs. 

La version 10 implémente les nouveaux rôles suivants :

| Rôle | Accès autorisé |
| ------------------------ | ------------------------------------------------ |
| pg_monitor | Lit et exécute plusieurs vues et fonctions de monitoring. Ce rôle est membre de pg_read_all_settings, pg_read_all_stats et pg_stat_scan_tables. |
| pg_read_all_settings | Lit toutes les variables de configuration, y compris celles normalement visibles des seuls super-utilisateurs. |
| pg_read_all_stats | Lit toutes les vues pg_stat_* et utilise plusieurs extensions relatives aux statistiques, y compris celles normalement visibles des seuls super-utilisateurs. |
| pg_stat_scan_tables | Exécute des fonctions de monitoring pouvant prendre des verrous ACCESS SHARE sur les tables, potentiellement pour une longue durée. |
</div>

-----

## Administration

<div class="slide-content">
  * pg_stat_activity
  * Architecture
  * SQL/MED
  * Quorum réplication synchrone
  * Changements dans pg_basebackup
  * pg_receivewal
  * Index hash
  * Renommage d'un enum
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
  * Impact sur les outils de supervision
</div>

<div class="notes">
*pg_stat_activity* n'affichait que les processus backend, autrement dit les
processus gérant la communication avec les clients, et donc responsables de
l'exécution des requêtes SQL. En version 10, cette vue affiche en plus les
processus auxiliaires. Il est possible de différencier les processus avec
la nouvelle colonne *backend_type*.

Les types possibles sont : autovacuum launcher, autovacuum worker, background worker, background writer, client backend, checkpointer, startup, walreceiver, walsender et walwriter.

Voici ce que pourrait donner une lecture de cette vue sur une version 10 :

```sql
postgres@postgres=# SELECT pid, application_name, wait_event_type, wait_event, backend_type
  FROM pg_stat_activity ;
 pid  | application_name | wait_event_type |     wait_event      |    backend_type     
------+------------------+-----------------+---------------------+---------------------
 4938 |                  | Activity        | AutoVacuumMain      | autovacuum launcher
 4940 |                  | Activity        | LogicalLauncherMain | background worker
 4956 | psql             |                 |                     | client backend
 4936 |                  | Activity        | BgWriterHibernate   | background writer
 4935 |                  | Activity        | CheckpointerMain    | checkpointer
 4937 |                  | Activity        | WalWriterMain       | walwriter
```

On y voit aussi de nouveaux types d'événements pour lesquels un processus peut être en attente. En voici la liste :

  * Activity : Le processus serveur est inactif. En attente d'activité d'un processus d'arrière-plan.
  * Extension : Le processus serveur est en attente d'activité d'une extension. 
  * Client : Le processus serveur est en attente d'activité sur une connexion utilisateur.
  * IPC : Le processus serveur est en attente d'activité d'un autre processus serveur.
  * Timeout : Le processus serveur attend qu'un timeout expire.
  * IO : Le processus serveur attend qu'une opération I/O se termine.

FIXME: traductions à vérifier

Les types d'événements *LWLockNamed* et *LWLockTranche* ont été renommés en *LWLock*.

Ce changement va avoir un impact fort sur les outils de supervision et
notamment sur leur sonde. Par exemple, certaines sondes ont pour but de
compter le nombre de connexions au serveur. Elles font généralement un
simple *SELECT count* sur la vue *pg_stat_activity*. Sans modification, elles
vont se retrouver avec un nombre plus important de connexions, vu qu'elles
incluront les processus auxiliaires. De ce fait, avant de mettre une version
10 en production, assurez-vous que votre système de supervision ait été mis à
jour.
</div>

-----

### Architecture

<div class="slide-content">
  * Amélioration des options de connexion
  * Ajout des slots de réplication temporaires
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

Cela peut s'avérer utile pour établir une chaîne de connexion entre plusieurs instances en réplication et permettre l'exécution des requêtes en écriture sur le serveur primaire.

Exemple avec psql :

```bash
$ psql --dbname="postgresql://127.0.0.1:5432,127.0.0.1:5433/ma_db?target_session_attrs=any"

```

**Slots de réplication temporaires**

Un slot de réplication (utilisation par la réplication, par *pg_basebackup*,...) peut désormais être créé temporairement :

```
postgres=# SELECT pg_create_physical_replication_slot('workshop', true, true);
pg_create_physical_replication_slot 
-------------------------------------
(workshop,0/1620288)
(1 row)
```

Dans ce cas, le slot de réplication n'est valide que pendant la durée de vie
de la connexion qui l'a créé. À la fin de la connexion, le slot temporaire est
automatiquement supprimé.

Remarque pour *pg_basebackup* :

Par défaut, l'envoi des journaux dans le flux de réplication utilise un slot de réplication. Si l'option *-S* n'est pas spécifiée et que le serveur les supporte, un slot de réplication temporaire sera utilisé.
De cette manière, il est certain que le serveur ne supprimera pas les journaux nécessaires entre le début et la fin de la sauvegarde (ce qui peut arriver sans archivage et sans configuration assez forte du paramètre *wal_keep_segments*).

**Support de la librairie ICU**

Une collation est un objet du catalogue dont le nom au niveau SQL correspond à une locale fournie par les bibliothèques installées sur le système. Une définition de la collation a un fournisseur spécifiant quelle bibliothèque fournit les données locales. L'un des fournisseurs standards est libc, qui utilise les locales fournies par la bibliothèque C du système. Ce sont les locales les plus utilisées par des outils du système. Cependant, ces locales sont fréquemment modifiées lors de la sortie de nouvelles versions de la libc. Or ces modifications ont parfois des conséquences sur l'ordre de tri des chaînes de caractères, ce qui n'est pas acceptable pour PostgreSQL et ses index.

La version 10 permet l'utilisation des locales ICU si le support d'ICU a été configuré lors de la construction de PostgreSQL via l'option de configuration *--with-icu*. Les locales ICU sont beaucoup plus stables et sont aussi bien plus performantes.
</div>

-----

### SQL/MED, Foreign Data Wrappers

<div class="slide-content">
  * *file_fdw*
    * Récupération du résultat d'un programme comme entrée
  * *postgres_fdw*
    * Support des agrégations et jointures (*FULL JOIN*) sur le serveur distant
</div>

<div class="notes">
**file_fdw : exemple**

Soit le script bash suivant :

```bash
$ cat /opt/postgresql/file_fdw.sh 
#!/bin/bash
for (( i=0; i <= 1000; i++ ))
do
    echo "$i,test"
done
```

Créons l'extension et le serveur distant :

```sql
postgres=# CREATE EXTENSION file_fdw ;
CREATE EXTENSION

postgres=# CREATE SERVER fs FOREIGN DATA WRAPPER file_fdw ;
CREATE SERVER
```

Associons ensuite une table étrangère au script bash :

```sql
postgres=# CREATE FOREIGN TABLE tfile1 (id NUMERIC, val VARCHAR(10)) SERVER fs OPTIONS (program '/opt/postgresql/file_fdw.sh', delimiter ',') ;
CREATE FOREIGN TABLE
```

Il est désormais possible d'accéder aux données de cette table :

```sql
postgres=# SELECT * FROM tfile1 LIMIT 1;
 id | val  
----+------
  0 | test
(1 row)
```

**postgres_fdw**

postgres_fdw exécute désormais ses agrégations et jointures (*FULL JOIN*) sur le serveur distant au lieu de ramener toutes les données et les traiter localement.


*Exemple :*

Création et initialisation d'une base de données exemple :

```sql
postgres=# CREATE DATABASE db1;
CREATE DATABASE

postgres=# \c db1
You are now connected to database "db1" as user "postgres".

db1=# CREATE TABLE t1 (c1 integer);
CREATE TABLE

postgres@db1=# INSERT INTO t1 SELECT * FROM generate_series(0,10000);
INSERT 0 10001
```

Création de l'extension :

```sql
db1=# \c postgres
You are now connected to database "postgres" as user "postgres".

postgres=# CREATE EXTENSION postgres_fdw;
CREATE EXTENSION
```

Création du serveur distant (ici notre base *db1* locale) :

```sql
postgres=# CREATE SERVER fs1 FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '127.0.0.1', port '5432', dbname 'db1');
CREATE SERVER
```

Création d'une correspondance entre notre utilisateur local et l'utilisateur distant :

```sql
postgres=# CREATE USER MAPPING FOR postgres SERVER fs1 OPTIONS (user 'postgres');
CREATE USER MAPPING
```

Création localement de la table distante :

```sql
postgres@postgres=# CREATE FOREIGN TABLE remote_t1 (c1 integer) SERVER fs1 OPTIONS (table_name 't1');
CREATE FOREIGN TABLE
```

Vérification de son bon fonctionnement :

```sql
postgres=# SELECT * FROM remote_t1 LIMIT 3;
 c1 
----
  0
  1
  2
(3 rows)
```

Exécutions d'une opération d’agrégation sur le serveur distant :

```sql
postgres=# EXPLAIN (VERBOSE, COSTS off) SELECT COUNT(*), AVG(c1), SUM(c1) FROM remote_t1;
                           QUERY PLAN                           
----------------------------------------------------------------
 Foreign Scan
   Output: (count(*)), (avg(c1)), (sum(c1))
   Relations: Aggregate on (public.remote_t1)
   Remote SQL: SELECT count(*), avg(c1), sum(c1) FROM public.t1
(4 rows)
```

Même requête sur PostgreSQL 9.6 :

```sql
postgres=# EXPLAIN (VERBOSE, COSTS off) SELECT COUNT(*), AVG(c1), SUM(c1) FROM remote_t1;
                  QUERY PLAN                  
----------------------------------------------
 Aggregate
   Output: count(*), avg(c1), sum(c1)
   ->  Foreign Scan on public.remote_t1
         Output: c1
         Remote SQL: SELECT c1 FROM public.t1
(5 rows)
```

Pour plus d'information à ce sujet, vous pouvez consulter : 
[postgres_fdw: Push down aggregates to remote servers](https://dali.bo/waiting-for-postgresql-10-postgres_fdw-push-down-aggregates-to-remote-servers)
</div>

-----

### Quorum réplication synchrone

<div class="slide-content">
  * Possibilité de réplication synchrone sur une liste de plusieurs esclaves
    * Tous : 
       `synchronous_standby_names = (s1, s2, s3, s4)`
    * Certains par ordre de priorité : 
       `synchronous_standby_names = [FIRST] 3 (s1, s2, s3, s4)`

  * Nouveauté
    * Certains sur la base d'un quorum : 
       `synchronous_standby_names = [ANY] 3 (s1, s2, s3, s4)`
</div>

<div class="notes">
Il est possible d'appliquer arbitrairement une réplication synchrone à un sous-ensemble d'un groupe d'instances grâce au paramètre suivant : *synchronous_standby_names = [FIRST]|[ANY] num_sync (node1, node2,...)*.

Le mot-clé *FIRST*, utilisé avec *num_sync*, spécifie une réplication synchrone basée sur la priorité, si bien que chaque validation de transaction attendra jusqu'à ce que les enregistrements des WAL soient répliqués de manière synchrone sur *num_sync* serveurs secondaires, choisis en fonction de leur priorités. 

Par exemple, utiliser la valeur *FIRST 3 (s1, s2, s3, s4)* forcera chaque commit à attendre la réponse de trois serveurs secondaire de plus haute priorité choisis parmi les serveurs secondaires s1, s2, s3 et s4. Si l'un des serveurs secondaires actuellement synchrones se déconnecte pour quelque raison que ce soit, il sera remplacé par le serveur secondaire de priorité la plus proche.

Le mot-clé *ANY*, utilisé avec *num_sync*, spécifie une réplication synchrone basée sur un quorum, si bien que chaque validation de transaction attendra jusqu'à ce que les enregistrements des WAL soient répliqués de manière synchrone sur au moins *num_sync* des serveurs secondaires listés. 

Par exemple, utiliser la valeur *ANY 3 (s1, s2, s3, s4)* ne bloquera chaque commit que le temps qu'au moins trois des serveurs de la liste s1, s2, s3 and s4 aient répondu, quels qu'ils soient. 
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

### pg_receivewal

<div class="slide-content">
  * Gestion de la compression dans *pg_receivewal*
    * niveau 0 : pas de compression
    * niveau 9 : meilleure compression possible
</div>

<div class="notes">
L'option -Z/--compress active la compression des journaux de transaction, et spécifie le niveau de compression (de 0 à 9, 0 étant l'absence de compression et 9 étant la meilleure compression). Le suffixe .gz sera automatiquement ajouté à tous les noms de fichiers.
</div>

-----

### Index Hash

<div class="slide-content">
  * Journalisation
  * Amélioration des performances
  * Amélioration de l'efficacité sur le grossissement de ces index
</div>

<div class="notes">
Les indexes de type Hash sont désormais journalisés. Ils résisteront donc désormais aux éventuels crash et seront utilisables sur un environnement répliqué.

Pour en savoir plus : [hash indexing vs. WAL](https://dali.bo/waiting-for-postgresql-10-hash-indexing-vs-wal)
</div>

-----

### Renommage d'un enum

<div class="slide-content">
Il est désormais possible de renommer une valeur d'un type existant.

`ALTER TYPE nom RENAME VALUE valeur_enum_existante TO nouvelle_valeur_enum;`
</div>

<div class="notes">
Exemple :

```sql
postgres=# CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy') ;
CREATE TYPE

postgres=# ALTER TYPE mood RENAME VALUE 'ok' TO 'good' ;
ALTER TYPE
```

Documentation complète : [ALTER TYPE](https://dali.bo/sql-altertype)
</div>

-----

## Utilisateurs

<div class="slide-content">
  * Full Text Search sur du json
  * Nouvelle fonction XMLTABLE
  * psql, nouvelles méta-commandes
  * Tables de transition
  * Amélioration sur les séquences
  * Nouveau type de colonne identity
</div>

<div class="note">
</div>

-----

### Full Text Search sur du json

<div class="slide-content">
  * Type *json* et *jsonb*
  * Impacte les fonctions *ts_headline()* et *to_tsvector()*
</div>

<div class="notes">
Les fonctions ts_headline() et to_tsvector() peuvent désormais être utilisées sur des colonnes de type *JSON* et *JSONB*.

En voici un exemple :

```sql
postgres=# SELECT jsonb_pretty(document) FROM stock_jsonb;
                jsonb_pretty                
--------------------------------------------
 {                                         +
     "vin": {                              +
         "type_vin": "blanc",              +
         "recoltant": {                    +
             "nom": "Mas Daumas Gassac",   +
             "adresse": "34150 Aniane"     +
         },                                +
         "appellation": {                  +
             "region": "Provence et Corse",+
             "libelle": "Ajaccio"          +
         }                                 +
     },                                    +
     "stocks": [                           +
         {                                 +
             "annee": 1999,                +
             "nombre": 12,                 +
             "contenant": {                +
                 "libelle": "bouteille",   +
                 "contenance": 0.75        +
             }                             +
         },                                +
         {                                 +
             "annee": 1999,                +
             "nombre": 8,                  +
             "contenant": {                +
                 "libelle": "magnum",      +
                 "contenance": 1.5         +
             }                             +
         },                                +
         {                                 +
             "annee": 1999,                +
             "nombre": 10,                 +
             "contenant": {                +
                 "libelle": "jeroboam",    +
                 "contenance": 4.5         +
             }                             +
         }                                 +
     ]                                     +
 }
(1 row)


postgres=# SELECT to_tsvector('french', document) FROM stock_jsonb;
                             to_tsvector                                                                  
--------------------------------------------------------------------------------
 '34150':7 'ajaccio':14 'anian':8 'blanc':1 'bouteil':16,24 'cors':12 'daum':4
 'gassac':5 'jeroboam':20,26 'magnum':18,22 'mas':3 'provenc':10
(1 row)

postgres=# SELECT jsonb_pretty(ts_headline(document, 'jeroboam'::tsquery))
  FROM stock_jsonb;
                 jsonb_pretty                  
-----------------------------------------------
 {                                            +
     "vin": {                                 +
         "type_vin": "blanc",                 +
         "recoltant": {                       +
             "nom": "Mas Daumas Gassac",      +
             "adresse": "34150 Aniane"        +
         },                                   +
         "appellation": {                     +
             "region": "Provence et Corse",   +
             "libelle": "Ajaccio"             +
         }                                    +
     },                                       +
     "stocks": [                              +
         {                                    +
             "annee": 1999,                   +
             "nombre": 12,                    +
             "contenant": {                   +
                 "libelle": "bouteille",      +
                 "contenance": 0.75           +
             }                                +
         },                                   +
         {                                    +
             "annee": 1999,                   +
             "nombre": 8,                     +
             "contenant": {                   +
                 "libelle": "magnum",         +
                 "contenance": 1.5            +
             }                                +
         },                                   +
         {                                    +
             "annee": 1999,                   +
             "nombre": 10,                    +
             "contenant": {                   +
                 "libelle": "<b>jeroboam</b>",+
                 "contenance": 4.5            +
             }                                +
         }                                    +
     ]                                        +
 }
(1 row)
```

Plus d'information : [Full Text Search support for json and jsonb](https://dali.bo/waiting-for-postgresql-10-full-text-search-support-for-json-and-jsonb)
</div>

-----

### XMLTABLE

<div class="slide-content">
  * Transformation d'un document XML en table
  * Nécessite libxml
</div>

<div class="notes">
La fonction *xmltable()* produit une table basée sur la valeur XML donnée. Cette table pourra ensuite être utilisée par exemple comme table primaire d'une clause *FROM*.

L'utilisation de cette fonctionnalité nécessite d'installer PostgreSQL avec l'option de configuration *--with-libxml*.

Exemple :

```sql
postgres=# WITH x AS (
    SELECT '<people>
                <person>
                    <first_name>Hubert</first_name>
                    <last_name>Lubaczewski</last_name>
                    <nick>depesz</nick>
                </person>
                <person>
                    <first_name>Andrew</first_name>
                    <last_name>Gierth</last_name>
                    <nick>RhodiumToad</nick>
                </person>
                <person>
                    <first_name>Devrim</first_name>
                    <last_name>Gündüz</last_name>
                </person>
            </people>'::xml AS source_xml
)
SELECT decoded.*
FROM
    x,
    xmltable(
        '//people/person'
        PASSING source_xml
        COLUMNS
            first_name text,
            last_name text,
            nick_name text PATH 'nick'
    ) AS decoded;
    
first_name |  last_name  |    nick     
------------+-------------+-------------
Hubert     | Lubaczewski | depesz
Andrew     | Gierth      | RhodiumToad
Devrim     | Gündüz      | [null]
(3 rows)
```

Pour en savoir plus :
  * [Support XMLTABLE query expression](https://dali.bo/waiting-for-postgresql-10-support-xmltable-query-expression)
  * [xmltable](https://docs.postgresql.fr/10/functions-xml.html#functions-xml-processing-xmltable)
</div>

-----

### psql, nouvelles méta-commandes

<div class="slide-content">
  * \\gx, force l'affichage étendu de \\g
  * structure conditionnelle \\if, \\elif, \\else, \\endif
</div>

<div class="notes">
**\\gx**

\\gx est équivalent à \\g, mais force l'affichage étendu pour cette requête. 

Exemple :

```sql
postgres=# SELECT * FROM t1 LIMIT 2;
 a | b 
---+---
 0 | 0
 0 | 0
(2 rows)

postgres=# \g
 a | b 
---+---
 0 | 0
 0 | 0
(2 rows)

postgres=# \gx
-[ RECORD 1 ]
a | 0
b | 0
-[ RECORD 2 ]
a | 0
b | 0

```

Pour en savoir plus : [psql: Add \\gx command](https://dali.bo/waiting-for-postgresql-10-psql-add-gx-command)

**\\if, \\elif, \\else, \\endif**

Ce groupe de commandes implémente les blocs conditionnels imbriqués. Un bloc conditionnel doit commencer par un \\if et se terminer par un \\endif. Entre les deux, il peut y avoir plusieurs clauses \\elif, pouvant être suivies facultativement par une unique clause \\else.

Pour en savoir plus : [Support \\if … \\elif … \\else … \\endif in psql scripting](https://dali.bo/waiting-for-postgresql-10-support-if-elif-else-endif-in-psql-scripting)
</div>

-----

### Tables de transition

<div class="slide-content">
  * Pour les triggers de type AFTER et de niveau STATEMENT
  * Possibilité de stocker les lignes avant et/ou après modification
</div>

<div class="notes">
Avec un trigger de type AFTER, il est possible d'utiliser des tables de transition utilisables dans les fonctions exécutées.

Par exemple :

Initialisation d'une table de test :

```
postgres=# CREATE TABLE t1 (id serial, c1 integer);
CREATE TABLE

postgres=# INSERT INTO t1 (c1) SELECT * FROM generate_series(0, 100);
INSERT 0 101
```

Création du trigger :

```sql
postgres=#  CREATE TRIGGER transition_tables 
			AFTER UPDATE ON t1 
			REFERENCING 
				NEW TABLE AS v_new_table 
				OLD TABLE AS v_old_table 
			FOR EACH STATEMENT EXECUTE PROCEDURE test_trigger();
CREATE TRIGGER
```

Création de la fonction manipulant ces tables de transition :

```sql
postgres=#  CREATE FUNCTION test_trigger() RETURNS trigger AS $$
			DECLARE
    			temprec record;
			BEGIN
			    FOR temprec in select * from v_old_table LOOP
			        RAISE NOTICE 'OLD: %', temprec;
			    END LOOP;
			    FOR temprec in select * from v_new_table LOOP
			        RAISE NOTICE 'NEW: %', temprec;
			    END LOOP;
			    RETURN NEW;
			END;
			$$ language plpgsql;
CREATE FUNCTION
```

Exemple d'application :

```sql
postgres@postgres=# UPDATE t1 SET c1 = 0 WHERE id = 1;
NOTICE:  OLD: (1,0)
NOTICE:  NEW: (1,0)
UPDATE 1
```

Pour en savoir plus :
  * [Implement syntax for transition tables in AFTER triggers](https://dali.bo/waiting-for-postgresql-10-implement-syntax-for-transition-tables-in-after-triggers)
  * [Cool Stuff in PostgreSQL 10: Transition Table Triggers](https://dali.bo/cool-stuff-in-postgresql-10-transition)
</div>

-----

### Amélioration sur les séquences

<div class="slide-content">
  * Création des catalogues système *pg_sequence* et *pg_sequences*
  * Ajout de l'option *CREATE SEQUENCE AS type_donnee*
</div>

<div class="notes">
- Création des catalogues système *pg_sequence* et *pg_sequences*

```sql
postgres=# SELECT * FROM pg_sequences;
-[ RECORD 1 ]-+-----------
schemaname    | public
sequencename  | t1_id_seq
sequenceowner | postgres
data_type     | integer
start_value   | 1
min_value     | 1
max_value     | 2147483647
increment_by  | 1
cycle         | f
cache_size    | 1
last_value    | 101

postgres=# SELECT * FROM pg_sequence;
-[ RECORD 1 ]+-----------
seqrelid     | 16384
seqtypid     | 23
seqstart     | 1
seqincrement | 1
seqmax       | 2147483647
seqmin       | 1
seqcache     | 1
seqcycle     | f
```

Plus d'information : [Add pg_sequence system catalog](https://dali.bo/waiting-for-postgresql-10-add-pg_sequence-system-catalog)

- Ajout de l'option *CREATE SEQUENCE AS type_donnee*

La clause facultative *AS type_donnee* spécifie le type de données de la séquence. Les types valides sont *smallint*, *integer*, et *bigint* (par défaut). Le type de données détermine les valeurs minimales et maximales par défaut pour la séquence. 

Il est possible de changer le type de données avec l'ordre *ALTER SEQUENCE AS type_donnee*.
</div>

-----

### Colonne identity

<div class="slide-content">
  * Nouveau type de colonne *identity*
  * Similaire au type *serial* mais conforme au standard SQL
</div>

<div class="notes">
La contrainte *GENERATED AS IDENTITY* a été ajoutée à l'ordre *CREATE TABLE* pour assigner automatiquement une valeur unique à une colonne.

Comme le type *serial*, une colonne d'identité utilisera une séquence.

Pour en savoir plus : [Identity columns](https://dali.bo/waiting-for-postgresql-10-identity-columns)
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
    * *pg_ctl* attend désormais que l'instance soit démarrée avant de rendre la main (identique au comportement à l'arrêt)

  * Fin de support ou suppression :
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
  * Branche de développement de la version 11 créée le 15 août
  * Commit fests prévus : 09 et 11/2017, 01 et 03/2018
  * Axes d'amélioration notamment prévus :
    * Parallélisme
    * Partitionnement
    * Réplication logique
</div>

<div class="notes">
Attention, les utilisateurs des versions Beta doivent considérer que les mises à jour concernent des versions majeures. Ceci permettra notamment de pouvoir contourner toutes les incompatibilités ou changements de comportement dû au fait que PostgreSQL 10 est toujours en développement.

La [roadmap](https://dali.bo/pg-roadmap) du projet détaille les prochaines grandes étapes.

Les développements de la version 11 ont commencés. Le premier commit fest nous laisse entrevoir une continuité dans l'évolution des thèmes principaux suivants : parallélisme, partitionnement et réplication logique.

Robert Haas détaille d'ailleurs quels sont les plans pour l'évolution du partitionnement en version 11 dans cet [article](https://dali.bo/plans-for-partitioning-in-v11).
</div>

-----

## Questions

<div class="slide-content">
`SELECT * FROM questions;`
</div>

-----
