<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=17e03282241c6ac58a714eb0c3b6a8018cf6167a

Discussion :

* https://postgr.es/m/CAHGQGwFx_=DO-Gu-MfPW3VQ4qC7TfVdH2zHmvZfrGv6fQ3D-Tw@mail.gmail.com
* https://postgr.es/m/CAEepm=0e59Y_6Q_YXYCTHZkqOc6H2pJ54C_Xe=VFu50Aqqp_sA@mail.gmail.com
* https://postgr.es/m/DB6PR0301MB21352F6210E3B11934B0DCC790B00@DB6PR0301MB2135.eurprd03.prod.outlook.com

-->

<div class="slide-content">

* `pg_stat_statements` peut désormais collecter pour chaque requête le nombre
  de phases d'optimisation et le temps qui y est alloué ;
* `pg_stat_statements.track_planning` permet d'activer cette collecte. Sa
  valeur par défaut est `off`.

</div>

<div class="notes">

La collecte de statistiques sur le nombre de phases d'optimisation et leur
durée peut être effectuée dans la vue `pg_stat_statements` grâce l'option
`pg_stat_statements.track_planning`. Activer ce paramètre pourrait provoquer
une perte visible de performance, spécialement quand peu de requêtes du même
genre sont exécutées sur de nombreuses connexions concurrentes. La valeur par
défaut est `off`. Seuls les superutilisateurs peuvent modifier cette
configuration au sein d'une session.

Les colonnes suivantes sont alimentées lorsque ce paramètre est activé

* `plans` : Nombre d'optimisations de la requête.
* `total_plan_time` : Durée totale passée à optimiser la requête, en
  millisecondes.
* `min_plan_time` : Durée minimale passée à optimiser la requête, en
  millisecondes.
* `max_plan_time` : Durée maximale passée à optimiser la requête, en
  millisecondes.
* `mean_plan_time` : Durée moyenne passée à optimiser la requête, en
  millisecondes.
* `stddev_plan_time` : Déviation standard de la durée passée à optimiser la
  requête, en millisecondes.

Ces colonnes restent à zéro si le paramètre est désactivé.

Les statistiques sur le nombre de planifications et d'exécutions peuvent être
différentes car enregistrées séparément. Si une requête échoue pendant son
exécution, seules ses statistiques de planification sont mises à jour.

Exemple :

```
[local]:5433 postgres@postgres=# SELECT substr(query, 1, 40)||'...' AS query,
[local]:5433 postgres@postgres-#        plans,
[local]:5433 postgres@postgres-#        trunc(total_plan_time),
[local]:5433 postgres@postgres-#        trunc(min_plan_time),
[local]:5433 postgres@postgres-#        trunc(max_plan_time),
[local]:5433 postgres@postgres-#        trunc(mean_plan_time),
[local]:5433 postgres@postgres-#        trunc(stddev_plan_time)
[local]:5433 postgres@postgres-# FROM pg_stat_statements
[local]:5433 postgres@postgres-# ORDER BY plans desc
[local]:5433 postgres@postgres-# LIMIT 5;

               query               | plans | trunc | trunc | trunc | trunc | trunc
-----------------------------------+-------+-------+-------+-------+-------+-------
 UPDATE pgbench_accounts SET ab... | 51797 |   957 |     0 |     0 |     0 |     0
 UPDATE pgbench_tellers SET tba... | 51797 |   884 |     0 |     0 |     0 |     0
 INSERT INTO pgbench_history (t... | 51797 |   374 |     0 |     0 |     0 |     0
 SELECT abalance FROM pgbench_a... | 51797 |   851 |     0 |     0 |     0 |     0
 UPDATE pgbench_branches SET bb... | 51797 |   861 |     0 |     0 |     0 |     0
(5 rows)
```

</div>
