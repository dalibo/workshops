## TP - Colonne leader_pid dans pg_stat_activity

<div class="slide-content">

* Compter les requêtes parallélisées et le nombre processus _workers_ invoqués ;
* Identifier les processus _workers_ d'une requête parallélisée.

</div>

<div class="notes">

Créer une table et y insérer un nombre conséquent de lignes :

```sql
CREATE TABLE test_parallelise(i int, t text);

INSERT INTO test_parallelise(i, t)
       SELECT i, 't :' || i
       FROM generate_series(1,30000000) AS F(i);
```

Ouvrir plusieurs sessions `psql` et y exécuter la requête suivante :

```sql
SELECT count(*) FROM test_parallelise ;
```

Dans une session supplémentaire, compter le nombre de requêtes actuellement
parallélisées et le nombre de processus _worker_ invoqués :

```sql
SELECT COUNT(DISTINCT leader_pid) AS nb_requetes_parallelisees,
       COUNT(leader_pid) AS parallel_workers
  FROM pg_stat_activity
 WHERE leader_pid IS NOT NULL
   AND backend_type = 'parallel worker' \watch 1
```

Exemple de résultat :

```
 nb_requetes_parallelisees | parallel_workers
---------------------------+-----------------
                         2 |               4
```

Identifier les processus _worker_ d'une requête parallélisée :

```sql
SELECT pid,
       ARRAY(SELECT pid
             FROM pg_stat_activity
             WHERE leader_pid = psa.pid) AS workers,
       state, query
  FROM pg_stat_activity AS psa
 WHERE backend_type = 'client backend';
```

Exemple de retour :

```
  pid   |     workers     | state  | query
--------+-----------------+--------+--------------------------------------
 684097 | {684113,684114} | active | SELECT count(*) FROM test_parallelise ;
```

</div>
