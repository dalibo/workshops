<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/29/2500/

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/137

-->

<div class="slide-content">

![](medias/connection-scalability-improvements.png)

</div>

<div class="notes">

Pour rappel, le mécanisme MVCC (_MultiVersion Concurrency Control_) de PostgreSQL
facilite l’accès concurrent de plusieurs utilisateurs (sessions) à la base en 
disposant en permanence de plusieurs versions différentes d’un même enregistrement.
Chaque session peut travailler simultanément sur la version qui s’applique à son
contexte (on parle d’« instantané » ou de _snapshot_).

Une série d'optimisation ont été apportées dans cette version 14 sur la gestion
des _snapshots_ induits par ce mécanisme lorsqu'un très grand nombre de connexions
est atteint. Dans un [mail destiné aux développeurs][20200301083601], Andres Freund
explique qu'une transaction consomme beaucoup de ressources pour actualiser l'état
_xmin_ de sa propre session et que la méthode `GetSnapshotData()` requise pour
obtenir les informations sur les transactions du système, nécessitait de consulter
l'état de chacune d'entre elles dans les zones mémoires de tous les CPU du serveur.

[20200301083601]: https://www.postgresql.org/message-id/flat/20200301083601.ews6hz5dduc3w2se@alap3.anarazel.de

La solution consiste à changer la méthode `GetSnapshotData()` afin que seules les
informations _xmin_ des transactions en écriture soient accessibles depuis un
cache partagé. Dans une architecture où les lectures sont majoritaires, cette
astuce permet de reconstituer les instantanés bien plus rapidement, augmentant 
considérablement la quantité d'opérations par transaction.

</div>
