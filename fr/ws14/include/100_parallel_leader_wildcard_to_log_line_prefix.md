<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=b8fdee7d0ca8bd2165d46fb1468f75571b706a01
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=4f0b0966c866ae9f0e15d7cc73ccf7ce4e1af84b

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/100

-->

<div class="slide-content">

`log_line_prefix` : enrichit le préfixe des lignes de la sortie d'erreur

* `%P` : identifiant du processus principal (_parallel leader_)
  * si l'entrée de journal provient d'un processus auxiliaire (_parallel worker_)
* `%Q` : identifiant de la requête (nouveauté)
  * si le calcul interne de l'identifiant est actif

</div>

<div class="notes">

Le paramètre `log_line_prefix` accepte deux nouveaux caractères d'échappement.

* `%P` pour l'identifiant de processus _leader_ dans un groupe parallélisé

Déjà présent depuis la version 13 dans la vue `pg_stat_activity`, l'identifiant
de processus _leader pid_ est désormais disponible pour faciliter la compréhension
des événements dans la sortie d'erreur.

* `%Q` pour l'identifiant de la requête _query id_

Le calcul interne pour l'identifiant de requête est une nouveauté de la version 14
et sera abordé plus loin dans ce workshop.

Prenons une instance dont la configuration est semblable à ce qui suit :

```ini
compute_query_id = on
log_temp_files = 0
log_min_duration_statement = 0
max_parallel_workers_per_gather = 8
log_line_prefix = '[%P-%p]: id=%Q '
```

On constate dans un extrait des traces, qu'une requête d'agrégat bénéficie de 
quatre processus auxiliaires (pid `20992` à `20995`) et d'un processus principal 
(pid `20969`). Chacun de ses processus partage le même identifiant de requête
`-8329068551672606797`.

```text
[20969-20995]: id=-8329068551672606797 
    LOG:  temporary file: path "pgsql_tmp20995.0", size 29450240
[20969-20993]: id=-8329068551672606797 
    LOG:  temporary file: path "pgsql_tmp20993.0", size 52682752
[20969-20994]: id=-8329068551672606797 
    LOG:  temporary file: path "pgsql_tmp20994.0", size 53387264
[20969-20992]: id=-8329068551672606797 
    LOG:  temporary file: path "pgsql_tmp20992.0", size 53477376
[-20969]: id=-8329068551672606797 
    LOG:  temporary file: path "pgsql_tmp20969.0", size 29384704
[-20969]: id=-8329068551672606797 
    LOG:  duration: 2331.661 ms  
    statement:  select trunc(montant/1000) as quintile, avg(montant) 
                from ventes group by quintile;
```

</div>
