<!--
Les commits sur ce sujet sont :
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=1349d2790
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=3226f4728

Discussion :

* https://postgr.es/m/CAApHDvpHzfo92%3DR4W0%2BxVua3BUYCKMckWAmo-2t_KiXN-wYH%3Dw%40mail.gmail.com

-->

<div class="slide-content">

  * Pour les clauses ORDER BY et DISTINCT dans des agrégats
    + par exemple `string_agg(nom, ',' ORDER BY nom)`
  * Possibilité d'utiliser
    + parcours d'index
    + tri incrémental

</div>

<div class="notes">

Certaines fonctions d'agrégat, comme `string_agg` ou `array_agg` peuvent
indiquer les clauses `ORDER BY` et `DISTINCT`. Ces clauses nécessitent de trier
les données et PostgreSQL a plusieurs moyens pour cela : le nœud _Sort_ qui trie
les données à l'exécution de la requête (et donc ralentit la récupération du
résultat) et les nœuds _Index Scan_ et _Index Only Scan_ qui parcourent un index dans
l'ordre et récupèrent donc les données pré-triées. Une clause `ORDER BY` en fin
d'un `SELECT` peut utiliser ces différents nœuds. Par contre, une clause `ORDER
BY` ne peut pas le faire si elle est utilisée dans un agrégat. La version 16
ajoute cette possibilité, comme le montre cet exemple :

```sql
create table t3(c1 integer, c2 text);
insert into t3 select i, 'ligne '||i from generate_series(1, 1000000) i;
analyze;

explain select string_agg(c2, ',' order by c2) from t3;

                               QUERY PLAN                                
-------------------------------------------------------------------------
 Aggregate  (cost=138022.35..138022.36 rows=1 width=32)
   ->  Sort  (cost=133022.34..135522.34 rows=1000000 width=12)
         Sort Key: c2
         ->  Seq Scan on t3  (cost=0.00..16274.00 rows=1000000 width=12)
(4 rows)
```

Sans index, PostgreSQL ne peut que passer par un nœud _Sort_. Par contre, si on
crée un index :

```
create index on t3(c2);

explain select string_agg(c2, ',' order by c2) from t3;

                                QUERY PLAN
-------------------------------------------------------------------------
 Aggregate  (cost=45138.36..45138.37 rows=1 width=32)
   ->  Index Only Scan using t3_c2_idx on t3
       (cost=0.42..42638.36 rows=1000000 width=12)
(2 rows)
```

Cette fois, l'index est utilisé. Le coût estimé chûte fortement.

La version 16 permet aussi d'utiliser un tri incrémental :

```
explain select string_agg(c2, ',' order by c2,c1) from t3;

                                QUERY PLAN
-------------------------------------------------------------------------
 Aggregate  (cost=90138.36..90138.37 rows=1 width=32)
   ->  Incremental Sort  (cost=0.48..87638.36 rows=1000000 width=16)
         Sort Key: c2, c1
         Presorted Key: c2
         ->  Index Scan using t3_c2_idx on t3
             (cost=0.42..42638.36 rows=1000000 width=16)
(5 rows)
```

Ce nouveau comportement dépend du paramètre `enable_presorted_aggregate`. En
le désactivant, nous récupérons l'ancien fonctionnement.

```
show enable_presorted_aggregate;

 enable_presorted_aggregate 
----------------------------
 on
(1 row)

set enable_presorted_aggregate to off;

explain select string_agg(c2, ',' order by c2,c1) from t3;

                            QUERY PLAN                             
-------------------------------------------------------------------
 Aggregate  (cost=18774.00..18774.01 rows=1 width=32)
   ->  Seq Scan on t3  (cost=0.00..16274.00 rows=1000000 width=16)
(2 rows)
```

</div>
