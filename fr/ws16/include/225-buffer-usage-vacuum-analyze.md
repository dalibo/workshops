<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=1cbbee03385763b066ae3961fc61f2cd01a0d0d7

Discussion :

* https://postgr.es/m/20230111182720.ejifsclfwymw2reb@awork3.anarazel.de

-->

<div class="slide-content">

  * Nouvelle option `BUFFER_USAGE_LIMIT`
    + `VACUUM`
    + `ANALYZE`
  * Nouveau paramètre de configuration
    + `vacuum_buffer_usage_limit`
</div>

<div class="notes">

Une nouvelle option est désormais disponible pour contrôler la stratégie d'accès
aux `buffers` de la mémoire partagée par les commandes `VACUUM` et `ANALYZE`.
Cette option est nommée `BUFFER_USAGE_LIMIT`. Elle permet de limiter, ou non, la
quantité de `buffers` accédés par ces commandes.

Une grande valeur permettra, par exemple, une exécution plus rapide de `VACUUM`,
mais pourra avoir un impact négatif sur les autres requêtes qui verront la
mémoire partagée disponible se réduire. La plus petite valeur configurable est
de 128 ko et la plus grande est de 16 Go. 

En plus de cette option, le nouveau paramètre de configuration
`vacuum_buffer_usage_limit` voit le jour. Il indique si une stratégie d'accès à
la mémoire est utilisée ou non. Si ce paramètre est initialisé à 0, cela
désactive la stratégie d'accès à la mémoire partagée. Il n'y a alors aucune
limite en terme d'accès aux `buffers`. Autrement, ce paramètre indique le nombre
maximal de `buffers` accessibles par les commandes `VACUUM`, `ANALYZE` et
le processus d'autovacuum. La valeur par défaut est de 256 ko.

La valeur passée en argument est par défaut comprise en kilo-octets si aucune
unité n'est précisée. L'utilisation de cette option se fait de la manière
suivante :

```sql
ANALYZE (BUFFER_USAGE_LIMIT 1024);
```

Pour essayer de montrer l'incidence de cette configuration sur le comportement
d'un `VACUUM`, voici un script qui effectue une opération de `VACUUM` avec quatre
valeurs différentes pour l'option `BUFFER_USAGE_LIMIT` :

 * 0 : qui permet de désactiver la stratégie d'accès à la mémoire partagée ;
 * 256 : qui est la valeur par défaut ; 
 * 1024 ;
 * et 4096.

```bash
#!/bin/bash

#echo "\timing" >> .psqlrc # décommenter si le \timing n'est pas présent dans votre fichier .psqlrc

export PGUSER=postgres
psql -c "alter system set track_wal_io_timing to on";

for i in 0 256 1024 4096
do  
        pgbench --quiet -i -s 300 -d postgres
        psql --quiet -c "create index on pgbench_accounts (abalance);"
        psql --quiet -c "update pgbench_accounts set bid = 0 where aid <= 10000000;"
        systemctl stop postgresql-16
        systemctl start postgresql-16
        psql --quiet -c "select pg_stat_reset_shared('wal');"
        echo "### Test BUFFER_USAGE_LIMIT $i ###"
        psql -c "VACUUM (BUFFER_USAGE_LIMIT $i);"
        psql -c "select wal_sync, wal_sync_time from pg_stat_wal;"
done
```

Les résultats suivants sont obtenus :

| BUFFER_USAGE_LIMIT (ko) | VACUUM (ms) | wal_sync | wal_sync_time (ms) |
|-------------------------|-------------|----------|--------------------|
| 0                       | 7612        | 71       | 1578               |
| 256                     | 12756       | 12004    | 6763               |
| 1024                    | 10137       | 3031     | 4371               |
| 4096                    | 8280        | 789      | 2855               |

Quelles conclusions en tirer ?

Par défaut, `BUFFER_USAGE_LIMIT` limite l'accès à la mémoire partagée en
autorisant l'accès à 256 ko de mémoire à l'opération exécutée (voir [la documentation
officielle](https://www.postgresql.org/docs/current/glossary.html#GLOSSARY-BUFFER-ACCESS-STRATEGY)
pour connaitre la liste des opérations concernées). Celle-ci ne pourra utiliser
que cette quantité de `buffers` pour ses opérations. Si de la mémoire
supplémentaire est nécessaire, elle devra recycler certains `buffers`. Ce
recyclage entraine une écriture de WAL sur disque, augmentant dès lors le temps 
d'exécution.

L'effet de la taille du `BUFFER_USAGE_LIMIT` se voit très clairement dans le
tableau ci-dessous : plus la mémoire est grande, moins d'écritures de fichiers
de transactions sont nécessaires et plus le temps d'exécution est rapide.

Lorsque `BUFFER_USAGE_LIMIT` est à 0, il n'y a pas de limitation quant au nombre
de `buffers` que peut utiliser l'opération exécutée. Il y a alors très peu de
recyclage nécessaire. Nous avons donc de meilleurs temps d'exécution et moins
d'écritures sur disque. Pour autant, il ne faut pas oublier qu'avec cette
configuration là, les autres requêtes pourront utiliser moins de mémoire et
verrons donc leurs performances être dégradées.

Il est imaginable de positionner ce paramètre à 0 dans le cas d'une plage de
maintenance où il serait possible d'utiliser le maximum de mémoire
partagée.

<!-- 
Dire que si la base est en maintenance, passer l'option à 0 serait une bonne idée pour gagner du temps.

Relire https://www.postgresql.org/docs/current/sql-analyze.html

et https://www.postgresql.org/docs/current/glossary.html#GLOSSARY-BUFFER-ACCESS-STRATEGY
-->

</div>
