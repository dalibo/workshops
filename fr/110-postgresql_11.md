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

# Annule la transformation uppercase de certains thèmes
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
  * Développement depuis l'été 2017
  * Version bêta 1 sortie 24 mai 2018
  * bêta 2 sortie le 28 juin
  * bêta 3 sortie le 9 août
  * Sortie de la version finale attendue fin septembre 2018
  * Plus de 1,5 millions de lignes de code
  * Des centaines de contributeurs
</div>

<div class="notes">

Le développement de la version 11 a suivi l'organisation habituelle : un
démarrage vers la mi-2017, des _Commit Fests_ tous les deux mois, un 
_feature freeze_ le 7 avril, une première version bêta fin mai.

La version finale est sortie fin septembre ou début octobre 2018.

La version 11 de PostgreSQL contient plus de 1,5 millions de lignes de code *C*.
1 509 660 lignes pour être précis. Son développement est assuré par des centaines de contributeurs répartis partout dans le monde.

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
  * SQL
  * Outils
  * Réplication
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

## Nouveautés sur le partitionnement
<div class="slide-content">

  * Partitionnment par hachage
  * Création d'index automatique
  * Support de clés primaires et clés étrangères
  * Mise à jour de la clé de partition
  * Partitionnement par défaut
  * Amélioration des performances
  * Clause `INSERT ON CONFLICT`
  * Trigger `FOR EACH ROW`

</div>

<div class="notes">
Le partitionnement natif était une fonctionnalité très attendu de
PostgreSQL 10. Cependant, elle souffrait de plusieurs limitations qui pouvaient
dissuader de l'utilisation de celui-ci.

La version 11 apporte plusieurs améliorations au niveau du partitionnement et
corrige certaines limites impactant la version 10.

</div>

-----

### Partitionnement par hachage
<div class="slide-content">
  * répartition des données suivant la valeur de hachage de la clé de partition
  * très utile pour les partitions destinées à grandir
  * accéleration des `VACUUM`
</div>

<div class="notes">

Le partitionnement par hachage permet de répartir les données équitablement sur
plusieurs partitions selon la valeur de hachage de la clé de partition.

Ce mode de partitionnement est utile lorsqu'on cherche à séparer les données en
plusieurs parties sans rechercher un classement particulier des
enregistrements.

Tous les mode de partitionnement permettent d'accélérer les opérations de
`VACUUM`.  
Les partitionnements par liste ou par intervalles permettent de facilement
archiver ou supprimer des données. Le partitionnement par hachage va être utile
pour les partitions destinées à s’agrandir et pour lesquelles il n'y a pas de
clé de partitionnement naturelle.

</div>

-----

### Exemple de partitionnement par hachage
<div class="slide-content">
  * Créer une table partitionnée :
    `CREATE TABLE t1(c1 int) PARTITION BY HASH (c1)`
  * Ajouter une partition :
    `CREATE TABLE t1_a PARTITION OF t1`
    `  FOR VALUES WITH (modulus 3,remainder 0)`
  * Augmentation du nombre de partitions délicat
</div>

<div class="notes">

On fixe la valeur initiale du modulo au nombre de partitions à créer. On doit
créer les tables partitionnées pour tous les restes car il n'est pas possible
de définir de table par défaut avec les partitions par hachage.

```sql
v11=# CREATE TABLE t1(c1 int PRIMARY KEY) PARTITION BY HASH (c1);
CREATE TABLE
v11=# CREATE TABLE t1_default PARTITION OF t1 DEFAULT;
ERROR:  a hash-partitioned table may not have a default partition
v11=# CREATE TABLE t1_a PARTITION OF t1 FOR VALUES WITH (modulus 3,remainder 0);
CREATE TABLE
v11=# CREATE TABLE t1_b PARTITION OF t1 FOR VALUES WITH (modulus 3,remainder 1);
CREATE TABLE
v11=# INSERT INTO t1 SELECT generate_series(0,10000);
ERROR:  no partition of relation "t1" found for row
DÉTAIL : Partition key of the failing row contains (c1) = (0).
v11=# CREATE TABLE t1_c PARTITION OF t1 FOR VALUES WITH (modulus 3,remainder 2);
CREATE TABLE

v11=# \d+ t1
                          Table « public.t1 »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut | Stockage |
---------+---------+-----------------+-----------+------------+----------+
 c1      | integer |                 | not null  |            | plain    |
Clé de partition : HASH (c1)
Index :
    "t1_pkey" PRIMARY KEY, btree (c1)
Partitions: t1_a FOR VALUES WITH (modulus 3, remainder 0),
            t1_b FOR VALUES WITH (modulus 3, remainder 1),
            t1_c FOR VALUES WITH (modulus 3, remainder 2)

```

Pour trier les données dans la bonne colonne, la classe d'opérateur par hachage
par défaut des colonnes de la clé est utilisé. Il ne s'agit pas de l'opération
modulo mathématique. On le voit bien en regardant le nombre d'insertions dans
chaque partition pour une liste d'entiers de 0 à 10000.

```sql
v11=# INSERT INTO t1 SELECT generate_series(0,10000);
INSERT 0 10001
v11=# SELECT count(*) FROM t1;
 count
-------
 10001
(1 ligne)

v11=# SELECT count(*) FROM t1_a;
 count
-------
  3277
(1 ligne)

v11=# SELECT count(*) FROM t1_b;
 count
-------
  3369
(1 ligne)

v11=# select COUNT(*) FROM t1_c;
 count
-------
  3355
(1 ligne)
```

Il n'existe pas de commande permettant d'étendre automatiquement le nombre de
partitions d'une table partitionnée par hachage. On peut contourner en
détachant une partition et créant des « sous-partitions » (en terme de modulo)
de cette partition et réinsérer les données de la table détachée dans la table
mère.

```sql
v11=# BEGIN;
BEGIN
v11=# ALTER TABLE t1 DETACH PARTITION t1_a;
ALTER TABLE
v11=# CREATE TABLE t1_aa PARTITION OF t1 FOR VALUES WITH (modulus 6,remainder 0);
CREATE TABLE
v11=# CREATE TABLE t1_ab PARTITION OF t1 FOR VALUES WITH (modulus 6,remainder 3);
CREATE TABLE
v11=# INSERT INTO t1 SELECT * from t1_a;
INSERT 0 3277
v11=# DROP TABLE t1_a;
DROP TABLE
v11=# COMMIT;
COMMIT
v11=# SELECT SUM(c) count_aa_ab FROM (
  SELECT count(*) c FROM t1_aa
  UNION SELECT count(*) FROM t1_ab) t;
 count_aa_ab
-------------
        3277
(1 ligne)

workshop11=# \d+ t1
                         Table « public.t1 »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut | Stockage |
---------+---------+-----------------+-----------+------------+----------+
 c1      | integer |                 | not null  |            | plain    |
Clé de partition : HASH (c1)
Index :
    "t1_pkey" PRIMARY KEY, btree (c1)
Partitions: t1_aa FOR VALUES WITH (modulus 6, remainder 0),
            t1_ab FOR VALUES WITH (modulus 6, remainder 3),
            t1_b FOR VALUES WITH (modulus 3, remainder 1),
            t1_c FOR VALUES WITH (modulus 3, remainder 2)

```

Toutes les lignes de la table recoupée `t1_a` ont bien été insérées dans les 2
nouvelles partitions `t1_aa` et `t1_ab`.

</div>

-----

### Création d'INDEX automatique
<div class="slide-content">
  * Index sur une table partitionnée entière
  * Index créé sur chaque partition
  * Création automatique sur toute nouvelle partition

</div>

<div class="notes">
Soit la table partitionnée par intervalles :
```sql
CREATE TABLE livres (titre text, parution timestamp with time zone)
  PARTITION BY RANGE (titre);
CREATE TABLE livres_a_m PARTITION OF livres FOR VALUES FROM ('a') TO ('m');
CREATE TABLE livres_m_z PARTITION OF livres FOR VALUES FROM ('m') TO ('zzz');
```

En version 10, il n'était pas possible de créer un index sur une table
partitionnée :
```sql
v10=# CREATE INDEX ON livres (titre);
ERROR:  cannot create index on partitioned table "livres"
```

En version 11, les index sont créés sur chaques partitions :
```sql
v11=# CREATE INDEX ON livres (titre);
CREATE INDEX
v11=# \d livres
                            Table « public.livres »
 Colonne  |           Type           | Collationnement | NULL-able | Par défaut
----------+--------------------------+-----------------+-----------+------------
 titre    | text                     |                 |           |
 parution | timestamp with time zone |                 |           |
Clé de partition : RANGE (titre)
Index :
    "livres_titre_idx" btree (titre)
Nombre de partitions : 2 (utilisez \d+ pour les lister)

v11=# \d livres_a_m
                          Table « public.livres_a_m »
 Colonne  |           Type           | Collationnement | NULL-able | Par défaut
----------+--------------------------+-----------------+-----------+------------
 titre    | text                     |                 |           |
 parution | timestamp with time zone |                 |           |
Partition de : livres FOR VALUES FROM ('a') TO ('m')
Index :
    "livres_a_m_titre_idx" btree (titre)
```

Si on crée une nouvelle partition, l'index sera créé automatiquement :
```sql
v11=# CREATE TABLE livres_0_9 PARTITION OF livres FOR VALUES FROM ('0') TO ('999');
CREATE TABLE
v11=# \d livres_0_9
                          Table « public.livres_0_9 »
 Colonne  |           Type           | Collationnement | NULL-able | Par défaut
----------+--------------------------+-----------------+-----------+------------
 titre    | text                     |                 |           |
 parution | timestamp with time zone |                 |           |
Partition de : livres FOR VALUES FROM ('0') TO ('999')
Index :
    "livres_0_9_titre_idx" btree (titre)
```

</div>

-----

### Support des clés primaires
<div class="slide-content">
  * Support des index `UNIQUE`
  * Permet la création de clés primaires
  * Uniquement si l'index comprend la clé de partition
</div>

<div class="notes">

La version 11 offre la possibilité de créer des index sur des tables
partitionnées. Si l'index contient la clé de partition, il est possible de
créer un index unique :
```sql
v11=# CREATE UNIQUE INDEX ON livres (titre);
CREATE INDEX
v11=# \d livres;
                            Table « public.livres »
 Colonne  |           Type           | Collationnement | NULL-able | Par défaut
----------+--------------------------+-----------------+-----------+------------
 titre    | text                     |                 |           |
 parution | timestamp with time zone |                 |           |
Clé de partition : RANGE (titre)
Index :
    "livres_titre_idx" UNIQUE, btree (titre)
Nombre de partitions : 3 (utilisez \d+ pour les lister)
```

Cela n'est pas possible sur des colonnes en dehors de la clé de partition :
```sql
v11=# CREATE UNIQUE INDEX ON livres (parution);
ERROR:  insufficient columns in UNIQUE constraint definition
DÉTAIL : UNIQUE constraint on table "livres" lacks column "titre" which is part
         of the partition key.
```

Cette nouvelle fonctionnalité permet la création de clés primaires sur la clé
de partition :
```sql
v11=# CREATE TABLE livres_primary_key (
    titre text PRIMARY KEY, parution timestamp with time zone)
  PARTITION BY RANGE (titre);
CREATE TABLE
v11=# \d livres_primary_key;
                      Table « public.livres_primary_key »
 Colonne  |           Type           | Collationnement | NULL-able | Par défaut
----------+--------------------------+-----------------+-----------+------------
 titre    | text                     |                 | not null  |
 parution | timestamp with time zone |                 |           |
Clé de partition : RANGE (titre)
Index :
    "livres_primary_key_pkey" PRIMARY KEY, btree (titre)
Number of partitions: 0
```

</div>

-----

### Support des clés étrangères
<div class="slide-content">
  * Clé étrangère depuis une table non partitionnée
  * Clé étrangère vers une table partitionnée toujours impossible

</div>

<div class="notes">

En version 10 les clés étrangères ne sont pas supportées dans une partition :
```sql
v10=# CREATE TABLE auteur (nom text PRIMARY KEY);
CREATE TABLE
v10=# CREATE TABLE bibliographie (titre text, auteur text REFERENCES auteur(nom))
   PARTITION BY RANGE (titre);
ERROR:  foreign key constraints are not supported on partitioned tables
LIGNE 2 :                      auteur text REFERENCES auteur(nom))
                                           ^
```

La version 11 supporte les clés étrangères sur les partitions. Il faut bien sûr une
contrainte :
```sql
v11=# CREATE TABLE auteurs (nom text PRIMARY KEY);
CREATE TABLE
v11=# CREATE TABLE bibliographie (titre text PRIMARY KEY, auteur text REFERENCES auteurs(nom))
    PARTITION BY RANGE (titre);
CREATE TABLE
v11=# \d bibliographie
              Table « public.bibliographie »
 Colonne | Type | Collationnement | NULL-able | Par défaut
---------+------+-----------------+-----------+------------
 titre   | text |                 |           |
 auteur  | text |                 |           |
Clé de partition : RANGE (titre)
Contraintes de clés étrangères :
    "bibliographie_auteur_fkey" FOREIGN KEY (auteur) REFERENCES auteurs(nom)
Number of partitions: 0
```

Les clés étrangères depuis n'importe quelle table
vers une table partitionnée sont cependant toujours impossibles :
```sql
v11=# CREATE TABLE avis_livre (avis text, livre text REFERENCES bibliographie(titre)) ;
ERROR:  cannot reference partitioned table "livres"
```

On peut cependant créer une clé étrangère vers une partition donnée de la
table. Ceci ne correspondra qu'à des cas d'usage bien spécifiques :
```sql
v11=# CREATE TABLE avis_livres_a_m (
  nom text, livre text REFERENCES livres_a_m(titre))
    PARTITION BY RANGE (nom);
CREATE TABLE
```
</div>

-----

### Mise à jour d'une valeur de la clé de partition
<div class="slide-content">

  * En version 10 : `DELETE` puis `INSERT` obligatoires si clé modifiée
  * En version 11, `UPDATE` fonctionne
  * La ligne est alors déplacée dans une nouvelle partition

</div>

<div class="notes">

En version 10 il n'était pas possible de mettre à jour une clé de partition
entre deux partitions différentes avec la commande `UPDATE`, il était
nécessaire de faire un `DELETE` puis un `INSERT`.

En version 11, PostgreSQL rend la chose transparente.
</div>
-----

### Partition par défaut
<div class="slide-content">

  * Pour les données n'appartenant à aucune autre partition :
  `CREATE TABLE livres_default PARTITION OF livres DEFAULT;`

</div>

<div class="notes">
PostgreSQL génère une erreur lorsque les données n'appartiennent à aucune
partition :
```sql
v11=# INSERT INTO livres VALUES ('zzzz', now());
ERROR:  no partition of relation "livres" found for row
DÉTAIL : Partition key of the failing row contains (titre) = (zzzz).
```

En version 11, il est possible de définir une partition par défaut où iront les
données sans partition explicite :
```sql
v11=# CREATE TABLE livres_default PARTITION OF livres DEFAULT;
CREATE TABLE
v11=# INSERT INTO livres VALUES ('zzzz', now());
INSERT 0 1
```

Attention : on ne pourra pas ensuite créer de partition dont la contrainte
contiendrait des lignes présentes dans la partition par défaut :
```sql
v11=# CREATE TABLE livres_zzz_zzzzz PARTITION OF livres
  FOR VALUES FROM ('zzz') TO ('zzzzz');
ERROR:  updated partition constraint for default partition "livres_default"
        would be violated by some row
```

Le contournement est le suvant : créer la partition en dehors de la table
partitionnée, insérer les enregistrements de la table par défaut dans la
nouvelle table, supprimer ces enregistrements de la table par défaut et
attacher la table comme nouvelle partition :
```sql
v11=# BEGIN;
BEGIN
v11=# CREATE TABLE livres_zzz_zzzzz (
  titre text CHECK (titre>='zzz' AND titre<'zzzzz'),
  parution timestamp with time zone);
CREATE TABLE
v11=# INSERT INTO livres_zzz_zzzzz
  SELECT * FROM livres_default WHERE (titre>='zzz' AND titre<'zzzzz');
INSERT 0 1
v11=# DELETE FROM livres_default WHERE (titre>='zzz' AND titre<'zzzzz');
DELETE 1
v11=# ALTER TABLE livres ATTACH PARTITION livres_zzz_zzzzz
  FOR VALUES FROM ('zzz') TO ('zzzzz');
ALTER TABLE
v11=# COMMIT;
COMMIT
```

</div>

-----
### Meilleures performances des SELECT
<div class="slide-content">
  * Élagage dynamique des partitions
  * _Control Partition Pruning_
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
En version 10, la clause `ON CONFLICT` n'était pas supportée sur le
partitionnement :
```sql
v10=# INSERT INTO livres VALUES ('mon titre') ON CONFLICT DO NOTHING;
ERROR:  ON CONFLICT clause is not supported with partitioned tables
```

En version 11 la clause fonctionne :
```sql
v11=# INSERT INTO livres VALUES ('mon titre') ON CONFLICT DO NOTHING;
INSERT 0 1
v11=# INSERT INTO livres VALUES ('mon titre') ON CONFLICT DO NOTHING;
INSERT 0 0
```

Une évolution a été mise en place : le _Partition-Wise Aggregate_.

Les paramètres `enable_partitionwise_join` et `enable_partitionwise_aggregate`
ont été ajoutés. Ils sont désactivés par défaut. En cas de jointure entre
plusieurs tables partitionnées avec les mêmes contraintes, le moteur va d'abord
effectuer des jointures entre les différentes partitions de chaque table. Il
joindra dans un deuxième temps ces résultats entre eux.

L'activation de ces nouveaux paramètres va permettre au moteur d'effectuer dans
un premier temps les jointures entre les partitions de différentes tables
possédant les mêmes contraintes. Il effectuera dans un deuxième temps la
jointure des résultats entre eux.

```sql
CREATE TABLE t2(c1 int) PARTITION BY HASH (c1);
CREATE TABLE t2_a PARTITION OF t2 FOR VALUES WITH (modulus 2,remainder 0);
CREATE TABLE t2_b PARTITION OF t2 FOR VALUES WITH (modulus 2,remainder 1);
INSERT INTO t2 SELECT generate_series(0,200000);
CREATE TABLE t3(c1 int) PARTITION BY HASH (c1);
CREATE TABLE t3_a PARTITION OF t3 FOR VALUES WITH (modulus 2,remainder 0);
CREATE TABLE t3_b PARTITION OF t3 FOR VALUES WITH (modulus 2,remainder 1);
INSERT INTO t3 SELECT generate_series(0,400000);
VACUUM ANALYSE t2, t3;
```

Pour plus de simplicité dans la lecture des plans d'exécution, nous désactivons
la parallélisation. Il faut noter que les optimisations décrites fonctionnent
en mode parallélisé :
```sql
v11=# SET max_parallel_workers_per_gather=0;
SET
```

Voici le plan sans les optimisations. Les jointures sont effectuées entre les partitions d'une même table :
```sql
v11=# EXPLAIN (COSTS off) SELECT count(*) FROM t2 INNER JOIN t3 ON t2.c1=t3.c1;
                QUERY PLAN
------------------------------------------
 Aggregate
   ->  Hash Join
         Hash Cond: (t3_a.c1 = t2_a.c1)
         ->  Append
               ->  Seq Scan on t3_a
               ->  Seq Scan on t3_b
         ->  Hash
               ->  Append
                     ->  Seq Scan on t2_a
                     ->  Seq Scan on t2_b
(10 lignes)
```

Voici le plan avec l'activation de la jointure des partitions,
`enable_partitionwise_join`. On remarque que les jointures se font en premier
lieu entre les partitions de même type :
```sql
v11=# SET enable_partitionwise_join = on;
SET
v11=# EXPLAIN (COSTS off) SELECT count(*) FROM t2 INNER JOIN t3 ON t2.c1=t3.c1;
                  QUERY PLAN
----------------------------------------------
 Aggregate
   ->  Append
         ->  Hash Join
               Hash Cond: (t3_a.c1 = t2_a.c1)
               ->  Seq Scan on t3_a
               ->  Hash
                     ->  Seq Scan on t2_a
         ->  Hash Join
               Hash Cond: (t3_b.c1 = t2_b.c1)
               ->  Seq Scan on t3_b
               ->  Hash
                     ->  Seq Scan on t2_b
(12 lignes)
```

Voici le plan avec l'activation de l'agrégation et le regroupement des
partitions, `enable_partitionwise_aggregate`. Une fois les jointures entre les
partitions de même type effectuées, une agrégation partielle de celles-ci sont
effectuées avant l'agrégation finale entre les différentes jointures :
```sql
v11=# SET enable_partitionwise_aggregate = on;
SET
v11=# EXPLAIN (COSTS off) SELECT count(*) FROM t2 INNER JOIN t3 ON t2.c1=t3.c1;
                     QUERY PLAN
----------------------------------------------------
 Finalize Aggregate
   ->  Append
         ->  Partial Aggregate
               ->  Hash Join
                     Hash Cond: (t3_a.c1 = t2_a.c1)
                     ->  Seq Scan on t3_a
                     ->  Hash
                           ->  Seq Scan on t2_a
         ->  Partial Aggregate
               ->  Hash Join
                     Hash Cond: (t3_b.c1 = t2_b.c1)
                     ->  Seq Scan on t3_b
                     ->  Hash
                           ->  Seq Scan on t2_b
(14 lignes)
```

FIXME : trouver un use case idéal pour cette fonctionnalité


FIXME `FOR EACH ROW trigger`

</div>

-----

## Performances

<div class="slide-content">
  * Compilation Just In Time (JIT)
  * Parallélisme étendu à plusieurs commandes
  * `ALTER TABLE ADD COLUMN ... DEFAULT ...` sans réécriture

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

FIXME : TODO

</div>

-----

### Parallélisme

<div class="slide-content">

**Améliorations du parallélisme**

  * Nœuds Append (`UNION ALL`)
  * Jointures type Hash
  * `CREATE TABLE AS SELECT...`
  * `CREATE MATERIALIZED VIEW`
  * `SELECT INTO`
  * `CREATE INDEX` (`max_parallel_maintenance_workers`)
</div>

<div class="notes">

La parallélisation des requêtes avait été introduite en version 9.6, sur
certains nœuds d'exécution seulement, et pour les requêtes en lecture seule
uniquement. La version 10 avait étendu à d'autres nœuds.

Des nœuds supplémentaires peuvent à présent être parallélisés, notamment ceux
de type _Append_, qui servent aux `UNION ALL` notamment :

**FIXME** - exemple


Un nœud déjà parallélisé a été amélioré, le _Hash join_ (jointure par
hachage). Soit les tables suivantes :

```sql
CREATE TABLE a AS SELECT i FROM generate_series(1,10000000) i ;
CREATE TABLE b as SELECT i FROM generate_series(1,10000000) i ; 
CREATE INDEX ON a(i) ;

SET work_mem TO '1GB' ;
SET max_parallel_workers_per_gather TO 2;
```

Dans la version 10, le _hash join_ est déjà parallélisé :
```sql
v10=# EXPLAIN (COSTS off) SELECT * FROM a INNER JOIN b on (a.i=b.i)
        WHERE a.i BETWEEN 500000 AND 900000;
                            QUERY PLAN
-------------------------------------------------------------------
 Gather
   Workers Planned: 2
   ->  Hash Join
         Hash Cond: (b.i = a.i)
         ->  Parallel Seq Scan on b
         ->  Hash
               ->  Index Only Scan using a_i_idx on a
                     Index Cond: ((i >= 500000) AND (i <= 900000))
(8 lignes)
```

Mais les deux _hashs_ en s'exécutant font le travail en double. En version 11,
ils partagent la même table de travail et peuvent donc paralléliser sa
construction (ici en parallélisant l'_Index Scan_) :

```sql
v11=# SET enable_parallel_hash = on;
SET
v11=# EXPLAIN (COSTS off) SELECT * FROM a INNER JOIN b on (a.i=b.i)
        WHERE a.i BETWEEN 500000 AND 900000;
                            QUERY PLAN
-------------------------------------------------------------------
 Gather
   Workers Planned: 2
   ->  Parallel Hash Join
         Hash Cond: (b.i = a.i)
         ->  Parallel Seq Scan on b
         ->  Parallel Hash
               ->  Parallel Index Only Scan using a_i_idx on a
                     Index Cond: ((i >= 500000) AND (i <= 900000))
(8 lignes)
```

L'auteur de cette optmisation a écrit un article assez complet sur le sujet :
<https://write-skew.blogspot.com/2018/01/parallel-hash-for-postgresql.html>.


FIXME :  exemple d'Append avec UNION ALL

FIXME : exemple SELECT INTO

La création d'index peut à présent être parallélisée, ce qui va permettre de
gros gains de temps dans certains cas. La parallélisation est activée par
défaut et est contrôlée par un nouveau paramètre,
`max_parallel_maintenance_workers` (défaut : 2) et non l'habituel
`max_parallel_workers_per_gather`.

```sql
v11=# SET maintenance_work_mem TO '2GB';
SET
v11=# CREATE TABLE t9 AS SELECT random() FROM  generate_series(1,5000000);
CREATE TABLE
v11=# SET max_parallel_maintenance_workers TO 0;
SET
v11=# \timing on
Chronométrage activé.

v11=# CREATE index ix_t9 ON t9 (random);
CREATE INDEX
Durée : 86731,660 ms (01:26,732)
v11=# DROP INDEX ix_t9 ;
DROP INDEX
v11=# SET max_parallel_maintenance_workers TO 4;
SET
v11=# CREATE index ix_t9 ON t9 (random) ;
CREATE INDEX
Durée : 67278,338 ms (01:07,278)
```

Le gain en temps est dans cet exemple de plus de 20 % pour 4 workers.

La commande `ALTER TABLE t9 SET (parallel_workers = 4);` permet de fixer le
nombre de workers au niveau de la définition de la table, mais attention cela
va aussi impacter vos requêtes !

Pour de plus amples détails, les Allemands de Cybertec ont mis un [article sur
le
sujet](https://www.cybertec-postgresql.com/en/postgresql-parallel-create-index-for-better-performance/)
en ligne.

</div>

-----

### ALTER TABLE ADD COLUMN ... DEFAULT ... sans réécriture

<div class="slide-content">
  
  * `ALTER TABLE ... ADD COLUMN ... DEFAULT ...`
    * Réécriture complète de la table avant v11 !
	* v11 : valeur par défaut mémorisée, ajout instantané
	* ...si défaut n'est pas une fonctgion volatile

</div>

<div class="notes">

Jusqu'en version 10 incluse, l'ajout d'une colonne avec une valeur `DEFAULT`
(à raison de plus avec `NOT NULL`)
provoquait la réécriture complète de la table, en bloquant tous les accès.
Sur de grosses tables, l'interruption de service était parfois intolérable et menait
à des mises à jour par étapes délicates.

La version 11 prend simplement note de la valeur par défaut de la nouvelle
colonne et n'a pas besoin de l'écrire physiquement pour la restituer ensuite.

Une contrainte est que
cette valeur par défaut soit une constante pendant l'ordre, ce qui est le cas
de `DEFAULT 1234`, `DEFAULT now()` ou de toute fonction déclarée comme `STABLE`
ou `IMMUTABLE`, mais pas de `DEFAULT clock_timestamp()` par exemple.
Si la fonction est fournie par une fonction déclarée comme, ou implicitement,
`VOLATILE`, la réécriture de la table est nécessaire.

Le verrou _Access Exclusive_ reste nécessaire, et peut entraîner quelques
attentes, mais il est relâché beaucoup plus rapidement que si la réécriture
était nécessaire.

La table n'est donc pas réécrite ni ne change de taille. Par la suite,
chaque ligne modifée sera réécrite en intégrant la valeur par défaut. De même, un
`VACUUM FULL` réécrira la table avec ces valeurs par défaut, donnant au final
une table potentiellement beaucoup plus grande qu'avant le `VACUUM` !

La table système `pg_attribute` contient 2 nouveaux champs
`atthasmissing` et `attmissingval` indiquant si un
champ possède une telle valeur par défaut :
```sql
v11=# ALTER TABLE ajouts ADD COLUMN d3 timetz DEFAULT (now()) ;
ALTER TABLE

v11=# SELECT * FROM pg_attribute
   WHERE attrelid = (SELECT oid FROM pg_class WHERE relname='ajouts')
   and atthasmissing = 't' \gx

-[ RECORD 1 ]-+---------------------
attrelid      | 69352
attname       | d3
atttypid      | 1266
attstattarget | -1
attlen        | 12
attnum        | 7
attndims      | 0
attcacheoff   | -1
atttypmod     | -1
attbyval      | f
attstorage    | p
attalign      | d
attnotnull    | f
atthasdef     | t
atthasmissing | t
attidentity   | 
attisdropped  | f
attislocal    | t
attinhcount   | 0
attcollation  | 0
attacl        | 
attoptions    | 
attfdwoptions | 
attmissingval | {16:55:40.017082+02}
```


Pour les détails, voir <https://brandur.org/postgres-default>.

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

## SQL
<div class="slide-content">

  * Index couvrant
  * Objets `PROCEDURE`
  * Contrôle transactionnel en PL
  * JSON
  * PL/pgSQL
  * Fonctions de fenêtrage
  * Autres nouveautés
</div>

<div class="notes">

</div>

-----

### Index couvrant
<div class="slide-content">
  * Déclaration grâce au mot clé `INCLUDE`
  * Uniquement pour les index B-Tree
  * Permet des _Index Only Scan_ en complétant des index uniques
</div>

<div class="notes">
Cette nouvelle fonctionnalité permet d'inclure des colonnes d'une table uniquement dans les feuilles d'un index de type B-Tree. L'index ne pourra pas être utilisé pour faire des recherches sur ces colonnes incluses. L'index sera cependant utilisable pour récupérer directement les informations de ces colonnes incluses sans avoir besoin d'accéder à la table grâce à un `Index Only Scan`. La déclaration se fait par le mot clé `INCLUDE` à la fin de la déclaration de l'index :

```sql
CREATE INDEX index_couvrant ON ma_table
  (lookup_col1, lookup_col2) INCLUDE (autre_col);
```

La version 9.2 de PostgreSQL a apporté `Index Only Scan`. Si l'information est présente dans l'index, il n'est alors pas nécessaire de lire la table pour récupérer les données recherchées : on les lit directement dans l'index pour des gains substantiels de performance ! Mais pour que ce nœud s'active, il faut évidemment que toutes les colonnes recherchées soient présentes dans l'index.

Une colonne sur laquelle aucune recherche n'est faite mais dont on a besoin dans la requête peut être ajoutée à la fin de la liste des colonnes indexées. La requête pourra alors utiliser un `Index Only Scan`. Dans un index couvrant, le nouveau mot clé `INCLUDE` permet de ne pas l'ajouter à la liste des colonnes indexées, mais en plus de ces colonnes. Les colonnes incluses ne sont pas triées et ne peuvent donc pas directement servir aux tris et recherches.

Les index PostgreSQL étant des objets distincts des tables, ajouter des colonnes dans un index duplique de l'information. Cela a un impact en terme de volume sur disque mais également en terme de performance d'insertion et de mise à jour de la table.

Les index couvrants ne changent rien côté taille des index. Leur intérêt premier est de pouvoir ajouter des colonnes dans un index déjà présent (unique notamment) sans devoir déclarer un index distinct.
En effet, PostgreSQL utilise un index unique pour implémenter une contrainte d'unicité sur une ou un ensemble de colonnes. Si on veut pouvoir accéder par `Index Only Scan` à une de ces colonnes uniques ainsi qu'à une autre colonne, il faut créer un nouvel index. Un index couvrant va permettre de ne pas créer de nouvel index en intégrant l'autre colonne recherchée à l'index unique.

</div>

-----

### Objet `PROCEDURE`
<div class="slide-content">
  * Conforme à la norme SQL
  * Création par `CREATE PROCEDURE`
  * Appel avec `CALL`
  * Ne retourne rien
  * Permet un contrôle transactionnel en PL
</div>

<div class="notes">

Création et appel d'une procédure (ici en pur SQL) :
```sql
v11=# CREATE TABLE test1 (a int, b text);
CREATE TABLE

v11=# CREATE PROCEDURE insert_data(a integer, b integer)
      LANGUAGE SQL
      AS $$
        INSERT INTO test1 VALUES (a);
        INSERT INTO test1 VALUES (b);
      $$;
CREATE PROCEDURE

v11=# CALL insert_data(1, 2);
CALL

v11=# SELECT * FROM test1;
 a | b 
---+---
 1 | 
 2 | 
(2 lignes)
```

Les objets de type PROCEDURE sont sensiblement les mêmes que les objets de type FUNCTION.

Les différences sont :

  * l'appel se fait par le mot clé `CALL` et non `SELECT` ;
  * les object de type PROCEDURE ne peuvent rien retourner ;
  * les object de type PROCEDURE permettent un contrôle transactionnel,
ce que ne peuvent pas faire les objets de type FUNCTION.

</div>

-----

### Contrôle transactionnel en PL
<div class="slide-content">
  * Disponible en PL/pgSQL, PL/Perl, PL/Python, PL/Tcl, SPI (C)
  * Utilisable :
    * dans des blocs `DO` / `CALL`
    * dans des objets de type PROCEDURE
  * ne fonctionne pas à l'intérieur d'une transaction
  * incompatible avec une clause `EXCEPTION`
</div>

<div class="notes">
Les mots clés sont différents suivants les langages :

  * SPI : `SPI_start_transaction()`, `SPI_commit()` et `SPI_rollback()`
  * PL/Perl : `spi_commit()` et `spi_rollback()`
  * PL/pgSQL : `COMMIT` et `ROLLBACK`
  * PL/Python : `plpy.commit` et `plpy.rollback`
  * PL/Tcl : `commit` et `rollback`

Voici un exemple avec `COMMIT` ou `ROLLBACK` suivant que le nombre est pair ou impair :
```sql
v11=# CREATE TABLE test1 (a int) ;
CREATE TABLE

v11=# CREATE OR REPLACE PROCEDURE transaction_test1()
      LANGUAGE plpgsql
      AS $$
      BEGIN
        FOR i IN 0..5 LOOP
            INSERT INTO test1 (a) VALUES (i);
            IF i % 2 = 0 THEN
               COMMIT;
            ELSE
               ROLLBACK;
            END IF;
         END LOOP;
      END
      $$;
CREATE PROCEDURE

v11=# CALL transaction_test1();
CALL

v11=# SELECT * FROM test1;
 a | b
---+---
 0 |
 2 |
 4 |
 6 |
 8 |
(5 lignes)
```

Noter qu'il n'y a pas de `BEGIN` explicite dans la gestion des transactions.

On ne peut pas imbriquer des transactions :
```sql
v11=# BEGIN ; CALL transaction_test1() ;
BEGIN
Temps : 0,097 ms
ERROR:  invalid transaction termination
CONTEXTE : PL/pgSQL function transaction_test1() line 6 at COMMIT
```

On ne peut pas utiliser en même une clause `EXCEPTION` et le contrôle transactionnel :
```sql
v11=# DO LANGUAGE plpgsql $$
      BEGIN
        BEGIN
          INSERT INTO test1 (a) VALUES (1);
          COMMIT;
          INSERT INTO test1 (a) VALUES (1/0);
          COMMIT;
        EXCEPTION
          WHEN division_by_zero THEN
             RAISE NOTICE 'caught division_by_zero';
        END;
      END;
      $$;
ERREUR:  cannot commit while a subtransaction is active
CONTEXTE : fonction PL/pgsql inline_code_block, ligne 5 à COMMIT
```

Pour plus de détails, par exemple sur les curseurs :
<https://www.postgresql.org/docs/11/static/plpgsql-transactions.html>

</div>

-----

### PL/pgSQL
<div class="slide-content">
  * Ajout d'une clause `CONSTANT` à une variable
  * Contrainte `NOT NULL` à une variable
</div>

<div class="notes">
FIXME
</div>

-----

### JSON

<div class="slide-content">
  * Conversion de et vers du type jsonb
    * en SQL : booléen et nombre
    * en PL/Perl : tableau et _hash_
    * en PL/Python : `dict` et `list`
  * Conversion JSON en tsvector pour la _Full text Search_
</div>

<div class="notes">

#### Conversion de et vers du type jsonb

**jsonb <=> SQL**

Il existe 4 types primitif en JSON. Voici le tableau de correspondance avec les types PostgreSQL :


| Type Primitif JSON | Type PostgreSQL |
|:------------------:|:---------------:|
|  string            |  text           |
|  number            |  numeric        |
|  boolean           |  boolean        |
|  null              |  (aucun)        |

S'il était déjà possible de convertir des données PostgreSQL natives vers le type jsonb, l'inverse n'était possible que vers le type texte :
```sql
v10=# SELECT 'true'::jsonb::boolean;
ERROR:  cannot cast type jsonb to boolean
LIGNE 1 : SELECT 'true'::jsonb::boolean;
                              ^
v10=# SELECT 'true'::jsonb::text::boolean;
 bool 
------
 t
(1 ligne)

v10=# SELECT '3.141592'::jsonb::float;
ERROR:  cannot cast type jsonb to double precision
LIGNE 1 : SELECT '3.141592'::jsonb::float;
                                  ^
v10=# SELECT '3.141592'::jsonb::text::float;
  float8  
----------
 3.141592
(1 ligne)
```

Il est dorénavant possible de convertir des données de type jsonb vers les types booléen et numérique :
```sql
v11=# SELECT 'true'::jsonb::boolean;
 bool 
------
 t
(1 ligne)

v11=# SELECT '3.141592'::jsonb::float;
  float8  
----------
 3.141592
(1 ligne)
```

**jsonb <=> PL/Perl **

Une transformation a été ajoutée en PL/Perl pour transformer les champs jsonb en champs natif Perl.

Cette fonctionnalité nécessite l'installation de l'extension `jsonb_plperl`. Celle-ci n'est pas installée par défaut. On doit installer le paquet `postgresql11-plperl-11.0` sur RedHat/CentOS et le paquet `postgresql-plperl-11` sur Debian/Ubuntu.

Une fois l'extension activée, on précisera la transformation à utiliser pour charger les paramètres avec le mot clé `TRANSFORM` :

```sql
v11=# CREATE EXTENSION jsonb_plperl CASCADE;
NOTICE:  installing required extension "plperl"
CREATE EXTENSION

v11=# CREATE OR REPLACE FUNCTION fperl(val jsonb)
  RETURNS jsonb
  TRANSFORM FOR TYPE jsonb
  AS $$
    my $arg = shift;
    elog(NOTICE, "Arg is: [$arg]");
    my $keys_str = "";
    for my $key (keys %$arg) {
      $keys_str .= "'".$key."' "
    }
    elog(NOTICE, "JSON keys are: ".$keys_str);
  $$ LANGUAGE plperl;
CREATE FUNCTION

v11=# SELECT fperl('{"1":1,"example": null}'::jsonb);
NOTICE:  Arg is: [HASH(0x1d7e330)]
NOTICE:  jsonb keys are: '1' 'example'
 fperl 
-------
 
(1 ligne)
```

**jsonb <=> PL/Python **

Une transformation a été ajoutée en PL/Python pour transformer les champs jsonb en champs natif Python.

Cette fonctionnalité nécessite l'installation de l'extension `jsonb_plpython`. Celle-ci n'est pas installée par défaut. On doit installer le paquet `postgresql11-plpyhton-11.0` sur RedHat/CentOS. Sur Debian/Ubuntu_ on pourra installer l'extension en version 2 et/ou 3 de Python en utilisant les paquets `postgresql-plpython-11` et `postgresql-plpython3-11`.

Une fois l'extension activée, on précisera la transformation à utiliser pour charger les paramètres avec le mot clé `TRANSFORM` :

```sql
v11=# CREATE EXTENSION jsonb_plpythonu CASCADE;
NOTICE:  installing required extension "plperl"
CREATE EXTENSION

v11=# CREATE OR REPLACE FUNCTION fpython(val jsonb)
  RETURNS jsonb
  TRANSFORM FOR TYPE jsonb
  AS $$
    plpy.info(val)
    keys_str = ""
    for key in val:
      keys_str += "'"+key+"' "
    plpy.info("JSON keys are: " + keys_str)
  $$ LANGUAGE plpythonu;
CREATE FUNCTION

v11=# SELECT fpython('{"1":1,"example": null}'::jsonb);
INFO:  {'1': Decimal('1'), 'example': None}
INFO:  JSON keys are: '1' 'example' 
 fpython 
---------
 
(1 ligne)
```

#### JSON en tsvector pour la _Full Text Search_

La conversion en tsvector permet la recherche plein texte. Couplé à
une indexation adéquate, GIN ou GiST, les fonctionnalités sont
nombreuses et les performances impressionnantes.

Jusqu'à maintenant, les champs JSON était analysés comme des textes,
sans tenir compte de la sémantique. La nouvelle fonction
`jsonb_to_tsvector` permet d'extraire des informations ciblées issues
de champs JSON choisis.  
La fonction prend en premier paramètre la langue et en deuxième
paramètre la structure JSON à analyser. Le troisième paramètre permet
de choisir les valeur à filter :

  * _string_ : les chaines de caractères,
  * _numeric_ : les valeur numérique,
  * _boolean_ : les booléen (`true` et `false`),
  * _key_ : pour inclure toutes les clés de la structure JSON,
  * _all_ : pour inclure tous les champs ci-dessus.

Voici ce que donnait la fonction `to_tsvector` :
```sql
v11=# select to_tsvector('french',
    '{ "a": "Vive la v11 !",
       "b": 5432,
       "c" : { "1": 42, "2": "question", "3": true } }'::jsonb);
         to_tsvector          
------------------------------
 'question':5 'v11':3 'viv':1
(1 ligne)
```

En choisissant l'option de filtre `string`, on obtient le même résultat :
```sql
v11=# select jsonb_to_tsvector('french',
    '{ "a": "Vive la v11 !",
       "b": 5432,
       "c" : { "1": 42, "2": "question", "3": true } }'::jsonb, '["string"]');
      jsonb_to_tsvector       
------------------------------
 'question':5 'v11':3 'viv':1
(1 ligne)
```

La nouvelle fonction donne cependant accès à de nombreux autres modes :
```sql
v11=# select jsonb_to_tsvector('french',
    '{ "a": "Vive la v11 !",
       "b": 5432,
       "c" : { "1": 42, "2": "question", "3": true } }'::jsonb,
     '["numeric", "boolean"]');
    jsonb_to_tsvector    
-------------------------
 '42':3 '5432':1 'tru':5
(1 ligne)

v11=# select jsonb_to_tsvector('french',
    '{ "a": "Vive la v11 !",
       "b": 5432,
       "c" : { "1": 42, "2": "question", "3": true } }'::jsonb,
     '["key"]');
       jsonb_to_tsvector        
--------------------------------
 '1':6 '2':8 '3':10 'a':1 'b':3
(1 ligne)

v11=# select jsonb_to_tsvector('french',
    '{ "a": "Vive la v11 !",
       "b": 5432,
       "c" : { "1": 42, "2": "question", "3": true } }'::jsonb,
     '["all"]');
                 jsonb_to_tsvector
------------------------------------------------------
 '1':12 '2':16 '3':20 '42':14 '5432':9 'a':1 'b':7 \
 'question':18 'tru':22 'v11':5 'viv':3
(1 ligne)
```




</div>

-----

### Fonctions de fenêtrage

<div class="slide-content">
  * Support de l'intégralité des fonctions de fenêtrage de la norme **SQL:2011**
</div>

<div class="notes">
https://www.depesz.com/2018/02/13/waiting-for-postgresql-11-support-all-sql2011-options-for-window-frame-clauses/

FIXME
</div>

-----

### Autre nouveautés
<div class="slide-content">

  * `ANALYSE` et `VACUUM` tables multiples
  * `LOCK TABLE view`
  * Définir le seuil de conversion en _TOAST_ depuis l'ordre `CREATE TABLE`
  * Opérateur `^@` pour les index _SP-GiST_ similaire à `LIKE`
  * Option `recheck_on_update` pour les index fonctionnels

</div>

<div class="notes">
```sql
VACUUM t1, t2
```

FIXME
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

Un bon nombre de commits ont déjà eu lieu. Vous pouvez consulter l'ensemble des
modifications validées pour chaque commit fest :

  * [juillet 2018](https://commitfest.postgresql.org/18/?status=4)
  * [septembre 2018](https://commitfest.postgresql.org/19/?status=4)
  * [novembre 2018](https://commitfest.postgresql.org/20/?status=4)
  * [janvier 2019](https://commitfest.postgresql.org/21/?status=4)
  * [mars 2019](https://commitfest.postgresql.org/22/?status=4)

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
