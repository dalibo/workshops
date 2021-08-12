<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2714/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=71f4c8c6f74ba021e55d35b1128d22fb8c6e1629

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/108

-->

<div class="slide-content">

* Détachement de partition non bloquant
* Fonctionne en mode multi-transactions
* Quelques restrictions :
    * Ne fonctionne pas dans un bloc de transactions
    * Impossible en cas de partition par défaut

</div>

<div class="notes">

Détacher une partition peut maintenant se faire de façon non bloquante grâce à la commande `ALTER TABLE...DETACH PARTITION...CONCURRENTLY`.
Son fonctionnement repose sur le mode _multi-transactions_ (2 au total) et ne requiert qu'un verrou `SHARE UPDATE EXCLUSIVE` sur la table partitionnée.

Dans le cas d'une annulation ou d'un crash lors de la deuxième transaction, la commande `ALTER TABLE...DETACH PARTITION...FINALIZE` sera exécutée pour terminer l'opération.

Lors de la séparation d'une partition, une contrainte `CHECK` est créée à l'identique de la contrainte de partionnement. Celle-ci peut être supprimée par la suite.

Cependant, en cas de rattachement de la partition, le système n'aura pas besoin d'effectuer un parcours de la table pour valider la contrainte de partition si cette contrainte existe.
Sans elle, la table sera parcourue entièrement pour valider la contrainte de partition tout en ayant un verrou de niveau `ACCESS EXCLUSIVE` sur la table parente.
Elle pourra bien entendu être supprimée après le rattachement de la partition afin d'éviter des doublons.

```sql
-- On dispose d'une table partitionnée avec deux partitions
test=# \d parent
                     Table partitionnée « public.parent »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
Clé de partition : RANGE (id)
Partitions: enfant_1 FOR VALUES FROM (0) TO (5000000),
            enfant_2 FOR VALUES FROM (5000000) TO (11000000)

-- Nous allons procéder au détachement de la partition enfant_2
test=# \d enfant_2
                     Table « public.enfant_2 »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
Partition de : parent FOR VALUES FROM (5000000) TO (11000000)
Contrainte de partition : ((id IS NOT NULL) AND (id >= 5000000) AND (id < 11000000))
Index :
    "enfant_2_id_idx" btree (id)

test=# alter table parent detach partition enfant_2 concurrently ;

-- Une contrainte CHECK a été créée
-- Celle-ci correspond à la contrainte de partition
test=# \d enfant_2
                     Table « public.enfant_2 »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
Index :
    "enfant_2_id_idx" btree (id)
Contraintes de vérification :
    "enfant_2_id_check" CHECK (id IS NOT NULL AND id >= 5000000 AND id < 11000000)
```

Concernant les restrictions :

* Il n'est pas possible d'utiliser `ALTER TABLE...DETACH PARTITION...CONCURRENTLY` dans un bloc de transactions à cause de son mode _multi-transactions_.

```sql
test=# begin;
BEGIN
test=*# alter table parent detach partition enfant_2 concurrently ;
ERROR:  ALTER TABLE ... DETACH CONCURRENTLY cannot run inside a transaction block
```

* Il est impossible d'utiliser cette commande si une partition par défaut existe car il faut obtenir un verrou de type `exclusive lock` dessus.
\newpage
```sql
-- On dispose d'une table partitionnée et de trois partitions
-- Dont une par défaut
test=# \d parent
                     Table partitionnée « public.parent »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
Clé de partition : RANGE (id)
Partitions: enfant_1 FOR VALUES FROM (0) TO (5000000),
            enfant_2 FOR VALUES FROM (5000000) TO (11000000),
            enfant_3 DEFAULT

-- On tente de détacher la partition enfant_1
test=# alter table parent detach partition enfant_1 concurrently ;
ERROR:  cannot detach partitions concurrently when a default partition exists
```

</div>