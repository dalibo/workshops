<!--
Les commits sur ce sujet sont :
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=6ee30209a6f161d0a267a33f090c70c579c87c00

Discussion :

* https://postgr.es/m/CAF4Au4w2x-5LTnN_bxky-mq4=WOqsGsxSpENCzHRAzSnEd8+WQ@mail.gmail.com
* https://postgr.es/m/cd0bb935-0158-78a7-08b5-904886deac4b@postgrespro.ru
* https://postgr.es/m/20220616233130.rparivafipt6doj3@alap3.anarazel.de
* https://postgr.es/m/abd9b83b-aa66-f230-3d6d-734817f0995d%40postgresql.org

-->

<div class="slide-content">

  * Support du prédicat `IS JSON`
   + `IS NOT JSON`
   + option `WITH UNIQUE KEYS`

</div>

<div class="notes">

Le prédicat `IS JSON` est désormais implémenté dans la version 16 de PostgreSQL.
Il peut être appliqué sur des champs `text` ou `bytea` et évidemment sur des
champs `json` et `jsonb`.

Il existe quatre nouveaux predicats :

* IS JSON [VALUE]
* IS JSON ARRAY
* IS JSON OBJECT
* IS JSON SCALAR

Chacun d'eux possède également sa variante `IS NOT` qui renvoie `true` lorsque
la valeur testée ne respecte pas le standard `JSON`.

L'option `WITH UNIQUE KEYS` permet de renvoyer `false` si il existe des clés en
doublon dans la valeur testée.

Créons un petit jeu de test pour manipuler ces nouveautés :

```sql
CREATE TABLE doc (id SERIAL PRIMARY KEY, content text not NULL);

INSERT INTO doc (content) VALUES ('{"auteur": "Melanie", "titre": "Mon livre", "prix": "25", "date": "01-05-2023"}');

INSERT INTO doc (content) VALUES ('{"auteur": "Thomas", "auteur": "Thomas", "titre": "Le livre de Thomas","prix": "8", "date": "07-08-2022"}');

INSERT INTO doc (content) VALUES ('{"auteur": "Melanie", "titre": "Mon second livre", "prix": "30", "date": "10-08-2023}');
```

Regardons ce que nous renvoie `IS JSON` :
```sql
postgres=# select id, content IS JSON as valid from doc;
 id | valid 
----+-------
  1 | t
  2 | t
  3 | f
(3 rows)
```

La dernière ligne ne semble pas être du `JSON` ... en effet, il manque un `"`
après la date.

Regardons maintenant ce que retourne la même commande avec 
l'option `WITH UNIQUE KEYS`.
 
```sql
select id, content IS JSON WITH UNIQUE KEYS as valid from doc;
 id | valid 
----+-------
  1 | t
  2 | f
  3 | f
(3 rows)
```

Nous retrouvons bien la dernière ligne qui n'est pas du `JSON` mais également la
deuxième qui ne respecte pas la particularité d'avoir des clés uniques. En
effet, la clé `auteur` a été ajoutée deux fois.

Les autres prédicats servent à valider le contenu d'un `JSON`. Quelques exemples
très simples :

* IS JSON ARRAY

```sql
SELECT '{"noms": [{"interne": "production", "externe": "prod"}], "version":"1.1"}'::json ->> 'noms' IS JSON ARRAY as valid;
 valid 
-------
 t
(1 row)
SELECT '{"nom": "production", "version":"1.1"}'::json ->> 'nom' IS JSON ARRAY as valid;
 valid 
-------
 f
(1 row)
```

* IS JSON OBJECT

```sql
SELECT '{"nom": "production", "version":"1.1"}'::json IS JSON OBJECT as valid;
 valid 
-------
 t
(1 row)

SELECT '{"nom": "production", "version":"1.1"}'::json ->> 'nom' IS JSON OBJECT as valid;
 valid 
-------
 f
(1 row)

```

* IS JSON SCALAR

```sql
SELECT '{"nom": "production", "version":"1.1"}'::json ->> 'version' IS JSON SCALAR as valid;
 valid 
-------
 t
(1 row)

SELECT '{"nom": "production", "version":"RC1"}'::json ->> 'version' IS JSON SCALAR as valid;
 valid 
-------
 f
(1 row)
```

</div>
