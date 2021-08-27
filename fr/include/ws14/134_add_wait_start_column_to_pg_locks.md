<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2883/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=46d6e5f567906389c31c4fb3a2653da1885c18ee

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/134

-->

<div class="slide-content">

* Ajout de la colonne `waitstart`

</div>

<div class="notes">

La vue système `pg_locks` présente une nouvelle colonne `waitstart`. Elle indique l'heure à laquelle le processus serveur a commencé l'attente d'un verrou ou alors `null` si le verrou est détenu. Afin d'éviter tout surcôut, la mise à jour de cette colonne est faite sans pause de verrou, il est donc possible que la valeur de `waitstart` soit à `null` pendant une très courte période après le début d'une attente et ce même si la colonne `granted` est à `false`.

```sql
-- Une transaction pose un verrou
test=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
          27829
test=# BEGIN;
BEGIN
test=*# LOCK TABLE test_copy ;
LOCK TABLE


-- Une autre transaction réalise une requête sur la même table
test=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
          27680
test=# SELECT  * FROM test_copy ;


-- Via la vue pg_locks on peut donc voir qui bloque
-- le processus 27680 et également depuis quand
test=# select database,relation,pid,mode,granted,waitstart from pg_locks where pid in (27829,27680);
 database | relation |  pid  |        mode         | granted |           waitstart           
----------+----------+-------+---------------------+---------+-------------------------------
    16384 |    36500 | 27829 | AccessExclusiveLock | t       | 
    16384 |    36500 | 27680 | AccessShareLock     | f       | 2021-08-26 15:54:53.280405+02

</div>