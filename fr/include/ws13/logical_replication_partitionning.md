<!--
Support adding partitioned tables to publication:
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=17b9e7f9fe238eeb5f6b40061b444ebf28d9e06f

Add logical replication support to replicate into partitioned tables:
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=f1ac27bfda6ce8a399d8001843e9aefff5814f9b

Allow publishing partition changes via ancestors (publish_via_partition_root)
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=83fd4532a72179c370e318075a10e0e2aa832024





#### Publication d'une table partitionnée  

-->

<div class="slide-content">

Il est désormais possible de :

* ajouter une table partitionnée à une publication
* répliquer vers une table partitionnée
* répliquer depuis la racine d'une table partitionnée (option
  `publish_via_partition_root`)
  + en cas de partitionnement différent sur la cible

</div>

<div class="notes">

Dans les versions précédentes, il était possible d'ajouter des partitions à une
publication afin de répliquer les opérations sur celles-ci.  Il est désormais
possible d'ajouter directement une table partitionnée à une publication, toutes
les partitions seront alors automatiquement ajoutées à celle-ci. Tout ajout ou
suppression de partition sera également reflété dans la liste des tables
présentes dans la publication sans action supplémentaire. Il faudra cependant
rafraîchir la souscription pour qu'elle prenne en compte les changements opérés
avec la
[commande de modification de souscription](https://www.postgresql.org/docs/13/sql-altersubscription.html) :

```
ALTER SUBSCRIPTION <sub> REFRESH PUBLICATION;
```

La version 13 de PostgreSQL permet de répliquer vers une table partitionnée.

Il est également possible de répliquer depuis la racine d'une table
partitionnée. Cette fonctionnalité est rendue possible par l'ajout d'un
paramètre de publication : `publish_via_partition_root`. Il détermine si les
modifications faites sur une table partitionnée contenue dans une publication
sont publiées en utilisant le schéma et le nom de la table partitionnée plutôt
que ceux de ses partitions. Cela permet de répliquer depuis une table
partitionnée vers une table classique ou partitionnée avec un schéma de
partitionnement différent.

L'activation de ce paramètre est effectuée via la commande [CREATE
PUBLICATION](https://www.postgresql.org/docs/13/sql-createpublication.html) ou
[ALTER
PUBLICATION](https://www.postgresql.org/docs/13/sql-alterpublication.html).

Exemple :

```
CREATE PUBLICATION pub_table_partitionnee
    FOR TABLE factures
    WITH ( publish_via_partition_root = true );
```

Si ce paramètre est utilisé, les ordres TRUNCATE exécutés sur les partitions ne
sont pas répliqués.

</div>
