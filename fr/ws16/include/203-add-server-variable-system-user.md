<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=0823d061b0b7f1e20fbfd48bef3c2e093493dbd4

-->

<div class="slide-content">

  * Nouvelle fonction `SYSTEM_USER` du standard SQL
  * Affiche l'utilisateur système utilisé et la méthode de connexion
  * `auth_method:identity`
  * Valeur `NULL` si la méthode `trust` est utilisée

</div>

<div class="notes">

La fonction `SYSTEM_USER` du standard SQL est désormais implémentée avec
PostgreSQL 16. Les informations remontées par cette fonction permettent de
connaitre l'utilisateur système et la manière dont il s'est connecté.

Si la méthode d'authentification `trust` est utilisée, cette fonction retourne
`NULL`.

Dans l'exemple suivant, un utilisateur système `sysadmin` peut se connecter à
l'instance en tant que `dalibo` grâce au fichier `pg_ident.conf` et à la
configuration de `pg_hba.conf`.

Fichier `pg_ident.conf` :

```bash
# MAPNAME       SYSTEM-USERNAME         PG-USERNAME
sysdb           sysadmin                dalibo
```

Fichier `pg_hba.conf` :
```bash
[...]
local   all             all                        ident map=sysdb
[...]
```

La connexion s'effectue correctement et la variable `system_user` a bien pour
valeur `sysadmin`.

```bash
$ whoami
sysadmin
$ psql -U dalibo -d postgres
Password for user dalibo: 
psql (16.1)
Type "help" for help.
```
```sql
postgres=> select current_user, session_user, system_user;
 current_user | session_user | system_user 
--------------+--------------+-------------
 dalibo       | dalibo       | peer:sysadmin
(1 row)
```

Regardons ce qu'il se passe lorsque la commande `SET ROLE` est utilisée.
Celle-ci permet d'endosser un autre rôle (changement de `current_user`), par
exemple, pour l'exécution d'une commande spécifique. Elle ne change en rien
l'utilisateur de session ou du système.

```sql
$ whoami
sysadmin
$ psql -U dalibo -d postgres
psql (16.1)
Type "help" for help.

postgres=> set role admin;
SET
postgres=> select current_user, session_user, system_user;
 current_user | session_user | system_user 
--------------+--------------+-------------
 admin        | dalibo       | peer:sysadmin
(1 row)
```

Comme expliqué au début, la valeur de `system_user` sera `NULL` lorsque la
méthode `trust` est utilisée.

```sql
$ psql -U postgres
psql (16.1)
Type "help" for help.

postgres=# select current_user, session_user, system_user;
 current_user | session_user | system_user 
--------------+--------------+-------------
 postgres     | postgres     | 
(1 row)
```

Voici un autre exemple avec l'utilisation de la commande `SET ROLE`. Celle-ci
permet d'endosser un autre rôle (changement de `current_user`), par exemple,
pour l'exécution d'une commande spécifique. Elle ne change en rien
l'utilisateur de session ou du système.

```sql
$ psql -U dalibo -d postgres
psql (16.1)
Type "help" for help.

postgres=> set role admin;
SET
postgres=> select current_user, session_user, system_user;
 current_user | session_user | system_user 
--------------+--------------+-------------
 admin        | dalibo       | md5:dalibo
(1 row)
```


</div>
