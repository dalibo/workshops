<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=8d74fc96db5fd547e077bf9bf4c3b67f821d71cd 

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/161

-->

<div class="slide-content">

* Donne des informations sur les erreurs qui se sont produitent 
  durant la réplication logique
* Ajout de la fonction `pg_stat_reset_subscription_stats()`

</div>

<div class="notes">

La vue système `pg_stat_subscription_stats` permet de récupérer des 
informations sur les erreurs qui se sont produisent au niveau des souscriptions 
avec la réplication logique. Ces données sont stockées sous forme de compteur 
et concernent les erreurs rencontrées lors de l'application des changements 
ou lors de la synchronisation initiale. Elle contient une ligne par souscription.

Voici la description des colonnes de cette vue :

* `subid` : _OID_ de la souscription ;
* `subname` : nom de la souscription ;
* `apply_error_count` : nombre d'erreurs rencontrées lors de l'application des 
  changements ;
* `sync_error_count` : nombre d'erreurs rencontrées lors de la synchronisation 
  initiale des tables ;
* `stats_reset` : date de réinitialisation des statistiques.

La fonction `pg_stat_reset_subscription_stats` permet de réinitialiser les 
statistiques de la vue `pg_stat_subscription_stats`. Elle prend en paramètre soit 
l'_OID_ d'une souscription pour ne réinitialiser que les statistiques de cette 
dernière, soit `NULL` pour appliquer la réinitialisation à **toutes** les souscriptions.

</div>
