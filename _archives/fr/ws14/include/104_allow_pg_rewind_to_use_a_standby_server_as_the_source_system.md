<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9c4f5192f69ed16c99e0d079f0b5faebd7bad212 

Discussion

* https://www.postgresql.org/message-id/flat/0c5b3783-af52-3ee5-f8fa-6e794061f70d@iki.fi

-->

<div class="slide-content">

* La source d'un _rewind_ peut être une instance secondaire

</div>

<div class="notes">

`pg_rewind` permet de synchroniser le répertoire de données d'une instance avec
un autre répertoire de données de la même instance. Il est notamment utilisé
lorsqu'une instance d'un dispositif en réplication à divergé de l'instance
primaire. Cela peut arriver à l'ancienne primaire lors d'un _failover_. 
`pg_rewind` permet alors de raccrocher l'ancienne instance primaire sans avoir
besoin de restaurer une sauvegarde ou de cloner l'instance primaire avec
`pg_basebackup`.

Lorsque l'on dispose de plus de deux serveurs dans une architecture répliquée,
il est désormais possible d'utiliser une instance secondaire comme source du
_rewind_. Cela permet de limiter l'impact des lectures sur la nouvelle instance
primaire.

Précédemment, PostgreSQL utilisait une table temporaire pour stocker certaines
information le temps du _rewind_. Une réécriture du code a rendu cette étape
inutile. C'est cette modification qui permet l'utilisation des instances
secondaires comme source d'un _rewind_.

</div>
