<!--
Les commits sur ce sujet sont :
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a9c70b46dbe152e094f137f7e6ba9cd3a638ee25

Discussion :

* Présentation Melanie Plageman PGSESSION 2023
  https://pgsessions.com/assets/archives/2023/06_pg_stat_io_FINAL.pdf

-->

<div class="slide-content">

  * Nouvelle vue de statistiques I/O
  * Compteurs pour chaque combinaison de
    + type de backend ;
    + objet I/O cible ;
    + et contexte I/O.

</div>

<div class="notes">

La nouvelle vue `pg_stat_io` permet d'obtenir des informations sur les
opérations faites sur disques. Les différents compteurs (_reads_,
_writes_, _extends_, _hits_, etc) sont présents pour chaque combinaison de
type de backend, objets I/O cible, et  contexte I/O. Les définitions des
colonnes et des compteurs peuvent être trouvées
sur cette [page de la documentation officielle](https://www.postgresql.org/docs/devel/monitoring-stats.html#MONITORING-PG-STAT-IO-VIEW). 

Par exemple, la requête suivante permet d'obtenir le nombre de lectures faites
par les processsus de type `client backend` (processus créé à la création d'une
connexion sur l'instance), concernant des relations du type table ou index
s'exécutant dans un contexte normal, c'est-à-dire des lectures et écritures
utilisant les `shared_buffers`.  

```sql
postgres=# SELECT reads
FROM pg_stat_io
WHERE backend_type = 'client backend' AND
      object = 'relation' AND
      context = 'normal';
-[ RECORD 1 ]
reads | 454
```

454 demandes de lecture ont été envoyées au noyau depuis la mise à zéro des statistiques.
Cela signifie que PostgreSQL a effectué 454 demandes de lecture de blocs pour servir les
données demandées par des `client backend`.

Si maintenant un `SELECT` est exécuté, le compteur peut augmenter si des données
sont demandées au noyau.

```sql
postgres=# select * from pgbench_accounts ;
[...]
postgres=# SELECT reads
FROM pg_stat_io
WHERE backend_type = 'client backend' AND
      object = 'relation' AND
      context = 'normal';
-[ RECORD 1 ]
reads | 454
```

Le compteur n'a pas évolué. Les données étaient bien dans le cache de
PostgreSQL, aucune demande n'a été envoyé au noyau. Essayons avec un autre
table :

```sql
postgres=# select * from pgbench_accounts ;
[...]
postgres=# SELECT reads
FROM pg_stat_io
WHERE backend_type = 'client backend' AND
      object = 'relation' AND
      context = 'normal';
-[ RECORD 1 ]
reads | 456
[...]
```

Le compteur a évolué. Deux demandes de lecture ont été faites au noyau pour ramener des données.

Une analyse de la vue `pg_stat_io` permettra d'extraire des explications sur le 
fonctionnement et la santé de l'instance. Par exemple :

* Un compteur `reads` élevé laisse penser que le paramètre `shared_buffers` est
trop petit ;
* Un compteur `writes` plus élevé pour les `client backend` que pour le
  `background writer` laisse penser que les écritures en arrière plan ne sont
  pas correctement configurées.

</div>
