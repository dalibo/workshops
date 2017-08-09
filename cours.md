# Nouveautés de PostgreSQL 10

![PostgreSQL](medias/z1-elephant-1057465_1280.jpg)

<div class="notes">
Photographie obtenue sur [pixabay](https://pixabay.com/en/elephant-ears-butterfly-1057465/ "elephant-ears-butterfly-1057465").

CC0 Public Domain, Free for commercial use, No attribution required.
</div>

-----

## Introduction

<div class="slide-content">
  * Développement depuis août 2016
  * Version Beta1 sortie le 18/05/2017
  * Version Beta2 sortie le 13/07/2017
  * Sortie de la release prévue en 2017
  * Plus de 1,4 millions de lignes de code *C*
  * Des centaines de contributeurs
</div>


<div class="notes">
La version 10 de PostgreSQL contient plus de 1,4 millions de lignes de code *C*. Son développement est assuré par des centaines de contributeurs répartis partout dans le monde.

Si vous voulez en savoir plus sur le fonctionnement de la communauté PostgreSQL, la présentation intitulée [La communauté des développeurs de PostgreSQL](https://dali.bo/daniel-verite-communaute-dev-pgday "daniel-verite-communaute-dev-pgda") de *Daniel Vérité* est disponible en ligne.
</div>

-----

## Table des matières

<div class="slide-content">
  * Nouveau système de numérotation des versions
  * Changements de nommage
  * Compatibilité
  * Partitionnement
  * Réplication logique
  * Performances
  * Sécurité
  * Autres nouveautés
  * Futur
</div>


<div class="notes">
PostgreSQL 10 apporte un grand nombre de nouvelles fonctionnalités, qui sont d'ores et déjà détaillées dans de nombreux articles comme :

  * [New in postgres 10](https://dali.bo/new-in-postgres-10 "new-in-postgres-10") du projet PostgreSQL
  * [New Features Coming in PostgreSQL 10](https://dali.bo/new-features-coming-in-postgresql-10 "new-features-coming-in-postgresql-10") de *Robert Haas*
  * [PostgreSQL 10 New Features With examples](https://dali.bo/hp-new-features-pg10 "hp-new-features-pg10") de *HP*

Actuellement, deux versions [Beta1](https://dali.bo/pg10-beta1-changes "pg10-beta1-changes") et [Beta2](https://dali.bo/pg10-beta2-changes "pg10-beta2-changes") ont été publiées.
</div>

-----

## Nouveau système de numérotation des versions

<div class="slide-content">
L'ancienne numérotation était composée de 3 nombres :

```
  9 . 5 . 3 
  Majeure1 . Majeure2 . Mineure
```

La nouvelle numérotation ne sera désormais plus exprimée que sur 2 nombres :

```
  10 . 2
  Majeure . Mineure
```
</div>

<div class="notes">
La sortie de PostgreSQL 10 inaugure un nouveau système de numérotation des versions. Auparavant, chaque version était désignée par 3 nombres, comme *9.6.3*. La nouvelle numérotation sera désormais exprimée sur 2 nombres, *10.3* sera par exemple la troisième version mineure de la version majeure *10*.

Josh Berkus a détaillé les raisons de ce changement sur son [blog](https://dali.bo/changing-postgresql-version-numbering "changing-postgresql-version-numbering"), on notera que cela devrait notamment permettre de faciliter la communication externe, certains utilisateurs confondant avec l'ancien nommage les versions mineures et majeures.
</div>

-----

## Changements de nommage - Le répertoire de données

<div class="slide-content">
Afin de clarifier le rôle de ces répertoires qui contiennent non pas des *logs* mais des journaux de transaction ou de commits, les deux renommages suivants ont été effectués dans $PGDATA:

  * *xlog* -> *wal*, le répertoire devient *pg_wal*
  * *clog* -> *xact*, le répertoire devient *pg_xact*

Les outils livrés avec PostgreSQL ont bien sûr été adaptés.

L'ensemble des contibutions de l'écosystème PostgreSQL devra également s'adapter à ces changements de nommage. Pour en savoir plus sur le sujet, vous pouvez consulter l'article [Waiting for PostgreSQL 10 – Rename “pg_xlog” directory to “pg_wal](https://dali.bo/waiting-for-postgresql-10-rename-pg_xlog-directory-to-pg_wal "waiting-for-postgresql-10-rename-pg_xlog-directory-to-pg_wal").
</div>

-----

## Changements de nommage - Changements dans pg_basebackup

<div class="slide-content">
  * L'option *-x* de *pg_basebackup* a été supprimée
  * La méthode de transfert des WAL par défaut a été modifiée, on peut désormais utiliser pour l'option *-X* :
    * *none* : pas de récupération des WAL
    * *fetch* : récupération des WAL à la fin de la copie des données
    * *stream* : streaming, par défaut
  * Nommage des arguments longs :
    * --xlog-method -> --wal-method
    * --xlogdir -> --waldir
</div>

<div class="notes">
Le projet PostgreSQL a considéré que dans la majeure partie des cas, les utilisateurs de *pg_basebackup* souhaitait obtenir une copie cohérente des données, sans dépendre de l'archivage. C'est pourquoi la méthode *stream* est devenue le choix par défaut.
</div>

-----

## Compatibilité - Changements dans les outils

<div class="slide-content">
  * *pg_ctl* attend désormais que l'instance soit démarrée avant de rendre la main (identique au comportement à l'arrêt)
  * Fin de support ou suppression :
    * Type *floating point timestamp*
    * Contribution *tsearch2*
    * Support des BDD < 8.0 dans *pg_dump*
    * Protocole client/serveur 1.0
    * Clause *UNENCRYPTED* pour les mots de passe
</div>

<div class="notes">
Chaque version majeure introduit son lot d'incompatibilités, et il demeure important d'opérer régulièrement, en fonction des contraintes métier bien sûr, des mises à jour de PostgreSQL.
</div>

-----

## Compatibilité - Les outils de la sphère Dalibo

<div class="slide-content">
La plupart des outils sont d'ores et déjà compatibles avec PostgreSQL 10 :

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
</div>

<div class="notes">
Et bien sûr, **patches are welcome**.
</div>

-----

## Partitionnement - Par héritage

<div class="slide-content">
La partitionnement qui existait jusqu'alors se basait sur :

  * la notion d'héritage (1 table mère et des tables filles)
  * des triggers pour orienter les insertions vers les tables filles
  * des contraintes d’exclusion pour optimiser les requêtes
</div>

<div class="notes">
Cette méthode ne répondait pas à toutes les attentes du partitionnement, mais permettait tout de même d'orienter les lignes en fonction de certains critères.

Elle permet également d'ajouter des colonnes dans les tables filles.
</div>

-----

## Partitionnement - Déclaratif

<div class="slide-content">
La version *10* apporte un nouveau système de partitionnement se basant sur de l'infrastructure qui existait déjà dans PostgreSQL.

Avec le nouveau partitionnement, dit *déclaratif* :

  * on n'utilise plus de trigger, les insertions sont donc plus rapides
  * l'administration est simplifiée et directement intégrée au SGBD
  * une colonne clé du partitionnement peut être une expression
  * chaque partition a une contrainte implicite de partitionnement
  * les données insérées sont automatiquement routées dans la bonne partition
  * une partition peut être détachée / attachée à une autre partition
  * la vue *pg_class* a été completée
  * le catalogue *pg_partioned_table* a été ajouté
  * une partition peut être... partitionnée (sous partitions)
</div>

<div class="notes">
Le catalogue *pg_class* a été modifié et indique désormais :

  * si une table est en rapport avec le partitionnement (relispartition = 't' pour les deux)
  * si une table est partionnée (relkind = 'p') ou s'il s'agit d'une partition (relkind = 'r')
  * la représentation interne des bornes du partitionnement (relpartbound)

Le catalogue *pg_partitioned_table* contient les colonnes suivantes :

| Colonne | Contenu |
| ------------ | ------------------------------------------------ |
| partrelid | OID de la table partitionnée référencé dans *pg_class* |
| partstrat | Stratégie de partitionnement ; l = partitionnement par liste, r = partitionnement par intervalle |
| partnatts | Nombre de colonnes de la clé de partitionnement |
| partattrs | Tableau de partnatts valeurs indiquant les colonnes de la table faisant partie de la clé de partitionnement |
| partclass | Pour chaque colonne de la clé de partitionnement, contient l'OID de la classe d'opérateur à utiliser |
| partcollation | Pour chaque colonne de la clé de partitionnement, contient l'OID du collationnement à utiliser pour le partitionnement |
| partexprs | Arbres d'expression pour les colonnes de la clé de partitionnement qui ne sont pas des simples références de colonne |

Si on souhaite vérifier que la table partitionnée ne contient effectivement pas de données, on peut utiliser la clause *ONLY*, comme celà se faisait déjà avec l'héritage.

Lors de la déclaration des partitions, *FROM x TO y* indique que les données *supérieures ou égales à x* et *inférieures à y* (mais pas égales !) seront concernées.
</div>

-----

## Partitionnement - Déclaratif

<div class="slide-content">
Attention notamment aux points suivants :

  * la table mère ne peut pas avoir de données
  * la table mère ne peut avoir d'indexes, donc ni PK, ni UK, ni FK pointant vers elle
  * les partitions ne peuvent avoir de colonnes additionnelles
  * l'héritage multiple n'est pas permis
  * les partitions n'acceptent les valeurs nulles que si la table partitionnée le permet
  * les partitions distantes ne sont pour l'instant pas supportées
  * en cas d'attachement d'une partition :
    * un scan complet de la table est effectué de façon à vérifier qu'aucune ligne ne viole la contrainte de partitionnement
    * il peut être évité en ajoutant au préalable une contrainte *CHECK* identique
</div>

<div class="notes">
Vous pouvez également consulter 4 articles avec des explications ainsi que des exemples concrets :

  * [Partitionnement et transaction autonomes avec PostgreSQL](https://dali.bo/pgday-2017-partitionnement "pgday-2017-partitionnement")
  * [Cool Stuff in PostgreSQL 10: Partitioned Audit Table](https://dali.bo/cool-stuff-in-postgresql-10-partitioned "cool-stuff-in-postgresql-10-partitioned")
  * [PostgreSQL 10 Built-in Partitioning](https://dali.bo/postgresql-10-built-in-partitioning "postgresql-10-built-in-partitioning")
  * [Waiting for PostgreSQL 10 – Implement table partitioning](https://dali.bo/waiting-for-postgresql-10-implement-table-partitioning "waiting-for-postgresql-10-implement-table-partitioning")

Enfin, si PostgreSQL apporte de nombreuses fonctionnalités nativement, il peut néanmoins être également pertinent d'utiliser l'extension [pg_partman](https://dali.bo/pg-partman "pg-partman").
</div>

FIXME: remplacement de UNBOUNDED par MINVALUE et MAXVALUE dans la beta3 ?

## Réplication logique - Introduction

<div class="slide-content">
Avec la version 10 de PostgreSQL on peut noter :

  * l'intégration partielle de l’extension *pglogical* dans le cœur de Postgres
  * la réutilisation de l’infrastructure de réplication physique (streaming, slots)
  * la réplique des ensembles de tables d’une base de données lors de la création de la souscription (facultatif)
  * la possibilité de filtrer sur les verbes (INSERT / UPDATE / DELETE)
  * le support des réplications entre différentes versions majeures de postgres
  * le fait que les tables répliquées peuvent avoir des index différents

Quelques usages typiques :

  * alimentation d'une base de données de type *datawarehouse*
  * déport sur un serveur secondaire de traitements lourds
  * changement de version majeure de PostgreSQL sans arrêt de service

À noter :

  * Vues *pg_stat_replication* et *pg_stat_subscription*
  * Attention, ne réplique pas les *DDL* et les *TRUNCATE*
</div>

<div class="notes">
Ce nouveau type de réplication supporte la recopie des tables à la création de la souscription, ce qui peut s'avérer être très pratique. Pour en savoir plus sur ce sujet, vous pouvez consulter l'article [Waiting for PostgreSQL 10 – Logical replication support for initial data copy](https://dali.bo/waiting-for-postgresql-10-logical-replication-support-for-initial-data-copy "waiting-for-postgresql-10-logical-replication-support-for-initial-data-copy"). Sur le sujet plus général de la réplication logique, la lecture de l'article intitulé [Waiting for PostgreSQL 10 – Logical replication](https://dali.bo/waiting-for-postgresql-10-logical-replication "waiting-for-postgresql-10-logical-replication") est également conseillée.
</div>

-----

## Réplication logique - Fonctionnement

<div class="slide-content">
Fonctionnement de la réplication logique :

FIXME: schéma (reprendre celui du diaporama de Philippe)
</div>

-----

## Réplication logique - Les souscriptions

<div class="slide-content">
Souscriptions multiples :

FIXME: schéma (reprendre celui du diaporama de Philippe)
</div>

-----

## Performances - Les tris

<div class="slide-content">
  * Gains très significatifs au niveau des performances
  * Exemple avec les tris, à vérifier avec votre environnement...

Création de la table de test, du jeu de données, et calcul des statistiques :

```sql
CREATE TABLE test AS SELECT i FROM generate_series(1, 1000000) i;
INSERT INTO test SELECT i FROM test;
INSERT INTO test SELECT i FROM test;
VACUUM ANALYZE test;
```

SELECT avec PostgreSQL 9.6 :

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

SELECT avec PostgreSQL 10 :

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

## Performances - Les agrégats

<div class="slide-content">
Dans le même genre, les noeuds *HashAggregate* ont été améliorés.

Par exemple :

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

FIXME: plans d'exécution, explications
</div>

-----

## Performances - Le parallèlisme

<div class="slide-content">
Les noeuds suivants sont désormais gérés :

  * *Parallel Bitmap Heap Scan*
  * *Parallel Index Scan*
  * *Gather Merge*
  * *Parallel Merge Join*

À noter également :

  * différentes améliorations
  * davantage de fonctions en langage procédural (*PL/pgsql*)
  * le GUC *max_parallel_workers*
</div>

<div class="notes">
Pour en savoir plus sur le sujet du parallèlisme, le lecteur pourra consulter l'article [Parallel Query v2](https://dali.bo/parallel-query-v2 "parallel-query-v2") de *Robert Haas*.
</div>


-----

## Sécurité

<div class="slide-content">
  * Méthode d'authentification *SCRAM-SHA-256*, plus robuste que *MD5* pour la négociation et le stockage des mots de passe
  * Vue *pg_hba_file_rules*
  * Nouvel attribut pour l'instruction *CREATE POLICY* des *Row Level Security* :
    * *PERMISSIVE* : les politiques d’une table sont reliées par des *OR* (valeur par défaut)
    * *RESTRICTIVE* : les politiques d’une table sont reliées par des *AND*
  * Nouveaux rôles de monitoring permettant d'éviter l'attribut *SUPERUSER* :

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
  * Réplication avec quorum, c'est à dire qu'un *commit* doit par exemple être acquitté par 2 serveurs synchrones. Exemples :
    * *synchronous_standby_names* = FIRST 2 (node1,node2);
    * *synchronous_standby_names* = ANY 2 (node1,node2,node3);
  * Gestion du *failover* dans le protocole *libpq* (on se connecte au premier serveur qui répond)
  * Gestion de la compression dans *pg_receivewal* (via *libz*, avec un ratio entre 0 et 9)
  * Améliorations diverses sur les *FDW* (ex : "SELECT COUNT(\*) FROM foreign_table")
  * Bibliothèque  de collations *ICU* indépendante de l'OS
  * Slots de réplication temporaires
</div>

<div class="notes">
Il est désormais possible dans *libpq*de spécifier plusieurs serveurs, ainsi que des attributs qui permettront par exemple de trouver le serveur qui accepte les écritures.

Un slot de réplication (utilisation par la réplication, par *pg_basebackup*, etc.) peut désormais être créé temporairement :

```sql
postgres=# SELECT pg_create_physical_replication_slot('workshop', true, true);
 pg_create_physical_replication_slot 
-------------------------------------
 (workshop,0/1620288)
(1 row)
```

Pour compléter ces informations, vous pouvez également consulter :

  * [Waiting for PostgreSQL 10 – Implement multivariate n-distinct coefficients](https://dali.bo/waiting-for-postgresql-10-implement-multivariate-n-distinct-coefficients "waiting-for-postgresql-10-implement-multivariate-n-distinct-coefficients")
  * [Waiting for PostgreSQL 10 – postgres_fdw: Push down aggregates to remote servers](https://dali.bo/waiting-for-postgresql-10-postgres_fdw-push-down-aggregates-to-remote-servers "waiting-for-postgresql-10-postgres_fdw-push-down-aggregates-to-remote-servers")
</div>

-----

## Autres nouveautés - Pour les développeurs

<div class="slide-content">
  * *Full Text Search* sur des colonnes de type *JSON* et *JSONB*
  * Possibilité de renommer les valeurs des types énumérations (*ALTER TYPE ... RENAME VALUE*)
  * Nouveau catalogue *pg_sequence*
  * *XMLTABLE* :
    * Norme *SQL/XML*
    * Permet de voir des éléments de documents *XML* sous forme de table relationnelle
    * Une clause *XMLTABLE* dans la clause FROM définit le mapping entre éléments XML et colonnes
  * Tables de transition pour les triggers (les triggers de type AFTER et de niveau STATEMENT peuvent voir les lignes avant et/ou après modification)
  * Gestion des séries conforme à la norme SQL
    * Colonne SERIAL => INT GENERATED BY DEFAULT AS IDENTITY
    * Plus souple pour :
      * Gestion de la séquence (permissions, RESTART, ajout et suppression du DEFAULT par ALTER TABLE)
      * Copie de la table
    * On peut forcer l’usage de la séquence avec GENERATED ALWAYS AS IDENTITY
  * Les index *hash* sont utilisables !
    * Journalisés => "crash safe" + réplicables
    * Amélioration des performances
    * Supportés par la contribution *pageinspect*
  * Scripting conditionnel
  * \\GX
</div>

<div class="notes">
Pour en savoir plus :

  * [Waiting for PostgreSQL 10 – Full Text Search support for json and jsonb](https://dali.bo/waiting-for-postgresql-10-full-text-search-support-for-json-and-jsonb "waiting-for-postgresql-10-full-text-search-support-for-json-and-jsonb")
  * [Waiting for PostgreSQL 10 – Add pg_sequence system catalog](https://dali.bo/waiting-for-postgresql-10-add-pg_sequence-system-catalog "waiting-for-postgresql-10-add-pg_sequence-system-catalog")
  * [Waiting for PostgreSQL 10 – Support XMLTABLE query expression](https://dali.bo/waiting-for-postgresql-10-support-xmltable-query-expression "waiting-for-postgresql-10-support-xmltable-query-expression")
  * [Waiting for PostgreSQL 10 – Implement syntax for transition tables in AFTER triggers](https://dali.bo/waiting-for-postgresql-10-implement-syntax-for-transition-tables-in-after-triggers "waiting-for-postgresql-10-implement-syntax-for-transition-tables-in-after-triggers")
  * [Waiting for PostgreSQL 10 – Identity columns](https://dali.bo/waiting-for-postgresql-10-identity-columns "waiting-for-postgresql-10-identity-columns")
  * [Waiting for PostgreSQL 10 – hash indexing vs. WAL](https://dali.bo/waiting-for-postgresql-10-hash-indexing-vs-wal "waiting-for-postgresql-10-hash-indexing-vs-wal")
  * [Waiting for PostgreSQL 10 – Support \\if … \\elif … \\else … \\endif in psql scripting](https://dali.bo/waiting-for-postgresql-10-support-if-elif-else-endif-in-psql-scripting "waiting-for-postgresql-10-support-if-elif-else-endif-in-psql-scripting")
  * [Waiting for PostgreSQL 10 – psql: Add \\gx command](https://dali.bo/waiting-for-postgresql-10-psql-add-gx-command "waiting-for-postgresql-10-psql-add-gx-command")
  * [Cool Stuff in PostgreSQL 10: Transition Table Triggers](https://dali.bo/cool-stuff-in-postgresql-10-transition "cool-stuff-in-postgresql-10-transition")
  * [ALTER TYPE](https://www.postgresql.org/docs/10/static/sql-altertype.html)
</div>

-----

## Futur

<div class="slide-content">
  * FIXME: PostgreSQL 11...

Attention, les utilisateurs des versions Beta doivent considérer que les mises à jour concernent des versions majeures. Ceci permettra notamment de pouvoir contourner toutes les incompatibilités ou changements de comportement dûs au fait que PostgreSQL 10 est toujours en développemet.
</div>

<div class="notes">
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
