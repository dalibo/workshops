## TP - Progression de la commande ANALYZE

<div class="slide-content">

  * mise en place des tables et données ;
  * calcul des statistiques et observations.

</div>

<div class="notes">

### Mise en place des tables et données

Créer une table partitionnée avec 10 partitions :

```
psql << _EOF_
CREATE TABLE test(i int, j float, k float, l float, m float)
       PARTITION BY RANGE (i);
CREATE TABLE test_1 PARTITION OF test FOR VALUES FROM(0) TO(10);
CREATE TABLE test_2 PARTITION OF test FOR VALUES FROM(10) TO(20);
CREATE TABLE test_3 PARTITION OF test FOR VALUES FROM(20) TO(30);
CREATE TABLE test_4 PARTITION OF test FOR VALUES FROM(30) TO(40);
CREATE TABLE test_5 PARTITION OF test FOR VALUES FROM(40) TO(50);
CREATE TABLE test_6 PARTITION OF test FOR VALUES FROM(50) TO(60);
CREATE TABLE test_7 PARTITION OF test FOR VALUES FROM(60) TO(70);
CREATE TABLE test_8 PARTITION OF test FOR VALUES FROM(70) TO(80);
CREATE TABLE test_9 PARTITION OF test FOR VALUES FROM(80) TO(90);
CREATE TABLE test_10 PARTITION OF test FOR VALUES FROM(90) TO(100);

INSERT INTO test 
      SELECT random()*99, random(), random(), random(), random()
      FROM generate_series(1, 20000000);
_EOF_
```

### ANALYZE et observations

Dans une session psql, lancer la commande :

```
psql -x << _EOF_
SELECT pid,
       datname,
       relid::regclass,
       phase,
       (100 * sample_blks_scanned::float / sample_blks_total)::int pct_sampled,
       ext_stats_computed || '/' || ext_stats_total AS extended_stat_no,
       child_tables_done || '/' || child_tables_total AS child_table_no,
       current_child_table_relid::regclass
FROM pg_stat_progress_analyze \watch 0.1
_EOF_
```

Dans une autre session, lancer la commande analyze :

```
psql -c "ANALYZE test";
```

On observe que pendant la phase d'acquisition des échantillions les partitions
de la table défilent les une après les autres afin de calculer les statistiques
de la table partitionnée.

```
-[ RECORD 1 ]-------------+--------------------------------
pid                       | 23887
datname                   | postgres
relid                     | test
phase                     | acquiring inherited sample rows
pct_sampled               | 6
extended_stat_no          | 0/0
child_table_no            | 0/5
current_child_table_relid | test_1

-[ RECORD 1 ]-------------+--------------------------------
pid                       | 23887
datname                   | postgres
relid                     | test
phase                     | acquiring inherited sample rows
pct_sampled               | 19
extended_stat_no          | 0/0
child_table_no            | 3/5
current_child_table_relid | test_4
```

Ensuite, les partitions sont analysée individuellement :

```
-[ RECORD 1 ]-------------+----------------------
pid                       | 23887
datname                   | postgres
relid                     | test_2
phase                     | acquiring sample rows
pct_sampled               | 6
extended_stat_no          | 0/0
child_table_no            | 0/0
current_child_table_relid | -

-[ RECORD 1 ]-------------+----------------------
pid                       | 23887
datname                   | postgres
relid                     | test_3
phase                     | acquiring sample rows
pct_sampled               | 28
extended_stat_no          | 0/0
child_table_no            | 0/0
current_child_table_relid | -

-[ RECORD 1 ]-------------+----------------------
pid                       | 23887
datname                   | postgres
relid                     | test_5
phase                     | acquiring sample rows
pct_sampled               | 42
extended_stat_no          | 0/0
child_table_no            | 0/0
current_child_table_relid | -
```

Et les statistiques calaculées :

```
-[ RECORD 1 ]-------------+----------------------
pid                       | 11836
datname                   | postgres
relid                     | test_3
phase                     | computing statistics
pct_sampled               | 100
extended_stat_no          | 0/0
child_table_no            | 0/0
current_child_table_relid | -
```

</div>
