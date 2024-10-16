<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2883/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=46d6e5f567906389c31c4fb3a2653da1885c18ee

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/134

-->

<div class="slide-content">

* Ajout de la colonne `waitstart`
  * Heure à laquelle l'attente d'un verrou a commencé

  ```sql
          mode         | granted |      waitstart
  ---------------------+---------+---------------------
   AccessExclusiveLock | t       | 
   AccessShareLock     | f       | 2021-08-26 15:54:53
  ```
</div>

<div class="notes">

La vue système `pg_locks` présente une nouvelle colonne `waitstart`. Elle indique
l'heure à laquelle le processus serveur a commencé l'attente d'un verrou ou alors
`null` si le verrou est détenu. Afin d'éviter tout surcoût, la mise à jour de
cette colonne est faite sans poser de verrou, il est donc possible que la valeur
de `waitstart` soit à `null` pendant une très courte période après le début d'une
attente et ce même si la colonne `granted` est à `false`.

```sql
-- Une transaction pose un verrou
SELECT pg_backend_pid();
--  pg_backend_pid 
-- ----------------
--           27829
BEGIN;
LOCK TABLE test_copy ;
```

```sql
-- Une autre transaction réalise une requête sur la même table
SELECT pg_backend_pid();
--  pg_backend_pid 
-- ----------------
--           27680
SELECT * FROM test_copy ;
```

```sql
-- Via la vue pg_locks on peut donc voir qui bloque
-- le processus 27680 et également depuis quand
SELECT pid, mode, granted, waitstart 
  FROM pg_locks WHERE pid in (27829,27680);
```
```sh
  pid  |        mode         | granted |           waitstart           
-------+---------------------+---------+-------------------------------
 27829 | AccessExclusiveLock | t       | 
 27680 | AccessShareLock     | f       | 2021-08-26 15:54:53.280405+02
```

</div>
