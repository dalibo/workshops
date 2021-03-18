<!--
Les commits sur ce sujet sont :

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=c6550776394e25c1620bc8258427c8f1d448080d
https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=55ca50deb8ffaec3b81d83c9f54c94f7e519f3a6
https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=6f7a862bed3a49283c74c0adf207172002e3e03c

Discussion générale:

https://www.postgresql.org/message-id/20170228.122736.123383594.horiguchi.kyotaro@lab.ntt.co.jp
https://www.postgresql.org/message-id/20200616.120236.1809496990963386593.horikyota.ntt@gmail.com

-->

<div class="slide-content">

* `max_slot_wal_keep_size` permet de spécifier le volume maximal de WAL que les
  slots de réplication peuvent conserver dans le répertoire `pg_wal` ;
* Ajout des colonnes `wal_status` et `safe_wal_size` à la vue
  `pg_replication_slots` pour permettre de suivre l'état des slots.

</div>

<div class="notes">

En cas de déconnexion d'une instance secondaire ou de retard important de la
réplication, les slots de réplication permettent de conserver la quantité
exacte de WAL nécessaire à l'instance secondaire pour qu'elle puisse poursuivre
sa réplication.

Précédemment, la volumétrie de WAL conservée par les slots de réplication dans
le répertoire de `pg_wal` n'avait pas de limite. Cette absence de limite
était un problème en cas d'indisponibilité prolongée de l'instance secondaire.
En effet, elle met en péril la continuité du service sur l'instance primaire
en menaçant de remplir le répertoire `pg_wal`.

Le paramètre `max_slot_wal_keep_size` permet de limiter la quantité de WAL
conservé par les slots. Il peut être modifié a chaud. Sa valeur par défaut est
`-1`, signifiant que les slots conservent une quantité illimitée de WAL.

Afin de suivre l'état des slots de réplication, la vue `pg_replication_slots` a
été enrichie avec deux nouvelles colonnes.

La première, `wal_status` permet de connaître la disponibilité des WAL réservés
par le slot. Elle peut prendre quatre valeurs :

* `reserved` : le quantité de wal réservé est inférieure à `max_wal_size`.
* `extended` : le quantité de wal réservé est supérieure à `max_wal_size` mais
  les WAL sont conservés soit par le slot lui-même, soit par le biais du
  paramètre `wal_keep_size`.
* `unreserved` : le slot ne conserve plus de WAL et certains seront retirés
  lors du prochain `CHECKPOINT`. Cet état est réversible.
* `lost` : les WAL nécessaires au slot ne sont plus disponibles et le
  slot est inutilisable.

Les deux derniers statuts ne sont possibles que lorsque `max_slot_wal_keep_size`
est supérieur ou égal à zéro.

La seconde colonne, `safe_wal_size` contient le volume de WAL en octet qui
peut être produit sans mettre en danger le slot. Cette valeur est nulle lorsque
le statut du slot est `lost` ou que `max_slot_wal_keep_size` est égal à `-1`.

Attention, le volume maximal de WAL conservés par un slot reste dans le
répertoire `pg_wal` jusqu'à ce que le slot soit supprimé, même pour les slots
dont le statut est `lost`. Leur volumétrie s'ajoute donc à la volumétrie normale
des journaux de transaction. C'est un facteur à prendre en compte quand on
dimensionne un système de fichier dédié à `pg_wal`.

</div>

