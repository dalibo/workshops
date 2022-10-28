<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a0ffa885e478f5eeacc4e250e35ce25a4740c487 

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/162

-->

<div class="slide-content">

* Apparition de deux nouveaux privilèges :
  + `SET` : permet de modifier les paramètres avec le context `superuser`
  + `ALTER SYSTEM` : permet à un utilisateur non `superuser` de modifier des paramètres avec `ALTER SYSTEM SET ...`
* Donne des droits par rôle et par paramètre
* Nouvelle table système `pg_parameter_acl` qui stocke la configuration 

</div>

<div class="notes">

Deux nouveaux privilèges arrivent en version 15 : `SET` et `ALTER SYSTEM`. `SET` va permettre d'autoriser la modification 
des paramètres de contexte `superuser` pour des rôles non privilégiés via la commande du même nom :

```sql
# Je dispose d'un utilisateur dalibo non superuser
postgres=> \du+ dalibo
                  Liste des rôles
 Nom du rôle | Attributs | Membre de | Description 
-------------+-----------+-----------+-------------
 dalibo      |           | {}        | 

# Je veux modifier le paramètre log_lock_waits qui est normalement réservé au superuser
postgres=> SET log_lock_waits = on;
ERROR:  permission denied to set parameter "log_lock_waits"

# Je donne le droit au rôle dalibo de modifier ce paramètre
postgres=# GRANT SET ON PARAMETER log_lock_waits TO dalibo;
GRANT

# L'utilisateur dalibo peut maintenant modifier uniquement ce paramètre
postgres=> SET log_lock_waits = on;
SET
postgres=> show log_lock_waits ;
 log_lock_waits 
----------------
 on
```

Avec le privilège `SET`, vous pouvez donner des droits sur l'ensemble des paramètres de PostgreSQL. Cependant, cela n'a de sens 
que pour les paramètres de contexte `superuser` car les autres ne peuvent soit pas être défini via la commande `SET`, soit peuvent 
déjà être modifiés par un rôle classique.

Il est possible de déterminer les paramètres réservés aux `superuser` avec la requête suivante :

```sql
SELECT * FROM pg_settings WHERE context = 'superuser';
```

Pour le privilège `ALTER SYSTEM`, il va permettre de donner le droit à un rôle non `superuser` de réaliser des commandes `ALTER SYSTEM SET ...` sur 
des paramètres spécifiques. Contrairement à `SET`, il peut s'appliquer à tous les paramètres du fichier `postgresql.conf` :

```sql
# Toujours avec le rôle dalibo, je veux modifier le shared_buffers de mon instance
postgres=> ALTER SYSTEM SET shared_buffers = '500MB';
ERROR:  permission denied to set parameter "shared_buffers"

# Je donne le droit au rôle dalibo de modifier ce paramètre
postgres=# GRANT ALTER SYSTEM ON PARAMETER shared_buffers TO dalibo;
GRANT

# L'utilisateur dalibo peut maintenant modifier uniquement ce paramètre
postgres=> ALTER SYSTEM SET shared_buffers = '500MB';
ALTER SYSTEM

# La modification a bien été répercutée dans le fichier postgresql.auto.conf
postgres=> \! cat 15/main/postgresql.auto.conf
shared_buffers = '500MB'
```

De façon classique, on utilisera la commande `REVOKE` pour retirer ces droits :

```sql
REVOKE SET ON PARAMETER log_lock_waits FROM dalibo;
REVOKE ALTER SYSTEM ON PARAMETER shared_buffers FROM dalibo;
```

Même si un utilisateur dispose des droits pour modifier tous les paramètres 
présents dans le fichier `postgresql.auto.conf`, ce privilège ne donne 
pas le droit de faire un `ALTER SYSTEM RESET ALL`. Il faudra passer par 
un super utilisateur ou les annuler un par un.

Afin d'enregistrer la configuration de ces nouveaux privilèges, une nouvelle table système est disponible : `pg_parameter_acl`.

```sql
postgres=# select * from pg_parameter_acl ;
  oid  |    parname     |                  paracl                          
-------+----------------+-----------------------------------------
 16394 | shared_buffers | {postgres=sA/postgres,dalibo=A/postgres}
 16390 | log_lock_waits | {postgres=sA/postgres,dalibo=s/postgres}
```

On y retrouve un _OID_, le nom du paramètre et les privilèges par rôle. Concernant les privilèges, deux nouvelles abréviations 
apparaissent : `s` pour le privilège `SET` et `A` pour `ALTER SYSTEM`. 

</div>
