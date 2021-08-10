<!--
Les commits sur ce sujet sont :

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
* Restrictions :
    * Sur les tables et index partitionnés
    * Sur les tables `TOAST`
    * Sur le catalogue système

</div>

<div class="notes">

La commande `REINDEX` dispose avec cette nouvelle version de l'option `TABLESPACE` qui donne la possibilité de déplacer des index 
dans un autre tablespace durant leur reconstruction. Son utilisation avec la clause `CONCURRENTLY` est supportée.

```sql
-- On dispose d'une table t1 avec un index idx_col1 qui se trouvent dans le tablespace pg_default.
test=# \d+ t1
                                                     Table « public.t1 »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut | Stockage | Compression | Cible de statistiques | Description 
---------+---------+-----------------+-----------+------------+----------+-------------+-----------------------+-------------
 col1    | integer |                 |           |            | plain    |             |                       | 
Index :
    "idx_col1" btree (col1)
Méthode d'accès : heap

-- Réindexation de la table t1 et le déplacer l'index idx_col1 dans le tablespace tbs.
test=# reindex (tablespace tbs) table t1 ;

-- Le tablespace a bien été déplacé
test=# SELECT c.relname, t.spcname FROM pg_class c JOIN pg_tablespace t ON (c.reltablespace = t.oid) where c.relname = 'index_col1';
  relname   | spcname 
------------+---------
 index_col1 | tbs
```

Quelques restrictions s'appliquent :

* Lors de l'utilisation de l'option `TABLESPACE` sur des tables et index partitionnés, seuls les index des partitions seront déplacés vers le nouveau
tablespace. Aucune modification du tablespace ne sera effectuée dans `pg_class.reltablespace`, il faudra pour cela utiliser la commande `ALTER TABLE SET TABLESPACE`.
Afin de déplacer l'index parent, il faudra passer par la commande `ALTER INDEX SET TABLESPACE`.

```sql
-- On dispose de la table partionnée suivante
test=# SELECT * FROM pg_partition_tree('parent');
  relid   | parentrelid | isleaf | level 
----------+-------------+--------+-------
 parent   |             | f      |     0
 enfant_1 | parent      | t      |     1
 enfant_2 | parent      | t      |     1

-- Avec un index dans la table parent et dans chaque partition
test=# SELECT * FROM pg_partition_tree('parent_index');
      relid      | parentrelid  | isleaf | level 
-----------------+--------------+--------+-------
 parent_index    |              | f      |     0
 enfant_1_id_idx | parent_index | t      |     1
 enfant_2_id_idx | parent_index | t      |     1

-- Tous ces objets sont dans le tablespace pg_default
test=# \d+ parent
                                            Table partitionnée « public.parent »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut | Stockage | Compression | Cible de statistiques | Description 
---------+---------+-----------------+-----------+------------+----------+-------------+-----------------------+-------------
 id      | integer |                 |           |            | plain    |             |                       | 
Clé de partition : RANGE (id)
Index :
    "parent_index" btree (id)
Partitions: enfant_1 FOR VALUES FROM (0) TO (100),
            enfant_2 FOR VALUES FROM (100) TO (200)

-- Reindexation de la table parent avec l'option TABLESPACE
test=# reindex (tablespace tbs) table parent;

-- Seuls les index des partitions ont été déplacés
test=# SELECT c.relname, t.spcname FROM pg_partition_tree('parent_index') p JOIN pg_class c ON (c.oid = p.relid) JOIN pg_tablespace t ON (c.reltablespace = t.oid);
     relname     | spcname 
-----------------+---------
 enfant_1_id_idx | tbs
 enfant_2_id_idx | tbs
```

* Les index des tables `TOAST` sont concervés dans leur tablespace d'origine.

```sql
-- On dispose d'une table blog avec une table TOAST
test=# \d+ blog
                                                    Table « public.blog »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut | Stockage | Compression | Cible de statistiques | Description 
---------+---------+-----------------+-----------+------------+----------+-------------+-----------------------+-------------
 id      | integer |                 |           |            | plain    |             |                       | 
 title   | text    |                 |           |            | extended |             |                       | 
 content | text    |                 |           |            | extended |             |                       | 
Index :
    "idx_blog" btree (title)
Méthode d'accès : heap

test=# \d+ pg_toast.pg_toast_16417
Table TOAST « pg_toast.pg_toast_16417 »
  Colonne   |  Type   | Stockage 
------------+---------+----------
 chunk_id   | oid     | plain
 chunk_seq  | integer | plain
 chunk_data | bytea   | plain
Table propriétaire : « public.blog »
Index :
    "pg_toast_16417_index" PRIMARY KEY, btree (chunk_id, chunk_seq)
Méthode d'accès : heap

-- réindexation de la table blog
test=# reindex (tablespace tbs) table blog;

-- Seul l'index de la table blog à été déplacé. Celui de la table TOAST a uniquement été reconstruit
test=# SELECT c.relname, t.spcname FROM pg_class c JOIN pg_tablespace t ON (c.reltablespace = t.oid) where t.spcname = 'tbs';
     relname     | spcname 
-----------------+---------
idx_blog         | tbs

-- Test de déplacement d'un index directement sur une table TOAST
test=# reindex (tablespace tbs) table pg_toast.pg_toast_16417;
ERROR:  cannot move system relation "pg_toast_16417_index"
```

* L'option est interdite sur le catalogue système. Lors de l'utilisation des commandes `REINDEX SCHEMA`, `DATABASE` ou `SYSTEM` les objets systèmes ne seront pas concernés par le déplacement si l'option `TABLESPACE` est utilisée.

```sql
-- Test d'un déplacement d'index sur une table système
test=# reindex (tablespace tbs) table pg_aggregate;
ERROR:  cannot move system relation "pg_aggregate_fnoid_index"

-- Test d'une réindexation de BDD avec déplacement des index
test=# reindex (tablespace tbs) database test;
WARNING:  cannot move system relations, skipping all
REINDEX
```

Cette option est également utilisable avec la commande `reindexdb`.

</div>