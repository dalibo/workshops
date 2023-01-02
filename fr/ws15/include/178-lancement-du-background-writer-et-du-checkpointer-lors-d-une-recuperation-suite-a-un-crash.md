<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/E1mAQaC-0007Nz-MZ@gemulon.postgresql.org

-->

<div class="slide-content">
 
 * Les processus checkpointer et bgwriter sont lancés dès la phase de  _crash
   recovery_
   + simplifier le code en limitant la duplication
   + améliorer les performances dans certains cas

</div>

<div class="notes">

Le checkpointer et le bgwriter son désormais lancés pendant la phase de _crash
recovery_ de la même manière qu'on le fait pour la réplication. L'objectif est
de limiter la duplication de code en supprimant ce cas particulier.
Il est possible que, dans certains cas, cela améliore les performances. Par
exemple quand la quantité de données à mettre en cache pour la _recovery_
dépasse la taille des _shared buffers_.

Le comportement de l'instance reste inchangé en mode _single user_ (option
`--single` du _postmaster_).

</div>
