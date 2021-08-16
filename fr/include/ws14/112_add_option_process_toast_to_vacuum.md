<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2961/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=7cb3048f38e26b39dd5fd412ed8a4981b6809b35

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/112

-->

<div class="slide-content">

* Permet de spécifier à un `VACUUM` manuel s'il doit traiter ou non les tables `TOAST`

</div>

<div class="notes">

`VACUUM` dispose désormais de l'option `PROCESS_TOAST` qui permet de lui spécifier s'il doit traiter ou non les tables `TOAST`. C'est un booléen et il est positionné à `true` par défaut.

Ce paramètre pourra être particulièrement utile si le taux de fragmentation (`BLOAT`) ou l'âge des transactions diffère grandement entre la table principale et la table `TOAST`.

```sql
-- On dispose d'une table blog avec une table TOAST
test=# \d+ blog
                     Table « public.blog »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
 title   | text    |                 |           |            
 content | text    |                 |           |            

test=# select relname,relfilenode,reltoastrelid from pg_class where relname='blog';
 relname | relfilenode | reltoastrelid 
---------+-------------+---------------
 blog    |       16565 |         16568

test=# \d+ pg_toast.pg_toast_16565
Table TOAST « pg_toast.pg_toast_16565 »
  Colonne   |  Type   | Stockage 
------------+---------+----------
 chunk_id   | oid     | plain
 chunk_seq  | integer | plain
 chunk_data | bytea   | plain
Table propriétaire : « public.blog »

-- Lancement d'un VACUUM sans l'option PROCESS_TOAST
test=# vacuum blog;

-- Vérification via la vue pg_stat_all_tables pour la table blog
-- et la table TOAST. Les 2 ont bien été traitées par le VACUUM
test=# select last_vacuum from pg_stat_all_tables where relname = 'blog';
-[ RECORD 1 ]------------------------------
last_vacuum | 2021-08-16 12:03:43.994759+02
test=# select last_vacuum from pg_stat_all_tables where relname = 'pg_toast_16565';
-[ RECORD 1 ]------------------------------
last_vacuum | 2021-08-16 12:03:43.994995+02

-- Lancement d'un VACUUM avec l'option PROCESS_TOAST
test=# vacuum (PROCESS_TOAST false) blog;

-- Vérification via la vue pg_stat_all_tables pour la table blog
-- et la table TOAST. Cette fois seule la table principale a été
-- traitée par le VACUUM
test=# select last_vacuum from pg_stat_all_tables where relname = 'blog';
-[ RECORD 1 ]------------------------------
last_vacuum | 2021-08-16 12:06:04.745281+02
test=# select last_vacuum from pg_stat_all_tables where relname = 'pg_toast_16565';
-[ RECORD 1 ]------------------------------
last_vacuum | 2021-08-16 12:03:43.994995+02
```

Cette fonctionnalité est également disponible avec la commande `vacuumdb --no-process-toast`.

</div>