<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/31/2646/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9877374bef76ef03923f6aa8b955f2dbcbe6c2c7

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/101

-->

<div class="slide-content">

* Nouveau paramètre
  * `idle_session_timeout`

</div>

<div class="notes">

Le paramètre `idle_session_timeout` définit la durée maximale sans activié entre 
deux requêtes lorsque l'utilisateur n'est pas dans une transaction.

Ce paramètre a pour conséquence de terminer toute session ne faisant rien depuis
plus longtemps que la durée indiquée par ce paramètre. Cela permet de limiter
la consommation de ressources effectuée par des sessions inactives (mémoire par
exemple) et de diminuer le coût de maintenance des sessions connectées à l'instance
en limitant leur nombre.

Si cette valeur est indiquée sans unité, elle est comprise comme un nombre en
millisecondes.
La valeur par défaut de `0` désactive cette fonctionnalité.

Le changement de la valeur du paramètre `idle_session_timeout` ne requiert pas
de démarrage ou de droit particulier.

</div>
