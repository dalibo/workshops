<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/30/2584/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a6642b3ae060976b42830b7dc8f29ec190ab05e4
* https://commitfest.postgresql.org/32/2989/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=17661188336c8cbb1783808912096932c57893a3
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=8a8f4d8ede288c2a29105f4708e22ce7f3526149

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/109

-->

<div class="slide-content">

* `REINDEX` est maintenant disponible pour les tables et index partitionnés
* Supporte la clause `CONCURRENTLY`
* Fonctionne en mode multi-transactions

</div>

<div class="notes">

Jusqu'à la version 13, la commande `REINDEX` ne pouvait pas être utilisée sur les
tables et index partionnés. Il fallait réindexer les partitions une par une.

```sql
REINDEX INDEX parent_index;
-- ERROR:  REINDEX is not yet implemented for partitioned indexes

REINDEX TABLE parent;
-- WARNING:  REINDEX of partitioned tables is not yet implemented, skipping "parent"
-- REINDEX
```

Avec la version 14, il est maintenant possible de passer une table ou un index 
partitionné comme argument aux commandes `REINDEX INDEX` ou `REINDEX TABLE`.
L'ensemble des partitions sont parcourues afin de réindexer tous les éléments 
concernés. Seuls ceux disposant d'un stockage physique sont visés (on écarte 
donc les tables et index parents).

Prenons la table partitionnée `parent` et son index `parent_index`. Il est
possible de déterminer la fragmentation de l'index à l'aide de l'extension
`pgstattuple` :

```sql
CREATE EXTENSION pgstattuple;
SELECT avg_leaf_density, leaf_fragmentation FROM pgstatindex('enfant_1_id_idx');
```
```text
 avg_leaf_density | leaf_fragmentation 
------------------+--------------------
            74.18 |                 50
```
```sql
SELECT avg_leaf_density, leaf_fragmentation FROM pgstatindex('enfant_2_id_idx');
```
```text
 avg_leaf_density | leaf_fragmentation 
------------------+--------------------
            74.17 |                 50
```

Tous les index peuvent être reconstruits avec une unique commande :

```sql
REINDEX INDEX parent_index;
```

```sql
SELECT avg_leaf_density, leaf_fragmentation FROM pgstatindex('enfant_1_id_idx');
```
```text
 avg_leaf_density | leaf_fragmentation 
------------------+--------------------
            90.23 |                  0
```
```sql
SELECT avg_leaf_density, leaf_fragmentation FROM pgstatindex('enfant_2_id_idx');
```
```text
 avg_leaf_density | leaf_fragmentation 
------------------+--------------------
            90.23 |                  0
```

Côté fonctionnement, celui-ci est _multi transactions_. C'est-à-dire que chaque
partition est traitée séquentiellement dans une transaction spécifique. Cela à
pour avantage de minimiser le nombre d'index invalides en cas d'annulation ou
d'échec avec la commande `REINDEX CONCURRENTLY`. Cependant, cela empêche son
fonctionnement dans un bloc de transaction.

```sql
BEGIN;
REINDEX INDEX parent_index;
-- ERROR:  REINDEX INDEX cannot run inside a transaction block
-- CONTEXT: while reindexing partitioned index "public.parent_index"
```

Les colonnes `partitions_total` et `partitions_done` de la vue `pg_stat_progress_create_index`
sont positionnées à 0 durant la durée de l'opération. Il est néanmoins possible de voir les
`REINDEX` passer les un après les autres dans cette vue.

</div>
