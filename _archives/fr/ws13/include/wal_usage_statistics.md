
<!--
Les commits sur ce sujet sont :

| Sujet              | Lien                                                                                                        |
|====================|=============================================================================================================|
| infra              | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=df3b181499b40523bd6244a4e5eb554acb9020ce |
| pg_stat_statements | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=6b466bf5f2bea0c89fab54eef696bcfc7ecdafd7 |
| explain / autoexp  | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=33e05f89c53e5a1533d624046bb6fb0da7bb7141 |
| autovacuum         | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=b7ce6de93b59852c55d09acdaeebbf5aaf89114e |

Discussion : https://www.postgresql.org/message-id/flat/CAB-hujrP8ZfUkvL5OYETipQwA%3De3n7oqHFU%3D4ZLxWS_Cza3kQQ%40mail.gmail.com


### Suivi des statistiques d'utilisation des WAL

-->


#### Objectifs

<div class="slide-content">

* Mesurer l'impact des écritures dans les WAL sur les performances ;
* Statistiques calculées :
   + nombre d'enregistrements écrits dans les WAL ;
   + quantité de données écrites dans les WAL ;
   + nombre d'écritures de pages complètes.

</div>

<div class="notes"> 

Afin de garantir l'intégrité des données, PostgreSQL
utilise le _Write-Ahead Logging_ (WAL). Le concept central du WAL est d'effectuer
les changements des fichiers de données (donc les tables et les index)
uniquement après que ces changements ont été écrits de façon sûre dans un
journal, appelé journal des transactions.

La notion d'écriture de page complète (`full page write` ou `fpw`) est l'action
d'écrire une image de la page complète (`full page image` ou `fpi`) dans les
journaux de transactions. Ce comportement est régi par le paramètre
[`full_page_write`](https://www.postgresql.org/docs/13/runtime-config-wal.html#GUC-FULL-PAGE-WRITES).
Quand ce paramètre est activé, le serveur écrit l'intégralité du contenu de
chaque page disque dans les journaux de transactions lors de la première
modification de cette page qui intervient après un point de vérification
(`CHECKPOINT`). Le stockage de l'image de la page complète garantit une
restauration correcte de la page en cas de redémarrage suite à une panne. Ce
gain de sécurité se fait au prix d'un accroissement de la quantité de données à
écrire dans les journaux de transactions. Les écritures suivantes de la page ne
sont que des deltas. Il est donc préférable d'espacer les checkpoints. L'écart
entre les checkpoints à un impact sur la durée de la récupération après une
panne, il faut donc arriver à un équilibre entre performance et temps de
récupération. Cela peut être fait en manipulant
[`checkpoint_timeout`](https://www.postgresql.org/docs/13/runtime-config-wal.html#GUC-CHECKPOINT-TIMEOUT)
et
[`max_wal_size`](https://www.postgresql.org/docs/13/runtime-config-wal.html#GUC-MAX-WAL-SIZE).

L'objectif de cette fonctionnalité est de mesurer l'impact des écritures dans
les journaux de transactions sur les performances. Elle permet notamment de
calculer la proportion d'écritures de pages complètes par rapport au nombre
total d'enregistrements écrits dans les journaux de transactions.

Elle permet de calculer les statistiques suivantes :

* nombre d'enregistrements écrits dans les journaux de transactions ;
* quantité de données écrites dans les journaux de transactions ;
* nombre d'écritures de pages complètes.

À l'avenir, d'autres informations relatives à la génération d'enregistrement
pourraient être ajoutées.

</div>

-----

#### pg_stat_statements : informations sur les WAL

<div class="slide-content">

Nouvelles colonnes : 

* `wal_bytes` : volume d'écriture dans les WAL en octets
* `wal_records` : nombre d'écritures dans les WAL
* `wal_fpi` : nombre d'écritures de pages complètes dans les WAL.

</div>

<div class="notes">

Trois colonnes ont été ajoutées dans la vue
[pg_stat_statements](https://www.postgresql.org/docs/13/pgstatstatements.html) :

* `wal_bytes` : nombre total d'octets générés par la requête dans les journaux
  de transactions ;
* `wal_records` : nombre total d'enregistrements générés par la requête dans
  les journaux de transactions ;
* `wal_fpi` : nombre de total d'écritures d'images de pages complètes généré par
  la requête dans les journaux de transactions.

```
=# SELECT substring(query,1,100) AS query, wal_records, wal_fpi, wal_bytes 
-# FROM pg_stat_statements 
-# ORDER BY wal_records DESC;
| query                                         | wal_records | wal_fpi | wal_bytes |
|:----------------------------------------------|------------:|--------:|----------:|
| UPDATE test SET i = i + $1                    |       32000 |      16 |   2352992 |
| ANALYZE                                       |        3797 |     194 |   1691492 |
| CREATE EXTENSION pg_stat_statements           |         359 |      46 |    261878 |
| CREATE TABLE test(i int, t text)              |         113 |       9 |     35511 |
| EXPLAIN (ANALYZE, WAL) SELECT * FROM pg_class |           0 |       0 |         0 |
| SELECT * FROM pg_stat_statements              |           0 |       0 |         0 |
| CHECKPOINT                                    |           0 |       0 |         0 |
(8 rows)
```

Note : On peut voir que la commande `CHECKPOINT` n'écrit pas d'enregistrement
dans les journaux de transactions. En effet, elle se contente d'envoyer un
signal au processus `checkpointer`. C'est lui qui va effectuer le travail.

</div>

-----

#### EXPLAIN : affichage des WAL

<div class="slide-content">

* `EXPLAIN` :
   + `ANALYZE` : prérequis
   + `WAL` : affiche les statistiques d'utilisation des WAL
   
```
  Insert on test (actual time=3.231..3.231 rows=0 loops=1)
   WAL: records=1000 bytes=65893
```

</div>

<div class="notes">

Une option `WAL` a été ajoutée à la commande
[EXPLAIN](https://www.postgresql.org/docs/13/sql-explain.html). Cette
option  doit être utilisée conjointement avec `ANALYZE`.

```sql
=# EXPLAIN (ANALYZE, WAL, BUFFERS, COSTS OFF) 
-# INSERT INTO test (i,t) 
-#   SELECT x, 'x: '|| x FROM generate_series(1,1000) AS F(x);

                          QUERY PLAN
-------------------------------------------------------------------------------------
Insert on test (actual time=3.410..3.410 rows=0 loops=1)
  Buffers: shared hit=1012 read=6 dirtied=6
  I/O Timings: read=0.149
  WAL: records=1000 fpi=6 bytes=70646
  ->  Function Scan on generate_series f (actual time=0.196..0.819 rows=1000 loops=1)
Planning Time: 0.154 ms
Execution Time: 3.473 ms
```

</div>

-----

#### auto_explain : affichage des WAL

<div class="slide-content">

* `auto_explain.log_analyze` : prérequis
* `auto_explain.log_wal` : affiche les statistiques d'utilisation des journaux
  de transactions dans les plans
* équivalent de l'option `WAL` de `EXPLAIN`

</div>

<div class="notes">

L'extension
[auto_explain](https://www.postgresql.org/docs/13/auto-explain.html) a
également été mise à jour.  La nouvelle option `auto_explain.log_wal` contrôle
si les statistiques d'utilisation des journaux de transactions sont ajoutées
dans le plan d'exécution lors de son écriture dans les traces. C'est
l'équivalent de l'option `WAL` d'`EXPLAIN`. Cette option n'a d'effet que si
`auto_explain.log_analyze` est activé. `auto_explain.log_wal` est désactivé par
défaut. Seuls les utilisateurs ayant l'attribut `SUPERUSER` peuvent le modifier.

</div>

-----

#### autovacuum : affichage des WAL

<div class="slide-content">
* statistiques d'utilisation des WAL ajoutées dans les traces de l'autovacuum.

```
        WAL usage: 120 records, 3 full page images, 27935 bytes
```
</div>

<div class="notes">
Lorsque l'exécution de l'autovacuum déclenche une écriture dans les traces
(paramètre
[log_autovacuum_min_duration](https://www.postgresql.org/docs/13/runtime-config-autovacuum.html#GUC-LOG-AUTOVACUUM-MIN-DURATION)),
les informations concernant l'utilisation des journaux de transactions sont
également affichées.

```
LOG:  automatic vacuum of table "postgres.pg_catalog.pg_statistic": index scans: 1
  pages: 0 removed, 42 remain, 0 skipped due to pins, 0 skipped frozen
  tuples: 214 removed, 404 remain, 0 are dead but not yet removable, oldest xmin: 613
  buffer usage: 154 hits, 1 misses, 3 dirtied
  avg read rate: 4.360 MB/s, avg write rate: 13.079 MB/s
  system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
  WAL usage: 120 records, 3 full page images, 27935 bytes
```

Les commandes `ANALYZE` et `VACUUM` ne disposent pas d'options permettant de
tracer leurs statistiques d'utilisation des journaux de transactions.
Cependant, il est possible de récupérer ces informations dans la vue
`pg_stat_statements`.
</div>
