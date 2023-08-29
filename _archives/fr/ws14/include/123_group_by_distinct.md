<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=be45be9c33a85e72cdaeb9967e9f6d2d00199e09

Discussion

* https://www.postgresql.org/message-id/flat/bf3805a8-d7d1-ae61-fece-761b7ff41ecc@postgresfriends.org

-->

<div class="slide-content">
  * Dédoublonnage des résultats d'agrégations multiples produit par un `GROUP BY`
  * Utile avec `ROLLUP` ou `CUBE`
</div>

<div class="notes">

Lorsque l'on combine plusieurs méthodes d'agrégation comme `ROLLUP` ou `CUBE`,
il est fréquent de se retrouver avec des doublons. Le standard SQL prévoit de
dédupliquer le résultat de ce genre de requête avec la syntaxe `GROUP BY
DISTINCT`. Elle a été implémentée dans PostgreSQL.

Voici un exemple : 

```sql
cat <<_EOF_ | psql
CREATE TABLE entreprise(nom text, departement int, ville text, creation date, montant int);
COPY entreprise FROM STDIN WITH DELIMITER ',' CSV;
entreprise1,44,Nantes,20210506,1000
entreprise2,44,Nantes,20200506,200
entreprise3,29,Brest,20200605,3000
entreprise4,29,Brest,20200406,4000
\.
_EOF_
```

En exécutant cette requête, on voit que certaines lignes sont en double :

```sql
SELECT row_number() OVER(), departement, ville, 
       extract(YEAR FROM  creation) as year, 
       avg(montant)::int as montant
  FROM entreprise 
 GROUP BY rollup(departement, ville),
          rollup(departement, year);
```
```sh
 row_number | departement |  ville  | year | montant 
------------+-------------+---------+------+---------
          1 |           ¤ | ¤       |    ¤ |    2050
          2 |          44 | Nantes  | 2021 |    1000
          3 |          44 | Nantes  | 2020 |     200
          4 |          29 | Brest   | 2020 |    3500
          5 |          29 | Brest   |    ¤ |    3500
          6 |          44 | Nantes  |    ¤ |     600
          7 |          29 | Brest   |    ¤ |    3500 << DOUBLON DE 5
          8 |          44 | Nantes  |    ¤ |     600 << DOUBLON DE 6
          9 |          44 | ¤       |    ¤ |     600
         10 |          29 | ¤       |    ¤ |    3500
         11 |          44 | ¤       |    ¤ |     600 << DOUBLON DE 9
         12 |          29 | ¤       |    ¤ |    3500 << DOUBLON DE 10
         13 |          44 | ¤       |    ¤ |     600 << DOUBLON DE 9
         14 |          29 | ¤       |    ¤ |    3500 << DOUBLON DE 10
         15 |          29 | ¤       | 2020 |    3500
         16 |          44 | ¤       | 2020 |     200
         17 |          44 | ¤       | 2021 |    1000
         18 |          29 | ¤       | 2020 |    3500 << DOUBLON DE 15
         19 |          44 | ¤       | 2020 |     200 << DOUBLON DE 16 
         20 |          44 | ¤       | 2021 |    1000 << DOUBLON DE 17
(20 rows)
```

L'utilisation de `GROUP BY DISTINCT` permet de régler ce problème sans étape
supplémentaire :

```sql
SELECT departement, ville, extract(YEAR FROM  creation) as year, 
       avg(montant)::int as montant
  FROM entreprise 
 GROUP BY DISTINCT rollup(departement, ville),
                   rollup(departement, year);
```
```sh
 departement |  ville  | year | montant
-------------+---------+------+---------
           ¤ | ¤       |    ¤ |    2050
          44 |  Nantes | 2021 |    1000
          44 |  Nantes | 2020 |     200
          29 |  Brest  | 2020 |    3500
          29 |  Brest  |    ¤ |    3500
          44 |  Nantes |    ¤ |     600
          44 | ¤       |    ¤ |     600
          29 | ¤       |    ¤ |    3500
          29 | ¤       | 2020 |    3500
          44 | ¤       | 2020 |     200
          44 | ¤       | 2021 |    1000
(11 rows)
```

</div>
