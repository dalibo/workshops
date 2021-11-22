<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/2714/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=71f4c8c6f74ba021e55d35b1128d22fb8c6e1629

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/108

-->

<div class="slide-content">

* Détachement de partition non bloquant
* Fonctionne en mode multi-transactions
* Quelques restrictions :
    * Ne fonctionne pas dans un bloc de transactions
    * Impossible en cas de partition par défaut

</div>

<div class="notes">

Détacher une partition peut maintenant se faire de façon non bloquante grâce à
la commande `ALTER TABLE … DETACH PARTITION … CONCURRENTLY`.

Son fonctionnement repose sur l'utilisation de deux transactions :

* La première ne requiert qu'un verrou `SHARE UPDATE EXCLUSIVE` sur la table
  partitionnée et la partition. Pendant cette phase, la partition est marquée
  comme en cours de détachement, la transaction est validée et on attend
  que toutes les transactions qui utilisent la partition se terminent. Cette
  phase est nécessaire pour s'assurer que tout le monde voit le changement de
  statut de la partition.
* Pendant la seconde, un verrou `SHARE UPDATE EXCLUSIVE` est placé sur la table
  partitionnée et un verrou `ACCESS EXCLUSIVE` sur la partition pour terminer
  le processus de détachement.

Dans le cas d'une annulation ou d'un crash lors de la deuxième transaction,
la commande `ALTER TABLE … DETACH PARTITION … FINALIZE` devra être exécutée
pour terminer l'opération.

Lors de la séparation d'une partition, une contrainte `CHECK` est créée à 
l'identique de la contrainte de partitionnement.
Ainsi, en cas de ré-attachement de la partition, le système n'aura pas besoin
d'effectuer un parcours de la table pour valider la contrainte de partition si
cette contrainte existe.
Sans elle, la table serait parcourue entièrement pour valider la contrainte de 
partition tout en nécessitant un verrou de niveau `ACCESS EXCLUSIVE` sur la table parente.

La contrainte peut bien entendu être supprimée après le ré-attachement de la partition 
afin d'éviter des doublons.

L'exemple suivant porte sur une table partitionnée avec deux partitions :

```sql
\d+ parent
```
```text
                     Table partitionnée « public.parent »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
Clé de partition : RANGE (id)
Partitions: enfant_1 FOR VALUES FROM (0) TO (5000000),
            enfant_2 FOR VALUES FROM (5000000) TO (11000000)
```
```sql
\d enfant_2
```
```text
                     Table « public.enfant_2 »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
Partition de : parent FOR VALUES FROM (5000000) TO (11000000)
Index :
    "enfant_2_id_idx" btree (id)
```

Nous allons procéder au détachement de la partition `enfant_2` :
```sql
ALTER TABLE parent DETACH PARTITION enfant_2 CONCURRENTLY ;

-- Une contrainte CHECK a été créée
-- Celle-ci correspond à la contrainte de partition
\d enfant_2
```
```text
                     Table « public.enfant_2 »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 id      | integer |                 |           |            
Index :
    "enfant_2_id_idx" btree (id)
Contraintes de vérification :
    "enfant_2_id_check" CHECK (id IS NOT NULL AND id >= 5000000 AND id < 11000000)
```

Concernant les restrictions :

* Il n'est pas possible d'utiliser `ALTER TABLE … DETACH PARTITION … CONCURRENTLY`
  dans un bloc de transactions à cause de son mode _multi-transactions_.

```sql
BEGIN;
ALTER TABLE parent DETACH PARTITION enfant_2 CONCURRENTLY;
-- ERROR:  ALTER TABLE ... DETACH CONCURRENTLY cannot run inside a transaction block
```

* Il est impossible d'utiliser cette commande si une partition par défaut existe
  car les contraintes associées sont trop importante pour le mode concurrent. En
  effet, il faut obtenir un verrou de type `EXCLUSIVE LOCK` sur la partition par
  défaut.

```sql
ALTER TABLE parent DETACH PARTITION enfant_1 CONCURRENTLY;
-- ERROR:  cannot detach partitions concurrently when a default partition exists
```

</div>
