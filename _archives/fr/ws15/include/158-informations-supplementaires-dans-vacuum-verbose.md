<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/37/3433/

Discussion

* https://www.postgresql.org/message-id/flat/CAH2-Wznp=c=Opj8Z7RMR3G=ec3_JfGYMN_YvmCEjoPCHzWbx0g@mail.gmail.com

-->



<div class="slide-content">
* Optimisations du code de la commande `VACUUM`
* Amélioration de la verbosité de la commande `VACUUM VERBOSE`
</div>

<div class="notes">
Le code de la commande `VACUUM` a été simplifié et optimisé. La nouvelle
version permet de collecter plus d'informations sur l'exécution de l'opération de
maintenance. Par conséquent, la sortie de la commande `VACUUM VERBOSE` est encore 
plus verbeuse dans PostgreSQL 15. En voici un exemple :

```sql
postgres=# VACUUM VERBOSE T1;
INFO:  vacuuming "postgres.public.t1"
INFO:  table "t1": truncated 1 to 0 pages
INFO:  finished vacuuming "postgres.public.t1": index scans: 0
pages: 1 removed, 0 remain, 1 scanned (100.00% of total)
tuples: 5 removed, 0 remain, 0 are dead but not yet removable
removable cutoff: 747, which was 1 XIDs old when operation ended
new relfrozenxid: 747, which is 6 XIDs ahead of previous value
index scan not needed: 1 pages from table (100.00% of total) had 5 dead item identifiers removed
avg read rate: 2.637 MB/s, avg write rate: 4.394 MB/s
buffer usage: 7 hits, 3 misses, 5 dirtied
WAL usage: 6 records, 2 full page images, 9339 bytes
system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
VACUUM
```

La commande affiche un rapport détaillé de l'exécution, on y voit apparaître :

* le nouveau `relfrozenxid` après l'opération
* des informations sur l'utilisation des buffers
* des informations sur le nettoyage effectué sur les index de la table
* des métriques sur les performances du VACUUM : `avg read rate` et `avg write rate`.

La même commande en version 14 affichait un rapport moins complet:

```sql
postgres=# VACUUM VERBOSE T1;
INFO:  vacuuming "public.t1"
INFO:  table "t1": removed 5 dead item identifiers in 1 pages
INFO:  table "t1": found 5 removable, 0 nonremovable row versions in 1 out of 1 pages
DETAIL:  0 dead row versions cannot be removed yet, oldest xmin: 745
Skipped 0 pages due to buffer pins, 0 frozen pages.
CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s.
INFO:  table "t1": truncated 1 to 0 pages
DETAIL:  CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
VACUUM

```
</div>