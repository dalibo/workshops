<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=3c05284d8

Discussion

* https://postgr.es/m/0a29b954b10b57f0d135fe12aa0909bd41883eb0.camel@cybertec.at

-->

<div class="slide-content">

* Nouvelle option `GENERIC_PLAN`
* Trace le plan générique d'une requête préparée
  + Accepte les _placeholders_ comme `$1` ou `$2`

</div>

<div class="notes">

Lors de la création d'une requête préparée, un plan générique est créé. Pendant
les cinq premières exécutions, un plan personnalisé est aussi créé et les deux
sont comparés pour savoir lequel est le plus intéressant. Par la suite,
PostgreSQL utilisera tout le temps l'un ou l'autre, suivant lequel a été le plus
intéressant pendant les cinq premières exécutions.

Ce plan générique n'était pas récupérable facilement auparavant. La version 16
ajoute une option `GENERIC_PLAN` qui permet de le récupérer. Par exemple :

```sql
CREATE TABLE t4(id integer);
INSERT INTO t4 SELECT generate_series(1, 1_000_000) i;
CREATE INDEX ON t4(id);

EXPLAIN (GENERIC_PLAN) SELECT * FROM t4 WHERE id<$1;

                                   QUERY PLAN
---------------------------------------------------------------------------------
 Index Only Scan using t4_id_idx on t4  (cost=0.42..9493.75 rows=333333 width=4)
   Index Cond: (id < $1)
(2 rows)
```

Dans les versions précédentes, il était nécessaire d'activer les traces des requêtes pour 
obtenir les valeurs rattachées aux requêtes préparées à l'aide de la configuration
`log_min_duration_statement`. Par exemple, pour simuler une requête préparée, nous
utilisons l'outil `pgbench` et son option `--protocol=prepared`. Les traces pour une 
version 13 sont les suivantes :

```text
LOG:  duration: 1.091 ms  parse P_0: SELECT abalance FROM pgbench_accounts WHERE aid = $1;
LOG:  duration: 1.974 ms  bind P_0: SELECT abalance FROM pgbench_accounts WHERE aid = $1;
DETAIL:  parameters: $1 = '5613613'
LOG:  duration: 0.322 ms  execute P_0: SELECT abalance FROM pgbench_accounts WHERE aid = $1;
DETAIL:  parameters: $1 = '5613613'
```

Il fallait ensuite substituer la valeur de paramètre pour obtenir le plan d'exécution :

\tiny
```sql
EXPLAIN SELECT abalance FROM pgbench_accounts WHERE aid = 5613613;

                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.43..8.45 rows=1 width=4)
   Index Cond: (aid = 5613613)
(2 rows)
```

\normalsize

</div>
