# Nouveautés de PostgreSQL 9.6


![PostgreSQL](medias/z1-elephant-1057465_1280.jpg)

<div class="notes">


Photographie obtenue sur https://pixabay.com/en/elephant-ears-butterfly-1057465/

CC0 Public Domain, Free for commercial use, No attribution required
</div>

-----


## Introduction

<div class="slide-content">

  * Développement commencé en juin 2015
  * Version Beta1 sortie le 12 mai 2016
  * Sortie le 29 septembre 2016
</div>


<div class="notes">


Comme toutes les versions majeures de PostgreSQL, le développement se fait en
un peu plus d'un an et est suivi de plusieurs mois de tests approfondis. Le
développement de la version 9.6 a donc commencé en juin 2015. Cette version
est toujours en développement. Aucune version alpha n'a été proposée, les
développeurs ont choisi de travailler sur des versions bêta. La version finale
est sortie le 29 septembre 2016.

Au niveau de l'organisation, une Release Team a été montée depuis mai 2016
pour suivre la bonne gestion des open items (problèmes à résoudre avant la
sortie de la version finale) et pour s'assurer de la sortie en temps et en heure
de la version finale qui devrait être disponible fin septembre.

Afin de pouvoir facilement identifier les nouvelles fonctionnalités que
proposent cette mouture par rapport à une version précédente, vous pouvez
vous rendre sur le site [http://www.postgresql.org/about/featurematrix/](http://www.postgresql.org/about/featurematrix/)
: ceci vous permettra d'avoir une vue cumulative de ces fonctionnalités.
</div>



-----


## Au menu

<div class="slide-content">

* Performances
  * Administration
  * SQL
  * Monitoring
  * Régressions / changements
  * Et une petite ouverture vers le futur
</div>


<div class="notes">

</div>



-----


## Performances

<div class="slide-content">

  * Parallélisme :
    * parcours séquentiel
    * jointure
    * agrégation
  * Index bloom
  * Améliorations globales
    * checkpoint
</div>


<div class="notes">


La grosse amélioration au niveau des performances est l'ajout du parallélisme.
Cependant, les développeurs de PostgreSQL n'en sont pas restés et proposent
des évolutions qui auront des conséquences très positives pour les
performances.
</div>



-----


### Parallélisme

<div class="slide-content">

  * Avant la 9.6
    * une requête = un processus
    * pas de multithreading
  * À partir de la 9.6
    * toujours pas de multithreading
    * toujours un processus pour une session
    * mais il peut être aidé par d'autres processus appelés **workers**
</div>


<div class="notes">


PostgreSQL fonctionne en mode multi-processus avec mémoire partagée. Il a
été décidé que ce dernier ne fonctionnerait pas sur le principe des threads
(en raison de la complexité que cela pouvait engendrer au développement, voir [
Why don't you use threads?](
https://wiki.postgresql.org/wiki/Developer_FAQ#Why_don.27t_you_use_threads.2C_raw_devices.2C_async-I.2FO.2C_.3Cinsert_your_favorite_wizz-bang_feature_here.3E.3F)
).

Dans le cas classique donc, une session qui exécute une requête va utiliser un
cœur de processeur pour effectuer son calcul.

Il n'est plus rare aujourd'hui de voir des processeurs avec plus de dix cœurs
et des serveurs avec plus de deux emplacements pour processeurs. Ainsi les
serveurs disposent de plusieurs dizaines de cœurs disponibles. Dans le cas d'
une utilisation dite "transactionnelle" (ou OLTP) de l'instance PostgreSQL, avec
beaucoup de sessions exécutant de nombreuses petites requêtes, ces derniers
sont utilisés à bon escient.

Mais dans le cas d'une utilisation dite "décisionnelle" (ou OLAP), avec
peu de
sessions mais exécutant des requêtes complexes, on peut se retrouver
avec une
partie de la puissance de calcul de la machine qui n'est pas
utilisée au vu de
cette limitation.

Une manière d'optimiser l'utilisation des ressources, et éventuellement
d'améliorer les performances, serait de pouvoir utiliser deux processus ou
plus
pour partager la charge de calcul engendrée par cette opération.

Longtemps attendue, cette fonctionnalité, le parallélisme, fait partie de
la version 9.6.
</div>



-----


### Parallélisme : Opérations

<div class="slide-content">

  * Parcours séquentiel
  * Jointure
  * Agrégation
  * Uniquement les requêtes en lecture !
</div>


<div class="notes">


La version 9.6 intègre la parallélisation pour différentes opérations : les
parcours séquentiels, les jointures et les agrégats. Mais attention, cela ne
concerne que les requêtes en lecture : pas les `INSERT`/`UPDATE`/`DELETE`, pas les CTE en
écriture, pas les opérations de maintenance (`CREATE INDEX`, `VACUUM`, `ANALYZE`).

Les prochains chapitres vont détailler les différentes opérations
actuellement parallélisables.
</div>



-----


### Parallélisme : Paramètres 1/2

<div class="slide-content">

  * `max_worker_processes` : Nombre max de background worker
  * `max_parallel_workers_per_gather` : Nombre max de worker par gather
  * `min_parallel_relation_size` : Taille min de la relation pour déclencher le parallélisme
    * Possibilité de forcer le nombre de worker possible pour une table :
    *  `SET (parallel_workers = x)`
</div>


<div class="notes">


Dans un premier temps, il faut définir les paramètres suivants :


  * `max_worker_processes` : nombre maximum de processus supplémentaires pouvant être lancés par l'instance. Par défaut à 8. Ce paramètre est global à tous les background worker. Par exemple, si vous avez deux background worker déjà en place (extension ...), seulement 6 workers pourront être lancés pour la parallélisation.
  * `max_parallel_workers_per_gather` : nombre maximum de workers qu'un processus pourra utiliser. Par défaut à 2
pendant la beta, à 0 depuis la RC1. **Autrement dit, le parallélisme est désactivé par défaut!**. C'est une limite par **gather**, si une
requête utilise plusieurs gathers elle pourra dépasser ce seuil.
  * `min_parallel_relation_size` : taille minimale de la relation pour déclencher le parallélisme. Par
défaut à 8 Mo.
  * Il est aussi possible de forcer le nombre de workers possible pour une table
avec l'instruction `SET (parallel_workers = x)` à la création de la table `CREATE TABLE xxx SET (parallel_workers = x)` ou en modifiant les
propriétés d'une table déjà présente : `ALTER TABLE xxx SET (parallel_workers = x)`


La modification de ces paramètres nécessite un rechargement de la
configuration sauf pour `max_worker_processes` qui nécessite un redémarrage.
</div>



-----


### Parallélisme : Paramètres 2/2

<div class="slide-content">

  * `parallel_setup_cost` : Coût de la mise en place du parallélisme
  * `parallel_tuple_cost` : Coût pour passer une ligne d'un worker au gather.
</div>


<div class="notes">


La mise en place du parallélisme représente un coût : Il faut mettre en place
une mémoire partagée, lancer des processus... Ce coût est pris en compte par
le planificateur à l'aide du paramètre `parallel_setup_cost`. Par ailleurs, le transfert d'
enregistrement entre un worker et un autre processus a également un coût
représenté par le paramètre `parallel_tuple_cost`.

Ainsi une lecture complète d'une grosse table peut être moins couteuse sans
parallélisation du fait que le nombre de lignes retournées par les workers est
très important. En revanche, en filtrant les résultats, le nombre de lignes
retournées peut être moins important et le planificateur peut être amené à
choisir un plan comprenant la parallélisation.
</div>



-----


### Parcours séquentiel parallèle : explications 1

<div class="slide-content">

  * Traitement des blocs par processus
  * Compteur de blocs
    * Parallel Heap Scan Current Block
  * Fonctionne en mode partiel
    * impossible à utiliser avec des données à trier
</div>


<div class="notes">


Le processus de la session connectée va devoir diviser l'activité
qu'il doit
traiter par le biais du planificateur. Il réalise cette
opération en créant
des processus supplémentaires, appelés workers, qui
pourront chacun utiliser un
cœur.

En mémoire partagée est créé un compteur : PHSCB pour parallel heap
scan
current block, commun au processus initial ainsi qu'aux workers
supplémentaires
créés par ce dernier.
Ce compteur contient le numéro du bloc de données à lire. Chaque worker
va aller poser un verrou (Spin Lock) sur ce compteur pour le lire et
l'
incrémenter, puis relâche le verrou et va travailler sur les données
qu'il s'
est affecté par ce biais. L'autre worker procède de la même
manière et ainsi
de suite.

Le processus initial peut lui aussi travailler sur les données s'il n'est
pas constamment occupé à traiter les données renvoyées par les workers.
C'est de cette manière que les différents processus se partagent la tâche.

Les fonctions supportées par le parallélisme doivent donc pouvoir
fonctionner
en mode partiel, c'est pourquoi le parallélisme n'est pour
l'instant supporté qu'en lecture, et ne fonctionne pas pour des
requêtes dont
les données ont besoin d'être triées.
</div>



-----


### Parcours séquentiel parallèle : exemple 1

<div class="slide-content">

  * Exemple d'une table `test_parallel_little`
    * une seule colonne
    * non indexée
    * contenant 500 000 lignes
</div>


<div class="notes">


On insère 500 000 lignes dans une table de test, ce qui
représente environ 17
Mo.
</div>



-----


### Exemple 1 : jeu de tests

<div class="slide-content">


```sql
CREATE TABLE test_parallel_little (id int);

INSERT INTO test_parallel_little
  SELECT generate_series(0,500000);

SELECT n.nspname as "Schema",
       c.relname as "Name",
       pg_size_pretty(pg_table_size(c.oid)) as "Size"
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE c.relname = 'test_parallel_little';


 Schema |     Name      |  Size
--------+---------------+--------
 public | test_parallel | 17 MB
```


</div>


<div class="notes">


Il n'existe pas d'index sur cette colonne et la taille est supérieure au
seuil
de 8Mo défini au niveau du paramètre `min_parallel_relation_size`. En faisant une
extraction sur cette
table, on se trouve dans les conditions nécessaires pour
le déclenchement d'un
parcours séquentiel parallélisé.
</div>



-----


### Exemple 1 : plan

<div class="slide-content">


```sql
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT * FROM test_parallel_little WHERE id = 12;

 Gather  (cost=1000.00..6889.58 rows=1 width=4)
         (actual time=30.300..30.385 rows=1 loops=1)
   Output: id
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=2264
   ->  Parallel Seq Scan on public.test_parallel_little
       (cost=0.00..5889.48 rows=1 width=4)
       (actual time=18.568..27.957 rows=0 loops=2)
         Output: id
         Filter: (test_parallel_little.id = 124862)
         Rows Removed by Filter: 250000
         Buffers: shared hit=2213
         Worker 0: actual time=7.054..25.832 rows=1 loops=1
           Buffers: shared hit=978
 Planning time: 0.141 ms
 Execution time: 31.862 ms
(14 lignes)
```


</div>


<div class="notes">


En regardant le plan, on constate que l'on a utilisé le parallélisme mais avec
un worker seulement, la charge a été divisée entre le Gather (processus
principal) et le worker 0.
</div>



-----


### Parcours séquentiel parallèle : explications 2

<div class="slide-content">

  * Taille de la table = T
  * `min_parallel_relation_size` = S
  * Si T < S, pas de worker
  * Si T > S, un worker
  * Si T > Sx3, un worker supplémentaire (2)
  * Si T > Sx3x3, deux workers supplémentaires (3)
  * Si T > Sx3^3, trois workers supplémentaires (4)
</div>


<div class="notes">


Par exemple, dans notre cas :


  * à partir de 24 Mo on passe à 2 workers
  * à partir de 72 Mo on passe à 3 workers
  * à partir de 216 Mo on passe à 4 workers
  * à partir de 648 Mo on passe à 5 workers

et ainsi de suite dans la limite du nombre de workers qu'il est possible de
créer.
</div>



-----


### Parcours séquentiel parallèle : exemple 2

<div class="slide-content">

  * Exemple d'une table test_parallel
    * une seule colonne
    * non indéxée
    * contenant 5 000 000 lignes
</div>


<div class="notes">


Testons avec une table plus volumineuse.
</div>



-----


### Exemple 2 : jeu de tests

<div class="slide-content">


```sql
CREATE TABLE test_parallel_little (id int);

INSERT INTO test_parallel_little
  SELECT generate_series(0,5000000);

SELECT n.nspname as "Schema",
       c.relname as "Name",
       pg_size_pretty(pg_table_size(c.oid)) as "Size"
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE c.relname = 'test_parallel';

 Schema |     Name      |  Size
--------+---------------+--------
 public | test_parallel | 173 MB
```


</div>


<div class="notes">


On insère 5 millions de lignes dans une table de test, ce qui représente
environ 173 Mo.
</div>



-----


### Exemple 2 : plan

<div class="slide-content">


```sql
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT * FROM test_parallel WHERE id=12;
 Gather  [...]
   Output: id
   Workers Planned: 3
   Workers Launched: 3
   Buffers: shared hit=5465 read=16812
   ->  Parallel Seq Scan on public.test_parallel  [...]
         Output: id
         Filter: (test_parallel.id = 124862)
         Rows Removed by Filter: 1250000
         Buffers: shared hit=5312 read=16812
         Worker 0: actual time=3.766..139.729 rows=1...
           Buffers: shared hit=1748 read=5466
         Worker 1: actual time=138.532..138.532 rows=0...
           Buffers: shared hit=812 read=2669
         Worker 2: actual time=138.508..138.508 rows=0...
           Buffers: shared hit=816 read=2683
 Planning time: 0.120 ms
 Execution time: 151.700 ms
(18 lignes)
```


</div>


<div class="notes">


Détaillons un peu ce plan d'exécution :

```
   Workers Planned: 3
   Workers Launched: 3
```

Cette partie signifie que le
planificateur a choisi que trois workers
devraient être utilisés pour traiter
cette opération (Workers Planned), et
qu'en effet, trois workers ont été
utilisés pour la réaliser (Workers Launched).

Si par exemple, la limite des workers définie dans `max_worker_processes`
est atteinte, on pourra se retrouver avec l'information suivante :

```
   Workers Planned: 3
   Workers Launched: 1
```

Concernant la
répartition de la charge, dans le cas du parcours
séquentiel parallélisé, c'
est assez simple, chacun des trois
workers supplémentaires prend à sa charge une partie des données à lire.

```
         Worker 0: actual time=3.766..139.729 rows=1 loops=1
           Buffers: shared hit=1748 read=5466
         Worker 1: actual time=138.532..138.532 rows=0 loops=1
           Buffers: shared hit=812 read=2669
         Worker 2: actual time=138.508..138.508 rows=0 loops=1
           Buffers: shared hit=816 read=2683
```

Dans
notre exemple, le premier processus à lu 7214 blocs (1748+5466), le second
en a
lu 3481 (812+2669) et le dernier 3499 (816+2683).

C'est dans la partie des données traitées par le premier worker que
la ligne
concernée a été trouvée.

Le processus principal lit lui aussi des données :

```
         Buffers: shared hit=5312 read=16812
```

Et la partie supérieure (
Gather) donne le détail de l'assemblage des
informations fournies par les trois
workers :

```
 Gather  (cost=1000.00..43285.39 rows=1 width=4) (actual time=150.116..150.190
  rows=1 loops=1)
   Output: id
   Workers Planned: 3
   Workers Launched: 3
   Buffers: shared hit=5465 read=16812
```


Si on regarde du côté des processus postgres :

```
UID        PID  CMD
postgres   341  /usr/pgsql-9.6/bin/postmaster -D /var/lib/pgsql/9.6/data
postgres   343   \_ postgres: logger process
postgres   345   \_ postgres: checkpointer process
postgres   346   \_ postgres: writer process
postgres   347   \_ postgres: wal writer process
postgres   348   \_ postgres: autovacuum launcher process
postgres   349   \_ postgres: archiver process
postgres   350   \_ postgres: stats collector process
postgres   455   \_ postgres: postgres postgres [local] SELECT
postgres   550   \_ postgres: bgworker: parallel worker for PID 455
postgres   551   \_ postgres: bgworker: parallel worker for PID 455
```


On voit bien que trois
processus `worker` ont été créés et sont relatifs à
la session de PID 455, qui
est la session dans laquelle on a lancé notre
EXPLAIN. On voit aussi que ce ne sont pas des fils directs du processus en
communication avec le client, mais des fils du processus `postmaster`.
</div>



-----


### Parallélisme sur une jointure

<div class="slide-content">


```sql
EXPLAIN SELECT * FROM big b1 JOIN big bg2 USING (id);
                  QUERY PLAN
-------------------------------------------------------
 Hash Join  [...]
   Hash Cond: (b1.id = bg2.id)
   ->  Gather  [...]
         Workers Planned: 2
         ->  Parallel Seq Scan on big b1  [...]
   ->  Hash  [...]
         ->  Gather  [...]
               Workers Planned: 2
               ->  Parallel Seq Scan on big bg2  [...]
(9 rows)
```


</div>


<div class="notes">


Dans le cas d'une jointure classique, on a un premier parcours d'une table, puis
le calcul d'une table
de hachage, puis le parcours de la seconde table tenant compte du calcul
précédent.

Dans le cas d'une jointure parallélisée, les parcours séquentiels sont
parallélisés, comme dans le
cas d'un parcours classique et c'est le nœud
Gather qui s'occupe de réaliser le calcul du hachage
(première étape) puis la jointure en tant que telle (deuxième étape).

Il est aussi possible de constater une vraie parallélisation de la réalisation
de la jointure, où les
opérations de création de la table de hachage et le premier parcours de la
table sont faits en parallèle.
Néanmoins, chaque worker créant sa table de hachage, on en crée donc autant
qu'il y a de workers utilisés
pour la parallélisation.
Le parcours suivant est lui aussi fait en parallèle et les informations sont
finalement agrégées par le
nœud gather.
</div>



-----


### Parallélisme sur une agrégation

<div class="slide-content">


```sql
EXPLAIN (ANALYZE)
SELECT count(*), min(C1), max(C1) FROM t1;

                           QUERY PLAN
---------------------------------------------------------------------
 Finalize Aggregate
 (actual time=1766.820..1766.820 rows=1 loops=1)
   ->  Gather
       (actual time=1766.767..1766.799 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate
             (actual time=1765.236..1765.236 rows=1 loops=3)
               ->  Parallel Seq Scan on t1
                   (actual time=0.021..862.430 rows=6666667
                    loops=3)
 Planning time: 0.072 ms
 Execution time: 1769.164 ms
(8 rows)
```


</div>


<div class="notes">


Le principe est globalement le même.

Pour les fonctions type min et max, chacun des workers va récupérer la
valeur
minimale ou maximale des données qu'il traite, et ensuite le
nœud Gather va se
charger de comparer les valeurs intermédiaires pour
renvoyer la valeur minimale ou maximale pour l'ensemble des données.

Pour une fonction de comptage, de même, chacun des workers compte le
nombre de
lignes qu'il traite et le nœud Gather fait la somme de
l'ensemble.

Pour la fonction average, chacun des nœuds renvoie la somme des valeurs
traitées et le nombre de valeurs traitées. Le nœud Dather se charge de

calculer réellement la moyenne.

Les valeurs intermédiaires sont calculées par les nœuds `Partial Aggregate`,
et la valeur finale est renvoyée par le nœud `Finalize Aggregate`.
</div>



-----


### Parallélisation : limitations

<div class="slide-content">

  * Les fonction doivent être _Parallel Safe_
  * Il faut indiquer au planificateur qu'une fonction peut être utilisée :
    * Dans un gather et worker : `PARALLEL SAFE`
    * Dans un gather uniquement `RESTRICTED`
    * Ne peut pas être utilisée pour la parallélisation : `PARALLEL UNSAFE`
  * Pas de parallélisation pour :
    * Requête effectuant des écritures ou posant des verrous
    * Une requête qui pourrait être suspendue pendant son exécution. Exemple `CURSOR`
    * Une sous requête exécutée dans une requête déjà parallélisée.
    * Niveau d'isolation _serializable_
</div>


<div class="notes">

</div>



-----


### Index bloom

<div class="slide-content">

Infrastructure pour de nouvelles méthodes d'accès sous forme d'extensions.

  * Premier exemple : les index **bloom**
    * extension
    * basés sur la probabilité de présence, avec perte
    * plus petits mais impliquent un accès à la table
    * permettent d'avoir un index pour des **recherches multicritères** si les btree sont impraticables ou trop gros
    * égalité seulement pour entiers et chaînes
</div>


<div class="notes">


Cette version apporte l'infrastructure pour ajouter de nouvelles méthodes d'accès sous forme d'extension. Il sera ainsi possible d'ajouter un nouveau type d'index sans dépendre de la version majeure (à partir de la 9.6 bien entendu). Actuellement seul le support des index bloom a été ajouté. Il y a de fortes chances pour que nouveaux types d'index soient proposés sous forme d'extension.


</div>



-----


### Divers - Checkpoint

<div class="slide-content">

  * Avant
    * écriture aléatoire car blocs lus dans l'ordre du cache
  * Après
    * parcours intégral des blocs pour trier et mutualiser les écritures
  * `checkpoint_flush_after` : Flush les données sur disques tous les X octets
    * Permet d'éviter le tuning des options `dirty_background_*` du kernel
</div>


<div class="notes">


L'opération checkpoint a été améliorée dans cette version.

L'opération checkpoint permet d'écrire réellement les
données se trouvant
encore dans le cache disque de PostgreSQL et de valider définitivement
que ces dernières ne pourront pas être perdues (elles ont été écrites
précédemment dans
les WAL).

Auparavant, le checkpoint synchronisait ces données dans l'ordre dans lequel
il les trouvait en cache vers les fichiers. Désormais, il réalise un parcours
intégral des données, ce qui lui permet de synchroniser les données en
fonction de leur destination : par tablespace, puis par relation, puis par
numéro de fork, puis par numéro de bloc.
</div>



-----


### Divers - Tri

<div class="slide-content">

  * Gain sur les opérations de tris
    * `replacement_sort_tuples`
    * Meilleure utilisation du cache des CPU
</div>


<div class="notes">


Lorsque le nombre d’enregistrements à trier est de moins de `replacement_sort_tuples`, le moteur
utilise un autre algorithme de tri plus performant qui exploite mieux le cache
du CPU.
</div>



-----


## Administration

<div class="slide-content">

  * Gestion des slots de réplication pour `pg_basebackup`
  * Sauvegardes à chaud concurrentes
  * Réplication synchrone sur plusieurs nœuds
  * Amélioration des Foreign Data Wrapper
  * Amélioration du freeze
    * et nouvelle extension : `pg_visibility`
  * Divers
    * `pg_config`, `pg_control*`
</div>


<div class="notes">

</div>



-----


### Slots de réplication pour pg_basebackup

<div class="slide-content">

  * Nouvelle option
    * `-S slotname` ou `--slot=slotname`
    * s'utilise obligatoirement avec `-X stream`
  * Plus besoin d'archivage pour créer un serveur secondaire
    * sans aucun risque
</div>


<div class="notes">


Voici la commande complète pour créer un secondaire à distance :

```
$ /usr/pgsql-9.6/bin/pg_basebackup  -d 'host=127.0.0.1 port=5432
user=replication password=repli application_name=standby2' \
-D /pg_data/9.6/instance2/ -R -S standby2 -X stream
```


Cette
fonctionnalité permet à `pg_basebackup` de connaître le slot de réplication à utiliser
et donc de le définir automatiquement dans le fichier `recovery.conf` grâce à l'option `-R`.

Dans le cas d'une instance secondaire qui utilise les slots de réplication,
cela permet aussi d'assurer que le serveur primaire va conserver tous les WAL
nécessaires au serveur esclave tant que la restauration n'est pas terminée.
Ainsi, on peut facilement démarrer le serveur esclave sans mettre en place d'
archivage des journaux.
</div>



-----


### Sauvegardes à chaud concurrentes

<div class="slide-content">

  * Déjà possible avec `pg_basebackup`...
    * mais pas en manuel avec `pg_start_backup()`
  * Nouvelle API
  * `pg_start_backup()` et `pg_stop_backup()`
    * paramètre supplémentaire pour utilisation concurrente
    * par défaut à false
  * Contraintes lorsqu'on utilise l'option concurrente
    * maintien de la session
    * plus de `backup_label`
    * => Privilégier des outils supportant cette fonctionnalité.
</div>


<div class="notes">


Une nouvelle API existe désormais pour réaliser des sauvegardes physiques

concurrentes.
En effet, avant la version 9.6, il était impossible de réaliser plusieurs
sauvegardes physiques simultanées avec la méthode s'appuyant sur les
commandes
`pg_start_backup()` et `pg_stop_backup()`.

Une nouvelle API est donc disponible depuis la 9.6 qui permet de lancer
plusieurs sauvegardes physiques en parallèle.

Néanmoins, les contraintes concernant la réalisation de cette sauvegarde
sont bien plus importantes. En effet, la session qui exécute la
commande `pg_start_backup()` doit
être la même que celle qui exécute
`pg_stop_backup()`. Si la connexion venait à être
interrompue, alors
la sauvegarde doit être considérée comme invalide.

Autre point important, lors d'une sauvegarde non concurrente, le fichier
`backup.label` est
créé dans le répertoire de l'instance sauvegardée.
Dans le cas des
sauvegardes concurrentes, ce fichier serait écrasé.

Pour pallier à ce problème, c'est la commande `pg_stop_backup()` qui renvoie
les informations qui se trouvaient avant dans le fichier `backup_label` et
elle se charge
dans le même temps de créer un fichier
`0000000100000001000000XX.000000XX.backup` contenant les informations de
fin de sauvegarde. De ce fait, si vous voulez
implémenter cette nouvelle
méthode, il vous faudra récupérer et conserver
vous-même les informations
renvoyées par la commande de fin de sauvegarde.

La sauvegarde PITR devient donc plus complexe, il est donc recommandé d'
utiliser pg_basebackup ou des outils supportant ces fonctionnalités (pitrery,
pg_backrest ...).
</div>



-----


### Réplication synchrone, l'existant

<div class="slide-content">

  * 9.0, réplication asynchrone
  * 9.1, réplication synchrone
    * plusieurs esclaves potentiellement synchrones
    * mais un seul synchrone à un instant t
</div>


<div class="notes">


La version de PostgreSQL 9.0 a apporté une vraie réplication en disposant d'un
envoi plus fluide des informations grâce à la streaming replication, mais
aussi avec la possibilité d'accéder en lecture seule au serveur répliqué.

La réplication synchrone arrive dans PostgreSQL avec la version 9.1.
Plusieurs serveurs secondaires pouvaient être indiqués comme potentiellement

synchrones, mais un seul était réellement synchrone à un instant t.
Autrement
dit, le serveur primaire attendait la confirmation par le
serveur secondaire de l'inscription des données sur son disque pour renvoyer
le succès de l'opération à l'utilisateur.

En cas d'indisponibilité du serveur secondaire synchrone, le serveur suivant 
dans la liste des serveurs synchrones potentiels configurés avec le
paramètre `synchronous_standby_names` prenait la main comme serveur synchrone.

Si aucun serveur potentiellement synchrone n'était disponible, la validation
des
écritures sur le serveur primaire était mise en attente.
</div>



-----


### synchronous_commit

<div class="slide-content">

  * Positionné à ON par défaut
  * Soit le client, soit le maître
  * Les modifications sont écrites dans les WAL avant d'envoyer la confirmation
  * Nouvelle valeur :
    * `remote_apply`
</div>


<div class="notes">


La valeur du paramètre `synchronous_commit` permet de définir les conditions
nécessaires pour pouvoir renvoyer à l'utilisateur que sa transaction a été
validée.

Ce paramètre, dans le cadre d'un serveur synchrone répliqué, est utilisé
pour valider au serveur primaire qu'une transaction a été validée sur le
serveur secondaire.

Il peut prendre plusieurs valeurs :


  * `off` : La transaction est directement validée, mais elle pourra être écrite
plus tard dans les WAL. Cela correspond au maximum à 3 fois la valeur de `wal_writer_delay` (
200ms par défaut). Ce paramétrage peut causer la perte de certaines
transactions si le serveur se crashe et que les données n'ont pas encore été
écrites dans les fichiers WAL.


  * `local` : Permet de fonctionner, pour les prochaines requêtes de la session, en mode
de réplication asynchrone. Le commit est validé lorsque les données ont été
écrites et synchronisées sur le disque de l'instance primaire. En revanche, l'
instance primaire ne s'assure pas que le secondaire a reçu la transaction.


  * `remote_write` : Permet d'avoir de la réplication synchrone en mémoire. Cela veut dire que
la donnée n'est pas écrite sur disque au niveau de l'esclave mais il l'a en
mémoire. Les modifications sont écrites sur disque via le système d'
exploitation, mais sans avoir demandé le vidage du cache système sur disque.
Les informations sont donc dans la mémoire système. Cela permet de gagner
beaucoup en performance, avec une fenêtre de perte de données bien moins
importante que le mode asynchrone, mais toujours présente. Si c'est l'instance
primaire PostgreSQL qui se crashe, les informations ne sont pas perdues. Par
contre, il est possible de perdre des données si l'instance secondaire crashe (
en cas de bascule).


  * `on` (par défaut) : Le commit est validé lorsque les données ont été écrites
et synchronisées sur le disque de l'instance primaire et secondaire. C'est la
réplication synchrone. En revanche, l'instance primaire ne s'assure pas que le
secondaire a **rejoué** la transaction.

La version 9.6 apporte une nouvelle valeur pour ce paramètre : `remote_apply`.


  * `remote_apply`. Les modifications doivent être enregistrées dans les WAL et rejouées
avant que la confirmation ne soit envoyée. Cette méthode est la seule
garantissant qu'une transaction validée sur le maître sera visible sur le
secondaire. Cependant, elle rajoute une latence supplémentaire.

Tableau récapitulatif :

: Valeur paramètre `synchronous_commit`

+----------------+--------------------------+------------------------------+--------------------------+--------------------------+
| Ecriture       | WAL local                | Mémoire distant              | WAL distant              | Rejeu distant            |
|                | (synchronisé sur disque) | (non-synchronisé sur disque) | (synchronisé sur disque) | (enregistrement visible) |
+----------------+--------------------------+------------------------------+--------------------------+--------------------------+
| `off`          |                          |                              |                          |                          |
+----------------+--------------------------+------------------------------+--------------------------+--------------------------+
| `remote_write` | X                        | X                            |                          |                          |
+----------------+--------------------------+------------------------------+--------------------------+--------------------------+
| `local`        | X                        |                              |                          |                          |
+----------------+--------------------------+------------------------------+--------------------------+--------------------------+
| `on`           | X                        |                              | X                        |                          |
+----------------+--------------------------+------------------------------+--------------------------+--------------------------+
| `remote_apply` | X                        |                              | X                        | X                        |
+----------------+--------------------------+------------------------------+--------------------------+--------------------------+

</div>



-----


### Réplication synchrone sur plusieurs nœuds

<div class="slide-content">

  * Plusieurs serveurs synchrones
  * Configuration
    * synchronous_standby_names = 'N (liste serveurs)'
    * N = nombre serveurs synchrones
  * Contraintes
    * latence induite par la validation des transactions sur plusieurs esclaves
    * requêtes en attente sur le primaire s'il y a moins de N serveurs synchrones disponibles
</div>


<div class="notes">


La 9.6 apporte la possibilité de réaliser de la réplication synchrone avec
plusieurs esclaves.

En effet, la déclaration d'un esclave synchrone se fait en définissant
le paramètre `synchronous_standby_names`. Ce dernier possède une nouvelle
syntaxe telle que : `'N (<Slave_n°1>, <Slave_n°2>, ...)'`.

Cette méthode, bien utilisée, permet d'avoir plusieurs serveurs répliqués
avec
réellement les mêmes informations que le serveur maître.

Néanmoins, les contraintes amenées par cette méthode ne sont pas légères :


  * La latence est induite par l'attente de la validation des transactions
répliquées sur l'ensemble des serveurs répliqués définis.
  * Si 2 esclaves synchrones ont été définis, les requêtes se bloquent dès l'
absence d'un des deux esclaves.
  * Lorsque les transactions sont suspendues sur le maître dans ce cadre, l'
instance maître n'a aucune information à ce sujet.

Voici un exemple de ce qu'il se passe quand le nombre de serveurs synchrones n'
est pas suffisant.

Cette écriture va être bloquée :

```sql
INSERT INTO text_exemple
  VALUES ('la recherche fonctionne souvent par hasard deuxième');
```

Cela ne se voit pas dans la vue `pg_stat_activity` :

```sql
SELECT * FROM pg_stat_activity;
-[ RECORD 1 ]----+-----------------------------------
datid            | 13322
datname          | postgres
pid              | 2075
usesysid         | 10
usename          | postgres
application_name | psql
client_addr      |
client_hostname  |
client_port      | -1
backend_start    | 2016-08-18 08:18:17.999042+02
xact_start       | 2016-08-18 08:18:42.488234+02
query_start      | 2016-08-18 08:18:42.488234+02
state_change     | 2016-08-18 08:18:42.488241+02
wait_event_type  |
wait_event       |
state            | active
backend_xid      |
backend_xmin     | 1914
query            | select * from pg_stat_activity;
```




Cependant, on peut tout de même retrouver cette information en consultant
les processus côté système :

```sql
postgres 22395  0.0  7.0 484864 283600 ?       Ss   août17   0:55
    \_ postgres: postgres textes [local] INSERT waiting for 1/53410200
```



</div>



-----


### Foreign Data Wrapper

<div class="slide-content">

  * Norme SQL/MED
  * Interroger des données externes.
  * Données externes présentées comme des tables
  * Attention aux performances !
</div>


<div class="notes">


Il existe dans PostgreSQL la possibilité de travailler sur des bases distantes
grâce aux connecteurs
appelés `Foreign Data Wrapper`.

Le FDW pour PostgreSQL, appelé `postgres_fdw`, est disponible sous la forme d'une extension
à installer sur la
base où l'on veut créer des tables distantes.

Le principe est le suivant. En s'appuyant sur l'extension `postgres_fdw`, il est possible de
créer
une table dans la base courante, pointant sur une table de structure identique
mais se trouvant dans
une autre instance PostgreSQL.

```sql
CREATE FOREIGN TABLE table1_distante (
  id serial,
  bla text)
SERVER serveurdistant
OPTIONS (table_name 'table1');
```



Lorsqu'on fait une extraction
sur cette table, un FDW est capable de ne récupérer que les lignes
nécessaires, la
clause `WHERE` pouvant être envoyée au serveur secondaire. D'autres optimisations
ont été apportées au fil des
versions mais certaines manquent toujours à l'appel.
</div>



-----


### FDW : jeu de tests

<div class="slide-content">


```sql
CREATE TABLE t1 (id integer);
INSERT INTO t1 SELECT generate_series(1, 10000000);
CREATE INDEX ON t1(id);

CREATE EXTENSION postgres_fdw;

CREATE SERVER ailleurs FOREIGN DATA WRAPPER postgres_fdw;

CREATE USER MAPPING FOR postgres SERVER ailleurs;

CREATE FOREIGN TABLE ft1(id integer)
  SERVER ailleurs
  OPTIONS (table_name 't1');
```


</div>


<div class="notes">

</div>



-----


### FDW : Nouveautés

<div class="slide-content">

  * SORT pushdown
    * exécution du tri sur le serveur distant
  * JOIN pushdown
    * exécution de la jointure sur le serveur distant
</div>


<div class="notes">


La version 9.6 apporte désormais la possibilité de réaliser les opérations
de jointure et de tri à distance,
et de ne récupérer que la partie nécessaire pour la sélection demandée dans
l'ordre requis.

Dans certains cas, cela va apporter un gain de performance notoire.
</div>



-----


### FDW : tri en 9.5

<div class="slide-content">


```sql
EXPLAIN (ANALYZE, VERBOSE, COSTS off)
SELECT * FROM ft1 ORDER BY id ;

                          QUERY PLAN
--------------------------------------------------------------
 Sort (actual time=9452.057..10129.182 rows=10000000 loops=1)
   Output: id
   Sort Key: ft1.id
   Sort Method: external sort  Disk: 136856kB
   ->  Foreign Scan on public.ft1
       (actual time=1.064..5981.536 rows=10000000 loops=1)
         Output: id
         Remote SQL: SELECT id FROM public.t1
 Planning time: 0.131 ms
 Execution time: 10425.730 ms
(9 rows)
```


</div>


<div class="notes">

</div>



-----


### FDW : tri en 9.6

<div class="slide-content">


```sql
EXPLAIN (ANALYZE, VERBOSE, COSTS off)
SELECT * FROM ft1 ORDER BY id;

                      QUERY PLAN
-----------------------------------------------------
 Foreign Scan on public.ft1
 (actual time=2.092..7438.416 rows=10000000 loops=1)
   Output: id
   Remote SQL: SELECT id FROM public.t1
               ORDER BY id ASC NULLS LAST
 Planning time: 0.168 ms
 Execution time: 7748.122 ms
(5 rows)
```


</div>


<div class="notes">


On constate bien dans le second plan que la clause `ORDER BY` a été faite a distance
ce qui n'était pas le cas dans la version précédente.
</div>



-----


### FDW : jointure en 9.5

<div class="slide-content">


```sql
EXPLAIN (VERBOSE, ANALYZE)
SELECT * FROM table1_distante
JOIN table2_distante ON table1_distante.id = table2_distante.id
WHERE table2_distante.id = 1;

                      QUERY PLAN
-----------------------------------------------------------
 Nested Loop  [...]
   Output: table1_distante.id, table1_distante.bla,
           table2_distante.id, table2_distante.bli
   ->  Foreign Scan on public.table1_distante  [...]
         Output: table1_distante.id, table1_distante.bla
         Remote SQL: SELECT id, bla FROM public.table1
                     WHERE ((id = 1))
   ->  Foreign Scan on public.table2_distante  [...]
         Output: table2_distante.id, table2_distante.bli
         Remote SQL: SELECT id, bli FROM public.table2
                     WHERE ((id = 1))
 Planning time: 0.217 ms
 Execution time: 65.616 ms
```



</div>


<div class="notes">


En version 9.5, on peut constater sur ce plan d’exécution que les sélections
complètes des tables sont récupérées
depuis la base distante (partie `Remote SQL`), puis la sélection demandée est réalisée
sur place (partie `Nested Loop`)
</div>



-----


### FDW : jointure en 9.6

<div class="slide-content">


```sql
EXPLAIN (VERBOSE, ANALYZE)
SELECT * FROM table1_distante
JOIN table2_distante
  ON table1_distante.id=table2_distante.id
WHERE table2_distante.id = 1;

                      QUERY PLAN
--------------------------------------------------------
 Foreign Scan  [...]
   Output: table1_distante.id, table1_distante.bla,
           table2_distante.id, table2_distante.bli
   Relations: (public.table1_distante)
              INNER JOIN (public.table2_distante)
   Remote SQL: SELECT r1.id, r1.bla, r2.id, r2.bli
               FROM (public.table1 r1
               INNER JOIN public.table2 r2
                  ON (((r2.id = 1)) AND ((r1.id = 1))))
 Planning time: 0.170 ms
 Execution time: 2.299 ms
```


</div>


<div class="notes">


De la même manière, toute la requête est réalisée sur le serveur distant en
9.6.
</div>



-----


### FREEZE

<div class="slide-content">

  * Amélioration de la fonction de gel des données
  * pg_visibility(oid)
    * blkno
    * all_visible
    * all_frozen
    * pd_all_visible
</div>


<div class="notes">


La Visibility Map est un tableau qui, avant la version 9.6, permettait de
savoir, pour un bloc de données donné, si toutes les lignes qu'il
contenait
étaient des lignes "visibles", c'est-à-dire des lignes non supprimées
ou non obsolètes suite à la mise à jour.

Elle a récupéré dans la version 9.6 une nouvelle information permettant de

savoir, de la même manière, pour un bloc de données, si ce dernier
contenait
des lignes gelées.

Ces informations sont importantes dans le cas de l'exécution d'un `VACUUM FREEZE` pour
que ce dernier ne traite pas des blocs qui n'en ont pas besoin. Diminuer le
nombre de
lectures et de traitements permet de rendre l'opération plus rapide.

Nous intéresser à cette amélioration nous permet de nous pencher aussi sur
l'extension `pg_visibility`, arrivée elle aussi avec la version 9.6 de PostgreSQL.


  * `blkno` : numéro de bloc
  * `all_visible` : booléen, true si toutes les lignes du bloc sont visibles
  * `all_frozen` : booléen, true si toutes les lignes du bloc sont gelées
  * `pd_all_visible` : identique à all_visible mais stocké dans l'entête du bloc lui-même.

Il peut exister une différence entre all_visible et pd_all_visible.
Il faut dans ce cas faire confiance à la valeur se trouvant dans
all_visible.  En effet, en mode recovery, pd_all_visible peut parfois
rester défini tandis que la visibility map est purgée. Ils peuvent
aussi être différents si `pg_visibility()` examine la visibility map
et qu'un changement survienne avant que la fonction ait examiné le
bloc de données correspondant.  </div>



-----


### pg_config, pg_control

<div class="slide-content">

  * Outil pg_config
    * informations de compilation
  * Outil pg_controldata
    * informations du fichier pg_control
  * Informations uniquement disponibles sur la ligne de commande avant la 9.6
  * Maintenant disponibles aussi via l'interface SQL
    * vue pg_config
    * fonctions pg_control_system(), pg_control_init(), pg_control_checkpoint() et pg_control_recovery()
</div>


<div class="notes">


L'outil `pg_config` permet de récupérer un ensemble d'informations sur
la configuration de la compilation :

```
$ pg_config
BINDIR = /opt/postgresql/96/bin
DOCDIR = /opt/postgresql/96/share/doc
HTMLDIR = /opt/postgresql/96/share/doc
INCLUDEDIR = /opt/postgresql/96/include
PKGINCLUDEDIR = /opt/postgresql/96/include
INCLUDEDIR-SERVER = /opt/postgresql/96/include/server
LIBDIR = /opt/postgresql/96/lib
PKGLIBDIR = /opt/postgresql/96/lib
LOCALEDIR = /opt/postgresql/96/share/locale
MANDIR = /opt/postgresql/96/share/man
SHAREDIR = /opt/postgresql/96/share
SYSCONFDIR = /opt/postgresql/96/etc
PGXS = /opt/postgresql/96/lib/pgxs/src/makefiles/pgxs.mk
CONFIGURE = '--prefix=/opt/postgresql/96' '--enable-nls' \
 '--with-openssl' '--with-libxml' '--enable-thread-safety' \
 '--enable-debug' '--with-wx-version=3.1'
CC = gcc
CPPFLAGS = -DFRONTEND -D_GNU_SOURCE -I/usr/include/libxml2
CFLAGS = -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement \
 -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing \
 -fwrapv -fexcess-precision=standard -g -O2
CFLAGS_SL = -fpic
LDFLAGS = -L../../src/common -Wl,--as-needed \
 -Wl,-rpath,'/opt/postgresql/96/lib',--enable-new-dtags
LDFLAGS_EX =
LDFLAGS_SL =
LIBS = -lpgcommon -lpgport -lxml2 -lssl -lcrypto -lz -lreadline -lrt -lcrypt -ldl -lm
VERSION = PostgreSQL 9.6rc1
```


Ces informations sont maintenant disponibles via l'interface SQL :

```
postgres=# SELECT * FROM pg_config;
-[ RECORD 1 ]--------------------------
name    | BINDIR
setting | /opt/postgresql/96/bin
-[ RECORD 2 ]--------------------------
name    | DOCDIR
setting | /opt/postgresql/96/share/doc
[...]
```


L'outil pg_controldata est maintenant doublé par un ensemble de
fonctions SQL permettant de récupérer des informations contenues dans
le fichier `global/pg_control` :

```
postgres=# select * from pg_control_checkpoint();
-[ RECORD 1 ]--------+-------------------------
checkpoint_location  | 4/6985EE10
prior_location       | 4/6985ED30
redo_location        | 4/6985EDD8
redo_wal_file        | 000000010000000400000069
timeline_id          | 1
prev_timeline_id     | 1
full_page_writes     | t
next_xid             | 0:3447
next_oid             | 91758
next_multixact_id    | 1
next_multi_offset    | 0
oldest_xid           | 1797
oldest_xid_dbid      | 1
oldest_active_xid    | 3447
oldest_multi_xid     | 1
oldest_multi_dbid    | 1
oldest_commit_ts_xid | 0
newest_commit_ts_xid | 0
checkpoint_time      | 2016-09-02 11:47:56+02
```


Voici le détail sur les fonctions en question :


  * `pg_control_system()` renvoie des informations sur l'état courant du fichier de contrôle.
  * `pg_control_init()` renvoie la configuration de l'instance (taille d'un bloc d'un fichier de
données ou d'un journal de transactions, le nombre de blocs par segment dans un
fichier de données, le nombre d'octet par segment dans un journal de
transactions, le nombre maximum de colonnes pour un index, ...).
  * `pg_control_checkpoint()` renvoie des informations sur l'état du checkpoint courant (lorsque l'
instance réalise un checkpoint, la position de celui-ci est sauvegardée dans
le fichier `pg_control`).
  * `pg_control_recovery()` renvoie des informations sur l'état de la récupération en cours, n'est
utilisable que sur une instance dans cet état : vide si le serveur est ouvert
en lecture/écriture.
</div>



-----


## SQL

<div class="slide-content">

  * Recherche plein-texte pour les phrases
  * Option CASCADE pour les extensions
  * Pivotage des résultats
  * Autres nouveautés
    * fonction mathématiques
    * `jsonb_insert()`
</div>


<div class="notes">

</div>



-----


### Recherche plein-texte pour les phrases

<div class="slide-content">

  * FTS disponible dans PostgreSQL depuis la version 8.3
  * Opérateurs disponibles jusqu'à présent
    * ET logique : &
    * OU logique : |
    * NON logique :  !
  * Nouvel opérateur :
    * Succession : <->
    * Position dans la phrase : <N> (où N est un entier représentant le nombre de mot séparant les deux motifs)
</div>


<div class="notes">


Avant que la recherche plein texte soit disponible dans le moteur (en 8.3), la
seule manière de rechercher des expressions dans des tables se faisait avec la
commande LIKE ou une expression rationnelle.

Celle-ci est très longue, limitée par le motif employé et il est très
rarement possible d'utiliser l'indexation (un index Btree est inutilisable pour
un `LIKE '%mot%' `).

La recherche plein texte s'appuie sur la racine native de l'expression donnée.
Celle-ci est dépendante de la langue utilisée :

```sql
SHOW default_text_search_config;

 default_text_search_config
----------------------------
 pg_catalog.french
```



```sql
SELECT to_tsvector('empêcherais');

 to_tsvector
-------------
 'empêch':1
```

Combien de textes possèdent la racine de _empêcherais_

```sql
EXPLAIN ANALYZE SELECT count(*)
FROM textes WHERE to_tsvector('french',contenu) @@ to_tsquery('empêcherais');
                             QUERY PLAN
-----------------------------------------------------------------------------
 Aggregate  (cost=11146387.36..11146387.37 rows=1 width=8)
   (actual time=282384.083..282384.083 rows=1 loops=1)
   ->  Seq Scan on textes  (cost=0.00..11146125.45 rows=104764 width=0)
     (actual time=1.256..282372.941 rows=32141 loops=1)
         Filter: (to_tsvector('french'::regconfig, contenu) @@
           to_tsquery('empêcherais'::text))
         Rows Removed by Filter: 20917562
 Planning time: 192.846 ms
 Execution time: 282384.109 ms
(6 rows)
```



L'idéal pour optimiser les performances est de créer un index
fonctionnel avec la fonction `to_tsvector()` :

On peut utiliser un index GIN :

```sql
CREATE INDEX index_contenu_vectorise
  ON text_exemple
  USING gin ( to_tsvector('french',contenu) );
```


Cette fois la requête est bien plus rapide :

```sql
EXPLAIN ANALYZE SELECT count(*)
FROM textes
WHERE to_tsvector('french',contenu) @@ to_tsquery('empêcherais');
                                   QUERY PLAN
--------------------------------------------------------------------------------
 Aggregate  (cost=293383.13..293383.14 rows=1 width=8)
   (actual time=159.360..159.361 rows=1 loops=1)
   ->  Bitmap Heap Scan on textes  (cost=984.05..293121.26 rows=104749 width=0)
     (actual time=9.216..156.727 rows=32141 loops=1)
         Recheck Cond: (to_tsvector('french'::regconfig, contenu) @@
           to_tsquery('empêcherais'::text))
         Heap Blocks: exact=29635
         ->  Bitmap Index Scan on index_contenu_vectorise  (cost=0.00..957.86
             rows=104749 width=0) (actual time=4.979..4.979 rows=32141 loops=1)
               Index Cond: (to_tsvector('french'::regconfig, contenu) @@
                 to_tsquery('empêcherais'::text))
 Planning time: 18.162 ms
 Execution time: 159.397 ms
(8 rows)
```




Note, voici ce que donnait la requête sans index mais avec parallélisation :

```sql
EXPLAIN ANALYZE SELECT count(*)
FROM textes
WHERE to_tsvector('french',contenu) @@ to_tsquery('empêcherais');
                                   QUERY PLAN
---------------------------------------------------------------------------------
 Finalize Aggregate  (cost=2198596.85..2198596.86 rows=1 width=8) (actual
   time=65043.325..65043.325 rows=1 loops=1)
   ->  Gather  (cost=2198596.23..2198596.84 rows=6 width=8) (actual
        time=65042.856..65043.315 rows=7 loops=1)
         Workers Planned: 6
         Workers Launched: 6
         ->  Partial Aggregate  (cost=2197596.23..2197596.24 rows=1 width=8)
            (actual time=65037.435..65037.435 rows=1 loops=7)
               ->  Parallel Seq Scan on textes  (cost=0.00..2197552.58 rows=17461
                  width=0) (actual time=14.707..65035.315 rows=4592 loops=7)
                     Filter: (to_tsvector('french'::regconfig, contenu) @@
                      to_tsquery('empêcherais'::text))
                     Rows Removed by Filter: 2988223
 Planning time: 0.108 ms
 Execution time: 65046.598 ms
```

Un index fonctionnel est donc bien plus performant.

```sql
textes=# SELECT count(*) FROM textes WHERE contenu LIKE '%empêcherais%';
 count
-------
    31
(1 row)

textes=# SELECT count(*)
FROM textes
WHERE to_tsvector('french',contenu) @@ to_tsquery('empêcherais');
 count
-------
 32141
(1 row)
```


On constate bien par cet exemple que la recherche par motif est très
différente de la recherche plein texte.  En effet, lorsqu'on utilise
le motif, on ne va pas pouvoir récupérer de déclinaison du mot, si ce
mot n'est pas tout à fait bien orthographié, de la même manière, il ne
matchera pas.

Concernant la nouvelle fonctionnalité :

Avant, lorsqu'on désirait rechercher une phrase, on était obligé de
faire d' abord la sélection des mots avec FTS (ce qui permettait
d'utiliser l'index de manière à améliorer la rapidité de l'exécution)
puis de filtrer avec un LIKE pour obtenir exactement la combinaison de
mots désirée :

```sql
textes=# SELECT *
FROM textes
WHERE to_tsvector('french',contenu) @@ to_tsquery('monter&à&cheval')
  AND contenu LIKE '%monter à cheval%';
```



Maintenant, on peut utiliser notre nouvel opérateur ("monter à cheval"
et variations à un mot de distance)

```sql
textes=# SELECT contenu
FROM textes
WHERE  to_tsvector('french',contenu) @@ to_tsquery('monter<->à<->cheval');
```

Il se décline de manière à ne pas avoir forcément des mots se
succédant, par exemple :

```sql
textes=# SELECT contenu
FROM textes
WHERE  to_tsvector('french',contenu) @@ to_tsquery('monter<3>cheval');
```

Le chiffre 3 dans `<3>` indique la distance entre _monter_ et _cheval_.
</div>



-----


### Ajout de l'option CASCADE pour les extensions

<div class="slide-content">

  * Avant la version 9.6

  postgres=# CREATE EXTENSION ltree_plpythonu;
  ERREUR:  l'extension « ltree » requise n'est pas installée


  * Après la version 9.6

  postgres=# CREATE EXTENSION ltree_plpythonu CASCADE;
  NOTICE:  installing required extension "ltree"
  NOTICE:  installing required extension "plpythonu"
  CREATE EXTENSION
</div>


<div class="notes">


On obtient désormais la possibilité d'utiliser l'option CASCADE lorsque
l'on crée une extension. En effet, avant la version 9.6, il fallait gérer les
dépendances de façon manuelle, en installant chacune des extensions
supplémentaires nécessaires.
</div>



-----


### Pivotage des résultats

<div class="slide-content">

  * `\crosstabview [ colV [ colH [ colD [ sortcolH ] ] ] ]`
  * Exécute le contenu du tampon de requête
    * la requête doit renvoyer au moins 3 colonnes
  * Affiche le résultat dans une grille croisée
    * colV, en-tête vertical
    * colH, en-tête horizontal
    * colD, contenu à afficher dans le tableau
    * sortColH, colonne de tri pour l'en-tête horizontal
</div>


<div class="notes">


Disons que nous voulons récupérer le nombre de bouteilles en stock par
type de vin (blanc, rosé, rouge) par année, pour les années entre 1950
et 1959 :

```sql
cave=# SELECT t.libelle, s.annee, sum(s.nombre)
FROM stock s
  JOIN vin v ON v.id=s.vin_id
  JOIN type_vin t ON t.id=v.type_vin_id
WHERE s.annee BETWEEN 1950 AND 1959
GROUP BY t.libelle, s.annee
ORDER BY s.annee;

 libelle | annee |  sum
---------+-------+-------
 blanc   |  1950 | 69166
 rose    |  1950 | 70311
 rouge   |  1950 | 69836
 blanc   |  1951 | 67325
 rose    |  1951 | 67616
 rouge   |  1951 | 66708
 blanc   |  1952 | 67501
 rose    |  1952 | 67481
 rouge   |  1952 | 66116
 blanc   |  1953 | 67890
 rose    |  1953 | 67902
 rouge   |  1953 | 67045
 blanc   |  1954 | 67471
 rose    |  1954 | 67759
 rouge   |  1954 | 67299
 blanc   |  1955 | 67306
 rose    |  1955 | 68015
 rouge   |  1955 | 66854
 blanc   |  1956 | 67281
 rose    |  1956 | 67458
 rouge   |  1956 | 66990
 blanc   |  1957 | 67323
 rose    |  1957 | 67374
 rouge   |  1957 | 66409
 blanc   |  1958 | 67469
 rose    |  1958 | 67738
 rouge   |  1958 | 66782
 blanc   |  1959 | 67765
 rose    |  1959 | 67903
 rouge   |  1959 | 67560
(30 rows)
```

Et maintenant nous souhaitons afficher ces informations avec en
abscisse le libellé du type de vin et en ordonnée les années :

```
cave=# \crosstabview
 libelle | 1950  | 1951  | 1952  | 1953  | 1954  | ... | 1959
---------+-------+-------+-------+-------+-------+-----+-------
 blanc   | 69166 | 67325 | 67501 | 67890 | 67471 | ... | 67765
 rose    | 70311 | 67616 | 67481 | 67902 | 67759 | ... | 67903
 rouge   | 69836 | 66708 | 66116 | 67045 | 67299 | ... | 67560
(3 rows)
```


Et si nous souhaitons l' inverse (les années en abscisse et les types
de vin en ordonnée), c'est tout aussi simple :

```
cave=# \crosstabview annee libelle
 annee | blanc | rose  | rouge
-------+-------+-------+-------
  1950 | 69166 | 70311 | 69836
  1951 | 67325 | 67616 | 66708
  1952 | 67501 | 67481 | 66116
  1953 | 67890 | 67902 | 67045
  1954 | 67471 | 67759 | 67299
  1955 | 67306 | 68015 | 66854
  1956 | 67281 | 67458 | 66990
  1957 | 67323 | 67374 | 66409
  1958 | 67469 | 67738 | 66782
  1959 | 67765 | 67903 | 67560
(10 rows)
```


</div>



-----


### Autres nouveautés

<div class="slide-content">

  * Amélioration des performances globales pour plusieurs fonctions mathématiques
    * ln() / log() / exp() / pow()

  * Ajout des fonctions
    * sind() /  cosd() / tand()
</div>


<div class="notes">


Les performances globales de différentes fonctions mathématiques
telles que logarithme, exponentielle, puissance, ... ont été
améliorées.

Les fonctions `sind()`, `cosd()` et `tand()` ont été créées,
permettant de calculer sinus, cosinus, tangente avec une valeur en
degrés plutôt qu'avec une valeur en radian, ce qui permet d'obtenir
les résultats exacts, plutôt qu'inexacte après une conversion. Par
exemple, la tangente de 90° retourne la valeur infinie.

```sql
textes=# SELECT cos(3.14159);
        cos
--------------------
 -0.999999999996479
(1 ligne)

textes=# SELECT cosd(180);
 cosd
------
   -1
(1 ligne)

textes=# SELECT tan(1.5708);
        tan
-------------------
 -272241.808409276
(1 ligne)


textes=# SELECT tand(90);
   tand
----------
 Infinity
(1 ligne)
```


</div>



-----


## Monitoring

<div class="slide-content">

  * Nouvelles colonnes dans `pg_stat_activity`
  * Nouvelle fonction `pg_blocking_pid()`
  * Nouvelle vue `pg_stat_progress_vacuum`
</div>


<div class="notes">

</div>



-----


### Vue pg_stat_activity, pg_blocking_pids()

<div class="slide-content">

  * Avant la 9.6
    * identification complexe d'une requête bloquante
    * et de la raison du blocage
  * Ajout de la fonction `pg_blocking_pids()`
  * modification de la colonne waiting en deux colonnes
    * wait_event
    * wait_event_type
</div>


<div class="notes">


Il était parfois compliqué d'identifier d’où provenait un blocage
lorsqu' une requête ne parvenait pas à se terminer.

Dans un cas où deux 2 sessions ont chacune une transaction ouverte,
l'une insérant des données dans une table et l'autre tentant de
supprimer cette table, tant que la transaction d'insertion n'est pas
terminée, la session qui cherche à supprimer la table attends.

Jusqu'à la version 9.5, on disposait dans la vue `pg_stat_activity`
des informations suivantes :

```sql
postgres=# SELECT pid,state,waiting,query FROM pg_stat_activity;

pid     | 3279
state   | active
waiting | t
query   | drop table test_blocage ;


pid     | 3281
state   | idle in transaction
waiting | f
query   | INSERT INTO test_blocage (champ) (SELECT 'ligne '||i
        | FROM generate_series(1, 10000) i);
```


On constate bien que la session de pid 3279 est en attente : `waiting =
t` (true) . Mais on n'a pas plus d'informations, notamment pourquoi
celle-ci est bloquée, par qui etc ...

La colonne `waiting` a été séparée en deux colonnes, `wait_event_type`
et `wait_event`, ce qui nous apporte plus d'informations.

```sql
postgres=# SELECT pid,wait_event_type,wait_event,state,query
FROM pg_stat_activity;

pid             | 2800
wait_event_type | Lock
wait_event      | relation
state           | active
query           | drop table test_blocage ;

pid             | 3085
wait_event_type |
wait_event      |
state           | idle in transaction
query           | INSERT INTO test_blocage (champ) (SELECT 'ligne '||i
                | FROM generate_series(1, 10000) i);
```




</div>



-----


### Fonction pg_blocking_pids()

<div class="slide-content">

  * Avant la 9.6
    * requête complexe pour trouver la session bloquante
    * voire collection de requêtes
  * Depuis la 9.6
    * fonction `pg_blocking_pids()`
</div>

<div class="notes">

Avant pour  obtenir la requête bloquante, il fallait écrire la requête suivante :

```sql
SELECT
    waiting.locktype           AS waiting_locktype,
    waiting.relation::regclass AS waiting_table,
    waiting_stm.query  AS waiting_query,
    waiting.mode               AS waiting_mode,
    waiting.pid                AS waiting_pid,
    other.locktype             AS other_locktype,
    other.relation::regclass   AS other_table,
    other_stm.query    AS other_query,
    other.mode                 AS other_mode,
    other.pid                  AS other_pid,
    other.granted              AS other_granted
FROM
    pg_catalog.pg_locks AS waiting
JOIN
    pg_catalog.pg_stat_activity AS waiting_stm
    ON (
        waiting_stm.pid = waiting.pid
    )
JOIN
    pg_catalog.pg_locks AS other
    ON (
        (
            waiting."database" = other."database"
        AND waiting.relation  = other.relation
        )
        OR waiting.transactionid = other.transactionid
    )
JOIN
    pg_catalog.pg_stat_activity AS other_stm
    ON (
        other_stm.pid = other.pid
    )
WHERE NOT waiting.granted
AND waiting.pid <> other.pid;

waiting_locktype | relation
waiting_table    | test_blocage
waiting_query    | drop table test_blocage ;
waiting_mode     | AccessExclusiveLock
waiting_pid      | 3279
other_locktype   | relation
other_table      | test_blocage
other_query      | INSERT INTO test_blocage (champ) (SELECT 'ligne '||i
                 |  FROM generate_series(1, 10000) i);
other_mode       | RowExclusiveLock
other_pid        | 3281
other_granted    | t
```



Désormais il suffit de passer le pid de la requête bloquée :

```sql
postgres=# SELECT pg_blocking_pids(2800);
-[ RECORD 1 ]----+-------
pg_blocking_pids | {3085}
```

Dans notre cas, notre requête `drop table test_blocage;` est bloquée
par la session de pid `3085`
</div>
-----


### pg_stat_progress_vacuum

<div class="slide-content">

  * Intégration d'une API pour le suivi de progression d'une commande
  * Utilisation de cette API pour VACUUM
  * Vue pg_stat_progress_vacuum
    * nombreuses informations sur la progression d'une opération VACUUM
</div>


<div class="notes">


Les différentes phases dans lesquelles peut se trouver un `VACUUM` :


  * `initializing` : `VACUUM` se prépare à lire les données non indexées.
  * `scanning heap` : `VACUUM` parcourt les données non indexées. La colonne `heap_blks_scanned` peut donner une
indication sur l'avancement de cette étape.
  * `vacuuming indexes` : `VACUUM` procède au vacuum des index.
  * `vacuuming heap` : `VACUUM` procède au vacuum des données non indexées.
  * `cleaning up indexes` : `VACUUM` procède au nettoyage des index.
  * `truncating heap` : `VACUUM` agrège les blocs vides des données non indexées de manière à ce qu'
ils puissent être réutilisés.
  * `performing final cleanup` : `VACUUM` réalise le nettoyage final, ce qui inclut le traitement de la FSM, la
mise à jour des statistiques dans le catalogue système `pg_class` et le report de ces
informations vers le collecteur de statistiques.

Et voici le contenu de la vue `pg_stat_progress_vacuum` :

```
View "pg_catalog.pg_stat_progress_vacuum"
       Column       |  Type   | Modifiers
--------------------+---------+-----------
 pid                | integer |
 datid              | oid     |
 datname            | name    |
 relid              | oid     |
 phase              | text    |
 heap_blks_total    | bigint  |
 heap_blks_scanned  | bigint  |
 heap_blks_vacuumed | bigint  |
 index_vacuum_count | bigint  |
 max_dead_tuples    | bigint  |
 num_dead_tuples    | bigint  |
```


</div>



-----


## Régressions / changements

<div class="slide-content">

  * Il n'est plus possible de créer des rôles commençant par `pg_*`
  * L'option -c de psql (exécution de commande) n'active plus --no-psqlrc
  * L'option -t de `pg_restore` ne correspond plus seulement aux tables
    * mais à tous types de relations
  * Niveaux `archive` et `hot_standby` n'existent plus pour `wal_level`.
    * Remplacés par un niveau `replica` <=> `hot_standby`
</div>


<div class="notes">


Les rôles commençant par `pg_*` sont réservés aux rôles systèmes de gestion
de droits (comme `pg_signal_backend`).

Les niveaux `archive` et `hot_standby` n'existent plus pour `wal_level`. Ils sont remplacés par le
niveau `replica`. Afin de conserver une compatibilité, les niveaux `archive` et `hot_standby` sont
remplacé en interne par `replica`.
</div>



-----


## Futur

<div class="slide-content">

  * Version 10, en septembre 2017
  * A priori
    * améliorations de la parallélisation
    * améliorations de la réplication logique
  * Premier commitfest démarré mi-août
</div>


<div class="notes">


La roadmap par société : <https://wiki.postgresql.org/wiki/PostgreSQL10_Roadmap>
</div>



-----


## Questions
