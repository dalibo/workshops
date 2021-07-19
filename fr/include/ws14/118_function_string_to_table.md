<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=66f163068030b5c5fe792a0daee27822dac43791

Discussion

* https://www.postgresql.org/message-id/flat/CAFj8pRD8HOpjq2TqeTBhSo_QkzjLOhXzGCpKJ4nCs7Y9SQkuPw@mail.gmail.com

-->

<div class="slide-content">

* Nouvelle fonction pour subdiviser une chaîne de caractère et renvoyer le
  résultat dans une table :
  * `text` : chaîne de caractères à taiter
  * `text` : séparateur
  * `text` : chaîne de caractères à remplacer par `NULL` si rencontrée 
* Alternative plus performante à `regexp_split_to_table()` et
  `unnest(string_to_array())`.

</div>

<div class="notes">

Une nouvelle fonction a été créé pour subdiviser une chaine de caractères et
renvoyer le résultat dans une table :

```sql
# \df string_to_table
                              List of functions
   Schema   |      Name       | Result data type | Argument data types | Type
------------+-----------------+------------------+---------------------+------
 pg_catalog | string_to_table | SETOF text       | text, text          | func
 pg_catalog | string_to_table | SETOF text       | text, text, text    | func
(2 rows)
```

Exemple d'utilisation :

```sql
# \pset null '¤'
# SELECT string_to_table('une chaine à ignorer', ' ', 'ignorer');
 string_to_table
-----------------
 une
 chaine
 à
 ¤
(4 rows)
```

Dans les versions précédentes, ce genre d'opération était déjà possible avec
les fonctions `unnest(string_to_array())` et `regexp_split_to_table()`.
L'avantage de cette nouvelle fonction est qu'elle est beaucoup plus performante
car plus spécialisée.

</div>
