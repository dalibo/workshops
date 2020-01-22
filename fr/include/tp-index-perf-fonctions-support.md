## TP Index et performances

<div class="slide-content">

  * Les fonctions d'appui
  * reindex concurrently
</div>

<div class="notes">

</div>

----

### TP sur les fonctions d'appui

<div class="slide-content">


</div>

<div class="notes">


#### Modification des fonctions classiques

En regardant la définition de la fonction `unnest(anyarray)`, on remarque que la v12 fait apparaître une fonction d'appui (_support function_ en anglais) :


**En v11**

```SQL

v11 $ \ef unnest(anyarray)

CREATE OR REPLACE FUNCTION pg_catalog.unnest(anyarray)
 RETURNS SETOF anyelement
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT ROWS 100 
AS $function$array_unnest$function$
```


**En v12 :** 

```SQL

v12 $ \ef unnest(anyarray)

CREATE OR REPLACE FUNCTION pg_catalog.unnest(anyarray)
 RETURNS SETOF anyelement
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT ROWS 100 SUPPORT array_unnest_support
AS $function$array_unnest$function$
```

Le rôle de la fonction d'appui peut être vérifié rapidement en comparant  l'`explain` sous une version 11 et sous une version 12 :

```SQL
v11 $ explain select * from unnest(array[0,1,2,3]);
                         QUERY PLAN                          
-------------------------------------------------------------
 Function Scan on unnest  (cost=0.00..1.00 rows=100 width=4)
(1 row)
```

On remarque que l'optimiseur fait une erreur en estimant le nombre de lignes retournées (100 plutôt que 4).

```SQL
explain select * from unnest(array[0,1,2,3]);
                        QUERY PLAN                         
-----------------------------------------------------------
 Function Scan on unnest  (cost=0.00..0.04 rows=4 width=4)
(1 row)
```

La v12 estime bien le nombre de ligne car elle consulte la fonction d'appui.


Autre exemple avec la fonction `generate_series(bigint,bigint)`

```SQL
v11 $ explain select generate_series(1,100000000);
                   QUERY PLAN
-------------------------------------------------
 ProjectSet  (cost=0.00..5.02 rows=1000 width=4)
   ->  Result  (cost=0.00..0.01 rows=1 width=0)
(2 rows)
```

```SQL
v12 $ explain select generate_series(1,100000000);
                        QUERY PLAN
-----------------------------------------------------------
 ProjectSet  (cost=0.00..500000.02 rows=100000000 width=4)
   ->  Result  (cost=0.00..0.01 rows=1 width=0)
(2 rows)
```

La fonction generate_series a été modifiée : 

```SQL
v12 $ \ef generate_series(bigint,bigint)

CREATE OR REPLACE FUNCTION pg_catalog.generate_series(bigint, bigint)
 RETURNS SETOF bigint
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT SUPPORT generate_series_int8_support
AS $function$generate_series_int8$function$
```

La fonction d'appui est appelée par l'optimiseur, pour retourner une estimation du nombre de lignes qui est calculée en  rapport avec les  2 entiers donnés en paramètres.

</div>
----


### TP Reindex concurrently

<div class="slide-content">

</div>


<div class="notes">


Les tests sont à effectuer sur une instance de PostgreSQL 12 avec le paramétrage par défaut.

- Créer 10 000 000 de lignes. La commande ci-dessous ajoute 10 milions d'enregistrements dans la table pgbench_accounts.

```bash
$ pgbench -i -s 100
```

- Réindexer la table sans `concurrently`.

Exemple de résultat (sans concurrently) :

```bash
$ time -f%E reindexdb -i pgbench_accounts_pkey
0:06.83
$ time -f%E reindexdb -i pgbench_accounts_pkey
0:06.85
$ time -f%E reindexdb -i pgbench_accounts_pkey
0:06.83
```

- Réindexer la table avec  `concurrently`.

Exemple de résultat (avec concurrently) :

```bash
$ time -f%E reindexdb --concurrently -i pgbench_accounts_pkey
0:09.58
$ time -f%E reindexdb --concurrently -i pgbench_accounts_pkey
0:09.40
$ time -f%E reindexdb --concurrently -i pgbench_accounts_pkey
0:09.34
```

La réindexation classique est plus rapide car elle effectue moins d'opérations.

- Lancer un test avec `pgbench` de 20 secondes en lecture et déclencher une réindexation 5 secondes après le début du bench.

```bash
$ (sleep 5; time -f%E reindexdb -i pgbench_accounts_pkey ) & pgbench -c1 -T20 -S -P1 -r
```

Exemple de résultat :

```log
starting vacuum...end.
progress: 1.0 s, 6375.9 tps, lat 0.156 ms stddev 0.029
progress: 2.0 s, 6549.7 tps, lat 0.152 ms stddev 0.016
progress: 3.0 s, 6586.0 tps, lat 0.151 ms stddev 0.019
progress: 4.0 s, 6902.0 tps, lat 0.145 ms stddev 0.020
progress: 5.0 s, 6603.9 tps, lat 0.148 ms stddev 0.017
progress: 6.0 s, 0.0 tps, lat 0.000 ms stddev 0.000    <- reindex en cours
progress: 7.0 s, 0.0 tps, lat 0.000 ms stddev 0.000    <- reindex en cours
....
0:06.70                                                <- temps de reindex
progress: 12.0 s, 2324.2 tps, lat 3.022 ms stddev 138.282
progress: 13.0 s, 6684.0 tps, lat 0.149 ms stddev 0.028
... 
transaction type: <builtin: select only>
scaling factor: 100
query mode: simple
number of clients: 1
number of threads: 1
duration: 20 s
number of transactions actually processed: 89110
latency average = 0.224 ms
latency stddev = 22.327 ms
tps = 4455.484635 (including connections establishing)
tps = 4455.974731 (excluding connections establishing)
[1]+  Done      ( sleep 5; time -f%E reindexdb -i pgbench_accounts_pkey )
```

- Lancer un test avec `pgbench` de 20 secondes en lecture et déclencher une reindexation avec `concurrently` 5 secondes après le début du bench.

```bash
$ (sleep 5; time -f%E reindexdb --concurrently -i pgbench_accounts_pkey ) \
& pgbench -c1 -T20 -S -P1 -r
```

Exemple de résultat : 

```logs
starting vacuum...end.
progress: 1.0 s, 6346.8 tps, lat 0.156 ms stddev 0.029
progress: 2.0 s, 6688.0 tps, lat 0.149 ms stddev 0.016
progress: 3.0 s, 6471.9 tps, lat 0.154 ms stddev 0.053
progress: 4.0 s, 6730.9 tps, lat 0.148 ms stddev 0.025
progress: 5.0 s, 6723.0 tps, lat 0.148 ms stddev 0.021
progress: 6.0 s, 4546.0 tps, lat 0.219 ms stddev 0.047  <- reindex concurrently 
progress: 7.0 s, 4472.2 tps, lat 0.223 ms stddev 0.090  <- reindex concurrently 
progress: 8.0 s, 4557.0 tps, lat 0.219 ms stddev 0.067  <- reindex concurrently 
...
0:10.62                                                 <- temps de reindex
progress: 16.0 s, 6221.7 tps, lat 0.160 ms stddev 0.039
progress: 17.0 s, 6655.3 tps, lat 0.150 ms stddev 0.017
...
transaction type: <builtin: select only>
scaling factor: 100
query mode: simple
number of clients: 1
number of threads: 1
duration: 20 s
number of transactions actually processed: 120522
latency average = 0.165 ms
latency stddev = 0.150 ms
tps = 6026.060490 (including connections establishing)
tps = 6027.885412 (excluding connections establishing)
[1]+  Done  ( sleep 5; time -f%E reindexdb --concurrently -i pgbench_accounts_pkey )
```

- Lancer un test avec `pgbench` de 20 secondes en écriture et déclencher une reindexation 5 secondes après le début du bench.

```bash
$ (sleep 5; time -f%E reindexdb -i pgbench_accounts_pkey ) & pgbench -c1 -T20 -P1 -r
```

Exemple de résultat : 

```logs
starting vacuum...end.
progress: 1.0 s, 146.0 tps, lat 6.769 ms stddev 1.448
progress: 2.0 s, 155.0 tps, lat 6.468 ms stddev 1.254
progress: 3.0 s, 129.0 tps, lat 7.773 ms stddev 1.439
progress: 4.0 s, 129.0 tps, lat 7.704 ms stddev 1.415
progress: 5.0 s, 156.0 tps, lat 6.310 ms stddev 1.235
progress: 6.0 s, 0.0 tps, lat 0.000 ms stddev 0.000 <- reindex en cours
progress: 7.0 s, 0.0 tps, lat 0.000 ms stddev 0.000
....
0:07.70
progress: 13.0 s, 48.0 tps, lat 167.134 ms stddev 1094.662
progress: 14.0 s, 126.0 tps, lat 7.894 ms stddev 1.741
progress: 15.0 s, 143.0 tps, lat 7.015 ms stddev 1.629
...
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: simple
number of clients: 1
number of threads: 1
duration: 20 s
number of transactions actually processed: 1746
latency average = 11.454 ms
latency stddev = 183.386 ms
tps = 87.274426 (including connections establishing)
tps = 87.294817 (excluding connections establishing)
statement latencies in milliseconds:
           0.004  \set aid random(1, 100000 * :scale)
           0.001  \set bid random(1, 1 * :scale)
           0.001  \set tid random(1, 10 * :scale)
           0.001  \set delta random(-5000, 5000)
           0.145  BEGIN;
           4.907  UPDATE pgbench_accounts SET abalance = abalance + :delta 
                  WHERE aid = :aid;
           0.320  SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
           0.419  UPDATE pgbench_tellers SET tbalance = tbalance + :delta 
                  WHERE tid = :tid;
           0.367  UPDATE pgbench_branches SET bbalance = bbalance + :delta 
                  WHERE bid = :bid;
           0.269  INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) 
                  VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
           5.020  END;
  [1]+  Done      () sleep 5; time -f%E reindexdb -i pgbench_accounts_pkey )
```

- Lancer un test avec `pgbench` de 20 secondes en écriture et déclencher une reindexation avec `concurrently` 5 secondes après le début du bench.

```bash
$ (sleep 5; time -f%E reindexdb --concurrently -i pgbench_accounts_pkey ) \
& pgbench -c1 -T20 -P1 -r
```

Exemple de résultat :

```logs
progress: 1.0 s, 155.0 tps, lat 6.412 ms stddev 1.510
progress: 2.0 s, 142.0 tps, lat 7.039 ms stddev 1.780
progress: 3.0 s, 126.0 tps, lat 7.955 ms stddev 1.673
progress: 4.0 s, 130.0 tps, lat 7.665 ms stddev 1.640
progress: 5.0 s, 146.0 tps, lat 6.870 ms stddev 1.580
progress: 6.0 s, 147.0 tps, lat 6.762 ms stddev 1.278
progress: 7.0 s, 144.0 tps, lat 6.934 ms stddev 1.284
...

0:11.89
progress: 17.0 s, 157.0 tps, lat 6.321 ms stddev 1.546
progress: 18.0 s, 139.0 tps, lat 7.188 ms stddev 1.555
progress: 19.0 s, 145.0 tps, lat 6.944 ms stddev 3.168
progress: 20.0 s, 147.0 tps, lat 6.768 ms stddev 1.444
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: simple
number of clients: 1
number of threads: 1
duration: 20 s
number of transactions actually processed: 2740
latency average = 7.297 ms
latency stddev = 6.863 ms
tps = 136.994259 (including connections establishing)
tps = 137.018048 (excluding connections establishing)
[1]+  Done ( sleep 5; time -f%E reindexdb --concurrently -i pgbench_accounts_pkey) 
```

</div>

----



















