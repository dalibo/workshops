<!--
Les commits sur ce sujet sont :

| Sujet                    | Lien                                                                                                        |
|==========================|=============================================================================================================|
| VACUUM parallélisé       | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=40d964ec997f64227bc0ff5e058dc4a5770a70a9 |

-->

<!-- #### VACUUM et parallélisation -->

<div class="slide-content">

  * _VACUUM_ peut paralléliser le traitement des index
  * Nouvelle option _PARALLEL_
    * si 0, non parallélisé
  * La table doit avoir :
    * au minimum deux index
    * des index d'une taille supérieure à `min_parallel_index_scan_size`
  * Non disponible pour le _VACUUM FULL_

</div>

<div class="notes">

Le `VACUUM` fonctionne en trois phases :

  * parcours de la table pour trouver les lignes à nettoyer
  * nettoyage des index de la table
  * nettoyage de la table

La version 13 permet de traiter les index sur plusieurs CPU, un par index. De
ce fait, ceci n'a un intérêt que si la table contient au moins deux index, et
que ces index ont une taille supérieure à `min_parallel_index_scan_size`
(512 ko par défaut).

Lors de l'exécution d'un `VACUUM` parallélisé, un ou plusieurs autres processus
sont créés. Ces processus sont appelés des _workers_, alors que le processus
principal s'appelle le _leader_. Il participe lui aussi au traitement des
index. De ce fait, si une table a deux index et que la parallélisation est
activée, PostgreSQL utilisera le leader pour un index et un worker pour l'autre
index.

Par défaut, PostgreSQL choisit de lui-même s'il doit utiliser des workers et
leur nombre. Il détermine cela automatiquement, suivant le nombre d'index
éligibles, en se limitant à un maximum correspondant à la valeur du paramètre
`max_parallel_maintenance_workers` (2 par défaut).

Pour forcer un certain niveau de parallélisation, il faut utiliser l'option
`PARALLEL`.  Cette dernière doit être suivie du niveau de parallélisation. Il
est garanti qu'il n'y aura pas plus que ce nombre de processus pour traiter la
table et ses index. En revanche, il peut y en avoir moins. Cela dépend
une nouvelle fois du nombre d'index éligibles, de la configuration du paramètre
`max_parallel_maintenance_workers`, mais aussi du nombre de workers
autorisé, limité par le paramètre `max_parallel_workers` (8 par défaut).

En utilisant l'option `VERBOSE`, il est possible de voir l'impact de la
parallélisation et le travail des différents _workers_ :

```
CREATE TABLE t1 (c1 int, c2 int) WITH (autovacuum_enabled = off) ;
INSERT INTO t1 SELECT i,i FROM generate_series (1,1000000) i;
CREATE INDEX t1_c1_idx ON t1 (c1) ;
CREATE INDEX t1_c2_idx ON t1 (c2) ;
DELETE FROM t1 ;

VACUUM (VERBOSE, PARALLEL 3) t1 ;
INFO:  vacuuming "public.t1"
INFO:  launched 1 parallel vacuum worker for index vacuuming (planned: 1)
INFO:  scanned index "t1_c2_idx" to remove 10000000 row versions 
                                               by parallel vacuum worker
DETAIL:  CPU: user: 4.14 s, system: 0.29 s, elapsed: 6.85 s
INFO:  scanned index "t1_c1_idx" to remove 10000000 row versions
DETAIL:  CPU: user: 6.31 s, system: 0.59 s, elapsed: 19.62 s
INFO:  "t1": removed 10000000 row versions in 63598 pages
DETAIL:  CPU: user: 1.16 s, system: 0.90 s, elapsed: 7.24 s
...
```

Enfin, il est à noter que cette option n'est pas disponible pour le `VACUUM
FULL` :

```
# VACUUM (FULL,PARALLEL 2);
ERROR:  VACUUM FULL cannot be performed in parallel
```

</div>
