<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/E1ncJtG-000gDK-1G@gemulon.postgresql.org

Discussion

* https://www.postgresql.org/message-id/flat/20180629.173418.190173462.horiguchi.kyotaro@lab.ntt.co.jp

-->

<div class="slide-content">

 * Statistiques d'activité stockées en mémoire
 * Données perdues en cas de crash.
 * Disparition du processus `stats collector`
 * Disparition du paramètre `stats_temp_directory`
 * Nouveau paramètre `stats_fetch_consistency`

</div>

<div class="notes">

Dans les versions précédentes, le processus `stats collector` recevait des
mises à jour des statistiques d'activité collectées par les autres processus
via UDP. Il partageait ces statistiques en les écrivant à intervalle régulier
dans des fichiers temporaires situés dans le répertoire pointé par
`stats_temp_directory`. Ces fichiers pouvaient atteindre quelques dizaines de
mégaoctets et être écrits jusqu'à deux fois par seconde, ce goulet
d'étranglement a longtemps été un frein à l'ajout de statistiques pourtant
utiles.

Désormais, les statistiques sont stockées en mémoire partagée, soit directement
si le nombre de ces statistiques est fixe (`pg_stat_database`), soit dans une
table de hachage dans le cas où leur nombre est variable
(`pg_stat_users_tables`).

Une zone dédiée est désormais visible dans la mémoire partagée :

```sql
SELECT *
  FROM pg_shmem_allocations
 WHERE name = 'Shared Memory Stats';
```
```sh
        name         |    off    |  size  | allocated_size
---------------------+-----------+--------+----------------
 Shared Memory Stats | 147290112 | 263312 |         263424
(1 row)
```

Ce changement d'architecture se traduit par la disparition du processus 
`stats collector` et d(u paramètre `stats_temp_directory`. Le répertoire `pg_stat_tmp`
existe toujours dans le répertoire de données de l'instance car certaines
extensions dont `pg_stat_statements` l'utilisent toujours.

<!-- Le commit sur pg_stat_tmp : 
  https://www.postgresql.org/message-id/E1ncJtG-000gDN-1l@gemulon.postgresql.org
-->

Les statistiques sont chargées depuis des fichiers situés dans le répertoire
`pg_stat` lors du démarrage. Elles sont écrites lors de l'arrêt de l'instance
par le processus `checkpointer`. Il y a deux exceptions à cela : en cas de crash
les statistiques sont remises à zéro et en cas d'arrêt avec l'option
`immediate` les données ne sont pas sauvées.

Les données sont la plupart du temps accumulées localement par les processus
avant d'être écrites suite à un commit ou lors d'un timeout causé par
l'inactivité de la session.

Un nouveau paramètre a été introduit : `stats_fetch_consistency`. Il permet de
déterminer le comportement lorsque les statistiques sont accédées dans une
transaction. Il peut être changé dans la session et a trois valeurs possibles :

* `none` : chaque accès récupère les données depuis la mémoire partagée. Les
  valeurs ramenées sont donc différentes à chaque fois. C'est le mode le moins
  coûteux. Il est adapté pour les systèmes de supervision qui accèdent aux
  données une seule fois ;
* `cache` : le premier accès à une statistique la met en cache pour le restant
  de la transaction à moins que `pg_stat_clear_snapshot()` ne soit appelée.
  C'est utile pour des requêtes qui font des auto-jointures. C'est la valeur
  par défaut ;
* `snapshot` : le premier accès aux statistiques met en cache toutes les
  statistiques accessibles pour la base de données en cours. Elles seront
  conservées jusqu'à la fin de la transaction à moins que
  `pg_stat_clear_snapshot()` ne soit appelée. C'est le mode le plus coûteux.

On observe quatre contextes mémoires relatifs aux statistiques d'activité pour
ces trois modes de fonctionnement :

```sql
SELECT name, parent, level, total_bytes, free_bytes, used_bytes
  FROM pg_backend_memory_contexts
 WHERE name LIKE ANY(ARRAY['PgStat%','CacheMemoryContext']);
```
```sh
          name          |       parent       | level | total_bytes | free_bytes | used_bytes
------------------------+--------------------+-------+-------------+------------+------------
 CacheMemoryContext     | TopMemoryContext   |     1 |     1048576 |     501176 |     547400
 PgStat Shared Ref Hash | CacheMemoryContext |     2 |        7224 |        680 |       6544
 PgStat Shared Ref      | CacheMemoryContext |     2 |        8192 |       3568 |       4624
 PgStat Pending         | CacheMemoryContext |     2 |        8192 |       6944 |       1248
(4 rows)
```

On peut noter la présence de la zone mémoire `PgStat Pending` qui est celle
utilisée pour les statistiques en cours de mise à jour dans la session.

Avec les modes `cache` et `snapshot`, on voit l'apparition d'une autre zone.
Sa dimension est importante dans le cas du mode `snapshot`.

```sh
  mode   |         name           |       parent       | level | total_bytes | free_bytes | used_bytes
---------+------------------------+--------------------+-------+-------------+------------+------------
snapshot | PgStat Snapshot        | TopMemoryContext   |     1 |       57400 |       4488 |      52912
cache    | PgStat Snapshot        | TopMemoryContext   |     1 |       25656 |        680 |      24976
```

Les vues `pg_backend_memory_contexts`, `pg_shmem_allocations` sont normalement
accessibles uniquement aux utilisateurs dotés de l'attribut super utilisateur.
En version 15, les membres du groupe `pg_read_all_stats` peuvent aussi y
accéder.

</div>


<!--

Exemple complet (utilise les fonctions au lieu des vues pour visualiser la mémoire, mais cela ne change rien aux résultats):

[local]:5445 postgres@postgres=# BEGIN;
BEGIN
[local]:5445 postgres@postgres=#* SET stats_fetch_consistency TO 'none';
SET
[local]:5445 postgres@postgres=#* SELECT * FROM pg_get_backend_memory_contexts() WHERE name ILIKE ANY(ARRAY['%pgstat%','CacheMemoryContext']);
          name          | ident |       parent       | level | total_bytes | total_nblocks | free_bytes | free_chunks | used_bytes
------------------------+-------+--------------------+-------+-------------+---------------+------------+-------------+------------
 CacheMemoryContext     | ¤     | TopMemoryContext   |     1 |      524288 |             7 |      83808 |           0 |     440480
 PgStat Shared Ref Hash | ¤     | CacheMemoryContext |     2 |        7224 |             2 |        680 |           0 |       6544
 PgStat Shared Ref      | ¤     | CacheMemoryContext |     2 |        4096 |             3 |        872 |           2 |       3224
 PgStat Pending         | ¤     | CacheMemoryContext |     2 |        4096 |             3 |       1160 |           5 |       2936
(4 rows)

[local]:5445 postgres@postgres=#* SELECT * FROM pg_stat_all_tables LIMIT 1;
 relid | schemaname |    relname     | seq_scan | seq_tup_read | idx_scan | idx_tup_fetch | n_tup_ins | n_tup_upd | n_tup_del | n_tup_hot_upd | n_live_tup | n_dead_tup | n_mod_since_analyze
| n_ins_since_vacuum | last_vacuum | last_autovacuum | last_analyze | last_autoanalyze | vacuum_count | autovacuum_count | analyze_count | autoanalyze_count
-------+------------+----------------+----------+--------------+----------+---------------+-----------+-----------+-----------+---------------+------------+------------+---------------------
+--------------------+-------------+-----------------+--------------+------------------+--------------+------------------+---------------+-------------------
   826 | pg_catalog | pg_default_acl |        0 |            0 |        0 |             0 |         0 |         0 |         0 |             0 |          0 |          0 |                   0
|                  0 | ¤           | ¤               | ¤            | ¤                |            0 |                0 |             0 |                 0
(1 row)

[local]:5445 postgres@postgres=#* SELECT * FROM pg_get_backend_memory_contexts() WHERE name ILIKE ANY(ARRAY['%pgstat%','CacheMemoryContext']);
          name          | ident |       parent       | level | total_bytes | total_nblocks | free_bytes | free_chunks | used_bytes
------------------------+-------+--------------------+-------+-------------+---------------+------------+-------------+------------
 CacheMemoryContext     | ¤     | TopMemoryContext   |     1 |     1048576 |             8 |     504696 |           2 |     543880
 PgStat Shared Ref Hash | ¤     | CacheMemoryContext |     2 |        7224 |             2 |        680 |           0 |       6544
 PgStat Shared Ref      | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       3568 |           3 |       4624
 PgStat Pending         | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       1616 |           6 |       6576
(4 rows)

[local]:5445 postgres@postgres=#* ROLLBACK;
ROLLBACK
[local]:5445 postgres@postgres=# BEGIN;
BEGIN
[local]:5445 postgres@postgres=#* SET stats_fetch_consistency TO 'cache';
SET
[local]:5445 postgres@postgres=#* SELECT * FROM pg_get_backend_memory_contexts() WHERE name ILIKE ANY(ARRAY['%pgstat%','CacheMemoryContext']);
          name          | ident |       parent       | level | total_bytes | total_nblocks | free_bytes | free_chunks | used_bytes
------------------------+-------+--------------------+-------+-------------+---------------+------------+-------------+------------
 CacheMemoryContext     | ¤     | TopMemoryContext   |     1 |     1048576 |             8 |     504696 |           2 |     543880
 PgStat Shared Ref Hash | ¤     | CacheMemoryContext |     2 |        7224 |             2 |        680 |           0 |       6544
 PgStat Shared Ref      | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       3568 |           3 |       4624
 PgStat Pending         | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       7808 |          49 |        384
(4 rows)

[local]:5445 postgres@postgres=#* SELECT * FROM pg_stat_all_tables LIMIT 1;
 relid | schemaname |    relname     | seq_scan | seq_tup_read | idx_scan | idx_tup_fetch | n_tup_ins | n_tup_upd | n_tup_del | n_tup_hot_upd | n_live_tup | n_dead_tup | n_mod_since_analyze
| n_ins_since_vacuum | last_vacuum | last_autovacuum | last_analyze | last_autoanalyze | vacuum_count | autovacuum_count | analyze_count | autoanalyze_count
-------+------------+----------------+----------+--------------+----------+---------------+-----------+-----------+-----------+---------------+------------+------------+---------------------
+--------------------+-------------+-----------------+--------------+------------------+--------------+------------------+---------------+-------------------
   826 | pg_catalog | pg_default_acl |        0 |            0 |        0 |             0 |         0 |         0 |         0 |             0 |          0 |          0 |                   0
|                  0 | ¤           | ¤               | ¤            | ¤                |            0 |                0 |             0 |                 0
(1 row)

[local]:5445 postgres@postgres=#* SELECT * FROM pg_get_backend_memory_contexts() WHERE name ILIKE ANY(ARRAY['%pgstat%','CacheMemoryContext']);
          name          | ident |       parent       | level | total_bytes | total_nblocks | free_bytes | free_chunks | used_bytes
------------------------+-------+--------------------+-------+-------------+---------------+------------+-------------+------------
 PgStat Snapshot        | ¤     | TopMemoryContext   |     1 |       25656 |             2 |        680 |           0 |      24976
 CacheMemoryContext     | ¤     | TopMemoryContext   |     1 |     1048576 |             8 |     504696 |           2 |     543880
 PgStat Shared Ref Hash | ¤     | CacheMemoryContext |     2 |        7224 |             2 |        680 |           0 |       6544
 PgStat Shared Ref      | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       3568 |           3 |       4624
 PgStat Pending         | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       6656 |          41 |       1536
(5 rows)

[local]:5445 postgres@postgres=#* SELECT pg_stat_clear_snapshot();
 pg_stat_clear_snapshot
------------------------

(1 row)

[local]:5445 postgres@postgres=#* SELECT * FROM pg_get_backend_memory_contexts() WHERE name ILIKE ANY(ARRAY['%pgstat%','CacheMemoryContext']);
          name          | ident |       parent       | level | total_bytes | total_nblocks | free_bytes | free_chunks | used_bytes
------------------------+-------+--------------------+-------+-------------+---------------+------------+-------------+------------
 CacheMemoryContext     | ¤     | TopMemoryContext   |     1 |     1048576 |             8 |     502888 |           0 |     545688
 PgStat Shared Ref Hash | ¤     | CacheMemoryContext |     2 |        7224 |             2 |        680 |           0 |       6544
 PgStat Shared Ref      | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       3568 |           3 |       4624
 PgStat Pending         | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       5936 |          36 |       2256
(4 rows)

[local]:5445 postgres@postgres=#* ROLLBACK;
ROLLBACK
[local]:5445 postgres@postgres=# BEGIN;
BEGIN
[local]:5445 postgres@postgres=#* SET stats_fetch_consistency TO 'snapshot';
SET
[local]:5445 postgres@postgres=#* SELECT * FROM pg_get_backend_memory_contexts() WHERE name ILIKE ANY(ARRAY['%pgstat%','CacheMemoryContext']);
          name          | ident |       parent       | level | total_bytes | total_nblocks | free_bytes | free_chunks | used_bytes
------------------------+-------+--------------------+-------+-------------+---------------+------------+-------------+------------
 CacheMemoryContext     | ¤     | TopMemoryContext   |     1 |     1048576 |             8 |     502888 |           0 |     545688
 PgStat Shared Ref Hash | ¤     | CacheMemoryContext |     2 |        7224 |             2 |        680 |           0 |       6544
 PgStat Shared Ref      | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       3568 |           3 |       4624
 PgStat Pending         | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       7808 |          49 |        384
(4 rows)

[local]:5445 postgres@postgres=#* SELECT * FROM pg_stat_all_tables LIMIT 1;
 relid | schemaname |    relname     | seq_scan | seq_tup_read | idx_scan | idx_tup_fetch | n_tup_ins | n_tup_upd | n_tup_del | n_tup_hot_upd | n_live_tup | n_dead_tup | n_mod_since_analyze
| n_ins_since_vacuum | last_vacuum | last_autovacuum | last_analyze | last_autoanalyze | vacuum_count | autovacuum_count | analyze_count | autoanalyze_count
-------+------------+----------------+----------+--------------+----------+---------------+-----------+-----------+-----------+---------------+------------+------------+---------------------
+--------------------+-------------+-----------------+--------------+------------------+--------------+------------------+---------------+-------------------
   826 | pg_catalog | pg_default_acl |        0 |            0 |        0 |             0 |         0 |         0 |         0 |             0 |          0 |          0 |                   0
|                  0 | ¤           | ¤               | ¤            | ¤                |            0 |                0 |             0 |                 0
(1 row)

[local]:5445 postgres@postgres=#* SELECT * FROM pg_get_backend_memory_contexts() WHERE name ILIKE ANY(ARRAY['%pgstat%','CacheMemoryContext']);
          name          | ident |       parent       | level | total_bytes | total_nblocks | free_bytes | free_chunks | used_bytes
------------------------+-------+--------------------+-------+-------------+---------------+------------+-------------+------------
 PgStat Snapshot        | ¤     | TopMemoryContext   |     1 |       57400 |             8 |       4488 |           9 |      52912
 CacheMemoryContext     | ¤     | TopMemoryContext   |     1 |     1048576 |             8 |     502888 |           0 |     545688
 PgStat Shared Ref Hash | ¤     | CacheMemoryContext |     2 |        7224 |             2 |        680 |           0 |       6544
 PgStat Shared Ref      | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       3568 |           3 |       4624
 PgStat Pending         | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       6656 |          41 |       1536
(5 rows)

[local]:5445 postgres@postgres=#* SELECT pg_stat_clear_snapshot();
 pg_stat_clear_snapshot
------------------------

(1 row)

[local]:5445 postgres@postgres=#* SELECT * FROM pg_get_backend_memory_contexts() WHERE name ILIKE ANY(ARRAY['%pgstat%','CacheMemoryContext']);
          name          | ident |       parent       | level | total_bytes | total_nblocks | free_bytes | free_chunks | used_bytes
------------------------+-------+--------------------+-------+-------------+---------------+------------+-------------+------------
 CacheMemoryContext     | ¤     | TopMemoryContext   |     1 |     1048576 |             8 |     502888 |           0 |     545688
 PgStat Shared Ref Hash | ¤     | CacheMemoryContext |     2 |        7224 |             2 |        680 |           0 |       6544
 PgStat Shared Ref      | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       3568 |           3 |       4624
 PgStat Pending         | ¤     | CacheMemoryContext |     2 |        8192 |             4 |       6656 |          41 |       1536
(4 rows)

[local]:5445 postgres@postgres=#* ROLLBACK;
ROLLBACK
-->
