<!--
Les commits sur ce sujet sont :

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=1379fd537f9fc7941c8acff8c879ce3636dbdb77
https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=80e05a088e4edd421c9c0374d54d787c8a4c0d86

Discussion générale:


 #### Déconnexion des utilisateurs à la suppression d'une base de données 

-->

<div class="slide-content">

* Nouvelle clause `WITH FORCE` pour `DROP DATABASE`
* Force la déconnexion des utilisateurs
* Nouvel argument `--force` pour l'outil `dropdb`

</div>

<div class="notes">

Dans les versions précédentes de PostgreSQL, une erreur est levée si une
connexion existe sur la base que l'on souhaite supprimer :

```
ERROR:  database "dropme" is being accessed by other users
DETAIL:  There is 1 other session using the database.
```

C'est toujours le cas par défaut ! Cependant, il est désormais possible de
demander à la commande de tenter de déconnecter les personnes actives sur la
base désignée afin d'en terminer la suppression :

* pour la commande SQL avec l'option `FORCE`:
  
  ```
  DROP DATABASE dropme WITH (FORCE);
  ```
* pour la commande `dropdb` avec l'argument `--force`:
  
  ```
  dropdb --force dropme
  ```

Exemple:

~~~
$ createdb dropme

$ psql -qc "select pg_sleep(3600)" dropme &
[1] 16426

$ dropdb dropme
dropdb: error: database removal failed: ERROR:  database "dropme" is being accessed by other users
DETAIL:  There is 1 other session using the database.

$ dropdb --force --echo dropme
SELECT pg_catalog.set_config('search_path', '', false);
DROP DATABASE dropme WITH (FORCE);

FATAL:  terminating connection due to administrator command
[1]+  Exit 2                  psql -qc "select pg_sleep(3600)" dropme
~~~

</div>
