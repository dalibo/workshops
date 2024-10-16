<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=6e2775e4d4e47775f0d933e4a93c148024a3bc63

Discussion :

* http://postgr.es/m/20230119194601.GA4105788@nathanxps13

-->

<div class="slide-content">

  * Nouveau rôle `pg_use_reserved_connections`
    + permet d'utiliser des slots de connexions réservés
  * Nouveau paramètre `reserved_connections`
    * pour configurer le nombre de slots réservés

</div>

<div class="notes">

Un nouveau rôle prédéfini a été ajouté dans cette version de PostgreSQL.

Les rôles, pour lesquels le rôle prédéfini `pg_use_reserved_connections` a été
attribué, peuvent utiliser les connexions réservées par le paramètre de
configuration `reserved_connections`. 

Prenons un exemple très simpliste avec la configuration suivante. Un seul
utilisateur normal peut se connecter à l'instance (`6-3-2 = 1`). Les cinq autres
connexions étant réservées soit pour des utilisateurs privilégiés
(`reserved_connections`), soit pour des administrateurs
(`superuser_reserved_connections`).

```sql
postgres=# show max_connections ;
 max_connections 
-----------------
 6
(1 row)

postgres=# show reserved_connections ;
 reserved_connections 
----------------------
 2
(1 row)

postgres=# show superuser_reserved_connections ;
 superuser_reserved_connections 
--------------------------------
 3
(1 row)
```

La création des rôles s'est faite de la manière suivante :

```sql
postgres=# create role r1 with login password 'role1';
CREATE ROLE
postgres=# create role a1 with login password 'admin1';
CREATE ROLE

```

Le nouveau rôle prédéfini a été attribué avec la commande `GRANT`.

```sql
postgres=# grant pg_use_reserved_connections to a1;
GRANT ROLE
```

Essayons désormais de nous connecter une fois avec l'utilisateur `r1`. Tout se
passe bien.

```sql
$ psql -U r1 -d postgres
psql (16.1)
Type "help" for help.

postgres=>
```

Essayons une nouvelle fois avec ce même utilisateur ... Il n'est pas possible de se
connecter car nous avons atteint la limite de connexion possible pour des
utilisateurs normaux.

```sql
$ psql -U r1 -d postgres
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: FATAL:
remaining connection slots are reserved for roles with privileges of the
"pg_use_reserved_connections" role
```

Cependant, il nous est possible de nous connecter avec l'utilisateur `a1`, qui
lui en tant que membre de `pg_use_reserved_connections`, dispose des slots
de connexions réservés de `pg_use_reserved_connections`. 

```sql
$ psql -U a1 -d postgres
psql (16.1)
Type "help" for help.

postgres=> 
```

Si la limite de `reserved_connections` est atteinte, le message d'erreur
suivant sera affiché lors d'une connexion avec un rôle membre de
`pg_use_reserved_connections`.

```sh
$ psql -U a1 -d postgres
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: FATAL:  remaining connection slots are reserved for roles with the SUPERUSER attribute
```

Même si cette limite est atteinte, il restera encore la possibilité de se
connecter avec un superutilisateur.

```sh
$ psql -U postgres -d postgres
psql (16.1)
Type "help" for help.

postgres=#
```

</div>
