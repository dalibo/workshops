<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=b0f6c437160db640d4ea3e49398ebc3ba39d1982

-->

<div class="slide-content">

  * Suppression des variables en lecture seule :
    + `lc_collate`
    + `lc_ctype`

</div>

<div class="notes"> PostgreSQL 16 supprime ces deux variables. À l'origine
valables pour l'instance toute entière, elles sont devenues locales à chaque
base de données avec la sortie de la version 8.4. Rendues uniquement
consultables, elles peuvent même porter à confusion étant donné que la valeur
définie n'est pas nécessairement appliquée aux bases de l'instance.

Le message d'erreur suivant apparaitra lors d'une tentative de consultation :

```sql
psql (16.1)
Type "help" for help.

postgres=# show lc_collate ;
ERROR:  unrecognized configuration parameter "lc_collate"
postgres=# show lc_ctype;
ERROR:  unrecognized configuration parameter "lc_ctype"
```

</div>
