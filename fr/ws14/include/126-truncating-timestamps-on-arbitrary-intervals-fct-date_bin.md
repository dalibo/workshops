<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=49ab61f0bdc93984a8d36b602f6f2a15f09ebcc7

Discussion

* https://www.postgresql.org/message-id/flat/CACPNZCt4buQFRgy6DyjuZS-2aPDpccRkrJBmgUfwYc1KiaXYxg@mail.gmail.com

-->

<div class="slide-content">
* Nouvelle fonction pour répartir des timestamps dans des intervalles
  (_buckets_)
* `date_bin`
  * `interval` : taille des _buckets_ (unités `month` et `year` interdites)
  * `timestamptz` : valeur en entrée à traiter
  * `timestamptz` : timestamp correspondant au début du premier _bucket_

</div>

<div class="notes">

<!-- https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-BIN -->

La nouvelle fonction `date_bin` permet de placer un timestamp fourni en entrée 
(second paramètre) dans un intervalle aussi appellée _bucket_.

Documentation : <https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-BIN>

Les valeurs produites correspondent au timestamp en début de l'intervalle
et peuvent par exemple être utilisées pour calculer des statistiques en
regroupant les données par plages de 15 minutes.

La valeur mise en second paramètre de la fonction est placée dans un _bucket_
en se basant sur :

* Un timestamp de début (troisième paramètre).
* Une taille définie sous forme d'intervalle (premier paramètre). \
  L'unité utilisée pour définir la taille du _bucket_ peut être définie \
  en secondes, minutes, heures, jours ou semaines.

La fonction existe pour des timestamp avec et sans fuseau horaire :

```sql
\df date_bin
```
```text
List of functions
-[ RECORD 1 ]-------+-------------------------------------------------------------------
Schema              | pg_catalog
Name                | date_bin
Result data type    | timestamp with time zone
Argument data types | interval, timestamp with time zone, timestamp with time zone
Type                | func
-[ RECORD 2 ]-------+-------------------------------------------------------------------
Schema              | pg_catalog
Name                | date_bin
Result data type    | timestamp without time zone
Argument data types | interval, timestamp without time zone, timestamp without time zone
Type                | func
```

Voici un exemple de cette fonction en action :

```sql
-- Génération des données
CREATE TABLE sonde(t timestamp with time zone, id_sonde int, mesure int);
INSERT INTO sonde(t, id_sonde, mesure)
SELECT '2021-06-01 00:00:00'::timestamp with time zone + INTERVAL '1s' * x,
       1,
       sin(x*3.14/86401)*30
  FROM generate_series(0, 60*60*24) AS F(x);

-- création de buckets de 1h30 commençant à minuit le premier juin
SELECT date_bin('1 hour 30 minutes', t, '2021-06-01 00:00:00'::timestamp with time zone),
       id_sonde, avg(mesure)
  FROM sonde GROUP BY 1, 2 ORDER BY 1 ASC;
```
```text
        date_bin        | id_sonde |          avg
------------------------+----------+------------------------
 2021-06-01 00:00:00+02 |        1 |     2.9318518518518519
 2021-06-01 01:30:00+02 |        1 |     8.6712962962962963
 2021-06-01 03:00:00+02 |        1 |    14.1218518518518519
 2021-06-01 04:30:00+02 |        1 |    19.0009259259259259
 2021-06-01 06:00:00+02 |        1 |    23.1514814814814815
 2021-06-01 07:30:00+02 |        1 |    26.3951851851851852
 2021-06-01 09:00:00+02 |        1 |    28.6138888888888889
 2021-06-01 10:30:00+02 |        1 |    29.9274074074074074
 2021-06-01 12:00:00+02 |        1 |    29.9359259259259259
 2021-06-01 13:30:00+02 |        1 |    28.6224074074074074
 2021-06-01 15:00:00+02 |        1 |    26.4207407407407407
 2021-06-01 16:30:00+02 |        1 |    23.1851851851851852
 2021-06-01 18:00:00+02 |        1 |    19.0346296296296296
 2021-06-01 19:30:00+02 |        1 |    14.1690740740740741
 2021-06-01 21:00:00+02 |        1 |     8.7175925925925926
 2021-06-01 22:30:00+02 |        1 |     2.9829629629629630
 2021-06-02 00:00:00+02 |        1 | 0.00000000000000000000
(17 rows)
```

La date de début utilisée pour la création des _buckets_ ne doit pas
nécessairement coïncider avec le timestamp le plus ancien présent dans la table :

```sql
SELECT date_bin('1 hour 30 minutes', t, '2021-06-01 00:11:00'::timestamp with time zone),
       id_sonde,
       avg(mesure)
FROM sonde GROUP BY 1, 2 ORDER BY 1 ASC;
```
```text
        date_bin        | id_sonde |          avg
------------------------+----------+------------------------
 2021-05-31 22:41:00+02 |        1 | 0.30454545454545454545
 2021-06-01 00:11:00+02 |        1 |     3.6372222222222222
 2021-06-01 01:41:00+02 |        1 |     9.3907407407407407
 2021-06-01 03:11:00+02 |        1 |    14.7375925925925926
 2021-06-01 04:41:00+02 |        1 |    19.5405555555555556
 2021-06-01 06:11:00+02 |        1 |    23.5896296296296296
 2021-06-01 07:41:00+02 |        1 |    26.7618518518518519
 2021-06-01 09:11:00+02 |        1 |    28.7857407407407407
 2021-06-01 10:41:00+02 |        1 |    30.0000000000000000
 2021-06-01 12:11:00+02 |        1 |    29.8137037037037037
 2021-06-01 13:41:00+02 |        1 |    28.4772222222222222
 2021-06-01 15:11:00+02 |        1 |    26.0770370370370370
 2021-06-01 16:41:00+02 |        1 |    22.6962962962962963
 2021-06-01 18:11:00+02 |        1 |    18.4644444444444444
 2021-06-01 19:41:00+02 |        1 |    13.5207407407407407
 2021-06-01 21:11:00+02 |        1 |     8.0494444444444444
 2021-06-01 22:41:00+02 |        1 |     2.6230753005695001
(17 rows)
```

Comme dit précédemment, il n'est pas possible d'utiliser une taille de _bucket_
définie en mois ou années. Il est cependant possible de spécifier des tailles de
_bucket_ supérieures ou égales à un mois avec les autres unités :

```sql
SELECT date_bin('1 year', '2021-06-01 10:05:10', '2021-06-01');
-- ERROR:  timestamps cannot be binned into intervals containing months or years

SELECT date_bin('1 month', '2021-06-01 10:05:10', '2021-06-01');
-- ERROR:  timestamps cannot be binned into intervals containing months or years

SELECT date_bin('12 weeks', '2021-06-01 10:05:10', '2021-06-01');
```
```text
        date_bin
------------------------
 2021-06-01 00:00:00+02
(1 row)
```
```sql
SELECT date_bin('365 days', '2021-06-01 10:05:10', '2021-06-01');
```
```text
        date_bin
------------------------
 2021-06-01 00:00:00+02
(1 row)
```

<!-- https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-TRUNC -->

La fonction `date_bin` a un effet similaire à `date_trunc` lorsqu'elle est 
utilisée avec les intervalles `1 hour` et `1 minute`.

Documentation : <https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-TRUNC>

```sql
SELECT date_bin('1 hour', '2021-06-01 10:05:10'::timestamp, '2021-06-01'),
       date_trunc('hour', '2021-06-01 10:05:10'::timestamp);
```
```text
      date_bin       |     date_trunc
---------------------+---------------------
 2021-06-01 10:00:00 | 2021-06-01 10:00:00
(1 row)
```
```sql
SELECT date_bin('1 minute', '2021-06-01 10:05:10'::timestamp, '2021-06-01'),
       date_trunc('minute', '2021-06-01 10:05:10'::timestamp);
```
```text
      date_bin       |     date_trunc
---------------------+---------------------
 2021-06-01 10:05:00 | 2021-06-01 10:05:00
(1 row)
```

</div>
