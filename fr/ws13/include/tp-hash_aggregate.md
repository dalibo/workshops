## TP - _HashAggregate_, débord sur disque

<div class="slide-content">

Dimensionnement de `hash_mem_multiplier`.

</div>

<div class="notes">

Créer deux tables, les alimenter et calculer les statistiques dessus :

```
CREATE TABLE tableA(ac1 int, ac2 int);
CREATE TABLE tableB(bc1 int, bc2 int);
INSERT INTO tableA
   SELECT x, random()*100
   FROM generate_series(1,1000000) AS F(x);
INSERT INTO tableB
   SELECT mod(x,100000), random()*100
   FROM generate_series(1,1000000) AS F(x)
   ORDER BY 1;
ANALYZE tableA, tableB;
```

Afficher la valeur des paramètres `hash_mem_multiplier` et `work_mem` :

```
=> SELECT name, setting, unit, context
   FROM pg_settings
   WHERE name IN('work_mem', 'hash_mem_multiplier');

name                 | setting | unit | context
---------------------+---------+------+---------
 hash_mem_multiplier | 1       | ¤    | user
 work_mem            | 4096    | kB   | user
(2 rows)
```

Comme le montre la colonne `context`, ces deux paramètres peuvent être modifiés
dans une session.


Exécuter la requête suivante et observer les informations du nœud
_HashAggregate_ :

```
=> EXPLAIN (ANALYZE, SETTINGS)
   SELECT ac1, count(ac2), sum(bc2)
   FROM tableA INNER JOIN TABLEB ON ac1 = bc1
   GROUP BY Ac1;

                                    QUERY PLAN
------------------------------------------------------------------------------------
HashAggregate (actual time=781.895..898.119 rows=99999 loops=1)
 Group Key: tablea.ac1
 Planned Partitions: 32  Batches: 33  Memory Usage: 4369kB  Disk Usage: 30456kB
 -> Hash Join (actual time=170.824..587.731 rows=999990 loops=1)
     Hash Cond: (tableb.bc1 = tablea.ac1)
     ->  Seq Scan on tableb (actual time=0.037..81.744 rows=1000000 loops=1)
     ->  Hash (actual time=169.215..169.216 rows=1000000 loops=1)
          Buckets: 131072  Batches: 16  Memory Usage: 3471kB
          ->  Seq Scan on tablea (actual time=0.041..62.197 rows=1000000 loops=1)
Planning Time: 0.244 ms
Execution Time: 905.274 ms
```

Le nœud _HashAggregate_ permet de connaître les informations suivantes :

* le planificateur avait prévu de créer 32 partitions sur disque ;
* l'exécuteur a eu besoin de réaliser 33 passes (_batch_) ;
* la quantité de mémoire utilisée est 4 Mo ;
* le quantité de disque utilisé est de 30 Mo.

Modifier la configuration de `hash_mem_multiplier` à 5:

```
SET hash_mem_multiplier TO 5;
```

Exécuter à nouveau la commande `EXPLAIN`. Voici le plan obtenu :

```
HashAggregate (actual time=693.633..711.925 rows=99999 loops=1)
 Group Key: tablea.ac1
 Planned Partitions: 8  Batches: 1  Memory Usage: 15633kB
 -> Hash Join (actual time=172.467..558.101 rows=999990 loops=1)
     Hash Cond: (tableb.bc1 = tablea.ac1)
     -> Seq Scan on tableb (actual time=0.017..81.738 rows=1000000 loops=1)
     -> Hash (actual time=171.096..171.097 rows=1000000 loops=1)
         Buckets: 524288  Batches: 4  Memory Usage: 13854kB
         -> Seq Scan on tablea (actual time=0.008..59.526 rows=1000000 loops=1)
Settings: hash_mem_multiplier = '20'
Planning Time: 0.336 ms
Execution Time: 723.450 ms
```

Nous constatons que :

* concernant le nœud _HashAggregate_ :
  * la quantité de mémoire utilisée est désormais de 15 Mo ;
  * le planificateur avait prévu d'écrire 8 partitions sur disque ;
  * l'exécuteur n'a eu besoin de réaliser qu'une seule passe, ce qui est mieux
    que prévu. Cette différence provient probablement d'une erreur d'estimation.
  * l'exécution est deux fois plus rapide : `310.388` < `153.824`
* concernant les nœuds _Hash_ et _Hash Join_ :
  * utilisent maintenant plus de mémoire avec 13 Mo :
  * l'algorithme utilise donc moins de batch pour traiter la table de hachage ;
  * le temps de création de la table de hachage est stable ;
  * la jointure est marginalement plus rapide.

L'augmentation de la mémoire disponible pour les tables de hachage a ici permit
d'accélérer l'agrégation des données.

Modifier la configuration de `hash_mem_multiplier` à 20 :

```
SET hash_mem_multiplier TO 20;
```

Exécuter une nouvelle fois la commande `EXPLAIN` :

```
HashAggregate (actual time=603.446..624.357 rows=99999 loops=1)
 Group Key: tablea.ac1
 Batches: 1  Memory Usage: 34065kB
 -> Hash Join (actual time=216.018..467.546 rows=999990 loops=1)
     Hash Cond: (tableb.bc1 = tablea.ac1)
     -> Seq Scan on tableb (actual time=0.018..60.117 rows=1000000 loops=1)
     -> Hash (actual time=213.442..213.443 rows=1000000 loops=1)
         Buckets: 1048576  Batches: 1  Memory Usage: 47255kB
         ->  Seq Scan on tablea (actual time=0.010..63.532 rows=1000000 loops=1)
Settings: hash_mem_multiplier = '20'
Planning Time: 0.247 ms
Execution Time: 639.538 ms
```

Cette fois-ci, nous constatons que :

* concernant le nœud _HashAggregate_ :
  * la quantité de mémoire utilisée est de 33 Mo, c'est moins que ce que le
    maximum disponible (4 Mo * 20) ;
  * le planificateur n'a pas prévu d'écrire de partition sur disque ;
  * l'exécuteur n'a eu besoin de réaliser qu'une seule passe. Ce qui est
    conforme aux prévisions du planificateur ;
  * le temps d'exécution est similaire au plan précédent: `156.811`
* concernant les nœuds _Hash_ et _Hash Join_ :
  * ils utilisent maintenant plus de mémoire avec 46 Mo :
  * l'algorithme n'utilise plus qu'un seul batch ;
  * le temps de création de la table de hachage est marginalement plus long ;
  * la jointure est plus rapide `254.103` < `387.004`.

L'augmentation de la mémoire disponible pour les tables de hachage a ici permit
d'accélérer la jointure entre les tables.

Note : l'optimisation la plus efficace est de modifier la requête en groupant
les données sur la colonne `bc1`.  Le plan utilisé est un plan parallélisé.

```
=> EXPLAIN (ANALYZE, SETTINGS)
   SELECT bc1, count(ac2), sum(bc2)
   FROM tableA INNER JOIN TABLEB ON ac1 = bc1
   GROUP BY bc1;
                                    QUERY PLAN
-------------------------------------------------------------------------------
Finalize GroupAggregate
Group Key: tableb.bc1
-> Gather Merge
   Workers Planned: 2
   Workers Launched: 2
   -> Sort
      Sort Key: tableb.bc1
      Sort Method: quicksort  Memory: 3635kB
      Worker 0: Sort Method: quicksort Memory: 3787kB
      Worker 1: Sort Method: quicksort Memory: 3864kB
      -> Partial HashAggregate
         Group Key: tableb.bc1
         Planned Partitions: 4 Batches: 5 Memory Usage: 4145kB Disk Usage: 11712kB
         Worker 0: Batches: 5 Memory Usage: 4145kB Disk Usage: 11744kB
         Worker 1: Batches: 5 Memory Usage: 4145kB Disk Usage: 11696kB
         -> Parallel Hash Join
            Hash Cond: (tableb.bc1 = tablea.ac1)
            -> Parallel Seq Scan on tableb
            -> Parallel Hash
               Buckets: 131072 Batches: 32 Memory Usage: 3552kB
               -> Parallel Seq Scan on tablea
Planning Time: 0.300 ms
Execution Time: 841.684 ms
```

</div>
