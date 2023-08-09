<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=1939d26282b27b4b264c6930830a7991ed83917a

Discussion :

* https://postgr.es/m/3bbbb0df-7382-bf87-9737-340ba096e034@postgrespro.ru

-->

<div class="slide-content">

  * Deux nouvelles fonctions
    + `pg_input_is_valid()`
    + `pg_input_error_info()`

</div>

<div class="notes">

Deux nouvelles fonctions sont disponibles et permettent de vérifier qu'une
valeur est conforme à un type de données.

La fonction `pg_input_is_valid()` renvoie `true` / `false` selon si la valeur et
le type coïncident. 

La fonction `pg_input_error_info()` quant à elle renvoie
plusieurs informations (message, detail, hint, sql_error_code) si les deux ne
coïncident pas, NULL dans le cas contraire.

```sql
# valide
postgres=# select pg_input_is_valid('2005', 'integer');
 pg_input_is_valid 
-------------------
 t
(1 row)

# invalide
postgres=# select pg_input_is_valid('dalibo', 'integer');
 pg_input_is_valid 
-------------------
 f
(1 row)

# valide
postgres=# select * from  pg_input_error_info('2005', 'integer');
 message | detail | hint | sql_error_code 
---------+--------+------+----------------
         |        |      | 
(1 row)

# invalide
postgres=# select * from  pg_input_error_info('dalibo', 'integer');
                     message                     | detail | hint | sql_error_code 
-------------------------------------------------+--------+------+----------------
 invalid input syntax for type integer: "dalibo" |        |      | 22P02
(1 row)
```

</div>
