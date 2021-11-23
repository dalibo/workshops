<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2961/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=7cb3048f38e26b39dd5fd412ed8a4981b6809b35

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/112

-->

<div class="slide-content">

  * Traite les tables de débordement TOAST lors d'un `VACUUM` manuel
  * Activé par défaut

  ```sql
  VACUUM (PROCESS_TOAST false) blog;
  ```

</div>

<div class="notes">

`VACUUM` dispose désormais de l'option `PROCESS_TOAST` qui permet de lui spécifier
s'il doit traiter ou non les tables TOAST. C'est un booléen et il est positionné
à `true` par défaut.

À `false`, ce paramètre pourra être particulièrement utile pour accélérer un `VACUUM` si le taux de fragmentation
(_bloat_) ou l'âge des transactions diffère grandement entre la table principale
et la table TOAST, pour ne pas perdre de temps sur cette dernière.
Les TOAST sont toujours concernées par un `VACUUM FULL`. <!-- erreur si PROCESS_TOAST à false  -->

Dans cet exemple, on dispose d'une table `blog` avec une table TOAST associée :

```sql
test=# SELECT relname, reltoastrelid::regclass AS reltoastname
         FROM pg_class WHERE relname = 'blog';

test=# \d blog
```
```sh
 relname |      reltoastname       
---------+-------------------------
 blog    | pg_toast.pg_toast_16565

                     Table « public.blog »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
 title   | text    |                 |           |            
 content | text    |                 |           |            
```

Après lancement d'un VACUUM sans l'option `PROCESS_TOAST`, l'horodatage
du traitement, à travers la vue `pg_stat_all_tables`,
montre que la table `blog` et la table TOAST associée ont bien été traitées par le VACUUM.

```sql
test=# VACUUM blog;
test=# SELECT relname, last_vacuum FROM pg_stat_all_tables
        WHERE relname IN ('blog', 'pg_toast_16565');
```
```console
    relname     |          last_vacuum          
----------------+-------------------------------
 blog           | 2021-08-16 12:03:43.994759+02
 pg_toast_16565 | 2021-08-16 12:03:43.994995+02
```

Lors d'un lancement d'un VACUUM avec l'option `PROCESS_TOAST`, seule
la table principale est traitée par le VACUUM :

```sql
test=# VACUUM (PROCESS_TOAST false) blog;
test=# SELECT relname, last_vacuum FROM pg_stat_all_tables
        WHERE relname IN ('blog', 'pg_toast_16565');
```
```console
    relname     |          last_vacuum          
----------------+-------------------------------
 blog           | 2021-08-16 12:06:04.745281+02
 pg_toast_16565 | 2021-08-16 12:03:43.994995+02
```

Cette fonctionnalité est également disponible avec la commande
`vacuumdb --no-process-toast`.

</div>

