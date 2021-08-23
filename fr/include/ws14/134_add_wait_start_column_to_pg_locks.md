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
test=# begin;
BEGIN
test=*# lock table test_copy ;
LOCK TABLE

-- Une autre transaction fait une requête sur la même table
test=# select * from test_copy ;

-- Via pg_locks on peut voir quand a débuté l'attente
-[ RECORD 12 ]-----+------------------------------
locktype           | relation
database           | 16384
relation           | 36500
page               | 
tuple              | 
virtualxid         | 
transactionid      | 
classid            | 
objid              | 
objsubid           | 
virtualtransaction | 5/11
pid                | 14784
mode               | AccessShareLock
granted            | f
fastpath           | f
waitstart          | 2021-08-19 10:05:17.423733+02
```

</div>