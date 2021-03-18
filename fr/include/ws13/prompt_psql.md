<!--
Les commits sur ce sujet sont :

| Sujet                    | Lien                                                                                                        |
|==========================|=============================================================================================================|
| prompt psql              | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=dcdbb5a5db09064ac08ff3971c5031281ef2e545 |

-->

<!-- #### Prompt psql -->

<div class="slide-content">

  * Prompt psql modifié
  * Intègre maintenant l'état de la transaction
  * L'étoile représente une transaction valide en cours
  * Le point d'exclamation représente une transaction erronée en cours

</div>

<div class="notes">

Le prompt par défaut de `psql` a été modifié pour y ajouter le joker `%x`. Ce
dernier indique l'état de la transaction (valide ou erronnée, mais en cours)
quand une transaction a été ouverte explicitement. En voici quelques exemples :

```
-- pas de transaction ouverte, le prompt ressemble à l'ancien
b1=> BEGIN;
BEGIN

-- maintenant que la transaction est ouverte, une étoile indique qu'on est
-- dans une transaction explicite
b1=*> CREATE TABLE t1(id integer);
CREATE TABLE

b1=*> SELECT * FROM t1;
 id 
----
(0 rows)

b1=*> INSERT INTO t1 VALUES (10);
INSERT 0 1

b1=*> SELECT * FROM t1;
 id 
----
 10
(1 row)

-- cette étoile reste présente jusqu'à la fin de la transaction
b1=*> COMMIT;
COMMIT

-- voilà, COMMIT ou ROLLBACK exécuté, on revient à l'ancien prompt
b1=> BEGIN;
BEGIN

-- nouvelle transaction explicite, l'étoile revient
b1=*> CREATE TABLE t1(id integer);
ERROR:  relation "t1" already exists

-- la transaction est en erreur, l'étoile est remplacée par un point
-- d'exclamation
b1=!> SELECT * FROM t1;
ERROR:  current transaction is aborted,
        commands ignored until end of transaction block

-- ce dernier restera jusqu'à l'exécution d'un ROLLBACK
b1=!> ROLLBACK;
ROLLBACK

-- cela fonctionne aussi avec un ROLLBACK TO vers un savepoint créé avant
-- l'erreur
b1=> BEGIN;
BEGIN

b1=*> SAVEPOINT sp1;
SAVEPOINT

b1=*> CREATE TABLE t1(id integer);
ERROR:  relation "t1" already exists

b1=!> SELECT * FROM t1;
ERROR:  current transaction is aborted,
        commands ignored until end of transaction block

b1=!> ROLLBACK TO sp1;
ROLLBACK

-- on se retrouve bien avec l'étoile
b1=*> SELECT * FROM t1;
 id
----
 10
(1 row)

b1=*> COMMIT;
COMMIT
```

De ce fait, l'étoile est utilisée pour indiquer une transaction valide en
cours et le point d'exclamation pour une transaction en erreur en cours.

</div>
