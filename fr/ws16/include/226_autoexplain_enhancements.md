<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=d4bfe4128
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9d2d9728b

Discussion

* https://postgr.es/m/Y+MRdEq9W9XVa2AB@paquier.xyz

-->

<div class="slide-content">

* Trace le `queryid` en mode `VERBOSE`
* Gère le paramètre `log_parameter_max_length`

</div>

<div class="notes">

Bien que l'identifiant de requête soit disponible dans une commande `EXPLAIN`
manuelle, il n'était pas récupéré par le module `auto_explain`. Il le fait à
partir de la version 16. Par exemple :

```default
2023-09-29 18:44:40.229 CEST [136206] LOG:  duration: 0.029 ms  plan:
        Query Text: select pg_is_in_recovery() as ro 
        Result  (cost=0.00..0.01 rows=1 width=1)
          Output: pg_is_in_recovery()
        Query Identifier: 6937149974915068530
```

(Ne pas oublier que pour avoir cet identifiant, il faut
soit avoir installé le module `pg_stat_statements` soit avoir configuré le
paramètre `query_compute_id` à `on`.)

`auto_explain` dispose d'un nouveau paramètre,
`auto_explain.log_parameter_max_length`, qui est à l'image du paramètre
`log_parameter_max_length`, ajouté lui en version 15. Ce paramètre permet
d'indiquer si le module doit tracer les arguments d'une requête à paramètres (par
exemple une requête préparée). La valeur `-1` permet de tracer toutes les
requêtes, alors que la valeur `0` désactive cette trace. Les valeurs supérieures à
zéro indiquent la longueur maximale des valeurs tracées.

</div>
