<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/E1mnSso-00014n-V3@gemulon.postgresql.org

-->

<div class="slide-content">

 * `starts_with()` et son opérateur `^@` sont indexables directement avec un
   btree avec une collation C
   + fonctionnement similaire à `LIKE 'chaine%'`
   + conversion en deux prédicats `>=`, `<`
 * Si un index SPGist utilisable existe, `LIKE 'chaine%'` est transformé en
   `^@`

</div>

<div class="notes">

Le planificateur est désormais capable de traiter la fonction `starts_with()` et
l'opérateur équivalent `^@` de la même manière que l'expression `chaine LIKE
'foo%'`. Le prédicat est transformé en deux conditions `>=` et `<` qui sont
indexables si la collation est `C`.

Voici un exemple :

```sql
CREATE TABLE startswith(t text);
INSERT INTO startswith SELECT 'commence par ' || i FROM generate_series(1,10000) AS  F(i);
CREATE INDEX ON startswith USING btree (t COLLATE "C");
ANALYZE startswith;

EXPLAIN (COSTS OFF)
  SELECT *
    FROM startswith
   WHERE starts_with(t, 'commence par 1');
```
```text
                                      QUERY PLAN
--------------------------------------------------------------------------------------
 Bitmap Heap Scan on startswith
   Filter: starts_with(t, 'commence par 1'::text)
   ->  Bitmap Index Scan on startswith_t_idx
         Index Cond: ((t >= 'commence par 1'::text) AND (t < 'commence par 2'::text))
(4 rows)
```

On voit dans l'exemple suivant que si la collation est différente de `C`,
l'usage de l'index est impossible.

```sql
DROP INDEX startswith_t_idx ;
CREATE INDEX ON startswith USING btree (t COLLATE "fr_FR.utf8");

EXPLAIN (COSTS OFF)
  SELECT *
    FROM startswith
   WHERE starts_with(t, 'commence par 1');
```
```text
                    QUERY PLAN
--------------------------------------------------
 Seq Scan on startswith
   Filter: starts_with(t, 'commence par 1'::text)
(2 rows)
```

Si un index SP-Gist existe, l'index peut être utilisé, comme le montre cet
exemple.

```sql
DROP INDEX startswith_t_idx;
CREATE INDEX ON startswith USING spgist (t);
EXPLAIN (COSTS OFF)
  SELECT *
    FROM startswith
   WHERE starts_with(t, 'commence par 1');
```
```text
                      QUERY PLAN
------------------------------------------------------
 Index Only Scan using startswith_t_idx on startswith
   Index Cond: (t ^@ 'commence par 1'::text)
   Filter: starts_with(t, 'commence par 1'::text)
(3 rows)
```

Dans ce cas, les prédicats du type `chaine LIKE 'foo%'` sont transformés avec
l'opérateur `^@` pour tirer parti de l'index.

```sql
EXPLAIN (COSTS OFF)
  SELECT *
    FROM startswith
   WHERE t LIKE 'commence par 1%';
```
```text
                      QUERY PLAN
------------------------------------------------------
 Index Only Scan using startswith_t_idx on startswith
   Index Cond: (t ^@ 'commence par 1'::text)
   Filter: (t ~~ 'commence par 1%'::text)
(3 rows)
```

</div>
