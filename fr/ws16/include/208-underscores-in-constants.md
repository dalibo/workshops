<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=faff8f8e47f18c7d589453e2e0d841d2bd96c1ac

Discussions :

* https://postgr.es/m/84aae844-dc55-a4be-86d9-4f0fa405cc97%40enterprisedb.com

-->

<div class="slide-content">

  * Utilisation autorisée des `_` dans les nombres
  * Améliore la lisibilité
  * `1000000 = 1_000_000`

</div>

<div class="notes">

Cette amélioration permet d'utiliser le tiret bas (ou _underscore_) lors de
l'utilisation d'entiers ou de numériques. La lisibilité est alors grandement
améliorée.

Par exemple, une insertion de `9_999_999` ne relève plus d'erreur avec
PostgreSQL 16.

```sql
# En version 15
postgres=# insert into t1 values (9_999_999);
ERROR:  trailing junk after numeric literal at or near "9_"
LINE 1: insert into t1 values (9_999_999);

# En version 16
postgres=# insert into t1 values (9_999_999);
INSERT 0 1
```

Un autre exemple de ce qu'il est possible de faire avec des entiers dans deux
bases différentes (base 10 et base 2) :

```sql
postgres=# select 1_000_000_000 + 0b_1000_0000 as result;
   result
------------
 1000000128
(1 row)
```

</div>
