<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=27e1f14563cf982f1f4d71e21ef247866662a052

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/117

-->

<div class="slide-content">

* Nouveau nœud d'exécution `Async Foreign Scan`
* `CREATE SERVER … OPTIONS (host …, port …, async_capable on)`  (pas par défaut !)
* Lecture parallélisée pour les partitions distantes

```sql
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Append
   ->  Async Foreign Scan on public.async_p1 t1_1
         Output: t1_1.a, t1_1.b, t1_1.c
         Remote SQL: SELECT a, b, c FROM public.base_tbl1 WHERE (((b % 100) = 0))
   ->  Async Foreign Scan on public.async_p2 t1_2
         Output: t1_2.a, t1_2.b, t1_2.c
         Remote SQL: SELECT a, b, c FROM public.base_tbl2 WHERE (((b % 100) = 0))
```

</div>

<div class="notes">

Les tables distantes fournies par l'extension `postgres_fdw` bénéficient du
nouveau nœud d'exécution `Async Foreign Scan` lorsqu'elles proviennent de plusieurs
serveurs distincts. Il s'agit d'une évolution du nœud existant `Foreign Scan` pour
favoriser la lecture parallélisée de plusieurs tables distantes, notamment au sein d'une 
table partitionnée. <!-- ça marche aussi pour des tables étrangères isolées lues jointes avec UNION ALL -->

L'option `async_capable` doit être activée au niveau de l'objet serveur ou de
la table distante, selon la granularité voulue. L'option n'est pas active par défaut.

Les tables parcourues en asynchrone apparaissent dans un nouveau nœud `Async` :

```sql
EXPLAIN (verbose, costs off) SELECT * FROM t1 WHERE b % 100 = 0;
```
```sh
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Append
   ->  Async Foreign Scan on public.async_p1 t1_1
         Output: t1_1.a, t1_1.b, t1_1.c
         Remote SQL: SELECT a, b, c FROM public.base_tbl1 WHERE (((b % 100) = 0))
   ->  Async Foreign Scan on public.async_p2 t1_2
         Output: t1_2.a, t1_2.b, t1_2.c
         Remote SQL: SELECT a, b, c FROM public.base_tbl2 WHERE (((b % 100) = 0))
```

L'intérêt est évidemment de faire fonctionner simultanément plusieurs serveurs
distants, ce qui peut amener de gros gains de performance. C'est un grand pas
dans l'intégration d'un _sharding_ natif dans PostgreSQL.

En ce qui concerne la syntaxe, les ordres d'activation et de désactivation de l'option,
sur le serveur ou la table sont par exemple :

```sql
CREATE SERVER distant3
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'machine3', dbname 'bi', port 5432, async_capable 'on') ;
```
```sql
ALTER SERVER distant1 OPTIONS (ADD async_capable 'on');
```
```sql
CREATE FOREIGN TABLE donnees1
PARTITION OF …
OPTIONS (async_capable 'on') ;
```
```sql
ALTER FOREIGN TABLE donnees1  OPTIONS (DROP async_capable);
```

</div>
