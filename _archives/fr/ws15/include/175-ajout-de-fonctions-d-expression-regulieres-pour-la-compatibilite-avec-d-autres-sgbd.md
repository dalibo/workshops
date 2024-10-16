<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/E1mAxuZ-0005mu-Oo@gemulon.postgresql.org

-->

<div class="slide-content">

 * Nouvelles fonctions :
   + `regexp_count()`
   + `regexp_instr()`
   + `regexp_like()`
   + `regexp_substr()`
 * Fonction améliorée :
   + `regexp_replace()`

</div>

<div class="notes">

Les [fonctions] `regexp_count()`, `regexp_instr()`, `regexp_like()` et `regexp_substr()`
ont été ajoutées à PostgreSQL afin d'augmenter la compatibilité avec les autres
SGBD et de faciliter la réalisation de certaines tâches. La fonction
`regexp_replace()` a également été étendue.

[fonctions]: https://www.postgresql.org/docs/15/functions-string.html#FUNCTIONS-STRING-OTHER

La **fonction `regexp_count()`** permet de compter le nombre de fois qu'une
expression régulière trouve une correspondance dans la chaine placée en entrée.

```text
regexp_count(
    string text
    , pattern text
    [, start integer[, flags text]]
) → integer`
```

Note: la liste des [flags] se trouve dans la documentation, certaines fonctions
ont des flags supplémentaires comme `g` qui permet de sélectionner toutes les
occurrences.

[flags]: https://www.postgresql.org/docs/15/functions-matching.html#POSIX-EMBEDDED-OPTIONS-TABLE

Il y a une occurrence d'une chaîne contenant une lettre en minuscule suivie de 3
nombres dans la chaine d'entrée si l'on commence à la position 5.

```sql
SELECT regexp_count('a125 a5 a661 B12 lmlm', '[a-z][\d]{3}', 5);
```
```text
 regexp_count
--------------
            1
(1 row)
```

La **fonction `regexp_instr()`** permet de renvoyer la position de la première
occurrence qui correspond à l'expression régulière dans la chaine placée en
entrée ou zéro si elle n'est pas trouvée.

```text
regexp_instr(
    string text
    , pattern text
    [, start integer[, N integer[, endoption integer[, flags text[, subexpr integer]]]]]
) → integer
```

Si on reprend l'exemple précédent, la position de la première occurrence de
l'expression régulière dans la chaîne placée en entrée en commençant la
recherche à la position 5 est 9.

```sql
SELECT regexp_instr('a125 a5 a661 B12 lmlm', '[a-z][\d]{3}', 5);
```
```text
 regexp_instr
--------------
            9
(1 row)
```

La **fonction `regexp_like()`** permet de renvoyer `true` s'il y a une
occurrence qui correspond à l'expression régulière dans la chaine placée en
entrée, `false` sinon.

```text
regexp_like(
    string text
    , pattern text[, flags text]
) → boolean
```

Voici un exemple qui illustre le fonctionnement de cette fonction.


```sql
SELECT regexp_like('a125 a5 a661 B12 lmlm', '[a-z][\d]{3}') AS "regex 1",
       regexp_like('a125 a5 a661 B12 lmlm', '[a-z]{2}[\d]{3}') AS "regex 2";
```
```text
regex 1 | regex 2
---------+---------
 t       | f
(1 row)
```

La **fonction `regexp_substr()`** permet de renvoyer la chaine qui correspond à
la Nème occurrence de l'expression régulière ou NULL s'il n'y a pas d'occurrence.


```text
regexp_substr(
    string text
    , pattern text
    [, start integer[, N integer[, flags text[, subexpr integer]]]]
) → text
```

```sql
SELECT regexp_substr('a125 a5 a661 B12 lmlm', '[a-z][\d]{3}') AS "regex 1",
       regexp_substr('a125 a5 a661 B12 lmlm', '[a-z][\d]{3}', 1, 2) AS "regex 2",
       regexp_substr('a125 a5 a661 B12 lmlm', '([a-z])([\d]{3})', 1, 2, 'i', 2) AS "regex 3" \gx
```
```text
-[ RECORD 1 ]-
regex 1 | a125  -- première occurrence
regex 2 | a661  -- seconde occurrence
regex 3 | 661   -- seconde occurrence seconde sous expression (parenthèses)
```

La **fonction `regexp_replace()`** permet de remplacer la Nème occurrence d'une
chaîne de caractère qui correspond à l'expression régulière par une autre
chaine de caractère dans la chaine fournie en entrée. Son fonctionnement a été
étendu en version 15 pour permettre de spécifier une position de départ et un
nombre d'expressions à remplacer.

```text
regexp_replace(
    string text
    , pattern text
    , replacement text
    [, start integer[, flags text]]

regexp_replace(
    string text
    , pattern text
    , replacement text
    , start integer
    , N integer
    [, flags text]
) → text
```

Cet exemple remplace la seconde occurrence de l'expression régulière par
'PostgreSQL'.

```sql
SELECT regexp_replace(e'Un Oracle a prédit le succès de Oracle', 'Oracle', 'PostgreSQL', 1, 2);
```
```text
               regexp_replace
--------------------------------------------
 Un Oracle a prédit le succès de PostgreSQL
(1 row)
```

Avec le flag `g`, il est facile de remplacer toutes les occurrences repérées
par 'PostgreSQL'.

```
SELECT regexp_replace('oracle SQLServer Mysql', '(Oracle|\w*SQL\w*)', 'PostgreSQL', 'gi');
```
```
          regexp_replace
----------------------------------
 PostgreSQL PostgreSQL PostgreSQL
(1 row)
```

</div>
