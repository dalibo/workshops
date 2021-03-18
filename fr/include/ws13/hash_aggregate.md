<!--

Disk-based Hash Aggregation 
https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=1f39bce021540fde00990af55b4432c55ef4b3c7

HashAgg: use better cardinality estimate for recursive spilling. 
https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=3a232a3183d517743acf232794fadc07f0944220

Add hash_mem_multiplier GUC 
https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=78530c8e7a5abe0b646b0b46527f8799f831e1e1

doc: PG 13 relnotes: hash_mem_multiplier can restore old behav. 
https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=e7a6cd5dcf24c6d4b04d036a4837c7af154c4b49

-->

<div class="slide-content">

* les nœuds _Hash Aggregate_ peuvent désormais déborder sur disque
* permet une gestion plus saine de la mémoire
* nouveau paramètre `hash_mem_multiplier`
* `hash_mem_multiplier * work_mem` définit la quantité de mémoire autorisée
  pour chaque nœud _Hash Aggregate_ ou _Hash_
* régression de performance possible si ce paramètre n'est pas adapté
</div>

<div class="notes">

Dans les versions précédentes de PostgreSQL, il était possible de consommer
plus de mémoire que la valeur spécifiée dans `work_mem` si l'estimation du
nombre de ligne était incorrecte dans un nœud de type _Hash Aggregate_. Dans
cette nouvelle version de PostgreSQL, l'exécuteur est capable de suivre la
consommation mémoire de cette opération et peut choisir de déborder le surplus
de données sur disque dès que la mémoire allouée dépasse la valeur du
`work_mem`.

Dans ce mode, les lignes qui correspondent à des groupes en mémoire continuent
à les alimenter. Les lignes qui devraient créer de nouveaux groupes sont
écrites sur disque sous la forme de partitions. Les partitions sont
dimensionnées pour pouvoir être traitées en mémoire.

Lors de l'exécution, les partitions sont traitées en plusieurs passes appelée
_batch_. Il est possible que le nombre de passe soit différent du nombre de
partitions planifiée en cas d'erreur d'estimation. Il est également possible
que le traitement des partitions donne lieu à de nouveaux débordements sur
disque si la taille de la partition a été sous-estimée.

Voici un exemple de nœuds _Hash Aggregate_ affiché par `EXPLAIN`.

```
HashAggregate  (actual time=773.405..889.020 rows=99999 loops=1)
  Group Key: tablea.ac1
  Planned Partitions: 32  Batches: 33  Memory Usage: 4369kB  Disk Usage: 30456kB
```

La commande permet désormais de connaître :

* le nombre de partitions estimées par le planificateur (si pertinent) ;
* le nombre de passes (_batch_) effectivement réalisées par l'exécuteur ;
* la volumétrie occupée en mémoire ;
* la volumétrie occupée sur disque (si pertinent).

Ce nouveau comportement est plus résiliant, mais peut provoquer en contrepartie
des régressions de performance sur certaines requêtes qui bénéficieraient de
plus de mémoire dans les versions précédentes. Un nouveau paramètre a été créé
afin d'ajuster la quantité de mémoire autorisée pour la construction de table
de hachage : `hash_mem_multiplier`. La quantité de mémoire disponible pour les
_Hash Aggregate_ et _Hash_ (et donc _Hash Join_) est désormais calculée en
multipliant ce paramètre par `work_mem`.

Il faut prendre en compte le nombre maximal de connexions simultanées possible
sur le serveur lorsque l'on dimensionne cette zone mémoire. En effet, comme
pour `work_mem`, cette quantité de mémoire risque d'être allouée plusieurs fois
simultanément.

</div>
