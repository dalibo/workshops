<!--

Le commit sur ce sujet est :
https://github.com/postgres/postgres/commit/5adafaf176d09ba5ea11ae128416fc5211469bc0

Discussion générale :
https://postgr.es/m/CAEET0ZEffUkXc48pg2iqARQgGRYDiiVxDu+yYek_bTwJF+q=Uw@mail.gmail.com


#### `pg_rewind` récupère automatiquement une instance
-->

<div class="slide-content">

* pg_rewind lance automatiquement la phase de récupération du serveur cible
  si nécessaire avant son traitement.
* il est possible de désactiver ce nouveau comportement avec
  `--no-ensure-shutdown`.

</div>

<div class="notes">

pg_rewind s'assure que le serveur cible a été arrêté proprement avant de lancer
tout traitement. Si ce n'est pas le cas, l'instance est démarrée en mode
mono-utilisateur afin d'effectuer la récupération (phase de _crash recovery_).
Elle est ensuite éteinte.

L'option `--no-ensure-shutdown` permet de ne pas faire ces opérations
automatiquement. Si l'instance cible n'a pas été arrêtée proprement, un message
d'erreur est affiché et l'utilisateur doit faire les actions nécessaires
lui-même. C'était le fonctionnement normal dans les versions précédentes de
l'outil.

</div>
