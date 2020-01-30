## Performances

<div class="slide-content">

  * `REINDEX CONCURRENTLY`
  * `CREATE STATISTICS` pour les distributions non-uniformes
  * Paramètre `plan_cache_mode`
  * Fonctions d'appui : pour améliorer les estimations de coût des fonctions
  * _JIT_ par défaut
  * Optimisation _CTE_ : `MATERIALIZED` / `NOT MATERIALIZED`
  * Meilleures performances sur le partitionnement
</div>  

<div class="notes"></div>
----

### REINDEX CONCURRENTLY

<div class="slide-content">

* `REINDEX CONCURRENTLY`

</div>

<div class="notes">

La commande `REINDEX` peut être maintenant suivie de l'option `CONCURRENTLY`,
afin de permettre la réindexation d'un index en parallèle de son utilisation.

`REINDEX CONCURRENTLY` crée un nouvel index en concurrence de l'activité
usuelle sur l'ancien. Une fois le nouvel index créé et validé, il remplace
alors l'ancien. C'est seulement lors de cette dernière phase très rapide que
la commande nécessite un verrou exclusif sur l'index.

**Exemple :**

```sql
pg12=$ REINDEX (VERBOSE) TABLE CONCURRENTLY t1;
psql: INFO:  index "public.idx_t1_id" was reindexed
psql: INFO:  table "public.t1" was reindexed
DETAIL:  CPU: user: 1.97 s, system: 0.71 s, elapsed: 3.48 s.
REINDEX 
```

L'option existe également pour la commande shell `reindexdb` ( `--concurrently` ).

**Exemple :** 

```shell
$ reindexdb --dbname pg12 --concurrently --table t1 --verbose
INFO:  index "public.idx_t1_id" was reindexed
INFO:  table "public.t1" was reindexed
DETAIL:  CPU: user: 1.74 s, system: 0.69 s, elapsed: 3.23 s.
```

Notez qu'un `REINDEX` classique est plus rapide sans l'option `CONCURRENTLY`,
ce dernier effectuant moins de travail:

```shell
$ pgbench -i -s 100

$ time -f%E reindexdb -i pgbench_accounts_pkey
0:06.83

$ time -f%E reindexdb --concurrently -i pgbench_accounts_pkey
0:09.34
```

Néanmoins, la reconstruction se faisant en concurrence avec la production
usuelle, ce temps supplémentaire est moins impactant. Voici un exemple:

```shell
#### SANS CONCURRENTLY

$ pgbench -c1 -T20 -S & reindexdb -i pgbench_accounts_pkey
[...]
number of transactions actually processed: 66241
latency average = 0.302 ms
tps = 3312.017682 (including connections establishing)
tps = 3312.738804 (excluding connections establishing)

#### AVEC CONCURRENTLY

$ pgbench -c1 -T20 -S & reindexdb --concurrently -i pgbench_accounts_pkey
[...]
number of transactions actually processed: 118991
latency average = 0.168 ms
tps = 5949.500860 (including connections establishing)
tps = 5951.142968 (excluding connections establishing)

```

Le nombre de transactions par seconde est plus important avec l'option
`CONCURRENTLY` (5951 tps contre 3312), ce dernier n'ayant bloqué la production
qu'un court instant.

</div>

----

### CREATE STATISTICS mcv

<div class="slide-content">

  * Nouveau type `MCV` pour la commande `CREATE STATISTICS`
  * _Most Common Values_
  * Collecte les valeurs les plus communes pour un ensemble de colonnes
</div>

<div class="notes">

Jusqu'en version 11, la commande `CREATE STATISTICS` supportait deux types de collecte de
statistique: `n-distinct` et `dependencies`.

Le type `mcv` ajouté en version 12 permet de créer des statistiques sur les
valeurs les plus communes pour les colonnes indiquées.

Les statistiques sont stockées dans la table `pg_statistic_ext`.

**Exemple :** 

```sql
pg12=$ CREATE TABLE t4 (id INT, nb NUMERIC, comm varchar(50));
CREATE TABLE

pg12=$ CREATE STATISTICS stat_mcv_t4(mcv) ON id, nb FROM t4 ;
CREATE STATISTICS

pg12=$ select * from pg_statistic_ext;
  oid  | stxrelid |   stxname   | stxnamespace | stxowner | stxkeys | stxkind 
-------+----------+-------------+--------------+----------+---------+---------
 41010 |    41003 | stat_mcv_t4 |         2200 |       10 | 1 2     | {m}
(1 row)
```

Pour plus d'information et d'exemple, voir le chapitre
[Extended Statistics](https://www.postgresql.org/docs/12/planner-stats.html#PLANNER-STATS-EXTENDED)

</div>

----

### Mise en cache des plans d'exécution 

<div class="slide-content">

* `plan_cache_mode`
* Trois modes:
  * `auto`
  * `force_custom_plan`
  * `force_generic_plan`
</div>

<div class="notes">

Ce nouveau paramètre permet de définir la méthode de mise en cache du plan
d'exécution des instructions préparées (eg. commande `PREPARE`).

La valeur par défaut est `auto`, ce qui correspond au comportement habituel du
moteur: utiliser le plan générique si son coût n'est pas beaucoup plus
important que celui des cinq premières exécutions réalisées de la requête.

Les deux autres valeurs `force_custom_plan` et `force_generic_plan` permettent
respectivement de forcer l'utilisation d'un plan calculé à chaque exécution,
ou au contraire de forcer l'utilisation d'un plan générique.

Note : Le paramètre est appliqué lorsqu'un plan mis en cache doit être
exécuté, pas lorsqu'il est préparé.

</div>

----

### Fonctions d'appui (_support functions_)

<div class="slide-content"> 

* Améliore la visibilité du planificateur sur les fonctions
* Possibilité d'associer à une fonction une fonction « de support »
* Produit dynamiquement des informations sur:
  * la sélectivité
  * le nombre de lignes produit
  * son coût d'exécution
* La fonction doit être écrite en C
</div>

<div class="notes">

Jusqu'en version 11, le planificateur considérait des fonctions comme des boîtes
noires, avec éventuellement quelques informations très partielles et surtout
statiques à propos de leur coût et du nombre de lignes retourné.

Les _supports functions_ permettent de fournir dynamiquement des informations
au planificateurs concernant les fonctions utilisées et leur résultat dans le
contexte de la requête. 

Voici un exemple avec la fonction `generate_series`:

~~~
# \sf generate_series(int, int)
CREATE OR REPLACE FUNCTION pg_catalog.generate_series(integer, integer)
 RETURNS SETOF integer
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT SUPPORT generate_series_int4_support
AS $function$generate_series_int4$function$


# explain select i from generate_series(1,10000) t(i);
                                 QUERY PLAN                                 
----------------------------------------------------------------------------
 Function Scan on generate_series t  (cost=0.00..100.00 rows=10000 width=4)


# explain select i from generate_series(1,10) t(i);
                              QUERY PLAN                               
-----------------------------------------------------------------------
 Function Scan on generate_series t  (cost=0.00..0.10 rows=10 width=4)


# explain select i from generate_series(1,10) t(i) where i > 9;
                              QUERY PLAN                              
----------------------------------------------------------------------
 Function Scan on generate_series t  (cost=0.00..0.13 rows=3 width=4)
   Filter: (i > 9)
~~~
</div>

----

### JIT par défaut

<div class="slide-content">

* JIT (Just-In-time) est maintenant activé par défaut 
</div>

<div class="notes">

La compilation _JIT_ (_Just-In-time_) est maintenant active par défaut dans
PostgreSQL 12.

Les informations de compilation _JIT_, peuvent être loggées dans le journal.

</div>

----

### Modification du comportement par défaut des requêtes _CTE_ 

<div class="slide-content">

* Les _CTE_ ne sont plus par défaut des barrières d'optimisation
* Modification du comportement par défaut des CTE
* Nouvelles syntaxes:
  * `MATERIALIZED`
  * `NOT MATERIALIZED`
</div>

<div class="notes">


Jusqu'en version 11, les _CTE_ (_Common Table Expression_) spécifiées dans la
clause `WITH` étaient "matérialisées". Autrement dit, les CTE devaient être
exécutés tels quels sans optimisation possible avec le reste de la requête.
C'est ce qu'on appelle une « barrière d'optimisation »

Depuis la version 12, ce comportement n'est plus le même. Par défaut, les
_CTE_ ne sont plus des barrières d'optimisation, ce qui permet de déplacer
certaines opérations de la requête afin de les rendre plus efficaces.

Il est possible de forcer l'un ou l'autre des comportements grâce aux syntaxes
`MATERIALIZED` ou `NOT MATERIALIZED` de la clause `WITH`.

Par exemple, le fait de spécifier l'option `NOT MATERIALIZED`, permet à la
clause `WHERE` de pousser  les restrictions à l'intérieur de la clause
`WITH`.

Les conditions des requêtes pour l'application de l'option `NOT MATERIALIZED` sont : 

- requêtes non récursives
- requêtes référencées une seule fois 
- requêtes n'ayant aucun effet de bord



**Exemple :** dans cet exemple, on voit que l'index sur la colonne `id` n'est
pas utilisé à cause du CTE.

```sql
pg12=$ EXPLAIN ANALYZE WITH rq AS MATERIALIZED (SELECT * FROM t1) 
SELECT * FROM rq WHERE id=1500;

                                     QUERY PLAN                                     
---------------------------------------------------------------------------------
 CTE Scan on rq  (cost=133470.68..201273.71 rows=15067 width=4) 
(actual time=19.185..7067.369 rows=4 loops=1)
   Filter: (id = 1500)
   Rows Removed by Filter: 3100096
   CTE rq
     ->  Seq Scan on t1  (cost=0.00..133470.68 rows=3013468 width=4) 
(actual time=4.311..3749.203 rows=3100100 loops=1)
 Planning Time: 0.195 ms
 Execution Time: 7073.119 ms
```

La même requête avec l'option `NOT MATERIALIZED` (valeur par défaut si l'option
n'est pas spécifiée) permet de réduire le temps d'exécution.

```sql
pg12=$ EXPLAIN ANALYSE WITH rq AS NOT MATERIALIZED (SELECT * FROM t1) 
SELECT * FROM rq WHERE id =1500;
                                     QUERY PLAN                                     
---------------------------------------------------------------------------------
 Index Only Scan using idx_t1_id on t1  (cost=0.43..15.26 rows=3 width=4) 
(actual time=0.184..0.245 rows=4 loops=1)
   Index Cond: (id = 1500)
   Heap Fetches: 0
 Planning Time: 0.209 ms
 Execution Time: 0.338 ms
```

</div>

----

### Performances du partitionnement

<div class="slide-content">

  * Performances accrues pour les tables avec un grand nombre de partitions
  * Verrous lors des manipulations de partitions
  * Support des clés étrangères vers une table partitionnée
  * Amélioration du chargement de données

</div>


<div class="notes">

PostgreSQL 12 optimise l'accès aux tables ayant plusieurs milliers de
partitions.

La commande `ATTACH PARTITION`, ne verrouille plus de façon exclusive la table
partitionnée, permettant ainsi de ne pas bloquer la production lors de l'ajout
d'une partition. En revanche, l'option `DETACH PARTITION`, pose toujours un
verrou exclusif.

L'utilisation de clés étrangères pour les partitions filles est désormais
supportée. Voir à ce propos le chapitre sur le partitionnement.

Une amélioration de la fonction `COPY` dans les partitions permet un chargement plus
rapide.

</div>

----
