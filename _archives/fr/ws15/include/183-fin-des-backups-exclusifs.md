<!--
Les sources pour ce sujet sont :

* https://www.postgresql.org/message-id/flat/CAHg+QDfiM+WU61tF6=nPZocMZvHDzCK47Kneyb0ZRULYzV5sKQ@mail.gmail.com
* https://commitfest.postgresql.org/35/?text=&status=4&targetversion=5&author=-1&reviewer=-1&sortkey=

-->

<div class="slide-content">

  * le mode _backup exclusive_:
    + risqué en cas de crash de l'instance
    + déprécié depuis la version 9.6
    + supprimé depuis la version 15

  * renommage des fonctions de _backup_ :
    + `pg_start_backup()` devient `pg_backup_start()`
    + `pg_stop_backup()` devient `pg_backup_stop()`

</div>

<div class="notes">

Le mode _backup_exclusive_ pose problème car il crée un fichier `backup_label` dans le répertoire de données durant l'execution d'une sauvegarde. Avec ce mode, il n'y a aucun moyen de distinguer le répertoire de données d'un serveur en mode sauvegarde de celui d'un serveur interrompu pendant la sauvegarde. En cas de crash, l'instance cherche alors à se restaurer au lieu de poursuivre la sauvegarde inachevée. 

En essayant de se restaurer sans `restore_command`, PostgreSQL cherche à rejouer les journaux disponibles dans _pg\_wal_ et peut échouer si une activité importante a entraîné la rotation desdits journaux. Dans certains cas, si le _checkpoint_ écrit dans `backup_label` n'est pas bon, ou si le fichier lui-même n'est pas bon, l'instance tente de revenir à un état différent de celui précédent le backup, entraînant un risque de corruption des données. 

Avec le mode de sauvegarde non exclusif, le fichier _backup_label_ est renvoyé par la fonction `pg_backup_stop` au lieu d'être écrit dans le répertoire de données, protégeant ainsi le serveur en cas de crash pendant une sauvegarde. Une connexion avec le client de sauvegarde est nécessaire pendant toute la durée de celle-ci. En cas d'interruption, l'opération est abandonnée, sans risque pour l'intégrité des données. Ce mode de sauvegarde a été introduit avec PostgreSQL 9.6 et a supplanté le mode exclusif qui a été déprécié dans la foulée. Cependant, les sauvegardes exclusives ont continué à être présentes et utilisables jusqu'à la version 14. 

PostgreSQL 15 supprime cette possibilité, et pour éviter toute confusion, les fonctions `pg_start_backup()` et `pg_stop_backup()`ont été renommées `pg_backup_start()` et `pg_backup_stop()`. Il est donc impératif de contrôler ses procédures de sauvegardes pour, d'une part, vérifier qu'elles n'utilisent plus les sauvegardes exclusives, et d'autre part, renommer les fonctions d'appel.


<!-- Note
à améliorer / illustrer éventuellement
<!-->
</div>
