<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=bcedd8f5f

Discussions :

* https://postgr.es/m/CAEZATCUCGCf82=hxd9N5n6xGHPyYpQnxW8HneeH+uP7yNALkWA@mail.gmail.com

-->

<div class="slide-content">

  * Auparavant, l'alias était obligatoire

```sql
SELECT datname, pg_database_size(datname)
FROM (SELECT * from pg_datatase WHERE NOT datistemplate) tmp;
```

  * Maintenant, c'est optionnel

```sql
SELECT datname, pg_database_size(datname)
FROM (SELECT * from pg_datatase WHERE NOT datistemplate);
```

  * Améliore la lisibilité

</div>

<div class="notes">

Les versions antérieures à la 16 étaient très rigides sur ce point :

```sql
# En version 15, sans alias
postgres=# SELECT datname, pg_database_size(datname)
FROM (SELECT * from pg_database WHERE NOT datistemplate);

ERROR:  subquery in FROM must have an alias
LINE 2: FROM (SELECT * from pg_database WHERE NOT datistemplate);
             ^
HINT:  For example, FROM (SELECT ...) [AS] foo.

# En version 15, avec alias
postgres=# SELECT datname, pg_database_size(datname)
FROM (SELECT * from pg_database WHERE NOT datistemplate) tmp;

 datname  | pg_database_size 
----------+------------------
 postgres |          7869231
(1 row)
```

En version 16, les deux écritures sont acceptées :

```sql
# En version 16, sans alias
postgres=# SELECT datname, pg_database_size(datname)
FROM (SELECT * from pg_database WHERE NOT datistemplate);
 datname  | pg_database_size 
----------+------------------
 postgres |          7909859
(1 row)

# En version 16, avec alias
postgres=# SELECT datname, pg_database_size(datname)
FROM (SELECT * from pg_database WHERE NOT datistemplate) tmp;
 datname  | pg_database_size 
----------+------------------
 postgres |          7909859
(1 row)
```

</div>
