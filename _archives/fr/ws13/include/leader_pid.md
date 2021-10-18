
<!--
Les commits sur ce sujet sont :

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=b025f32e0b5d7668daec9bfa957edf3599f4baa8
https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=11a68e4b53ffccf336a2faf5fa380acda28e880b

Discussion :



#### Champ `leader_pid` dans `pg_stat_activity`
-->

<div class="slide-content">

* La vue `pg_stat_activity` contient une nouvelle colonne `leader_pid` pour
  identifier le _leader_ d'un groupe de processus parallélisés ;
* Pour un _leader_ ou un processus non parallélisé, la valeur de cette colonne
  est `NULL`.

</div>

<div class="notes">

Il est désormais possible de distinguer et faire un lien entre le processus
_leader_ d'une requête parallélisée et ses processus _workers_ dans la vue
`pg_stat_activity`.

La colonne `leader_pid` contient le pid du processus _leader_ pour chaque ligne
de `pg_stat_activity` correspondant à un processus _worker_. Elle contient
`NULL` dans tous les autres cas :

```
PG13> SELECT leader_pid, pid, state, backend_type, query
        FROM pg_stat_activity
       WHERE backend_type IN ('client backend', 'parallel worker');

leader_pid |  pid   | state  |   backend_type  |           query
------------+--------+--------+-----------------+-----------------------------------------
      NULL | 207706 | active | client backend  | SELECT avg(i) FROM test_nonparallelise;
      NULL | 207949 | active | client backend  | SELECT avg(i) FROM test_parallelise;
      NULL | 207959 | active | client backend  | SELECT avg(i) FROM test_parallelise;
    207959 | 208561 | active | parallel worker | SELECT avg(i) FROM test_parallelise;
    207959 | 208562 | active | parallel worker | SELECT avg(i) FROM test_parallelise;
    207949 | 208564 | active | parallel worker | SELECT avg(i) FROM test_parallelise;
    207949 | 208565 | active | parallel worker | SELECT avg(i) FROM test_parallelise;
```

Dans les versions précédentes de PostgreSQL, il était difficile de rattacher un
_parallel worker_ à son processus _leader_.

Il y a eu plusieurs évolutions depuis la mise en place du parallélisme. En
version 9.6, les processus dédiés au parallélisme étaient visibles dans la vue
`pg_stat_activity`, mais la plupart des informations n'étaient pas renseignées.
En version 10, les processus _parallel workers_ étaient catégorisés comme
`background workers` dans celle-ci. Depuis la version 11 de PostgreSQL, la
colonne `backend_type` a une dénomination spécifique pour ces processus dédiés
à la parallélisation des requêtes : `parallel worker`.

Pour comparaison, voici le résultat du précédent exemple exécuté sous PostgreSQL
12 :

```
PG12> SELECT pid, state, backend_type, query
      FROM pg_stat_activity
      WHERE backend_type IN ('client backend', 'parallel worker');

 pid   | state  |   backend_type  |                query
--------+--------+-----------------+-----------------------------------------
206327 | active | client backend  | SELECT avg(i) FROM test_parallelise;
206328 | active | client backend  | SELECT avg(i) FROM test_parallelise;
206329 | active | client backend  | SELECT avg(i) FROM test_nonparallelise;
207201 | active | parallel worker | SELECT avg(i) FROM test_parallelise;
207202 | active | parallel worker | SELECT avg(i) FROM test_parallelise;
207203 | active | parallel worker | SELECT avg(i) FROM test_parallelise;
207204 | active | parallel worker | SELECT avg(i) FROM test_parallelise;
```

</div>
