<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=c9d5298485b78a37923a23f9af9aa0ade06762db

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/121
* https://www.postgresql.org/message-id/flat/4165684.1607707277@sss.pgh.pa.us

-->

<div class="slide-content">

* Évolution du _parser_ de requêtes
* Supporte l'assignation de valeurs pour les types complexes en PL/pgSQL
  
```sql
  a[2:3] := array[3,4];    -- slice de tableaux  int[]
  a[1].i := 2;             -- champ de record
  h['a'] := 'b';           -- hstore
```

* et plus performants !

</div>

<div class="notes">

Le langage PL/pgSQL bénéficie d'une petite évolution dans les règles d'assignation
de valeurs pour les types complexes, tels que les lignes (_records_) ou les
tableaux (_arrays_). Le _parser_ du langage est à présent capable de reconnaître
des expressions pour les assigner avec l'opérateur `:=` dans la variable de
destination, sans contournement du langage.

Ci-dessous, une liste non-exhaustive des possibilités :

```sql
-- assigner les valeurs d'une portion d'un tableau
-- où "a" est de type int[]
a[2:3] := array[3,4];

-- assigner la valeur d'un champ de record personnalisé
-- où "a" est de type complex[]
CREATE TYPE complex AS (r float8, i float8);
a[1].r := 1;
a[1].i := 2;

-- assigner la valeur d'une clé hstore
-- où "h" est de type hstore
CREATE EXTENSION hstore;
h['a'] := 'b';
```

D'autres bénéfices sont obtenus avec cette évolution dans l'analyse de la syntaxe
de ces types d'assignations. Tom Lane, à l'origine de ce patch, [annonce][plpgsql-assignment] 
un gain de performance substantiel ainsi qu'une meilleure lisibilité des erreurs
pouvant survenir à l'assignation.

[plpgsql-assignment]: https://www.postgresql.org/message-id/flat/4165684.1607707277@sss.pgh.pa.us

Exemple en version 13 et inférieures :

```sql
DO $$ DECLARE x int := 1/0; BEGIN END $$ ;
-- ERROR:  division by zero
-- CONTEXT:  SQL statement "SELECT 1/0"
```

Exemple en version 14 :

```sql
DO $$ DECLARE x int := 1/0; BEGIN END $$ ;
-- ERROR:  division by zero
-- CONTEXT:  SQL expression "1/0"
```

</div>
