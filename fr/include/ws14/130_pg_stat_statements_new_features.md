<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=6023b7ea717ca04cf1bd53709d9c862db07eaefb
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=b62e6056a05c60ce9edf93e87e1487ae50245a04
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9fbc3f318d039c3e1e8614c38e40843cf8fcffde
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=6b4d23feef6e334fb85af077f2857f62ab781848

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/130

-->

<div class="slide-content">
  * Traçage des accès faits via `CREATE TABLE AS`, `SELECT INTO`,
  `CREATE MATERIALIZED VIEW`, `REFRESH MATERIALIZED VIEW` et `FETCH`
  * Nouvelle vue `pg_stat_statements_info`
  * Nouvelle colonne `toplevel` dans la vue `pg_stat_statements`
</div>

<div class="notes">

**Statistiques plus complètes**

`pg_stat_statements` est désormais capable de comptabiliser les lignes
lues ou affectées par les commandes `CREATE TABLE AS`, `SELECT INTO`,
`CREATE MATERIALIZED VIEW`, `REFRESH MATERIALIZED VIEW` et `FETCH`.

Le script SQL suivant permet d'illustrer cette nouvelle fonctionnalité. Il
effectue plusieurs de ces opérations après avoir réinitialisé les statistiques
de `pg_stat_statements`.

```sql
SELECT pg_stat_statements_reset();

CREATE TABLE pg_class_1 AS SELECT * FROM pg_class;
SELECT * INTO pg_class_2 FROM pg_class;
CREATE MATERIALIZED VIEW pg_class_3 AS SELECT * FROM pg_class;
REFRESH MATERIALIZED VIEW pg_class_3;
```

On retrouve bien le nombre de lignes affectées par les requêtes, dans le champ
`rows` de la vue `pg_stat_statements`.

```sql
SELECT query, rows FROM pg_stat_statements;
                             query                             | rows
---------------------------------------------------------------+------
 select * into pg_class_2 FROM pg_class                        |  401
 select pg_stat_statements_reset()                             |    1
 refresh materialized view pg_class_3                          |  410
 create materialized view pg_class_3 as select * from pg_class |  404
 create table pg_class_1 as select * from pg_class             |  398
```

Le même scénario de test réalisé en version 13 ne donne pas ces informations.

```sql
SELECT query, rows FROM pg_stat_statements;
                             query                             | rows
---------------------------------------------------------------+------
 select * into pg_class_2 FROM pg_class                        |    0
 refresh materialized view pg_class_3                          |    0
 select pg_stat_statements_reset()                             |    1
 create table pg_class_1 as select * from pg_class             |    0
 create materialized view pg_class_3 as select * from pg_class |    0
```

**La vue `pg_stat_statements_info`**

Une nouvelle vue `pg_stat_statements_info` est ajoutée pour tracer les
statistiques du module lui-même.

```sql
\d pg_stat_statements_info;
                  View "public.pg_stat_statements_info"
   Column    |           Type           | Collation | Nullable | Default
-------------+--------------------------+-----------+----------+---------
 dealloc     | bigint                   |           |          |
 stats_reset | timestamp with time zone |           |          |
```

La colonne `stats_reset` rapporte la date de la dernière réinitialisation des
statistiques par la fonction `pg_stat_statements_reset()`.

La colonne `dealloc` décompte les événements de purge qui sont déclenchés
lorsque le nombre de requêtes distinctes dépasse le seuil défini par le
paramètre `pg_stat_statements.max`. Elle sera particulièrement utile pour 
configurer ce paramètre.

Sur une instance en version 14 avec `pg_stat_statement.max` configuré à une valeur
basse de 100, des requêtes distinctes sont exécutées via un script après une 
réinitialisation des statistiques de `pg_stat_statements`, afin de provoquer un
dépassement volontaire du seuil.

```bash
psql -d ws14 -c "select pg_stat_statements_reset();"

for rel_id in {0..200} ; do
    psql -d ws14 -c "create table pg_rel_${rel_id} (id int)";
    psql -d ws14 -c "drop table pg_rel_${rel_id}";
done
```

La vue `pg_stat_statements` a bien conservé un nombre de requêtes 
inférieur à `pg_stat_statement.max`, bien que 400 requêtes distinctes aient
été exécutées :

```sql
SELECT count(*) FROM pg_stat_statements;

 count 
-------
    93
```

Le nombre d'exécution de la purge de `pg_stat_statements` est désormais
tracé dans la vue `pg_stat_statements_info`. Elle a été déclenchée 31 fois 
pendant les créations et suppressions de tables :

```sql
SELECT * FROM pg_stat_statements_info;

 dealloc |          stats_reset          
---------+-------------------------------
      31 | 2021-09-02 13:30:26.497678+02
```

Ces informations peuvent également être obtenues via la fonction du même nom :

```sql
SELECT pg_stat_statements_info();
       pg_stat_statements_info        
--------------------------------------
 (31,"2021-09-02 13:35:22.457383+02")
```

**La nouvelle colonne `toplevel`**

Une nouvelle colonne `toplevel` apparaît dans la vue `pg_stat_statements`. Elle
est de type booléen et précise si la requête est directement exécutée ou bien 
exécutée au sein d'une fonction. Le traçage des exécutions dans les fonctions
n'est possible que si le paramètre `pg_stat_statements.track` est à `all`.

Sur une instance en version 14 avec `pg_stat_statement.track` configuré à `all`,
une fonction simple contenant une seule requête SQL est créée. Elle permet de
retrouver le nom d'une relation à partir de son `oid`.

```sql
CREATE OR REPLACE FUNCTION f_rel_name(oid int) RETURNS varchar(32) AS 
$$
    SELECT relname FROM pg_class WHERE oid=$1;
$$ 
LANGUAGE SQL;
```
Après avoir réinitialisé les statistiques de `pg_stat_statements`, le nom d'une 
table est récupérée depuis son `oid` en utilisant une requête SQL directement, 
puis via la fonction `f_rel_name` :

```sql
SELECT pg_stat_statements_reset();
SELECT relname FROM pg_class WHERE oid=26140 ;
SELECT f_rel_name(26140);
```

La vue `pg_stat_statements` est consultée directement après :

```sql
SELECT query, toplevel FROM pg_stat_statements
 WHERE query NOT LIKE '%pg_stat_statements%'
 ORDER BY query;
                  query                   | toplevel 
-------------------------------------------+----------
 select f_rel_name($1)                     | t
 select relname from pg_class where oid=$1 | f
 select relname from pg_class where oid=$1 | t
```

On retrouve bien l'appel de la fonction, ainsi que les deux exécutions de la 
requête sur `pg_class`, celle faite directement, et celle faite au sein de la 
fonction `f_rel_name`. La requête dont `toplevel` vaut `false` correspond
à l'exécution dans la fonction. Il n'était pas possible dans une version
antérieure de distinguer aussi nettement les deux contextes d'exécution.

</div>
