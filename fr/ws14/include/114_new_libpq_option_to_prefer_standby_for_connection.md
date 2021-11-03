<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/1677/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=ee28cacf619f4d9c23af5a80e1171a5adae97381

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/114

-->

<div class="slide-content">

* Nouvelles options pour le paramètre `target_session_attrs`
  * `read-only`, `primary`, `standby`, et `prefer-standby`

</div>

<div class="notes">

En plus des options `any` (qui reste celle par défaut) et `read-write`, le
paramètre `target_session_attrs` de `libpq` supporte désormais les options
suivantes :

* `read-only`, le serveur ne doit accepter que les sessions en lecture seule
  (mode _hot standby_ ou `default_transaction_read_only` à `on`) ;
* `primary`, le serveur ne doit pas être en mode _hot standby_ ;
* `standby`, le serveur doit être en mode _hot standby_ ;
* `prefer-standby`, dans un premier temps, essayer de trouver une instance
  secondaire, sinon utilise le mode `any`.

Avec ces nouvelles options, aucune communication réseau supplémentaire ne sera
nécessaire pour obtenir l'état de la session ou du serveur. Les variables GUC
fournies sont suffisantes. Pour les versions plus anciennes, une requête `SHOW`
ou `SELECT` devait être émise afin de détecter si la session était en lecture
seule ou si l'instance était en mode _hot standby_.

</div>
