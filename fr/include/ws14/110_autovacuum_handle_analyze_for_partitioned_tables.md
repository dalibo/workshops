<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2492/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=0827e8af70f4653ba17ed773f123a60eadd9f9c9

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/110

-->

<div class="slide-content">

* `ANALYZE` sur les tables partitionnées grâce à l'autovacuum
* Permet d'améliorer les choix de l'optimiseur

</div>

<div class="notes">

Avant la version 14, l'autovacuum ignorait les tables partitionnées. Ce comportement avait pour conséquence de ne générer aucune statistique pour ces objets et pouvait provoquer des mauvais choix de plan d'exécution.
Pour corriger ce problème, il fallait réaliser un `ANALYZE` manuel. Avec cette nouvelle version, ce n'est plus le cas et les statistiques des tables partitionnées sont analysées comme pour une table classique en 
fonction des paramètres `autovacuum_analyze_scale_factor` et `autovacuum_analyze_threshold`.

```sql
-- En version 13, on dispose d'une table partitionnée et de deux partitions
test=# \d parent
                     Table partitionnée « public.parent »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
Clé de partition : RANGE (id)
Index :
    "parent_id_idx" btree (id)
Partitions: enfant_1 FOR VALUES FROM (0) TO (5000000),
            enfant_2 FOR VALUES FROM (5000000) TO (11000000)

-- Auncune entrée dans la vue pg_stat_user_tables
-- Pour la table partitionnée parent
test=# select * from pg_stat_user_tables where relname = 'parent' \gx

-- Aucune statistique non plus
test=# select * from pg_stats where tablename = 'parent' \gx

-- On génère de l'activité
test=# insert into parent SELECT generate_series(0,10000000);

-- Toujours aucune statistique pour la table partitionnée
test=# select * from pg_stats where tablename = 'parent' \gx

-- Lancement d'un ANALYZE
test=# analyze parent;

-- Maintenant on dispose des statistiques
test=# select * from pg_stats where tablename = 'parent' \gx
schemaname             | public
tablename              | parent
attname                | id
inherited              | t
null_frac              | 0
avg_width              | 4
n_distinct             | -0.2883121
most_common_vals       | 
most_common_freqs      | 
histogram_bounds       | {103,103827,211375,307923,...,9900329,9999238}
correlation            | 0.83158755
most_common_elems      | 
most_common_elem_freqs | 
elem_count_histogram   | 


-- en version 14 maintenant avec toujours la même configuration
-- une table partitionnée et deux partitions
test=# \d parent
                     Table partitionnée « public.parent »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
Clé de partition : RANGE (id)
Index :
    "parent_id_idx" btree (id)
Partitions: enfant_1 FOR VALUES FROM (0) TO (5000000),
            enfant_2 FOR VALUES FROM (5000000) TO (11000000)

-- Dans cette version on dispose d'une entrée dans la vue pg_stat_user_tables
test=# select * from pg_stat_user_tables where relname = 'parent' \gx
-[ RECORD 1 ]-------+------------------------------
relid               | 16551
schemaname          | public
relname             | parent
seq_scan            | 0
seq_tup_read        | 0
idx_scan            | 0
idx_tup_fetch       | 0
n_tup_ins           | 0
n_tup_upd           | 0
n_tup_del           | 0
n_tup_hot_upd       | 0
n_live_tup          | 0
n_dead_tup          | 0
n_mod_since_analyze | 0
n_ins_since_vacuum  | 0
last_vacuum         | 
last_autovacuum     | 
last_analyze        | 
last_autoanalyze    | 
vacuum_count        | 0
autovacuum_count    | 0
analyze_count       | 0
autoanalyze_count   | 0

-- Pour l'instant pas de statistique
test=# select * from pg_stats where tablename = 'parent' \gx

-- On génère de l'activité
test=# insert into parent SELECT generate_series(0,10000000);

-- On peut voir dans la vue pg_stat_user_tables qu'un autoanalyze
-- a été réalisé
test=# select * from pg_stat_user_tables where relname = 'parent' \gx
-[ RECORD 1 ]-------+------------------------------
relid               | 16551
schemaname          | public
relname             | parent
seq_scan            | 0
seq_tup_read        | 0
idx_scan            | 0
idx_tup_fetch       | 0
n_tup_ins           | 0
n_tup_upd           | 0
n_tup_del           | 0
n_tup_hot_upd       | 0
n_live_tup          | 0
n_dead_tup          | 0
n_mod_since_analyze | 0
n_ins_since_vacuum  | 0
last_vacuum         | 
last_autovacuum     | 
last_analyze        | 
last_autoanalyze    | 2021-08-12 14:29:20.905265+02
vacuum_count        | 0
autovacuum_count    | 0
analyze_count       | 0
autoanalyze_count   | 1

-- On dispose également des statistiques sur la table partitionnée
test=# select * from pg_stats where tablename = 'parent' \gx
schemaname             | public
tablename              | parent
attname                | id
inherited              | t
null_frac              | 0
avg_width              | 4
n_distinct             | -0.31902468
most_common_vals       | 
most_common_freqs      | 
histogram_bounds       | {142,103627,191068,287967,...,9892316,9999647}
correlation            | 0.8334989
most_common_elems      | 
most_common_elem_freqs | 
elem_count_histogram   | 
```

Précision concernant le déclanchement de l'autovacuum sur des tables partitionnées, les opérations `SELECT`, `INSERT` et `DELETE` sur des partitions sont comptabilisées pour le paramètre `autovacuum_analyze_threshold`. 
Les opérations DDL comme `ATTACH`, `DETACH` et `DROP` ne le sont pas. Il est donc recommandé de lancer un `ANALYZE` manuel après ce type d'opération.

</div>