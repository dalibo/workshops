<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=5fd9dfa5f50e4906c35133a414ebec5b6d518493
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=4f0b0966c866ae9f0e15d7cc73ccf7ce4e1af84b

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/132
* https://gitlab.dalibo.info/formation/workshops/-/issues/100

-->

<div class="slide-content">
* Le _query id_ est disponible globalement
  * valeur hâchée sur 64 bits d'une requête normalisée
  * introduit avec `pg_stat_statements` en version 9.4
  * `pg_stat_activity`, `log_line_prefix`, `EXPLAIN VERBOSE`
* nouveau paramètre `compute_query_id` (`auto` par défaut)

```sql
      query_id       |                           query
---------------------+---------------------------------------------------------
 2691537454541915536 | SELECT abalance FROM pgbench_accounts WHERE aid = 85694;
 2691537454541915536 | SELECT abalance FROM pgbench_accounts WHERE aid = 51222;
 2691537454541915536 | SELECT abalance FROM pgbench_accounts WHERE aid = 14006;
 2691537454541915536 | SELECT abalance FROM pgbench_accounts WHERE aid = 48639;
```
</div>

<div class="notes">
L'identifiant de requête est un _hash_ unique pour les requêtes dites normalisées,
qui présentent la même forme sans considération des expressions variables. Cet
identifiant, ou _query id_, a été introduit avec la contribution `pg_stat_statements`
afin de regrouper des statistiques d'exécution d'une requête distincte pour chaque
base et chaque utilisateur.

La méthode pour générer cet identifiant a été élargie globalement dans le code de
PostgreSQL, rendant possible son exposition en dehors de `pg_stat_statements`.
Les quelques composants de supervision en ayant bénéficié sont :

* La vue `pg_stat_activity` dispose à présent de sa colonne `query_id` ;
* Le paramètre `log_line_prefix` peut afficher l'identifiant avec le nouveau caractère d'échappement `%Q` ;
* Le mode `VERBOSE` de la commande `EXPLAIN`.

```sql
SET compute_query_id = on;
EXPLAIN (verbose, costs off)
 SELECT abalance FROM pgbench_accounts WHERE aid = 28742;
```
```sh
                            QUERY PLAN
-------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on public.pgbench_accounts
   Output: abalance
   Index Cond: (pgbench_accounts.aid = 28742)
 Query Identifier: 2691537454541915536
```

Dans l'exemple ci-dessus, le paramètre `compute_query_id` doit être activé pour
déclencher la recherche de l'identifiant rattachée à une requête. Par défaut, ce
paramètre vaut `auto`, c'est-à-dire qu'en l'absence d'un module externe comme
l'extension `pg_stat_statements`, l'identifiant ne sera pas disponible.

```sql
CREATE EXTENSION pg_stat_statements;
SHOW compute_query_id ;
```
```sh
 compute_query_id 
------------------
 auto
```
```sql
SELECT query_id, query FROM pg_stat_activity 
 WHERE state = 'active';
```
```sh
      query_id       |                           query
---------------------+---------------------------------------------------------
 2691537454541915536 | SELECT abalance FROM pgbench_accounts WHERE aid = 85694;
 2691537454541915536 | SELECT abalance FROM pgbench_accounts WHERE aid = 51222;
 2691537454541915536 | SELECT abalance FROM pgbench_accounts WHERE aid = 14006;
 2691537454541915536 | SELECT abalance FROM pgbench_accounts WHERE aid = 48639;
```
```sql
SELECT query, calls, mean_exec_time FROM pg_stat_statements 
 WHERE queryid = 2691537454541915536 \gx
```
```sh
-[ RECORD 1 ]--+-----------------------------------------------------
query          | SELECT abalance FROM pgbench_accounts WHERE aid = $1
calls          | 3786805
mean_exec_time | 0.009108110672981447
```

</div>
