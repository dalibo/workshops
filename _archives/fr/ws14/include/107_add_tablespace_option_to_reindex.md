<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2269/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=c5b286047cd698021e57a527215b48865fd4ad4e
* https://commitfest.postgresql.org/32/3009/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=
* https://commitfest.postgresql.org/31/2849/
* https://commitfest.postgresql.org/32/2940/

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/107

-->

<div class="slide-content">

* Ajout de l'option `TABLESPACE` pour la commande `REINDEX`
* Possibilité de déplacer des index vers un autre tablespace tout en les reconstruisant
* Avec ou sans la clause `CONCURRENTLY`
* Restrictions :
    * sur les tables et index partitionnés
    * sur les tables TOAST
    * sur le catalogue système

</div>

<div class="notes">

La commande `REINDEX` dispose avec cette nouvelle version de l'option `TABLESPACE` qui donne la possibilité de déplacer des index 
dans un autre tablespace durant leur reconstruction. Son utilisation avec la clause `CONCURRENTLY` est supportée.

```sql
-- On dispose d'une table t1 avec un index idx_col1 dans le tablespace pg_default.
test=# \d t1
                     Table « public.t1 »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut  
---------+---------+-----------------+-----------+------------
 col1    | integer |                 |           |            
Index :
    "idx_col1" btree (col1)

-- Réindexation de la table t1 et déplacement de l'index idx_col1 dans le tablespace tbs.
test=# REINDEX (TABLESPACE tbs) TABLE t1 ;

-- L'index a bien été déplacé.
test=# SELECT c.relname, t.spcname FROM pg_class c 
         JOIN pg_tablespace t ON (c.reltablespace = t.oid) 
        WHERE c.relname = 'index_col1';

  relname   | spcname 
------------+---------
 index_col1 | tbs
```

Quelques restrictions s'appliquent :

* Lors de l'utilisation de l'option `TABLESPACE` sur des tables et index partitionnés, seuls les index des partitions seront déplacés vers le nouveau
tablespace. Aucune modification du tablespace ne sera effectuée dans `pg_class.reltablespace`, il faudra pour cela utiliser la commande `ALTER TABLE SET TABLESPACE`.
Afin de déplacer l'index parent, il faudra passer par la commande `ALTER INDEX SET TABLESPACE`.

```sql
-- On dispose de la table partionnée suivante.
test=# SELECT * FROM pg_partition_tree('parent');
  relid   | parentrelid | isleaf | level 
----------+-------------+--------+-------
 parent   |             | f      |     0
 enfant_1 | parent      | t      |     1
 enfant_2 | parent      | t      |     1

-- Avec un index dans la table parent et dans chaque partition.
test=# SELECT * FROM pg_partition_tree('parent_index');
      relid      | parentrelid  | isleaf | level 
-----------------+--------------+--------+-------
 parent_index    |              | f      |     0
 enfant_1_id_idx | parent_index | t      |     1
 enfant_2_id_idx | parent_index | t      |     1

-- Tous les index sont dans le tablespace pg_default.
test=# SELECT c.relname, CASE 
                WHEN c.reltablespace = 0 THEN td.spcname 
                ELSE tr.spcname
              END spcname
         FROM pg_partition_tree('parent_index') p
         JOIN pg_class c ON (c.oid = p.relid)
         JOIN pg_database d ON (d.datname = current_database())
         JOIN pg_tablespace td ON (d.dattablespace = td.oid)
    LEFT JOIN pg_tablespace tr ON (c.reltablespace = tr.oid);

     relname     |  spcname   
-----------------+------------
 parent_index    | pg_default
 enfant_1_id_idx | pg_default
 enfant_2_id_idx | pg_default

-- Reindexation de la table parent avec l'option TABLESPACE.
test=# REINDEX (TABLESPACE tbs) TABLE parent;

-- Seuls les index des partitions ont été déplacés.
test=# SELECT c.relname, CASE 
                WHEN c.reltablespace = 0 THEN td.spcname 
                ELSE tr.spcname
              END spcname
         FROM pg_partition_tree('parent_index') p
         JOIN pg_class c ON (c.oid = p.relid)
         JOIN pg_database d ON (d.datname = current_database())
         JOIN pg_tablespace td ON (d.dattablespace = td.oid)
    LEFT JOIN pg_tablespace tr ON (c.reltablespace = tr.oid);

     relname     |  spcname   
-----------------+------------
 parent_index    | pg_default
 enfant_1_id_idx | tbs
 enfant_2_id_idx | tbs
```

* Les index des tables TOAST sont conservés dans leur tablespace d'origine. Ils seront
  déplacés avec la table TOAST si la table utilisateur rattachée est déplacée.

```sql
-- On dispose d'une table blog avec une table TOAST.
test=# \d blog
                     Table « public.blog »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
 title   | text    |                 |           |            
 content | text    |                 |           |            
Index :
    "blog_title_idx" btree (title)

test=# \d+ pg_toast.pg_toast_16417
Table TOAST « pg_toast.pg_toast_16417 »
  Colonne   |  Type   | Stockage 
------------+---------+----------
 chunk_id   | oid     | plain
 chunk_seq  | integer | plain
 chunk_data | bytea   | plain
Table propriétaire : « public.blog »
Index :
    "pg_toast_16417_index" PRIMARY KEY, btree (chunk_id, chunk_seq)

-- réindexation de la table blog
test=# REINDEX (TABLESPACE tbs) TABLE blog;

-- Seul l'index de la table blog à été déplacé.
-- Celui de la table TOAST a uniquement été reconstruit.
test=# SELECT c.relname, t.spcname FROM pg_class c 
         JOIN pg_tablespace t ON (c.reltablespace = t.oid)
        WHERE t.spcname = 'tbs';

     relname     | spcname 
-----------------+---------
blog_title_idx   | tbs

-- Test de déplacement d'un index directement sur une table TOAST.
test=# reindex (tablespace tbs) table pg_toast.pg_toast_16417;
ERROR:  cannot move system relation "pg_toast_16417_index"
```

* L'option est interdite sur le catalogue système. Lors de l'utilisation des commandes `REINDEX SCHEMA`, `DATABASE` ou `TABLE` les objets systèmes ne seront pas concernés par le déplacement si l'option `TABLESPACE` est utilisée.

```sql
-- Test d'un déplacement d'index sur une table système.
test=# REINDEX (TABLESPACE tbs) TABLE pg_aggregate;
ERROR:  cannot move system relation "pg_aggregate_fnoid_index"

-- Test d'une réindexation de BDD avec déplacement des index.
test=# REINDEX (TABLESPACE tbs) DATABASE test;
WARNING:  cannot move system relations, skipping all
REINDEX
```

Cette fonctionnalité est également disponible avec la commande `reindexdb --tablespace`.

</div>
