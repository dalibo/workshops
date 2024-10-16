<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=676887a3b0b8e3c0348ac3f82ab0d16e9a24bd43

Discussion

* https://postgr.es/m/CA%2Bq6zcV8qvGcDXurwwgUbwACV86Th7G80pnubg42e-p9gsSf%3Dg%40mail.gmail.com
* https://blog.crunchydata.com/blog/better-json-in-postgres-with-postgresql-14

-->

<div class="slide-content">

* Nouvelle syntaxe d'accès aux éléments d'une colonne `jsonb`
* Expressions avec indice, de style tableau

  ```sql
  SELECT ('{"a": 1}'::jsonb)['a'];
  SELECT * FROM table_name WHERE jsonb_field['key'] = '"value"';
  UPDATE table_name SET jsonb_field['key'] = '1';
  ```

</div>

<div class="notes">

Cette nouvelle version de PostgreSQL apporte une nouvelle syntaxe pour extraire
ou modifier les éléments d'une colonne `jsonb`. À l'instar des opérateurs `->` et
`->>`, il est à présent possible de manipuler les éléments à la manière d'un
tableau avec l'indiçage (_subscripting_).

<!--
```sql
CREATE TABLE products (id bigint, product jsonb);
INSERT INTO products VALUES 
  (100, '{"name": "Arbre à chat tonneau Aurelio", "brand": "AniOne", 
          "price": 189, "color": "grey", "dimension": 
            {"h": 40, "L": 40, "l": 100, "unit": "cm"}}'),
  (101, '{"name": "Griffoir tonneau Tobi", "brand": "AniOne", "price": 169}'),
  (102, '{"name": "Arbre à chat Natural Harmony", "brand": "Europet Bernina",
          "price": 29.99}'),
  (103, '{"name": "Échelle d''escalade pour fixation murale", "brand": 
          "Trixie", "price": 53.69, "color": "taupe"}'),
  (104, '{"name": "Grattoir mural Dolomit 2.0 Tofana", "brand": "Kerbl", 
          "price": 112, "dimension":
            {"h": 160, "l": 75, "unit": "cm"}}');
```
-->

Les deux requêtes suivantes sont similaires :

```sql
SELECT id, product->'name' AS product, product->'price' AS price 
  FROM products WHERE product->>'brand' = 'AniOne';

SELECT id, product['name'] AS product, product['price'] AS price
  FROM products WHERE product['brand'] = '"AniOne"';
```
```sh
 id  |            product             | price 
-----+--------------------------------+-------
 100 | "Arbre à chat tonneau Aurelio" | 189
 101 | "Griffoir tonneau Tobi"        | 169
```

Cependant, l'opérateur `->>` permettant d'extraire la valeur d'un élément textuel
n'a pas d'équivalent et il est nécessaire d'ajouter les guillemets pour réaliser
des comparaisons, par exemple.

L'extraction de valeurs imbriquées est également possible avec cette syntaxe. La 
mise à jour d'un élément est aussi supportée comme le montre l'exemple suivant :

```sql
UPDATE products SET product['dimension']['L'] = '50' WHERE id = 100; 
```

</div>
