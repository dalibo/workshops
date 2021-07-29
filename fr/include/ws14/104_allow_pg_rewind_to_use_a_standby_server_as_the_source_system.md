<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9c4f5192f69ed16c99e0d079f0b5faebd7bad212 

Discussion

* https://www.postgresql.org/message-id/flat/0c5b3783-af52-3ee5-f8fa-6e794061f70d@iki.fi

-->

<div class="slide-content">

* la source d'un rewind peut être une instance secondaire

</div>

<div class="notes">

[`pg_rewind`](https://www.postgresql.org/docs/13/app-pgrewind.html) permet de
synchroniser le répertoire de données d'une instance avec un autre répertoire
de données de la même instance. Il est notamment utilisé pour réactiver une
ancienne instance primaire en tant qu'instance secondaire répliquée depuis la
nouvelle instance primaire suite à une bascule ayant provoqué une divergence.

Lorsque l'on dispose de plus de deux serveurs dans une architecture répliquée,
il est désormais possible d'utiliser une instance secondaire comme source du
`rewind`. Cela permet de limiter l'impact des lectures sur la nouvelle instance
primaire.

Précédemment, PostgreSQL utilisait une table temporaire pour stocker certaines
information le temps du `rewind`. Une réécriture du code à rendu cette étape
inutile. C'est cette modification qui permet l'utilisation les instances
secondaires comme source d'un `rewind`.

</div>
