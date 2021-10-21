## TP - Statistiques d'utilisation des WAL

<div class="slide-content">

  * dans `pg_stat_statements` ;
  * dans les logs applicatifs ;
  * dans les plans d'exécution.

</div>

<div class="notes">

### Prérequis

Il est nécessaire d'effectuer la configuration suivante dans PostgreSQL pour
faire ce TP :

* `log_autovacuum_min_duration = 0` : ce paramètre va permettre de voir les
  statistiques liées à l'autovacuum dans les traces de PostgreSQL.

* `shared_preload_libraries = 'pg_stat_statements, auto_explain'` : ce
  paramètre va précharger les extensions `pg_stat_statements` et
  `auto_explain`.

* `auto_explain.log_min_duration = 0` : déclencher la trace des plans
  d'exécution sur toutes les requêtes.

* `auto_explain.log_analyze = on` : activer ce paramètre est un prérequis à
  l'utilisation du paramètre `auto_explain.log_wal`. Il signale PostgreSQL
  qu'il doit effectuer des `EXPLAIN ANALYZE`.

* `auto_explain.log_wal = on` : ce paramètre permet d'ajouter les statistiques
  d'utilisation des wals au plan écrits dans les traces.

* `auto_explain.sample_rate = .01` : ce paramètre permet de limiter le nombre
  de requêtes écrites dans le traces en effectuant un échantillonnage. La
  valeur `1` signifie toutes les requêtes.

Il faudra ensuite installer `pg_stat_statements` dans la base de données
`postgres` avec la commande :

```
CREATE EXTENSION pg_stat_statements;
```

### Mise en place du test

Remettre à zéro les statistiques de `pg_stat_statements`.

```
$ psql -Atc "SELECT pg_stat_statements_reset()"
```

Créer une base de données `bench` pour l'outil `pgbench` et initialiser la base
de l'outil.

```
$ psql -c "CREATE DATABASE bench;"
CREATE DATABASE

$ pgbench -I -d bench
```

Lancer l'outil `pgbench` sur une durée de 60 secondes dans la base de données
`bench` : 

```
$ pgbench -T60 -d bench
```

### Consultation des statistiques

Consulter `pg_stat_statements` et repérer les commandes qui ont généré des
journaux de transactions.

```
$ psql <<EOF
SELECT substring(query,1,40) AS query, wal_records, wal_fpi, wal_bytes
FROM pg_stat_statements
ORDER BY wal_records DESC
LIMIT 10;
EOF
                  query                   | wal_records | wal_fpi | wal_bytes
------------------------------------------+-------------+---------+-----------
 UPDATE pgbench_accounts SET abalance = a |      103866 |       0 |   6979917
 UPDATE pgbench_tellers SET tbalance = tb |       51261 |       0 |   3798136
 UPDATE pgbench_branches SET bbalance = b |       51184 |       0 |   3781693
 INSERT INTO pgbench_history (tid, bid, a |       50934 |       0 |   4023786
 copy pgbench_accounts from stdin         |        1738 |       0 |  10691074
 vacuum analyze pgbench_accounts          |        1654 |       4 |    131678
 EXPLAIN (ANALYZE, WAL) INSERT INTO test  |        1000 |       0 |     65893
 EXPLAIN (ANALYZE, WAL, COSTS OFF) INSERT |        1000 |       0 |     65893
 alter table pgbench_accounts add primary |         303 |     276 |   2038141
 CREATE TABLE test (i int, t text)        |         115 |      28 |    128163
(10 rows)
```

Éditer le fichier de trace :

```
view $PGDATA/$(psql -tAc "SELECT pg_current_logfile()")
```

Observer l'activité de l'autovacuum, noter l'ajout des statistiques d'accès aux
journaux de transactions : 

```
LOG:  automatic vacuum of table "bench.public.pgbench_branches": index scans: 0
  pages: 0 removed, 1 remain, 0 skipped due to pins, 0 skipped frozen
  tuples: 150 removed, 1 remain, 0 are dead but not yet removable, oldest xmin: ... 
  buffer usage: 49 hits, 0 misses, 0 dirtied
  avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
  system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
  WAL usage: 3 records, 0 full page images, 646 bytes
```

Observer les plans écrits dans les traces, noter l'ajout des statistiques
d'accès aux journaux de transactions :

```
LOG:  duration: 0.313 ms  plan:
  Query Text: 
     UPDATE pgbench_accounts SET abalance = abalance + 4802 WHERE aid = 8849318;
  Update on pgbench_accounts  (...) (...)
     WAL: records=3 fpi=2 bytes=15759
       ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts  (...) (...)
              Index Cond: (aid = 8849318)
```

</div>
