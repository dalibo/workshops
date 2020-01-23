## Monitoring

<div class="slide-content">

  * Échantillon des requêtes dans les logs
  * Vues de progression pour `CREATE INDEX`, `CLUSTER`, `VACUUM`
  * Listing : 
    *  des fichiers dans les répertoires `status` des archives des _wals_ 
    *  des fichiers temporaires
  * `pg_stat_replication` : timestamp du dernier message reçu du secondaire

</div>

<div class="notes">


</div>

-----

### Échantillon des requêtes dans les logs

<div class="slide-content">

  * `log_transaction_sample_rate`
</div>

<div class="notes">

Adrien Nayrat a soumis un correctif proposant l'échantillonnage des transactions dans les journaux d'activité.

`log_transaction_sample_rate`, dont la valeur doit être comprise entre 0 et 1.0, définit la fraction des transactions dont les opérations sont toutes tracées, en plus de celles tracées pour d'autres raisons. Il s'applique à chaque nouvelle transaction quelle que soit la durée de ses opérations. La valeur par défaut 0 désactive cette fonctionnalité alors que la valeur 1 enregistre tous les ordres pour toutes les transactions. 

</div>

----

###  Informations de progression

<div class="slide-content">

  * Nouvelles vues pour l'avancement des tâches de maintenance
    * `pg_stat_progress_cluster`
    * `pg_stat_progress_create_index`
  * En complément d'une déjà existante depuis la version 11
    * `pg_stat_progress_vacuum`

</div>

<div class="notes">

</div>

----

###  Progression des réécritures de table

<div class="slide-content">

  * Vue `pg_stat_progress_cluster`
    * Pour les opérations `CLUSTER` et `VACCUM FULL`

</div>


<div class="notes">

Lors de l'opération [`CLUSTER`](https://docs.postgresql.fr/12/sql-cluster.html) et `VACUUM FULL`, la vue `pg_stat_progress_cluster` indique la progression de l'opération qui dans certains cas, peut être très 
longue.

On lance le traitement dans une session :

```SQL
$ CLUSTER tab USING tab_i_j_idx;
CLUSTER
```

On observe la progression dans une autre session :

```sql
$ SELECT
  phase,
  heap_tuples_scanned,
  heap_tuples_written
  FROM
    pg_stat_progress_cluster;
$ \watch 1
```

```console
          jeu. 17 oct. 2019 18:20:05 CEST (every 1s)

        phase        | heap_tuples_scanned | heap_tuples_written 
---------------------+---------------------+---------------------
 index scanning heap |              890880 |              890880
(1 row)

           jeu. 17 oct. 2019 18:20:06 CEST (every 1s)

        phase        | heap_tuples_scanned | heap_tuples_written 
---------------------+---------------------+---------------------
 index scanning heap |             1640280 |             1640280

...

         jeu. 17 oct. 2019 18:20:23 CEST (every 1s)

      phase       | heap_tuples_scanned | heap_tuples_written 
------------------+---------------------+---------------------
 rebuilding index |            11000000 |            11000000
(1 row)

...

   jeu. 17 oct. 2019 18:20:47 CEST (every 1s)

 phase | heap_tuples_scanned | heap_tuples_written 
-------+---------------------+---------------------
(0 rows)
```

</div>

----

### Progression des maintenances d'index

<div class="slide-content">

  * Vue `pg_stat_progress_create_index`
    * Pour les opérations `CREATE INDEX` et `REINDEX`

</div>


<div class="notes">

Lors de la création d' index, la progression est consultable dans la vue
`pg_stat_progress_create_index` :

```sql
$ CREATE INDEX ON a_table (i, a, b);
```

Dans une autre session, avant de lancer la création de l'index :

```sql
SELECT
  datname,
  relid::regclass,
  command,
  phase,
  tuples_done
FROM
  pg_stat_progress_create_index;


          ven. 26 juil. 2019 17:41:18 CEST (every 1s)

 datname | relid | index_relid | command | phase | tuples_done 
---------+-------+-------------+---------+-------+-------------
(0 rows)
$ \watch 1

                              ven. 26 juil. 2019 17:41:19 CEST (every 1s)


 datname  |  relid  |   command    |                 phase                  | tuples_done 
----------+---------+--------------+----------------------------------------+-------------
 postgres | a_table | CREATE INDEX | building index: loading tuples in tree |      718515
(1 row)

                              ven. 26 juil. 2019 17:41:20 CEST (every 1s)

 datname  |  relid  |   command    |                 phase                  | tuples_done 
----------+---------+--------------+----------------------------------------+-------------
 postgres | a_table | CREATE INDEX | building index: loading tuples in tree |     1000000
(1 row)


```
</div>

-----

### Archive status 

<div class="slide-content">

  * `pg_ls_archive_statusdir()`
</div>

<div class="notes">

Liste le nom, taille et l'heure de la dernière modification des fichiers dans  le dossier `status` de l'archive des _WAL_. Il faut être membre du group `pg_monitor` ou avoir explicitement le droit (`pg_read_server_files`).

À savoir que ce répertoire est peuplé lorsqu'un journal de transactions (wal)
est archivé par l'`archive_command`.


```sql
$ SELECT pg_switch_wal ();
$ SELECT pg_switch_wal ();
$ SELECT pg_switch_wal ();
$ SELECT * FROM pg_ls_archive_statusdir ();


             name              | size |      modification      
-------------------------------+------+------------------------
 0000000100000001000000CB.done |    0 | 2019-09-03 11:51:39+02
 0000000100000001000000CD.done |    0 | 2019-09-09 14:14:48+02
 0000000100000001000000CC.done |    0 | 2019-09-09 14:14:48+02
(3 rows)


```
</div>

-----

### Fichiers temporaires 

<div class="slide-content">

  * `pg_ls_tmpdir()`
</div>

<div class="notes">

La supervision des fichiers temporaires est désormais possible dans une session :

```sql
$ select * from pg_ls_tmpdir();
      name       |    size    |      modification      
-----------------+------------+------------------------
 pgsql_tmp8686.4 | 1073741824 | 2019-09-09 14:18:29+02
 pgsql_tmp8686.3 | 1073741824 | 2019-09-09 14:18:19+02
 pgsql_tmp8686.2 | 1073741824 | 2019-09-09 14:18:13+02
 pgsql_tmp8686.5 |  456941568 | 2019-09-09 14:18:31+02
 pgsql_tmp8686.1 |   26000000 | 2019-09-09 14:17:56+02
 pgsql_tmp8686.0 | 1073741824 | 2019-09-09 14:18:05+02
(6 rows)


```
</div>

-----

###  Ajout dans la vue `pg_stat_replication` 

<div class="slide-content">

  * timestamp du dernier message reçu du standby

</div>

<div class="notes">

Dans le cadre de la supervision de la réplication, il est possible de déterminer l'heure à laquelle un secondaire en standby a communiqué pour la dernière fois, avec le primaire.

```SQL
$ SELECT * FROM pg_stat_replication;

```

</div>

----
