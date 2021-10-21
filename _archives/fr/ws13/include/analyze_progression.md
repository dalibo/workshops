<!--
Les commits sur ce sujet sont :

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=a166d408eb0b35023c169e765f4664c3b114b52e

-->

<div class="slide-content">

* Nouvelle vue `pg_stat_progress_analyze`

</div>

<div class="notes">

La vue `pg_stat_progress_analyze` vient compléter la liste des vues qui
permettent de suivre l'activité des tâches de maintenance.

Cette vue contient une ligne pour chaque backend qui exécute la commande
`ANALYZE`. Elle contient les informations :

* `pid` : _id_ du processus qui exécute l'analyze ;
* `datid` : _oid_ de la base de donnée à laquelle est connecté le backend ;
* `datname` : nom de la base de donnée à laquelle est connecté le backend ;
* `relid` : _oid_ de la table analysée ;
* `phase` : phase du traitement parmi les valeurs :
  * `initializing` : préparation du scan de la table ;
  * `acquiring sample rows` : scan de la table pour collecter un échantillon de
    lignes ;
  * `acquiring inherited sample rows` : scan des tables filles pour collecter
    un échantillon de lignes ;
  * `computing statistics` : calcul des statistiques ;
  * `computing extended statistics` : calcul des statistiques étendues ;
  * `finalizing analyze` : mise à jour des statistiques dans `pg_class`.
* `sample_blks_total` : nombre total de blocs qui vont être échantillonnés ;
* `sample_blks_scanned` : nombre de blocs scannés ;
* `ext_stats_total` : nombre de statistiques étendues ;
* `ext_stats_computed`  : nombre de statistiques étendues calculées ;
* `child_tables_total` : nombre de tables filles à traiter pendant la phase
  `acquiring inherited sample rows` ;
* `child_tables_done` : nombre de tables filles traitées pendant la phase
  `acquiring inherited sample rows` ;
* `current_child_table_relid` : _oid_ de la table fille qui est en train d'être
  scannée pendant la phase `acquiring inherited sample rows`.

</div>
