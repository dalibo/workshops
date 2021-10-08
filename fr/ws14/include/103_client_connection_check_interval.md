<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/3024/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=c30f54ad732ca5c8762bb68bbe0f51de9137dd72

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/103

-->

<div class="slide-content">

* Nouveau paramètre `client_connection_check_interval`
* Détermine le délai entre deux contrôles de connexion
  * Désactivé par défaut (valeur `0`)
  * Utile pour les très longues requêtes
  * Repose sur des appels système non-standards (non définis par POSIX)

</div>

<div class="notes">

Le paramètre `client_connection_check_interval` indique le délai avant de contrôler
la connexion avec le client distant. En l'absence de ces contrôles intermédiaires,
le serveur ne détecte la perte de connexion que lorsqu'il interagit avec le 
_socket_ de la session (attente, envoyer ou recevoir des données).

Si cette valeur est indiquée sans unité, il s'agit d'une durée exprimée en 
milliseconde. La valeur par défaut est de `0`, ce qui désactive ce comportement.
Si le client ne répond pas lors de l'exécution d'une requête (très) longue,
l'instance peut à présent interrompre la requête afin de ne pas consommer
inutilement les ressources du serveur.

Actuellement, le comportement du paramètre `client_connection_check_interval`
repose sur une extension non-standard du système d'appel au kernel. Cela implique
que seuls les systèmes d'exploitation basés sur Linux peuvent en bénéficier. Dans
un avenir hypothétique, les développeurs pourront réécrire le code pour reposer
sur un nouveau système de _heartbeat_ ou équivalent pour supporter plus de systèmes.

</div>
