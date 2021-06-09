<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=be45be9c33a85e72cdaeb9967e9f6d2d00199e09

Discussion

* https://www.postgresql.org/message-id/flat/bf3805a8-d7d1-ae61-fece-761b7ff41ecc@postgresfriends.org

-->

<div class="slide-content">
  * Dédoublonnage des résultats d'agrégations multiples produit par un `GROUP BY`
</div>

<div class="notes">

Lorsque l'on combine plusieurs méthodes d'agrégation comme `ROLLUP` ou `CUBE`,
il est fréquent de se retrouver avec des doublons. Le standard SQL prévoit de
dédupliquer le résultat de ce genre de requête avec la syntaxe `GROUP BY
DISTINCT`. Elle a été implémentée dans PostgreSQL.

Voici un exemple : 

```bash
cat <<_EOF_ > entreprise.csv
entreprise1, 44, Nantes, 20210506, 1000
entreprise2, 44, Nantes, 20200506, 200
entreprise3, 85, Brrest, 20200605, 3000
entreprise4, 85, Brest, 20200406, 4000
entreprise5, 35, Rennes, 20210102, 200
_EOF_
```

```sql
=# CREATE TABLE entreprise(nom text, departement int, ville text, creation date, montant int); 
CREATE TABLE

=# \copy entreprise FROM 'entreprise.csv' WITH DELIMITER ',' CSV
COPY 5
```

En exécutant cette requête, on voit que certaines lignes sont en double :

```sql
=# SELECT row_number() OVER(),
          departement, ville, extract(YEAR FROM  creation) as year, avg(montant) 
   FROM entreprise 
   GROUP BY rollup(departement, ville),
            rollup(departement, year);

 row_number | departement |  ville  | year |          avg
------------+-------------+---------+------+-----------------------
          1 |           ¤ | ¤       |    ¤ | 1680.0000000000000000
          2 |          44 |  Nantes | 2021 | 1000.0000000000000000
          3 |          44 |  Nantes | 2020 |  200.0000000000000000
          4 |          85 |  Brest  | 2021 |  200.0000000000000000
          5 |          85 |  Brest  | 2020 | 3500.0000000000000000
          6 |          85 |  Brest  |    ¤ | 2400.0000000000000000
          7 |          44 |  Nantes |    ¤ |  600.0000000000000000
          8 |          85 |  Brest  |    ¤ | 2400.0000000000000000 << DOUBLON DE 6
          9 |          44 |  Nantes |    ¤ |  600.0000000000000000 << DOUBLON DE 7
         10 |          44 | ¤       |    ¤ |  600.0000000000000000
         11 |          85 | ¤       |    ¤ | 2400.0000000000000000
         12 |          44 | ¤       |    ¤ |  600.0000000000000000 << DOUBLON DE 10
         13 |          85 | ¤       |    ¤ | 2400.0000000000000000 << DOUBLON DE 11
         14 |          44 | ¤       |    ¤ |  600.0000000000000000 << DOUBLON DE 10
         15 |          85 | ¤       |    ¤ | 2400.0000000000000000 << DOUBLON DE 11
         16 |          85 | ¤       | 2020 | 3500.0000000000000000
         17 |          85 | ¤       | 2021 |  200.0000000000000000
         18 |          44 | ¤       | 2020 |  200.0000000000000000
         19 |          44 | ¤       | 2021 | 1000.0000000000000000
         20 |          85 | ¤       | 2020 | 3500.0000000000000000 << DOUBLON DE 16
         21 |          85 | ¤       | 2021 |  200.0000000000000000 << DOUBLON DE 17
         22 |          44 | ¤       | 2020 |  200.0000000000000000 << DOUBLON DE 18
         23 |          44 | ¤       | 2021 | 1000.0000000000000000 << DOUBLON DE 19
(23 rows)
```

L'utilisation de `GROUP BY DISTINCT` permet de régler ce problème sans étape
supplémentaire :

```sql
=# SELECT departement, ville, extract(YEAR FROM  creation) as year, avg(montant) 
   FROM entreprise 
   GROUP BY DISTINCT rollup(departement, ville), 
                     rollup(departement, year);

 departement |  ville  | year |          avg
-------------+---------+------+-----------------------
           ¤ | ¤       |    ¤ | 1680.0000000000000000
          44 |  Nantes | 2021 | 1000.0000000000000000
          44 |  Nantes | 2020 |  200.0000000000000000
          85 |  Brest  | 2021 |  200.0000000000000000
          85 |  Brest  | 2020 | 3500.0000000000000000
          85 |  Brest  |    ¤ | 2400.0000000000000000
          44 |  Nantes |    ¤ |  600.0000000000000000
          44 | ¤       |    ¤ |  600.0000000000000000
          85 | ¤       |    ¤ | 2400.0000000000000000
          85 | ¤       | 2020 | 3500.0000000000000000
          85 | ¤       | 2021 |  200.0000000000000000
          44 | ¤       | 2020 |  200.0000000000000000
          44 | ¤       | 2021 | 1000.0000000000000000
(13 rows)
```

</div>
