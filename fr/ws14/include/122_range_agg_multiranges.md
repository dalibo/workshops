<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=6df7a9698bb036610c1e8c6d375e1be38cb26d5f

Discussion

* https://www.postgresql.org/message-id/flat/16d71dc8-34cf-5ebd-1ce5-ccd93c0a14f9@illuminatedcomputing.com

-->

<div class="slide-content">

* Nouveaux types `multirange`
  * permettent de créer des ensembles d'intervalles disjoints
  * fonctionnalités similaires aux types d'intervalles simples
* Nouvelles fonctions pour agréger des intervalles :
  * `range_agg()`
  * `range_intersect_agg()`
* Indexable avec `btree`, `gist` et `hash`

</div>

<div class="notes">

PostgreSQL dispose de types intervalles de valeurs depuis la version 9.2 de PostgreSQL.
Ils permettent de stocker et manipuler des intervalles pour des données de type :
`int4`, `int8`, `numeric`, `timestamp`, `timestamp with timezone` et `date`.
Différents traitements peuvent être effectués sur les données, comme :

* différence, intersection, union d'intervalles ;
* comparaison d'intervalles ;
* tests sur les bornes, l'inclusion etc.

Exemple :

```sql
SELECT x,
       lower(x) as "borne inf",
       upper(x) as "borne sup",
       x @> 2 as "contient 2",
       x @> 4 as "contient 4",
       x * '[1,2]'::int4range AS "intersection avec [1,2]"
  FROM (VALUES ('[1,4)'::int4range) ) AS F(x) \gx
```
```text
-[ RECORD 1 ]-----------+------
x                       | [1,4)
borne inf               | 1
borne sup               | 4
contient 2              | t
contient 4              | f
intersection avec [1,2] | [1,3)
```

La version 14 voit une nouvelle avancée sur ce thème : les types `multirange`.
Ces nouveaux types étendent les types d'intervalles existant pour stocker
plusieurs intervalles disjoints ensemble.

Exemple :

```sql
SELECT '{ [1,2), (2,3]}'::int4multirange \gx

```
```text
-[ RECORD 1 ]--+--------
int4multirange | {[1,2),[3,4)}
```
```sql
SELECT '{[1,5], [2,6]}'::int4multirange \gx
```
```text
-[ RECORD 1 ]--+--------
int4multirange | {[1,7)}
```

Il est possible d'effectuer des opérations similaires à celles permises sur les
intervalles simples sur ces nouveaux types :

```sql
SELECT x,
       lower(x) as "borne inf",
       upper(x) as "borne sup",
       x @> 2 as "contient 2",
       x @> 4 as "contient 4",
       x * '{[1,2],[6,7]}'::int4multirange 
         AS "intersection avec {[1,2], [6,7]}"
  FROM (VALUES ('{[1,4), [5,8)}'::int4multirange) ) 
    AS F(x) \gx
```
```text
-[ RECORD 1 ]--------------------+--------------
x                                | {[1,4),[5,8)}
borne inf                        | 1
borne sup                        | 8
contient 2                       | t
contient 4                       | f
intersection avec {[1,2], [6,7]} | {[1,3),[6,8)}
```

Ils permettent également de produire des résultats qui n'étaient pas
possibles avec des intervalles simples. Comme pour cette soustraction
d'intervalles :

```sql
SELECT '[1,5]'::int4range - '[2,3)'::int4range AS RESULT;
-- ERROR:  result of range difference would not be contiguous

SELECT '{[1,5]}'::int4multirange - '{[2,3)}'::int4multirange AS result;
```
```text
    result
---------------
 {[1,2),[3,6)}
```

De nouvelles fonctions sont également disponibles pour agréger les
intervalles. Il s'agit de `range_agg()` et `range_intersect_agg()`.

Voici un exemple d'utilisation :

```sql
CREATE TABLE planning (
  classe text,
  salle text,
  plage_horaire tsrange,
  matiere text
);

INSERT INTO planning(classe, salle, plage_horaire, matiere)
VALUES
  (1, 'Salle 1', '[2021-07-19  9:00, 2021-07-19 10:00)'::tsrange, 'math'),
  (1, NULL,      '[2021-07-19 10:00, 2021-07-19 10:15)'::tsrange, 'recreation'),
  (1, 'Salle 2', '[2021-07-19 10:15, 2021-07-19 12:15)'::tsrange, 'français'),
  (1, NULL,      '[2021-07-19 12:15, 2021-07-19 14:15)'::tsrange, 'repas / recreation'),
  (1, 'Salle 2', '[2021-07-19 14:15, 2021-07-19 15:15)'::tsrange, 'anglais'),
  (2, 'Salle 1', '[2021-07-19  8:00, 2021-07-19 10:00)'::tsrange, 'physique'),
  (2, NULL,      '[2021-07-19 10:00, 2021-07-19 10:15)'::tsrange, 'recreation'),
  (2, 'Salle 1', '[2021-07-19 10:15, 2021-07-19 12:45)'::tsrange, 'technologie'),
  (2, NULL,      '[2021-07-19 12:45, 2021-07-19 14:15)'::tsrange, 'repas / recreation'),
  (2, 'Salle 1', '[2021-07-19 14:15, 2021-07-19 16:15)'::tsrange, 'math'),
  (3, 'Salle 2', '[2021-07-19 14:15, 2021-07-19 15:15)'::tsrange, 'allemand')
;
```

Planning par classe et salle :

```sql
SELECT classe, salle, range_agg(plage_horaire) AS plages_horaires
  FROM planning
 WHERE salle IS NOT NULL 
 GROUP BY classe, salle
 ORDER BY classe, salle;
```
```text
 classe |  salle  |               plages_horaires
--------+---------+--------------------------------------------------
 1      | Salle 1 | {["2021-07-19 09:00:00","2021-07-19 10:00:00")}
 1      | Salle 2 | {["2021-07-19 10:15:00","2021-07-19 12:15:00"),
        |         |  ["2021-07-19 14:15:00","2021-07-19 15:15:00")}
 2      | Salle 1 | {["2021-07-19 08:00:00","2021-07-19 10:00:00"),
        |         |  ["2021-07-19 10:15:00","2021-07-19 12:45:00"),
        |         |  ["2021-07-19 14:15:00","2021-07-19 16:15:00")}
 3      | Salle 2 | {["2021-07-19 14:15:00","2021-07-19 15:15:00")}
(4 rows)
```

Collisions dans l'utilisation des salles :

```sql
WITH planning_par_classe_et_salle (classe, salle, plages_horaires) AS (
  SELECT classe, salle, range_agg(plage_horaire) AS plages_horaires
    FROM planning
   WHERE salle IS NOT NULL
   GROUP BY classe, salle
)
SELECT salle, 
       range_intersect_agg(plages_horaires) as plages_horaires,
       array_agg(classe) as classes
  FROM planning_par_classe_et_salle
 GROUP BY salle HAVING count(*) > 1
 ORDER BY salle;
```
```text
  salle  |                 plages_horaires                 | classes
---------+-------------------------------------------------+---------
 Salle 1 | {["2021-07-19 09:00:00","2021-07-19 10:00:00")} | {1,2}
 Salle 2 | {["2021-07-19 14:15:00","2021-07-19 15:15:00")} | {3,1}
(2 rows)
```

Voici la liste des index qui supportent ces nouveaux types et les opérations
indexables :

```sql
SELECT a.amname, of.opfname, t1.typname as lefttype, 
        t2.typname as righttyp, o.oprname, o.oprcode
  FROM pg_amop ao
 INNER JOIN pg_am a ON ao.amopmethod = a.oid
 INNER JOIN pg_opfamily of ON ao.amopfamily = of.oid
 INNER JOIN pg_type t1 ON ao.amoplefttype = t1.oid
 INNER JOIN pg_type t2 ON ao.amoplefttype = t2.oid
 INNER JOIN pg_operator o ON ao.amopopr = o.oid
 WHERE of.opfname LIKE '%multirange%';
```
```text
 amname |    opfname     |   lefttype    |   righttyp    | oprname |              oprcode
--------+----------------+---------------+---------------+---------+------------------------------------
 gist   | multirange_ops | anymultirange | anymultirange | <<      | multirange_before_multirange
 gist   | multirange_ops | anymultirange | anymultirange | <<      | multirange_before_range
 gist   | multirange_ops | anymultirange | anymultirange | &<      | multirange_overleft_multirange
 gist   | multirange_ops | anymultirange | anymultirange | &<      | multirange_overleft_range
 gist   | multirange_ops | anymultirange | anymultirange | &&      | multirange_overlaps_multirange
 gist   | multirange_ops | anymultirange | anymultirange | &&      | multirange_overlaps_range
 gist   | multirange_ops | anymultirange | anymultirange | &>      | multirange_overright_multirange
 gist   | multirange_ops | anymultirange | anymultirange | &>      | multirange_overright_range
 gist   | multirange_ops | anymultirange | anymultirange | >>      | multirange_after_multirange
 gist   | multirange_ops | anymultirange | anymultirange | >>      | multirange_after_range
 gist   | multirange_ops | anymultirange | anymultirange | -|-     | multirange_adjacent_multirange
 gist   | multirange_ops | anymultirange | anymultirange | -|-     | multirange_adjacent_range
 gist   | multirange_ops | anymultirange | anymultirange | @>      | multirange_contains_multirange
 gist   | multirange_ops | anymultirange | anymultirange | @>      | multirange_contains_range
 gist   | multirange_ops | anymultirange | anymultirange | <@      | multirange_contained_by_multirange
 gist   | multirange_ops | anymultirange | anymultirange | <@      | multirange_contained_by_range
 gist   | multirange_ops | anymultirange | anymultirange | @>      | multirange_contains_elem
 gist   | multirange_ops | anymultirange | anymultirange | =       | multirange_eq
 btree  | multirange_ops | anymultirange | anymultirange | <       | multirange_lt
 btree  | multirange_ops | anymultirange | anymultirange | <=      | multirange_le
 btree  | multirange_ops | anymultirange | anymultirange | =       | multirange_eq
 btree  | multirange_ops | anymultirange | anymultirange | >=      | multirange_ge
 btree  | multirange_ops | anymultirange | anymultirange | >       | multirange_gt
 hash   | multirange_ops | anymultirange | anymultirange | =       | multirange_eq
```

La lecture du catalogue nous montre que les opérations simples (exp : `=`, `>`, `<`)
peuvent être indexées avec un `btree`. En revanche, pour les opérations plus
complexes (appartenance, proximité ...), il faut utiliser un index `gist`.
<!--

Exemple conservés en commentaire pour la postérité :)

```
CREATE OR REPLACE FUNCTION gen_nummultirange(max_ranges int, max_numeric numeric) 
  RETURNS nummultirange 
  LANGUAGE plpgsql 
  AS $$
DECLARE 
  _cnt int;
  _min numeric;
  _max numeric;
  _n nummultirange;
BEGIN
  _min := random()*10::numeric;
  _max := random()*10::numeric + _min;
  _n := nummultirange(numrange(_min, _max, '[)'));
  FOR _cnt IN 1..random()*max_ranges LOOP
    _min := random()*max_numeric;
    _max := random()*max_numeric + _min;
    _n := nummultirange(numrange(_min, _max, '[)')) + _n;
  END LOOP;
  RETURN _n;
END;
$$;

CREATE TABLE nummultiranges AS 
  SELECT x, gen_nummultirange(5, 10000::numeric) as r FROM generate_series(1,1000000) AS F(x)
  UNION
  SELECT 0, '{[0.0, 0.1]}'::nummultirange;
```

Création d'un index btree :

```
CREATE INDEX idx_nummultiranges_btree ON nummultiranges USING btree(r);
```

On voit que ce type d'index peut être utilisé pour une égalité :

```
# EXPLAIN (ANALYZE, COSTS off) SELECT * FROM nummultiranges WHERE r = '{[0.0,0.1]}'::nummultirange;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using idx_nummultiranges_btree on nummultiranges (actual time=1.895..1.899 rows=1 loops=1)
   Index Cond: (r = '{[0.0,0.1]}'::nummultirange)
 Planning Time: 0.223 ms
 Execution Time: 1.935 ms
(4 rows)
```

Création d'un index gist :

```
CREATE INDEX idx_nummultiranges_gist ON nummultiranges USING gist(r);
```

On voit que dans ce cas l'optimiseur préfère cet index à l'index btree :

```
# EXPLAIN (ANALYZE, COSTS off) SELECT * FROM nummultiranges WHERE r = '{[0.0,0.1]}'::nummultirange;
                                              QUERY PLAN
------------------------------------------------------------------------------------------------------
 Index Scan using idx_nummultiranges_gist on nummultiranges (actual time=0.131..0.133 rows=1 loops=1)
   Index Cond: (r = '{[0.0,0.1]}'::nummultirange)
 Planning Time: 0.132 ms
 Execution Time: 0.168 ms
(4 rows)
```

Voci quelques exemples d'autres opérateurs supportés :

```
localhost:5444 postgres@postgres=# EXPLAIN (ANALYZE) SELECT * FROM nummultiranges WHERE r @> '{[100,101)}'::nummultirange
;
                                                       QUERY PLAN
------------------------------------------------------------------------------------------------------------------------
 Seq Scan on nummultiranges  (cost=0.00..26070.01 rows=899782 width=76) (actual time=0.106..298.815 rows=24866 loops=1)
   Filter: (r @> '{[100,101)}'::nummultirange)
   Rows Removed by Filter: 975135
 Planning Time: 0.349 ms
 Execution Time: 299.492 ms
(5 rows)

localhost:5444 postgres@postgres=# EXPLAIN (ANALYZE) SELECT * FROM nummultiranges WHERE r @> '{[0.0,0.1)}'::nummultirange
;
                                                               QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_nummultiranges_gist on nummultiranges  (cost=0.41..8.43 rows=1 width=76) (actual time=3.676..3.680 rows=1 loops=1)
   Index Cond: (r @> '{[0.0,0.1)}'::nummultirange)
 Planning Time: 0.178 ms
 Execution Time: 3.718 ms
(4 rows)

localhost:5444 postgres@postgres=# EXPLAIN (ANALYZE) SELECT * FROM nummultiranges WHERE r >> '{[100,110]}'::nummultirange
;
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_nummultiranges_gist on nummultiranges  (cost=0.41..8.43 rows=1 width=76) (actual time=1658.175..1658.176 rows=0 loops=1)
   Index Cond: (r >> '{[100,110]}'::nummultirange)
 Planning Time: 2.334 ms
 Execution Time: 1658.241 ms
(4 rows)
```

-->

La documentation détaille l'ensemble des
[opérateurs](https://docs.postgresql.fr/14/functions-range.html#RANGE-OPERATORS-TABLE),
[fonctions](https://docs.postgresql.fr/14/functions-range.html#RANGE-FUNCTIONS-TABLE),
et [agrégats](https://docs.postgresql.fr/14/functions-aggregate.html)
disponibles pour ce nouveau
[type](https://docs.postgresql.fr/14/rangetypes.html#RANGETYPES-BUILTIN).
</div>
