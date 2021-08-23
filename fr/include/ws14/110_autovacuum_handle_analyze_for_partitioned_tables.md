<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2492/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=0827e8af70f4653ba17ed773f123a60eadd9f9c9

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/110

-->

<div class="slide-content">

* Les tables partitionnées ne sont plus exclues lors de la phase `ANALYZE` de l'autovacuum
* Permet d'améliorer les choix de l'optimiseur

</div>

<div class="notes">

Avant la version 14, l'autovacuum ignorait les tables partitionnées. Ce comportement
avait pour conséquence de ne générer aucune statistique pour ces objets et 
pouvait provoquer des mauvais choix de plan d'exécution.

Pour corriger ce problème, il fallait réaliser un `ANALYZE` manuel. Avec cette 
nouvelle version, ce n'est plus le cas et les statistiques des tables partitionnées
sont collectées comme pour une table classique en fonction des paramètres 
`autovacuum_analyze_scale_factor` et `autovacuum_analyze_threshold`.

Dans notre exemple, nous observons le comportement en version 13 puis en version
14 avec la table partitionnée suivante.

```sql
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

-- Aucune entrée dans la vue pg_stat_user_tables
-- Pour la table partitionnée parent
test=# SELECT * FROM pg_stat_user_tables WHERE relname = 'parent' \gx

-- Aucune statistique non plus
test=# SELECT * FROM pg_stats WHERE tablename = 'parent' \gx

-- On génère de l'activité
test=# INSERT INTO parent SELECT generate_series(0,10000000);

-- Toujours aucune statistique pour la table partitionnée
test=# SELECT * FROM pg_stats WHERE tablename = 'parent' \gx

-- Lancement d'un ANALYZE
test=# ANALYZE parent;

-- Maintenant on dispose des statistiques
test=# select * from pg_stats where tablename = 'parent' \gx
-[ RECORD 1 ]----------+------------------------------
schemaname             | public
tablename              | parent
attname                | id
inherited              | t
null_frac              | 0
avg_width              | 4
...
```

À présent, avec une instance en version 14 et la même configuration, à savoir :
une table partitionnée et deux partitions.

```sql
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
...
last_vacuum         | 
last_autovacuum     | 
last_analyze        | 
last_autoanalyze    | 
vacuum_count        | 0
autovacuum_count    | 0
analyze_count       | 0
autoanalyze_count   | 0

-- Pour l'instant pas de statistique
test=# SELECT * FROM pg_stats WHERE tablename = 'parent' \gx

-- On génère de l'activité
test=# INSERT INTO into parent SELECT generate_series(0,10000000);

-- On peut voir dans la vue pg_stat_user_tables qu'un autoanalyze
-- a été réalisé
test=# SELECT * FROM pg_stat_user_tables WHERE relname = 'parent' \gx
-[ RECORD 1 ]-------+------------------------------
relid               | 16551
schemaname          | public
relname             | parent
seq_scan            | 0
...
last_autoanalyze    | 2021-08-12 14:29:20.905265+02
...
autoanalyze_count   | 1

-- On dispose également des statistiques sur la table partitionnée
test=# SELECT * FROM pg_stats WHERE tablename = 'parent' \gx
-[ RECORD 1 ]----------+------------------------------
schemaname             | public
tablename              | parent
attname                | id
inherited              | t
null_frac              | 0
avg_width              | 4
...
```

Précision concernant le déclanchement de l'autovacuum sur des tables partitionnées :
les opérations `SELECT`, `INSERT` et `DELETE` sur des partitions sont comptabilisées
pour le paramètre `autovacuum_analyze_threshold`.

Les opérations DDL comme `ATTACH`, `DETACH` et `DROP` ne le sont pas. Il est donc
recommandé de lancer un `ANALYZE` manuel après ce type d'opération.

</div>