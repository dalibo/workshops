<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/E1ncFSE-000eOi-Ss@gemulon.postgresql.org

Discussion

* https://www.postgresql.org/message-id/E1ncFSE-000eOi-Ss@gemulon.postgresql.org
* https://github.com/zalando/patroni/pull/2225

-->

<div class="slide-content">
 * Nouvelle option `-C/--config-file`
 * Permet l'utilisation de l'option `-c/--restore-target-wal` quand la
   configuration de PostgreSQL n'est pas dans `$PGDATA`.
</div>

<div class="notes">

L'option `-c/--restore-target-wal` ajoutée en version 13 permet d'utiliser la
commande de restauration des archives (`restore_command`) stockée dans le
fichier de configuration de l'instance pour récupérer les WAL nécessaires à
l'opération de _rewind_, s'ils ne sont plus dans le répertoire `pg_wal`.

Ce mode de fonctionnement pose problème pour les installations où les fichiers
de configuration de PostgreSQL ne sont pas stockés dans le répertoire de
données de l'instance. C'est par exemple le cas par défaut sur les
installations DEBIAN. Sur ce genre d'installation, le fichier de
configuration doit être copié dans le répertoire de données manuellement avant
de lancer l'opération de _rewind_. Cela peut également complexifier
l'implémentation d'outils de haute disponibilité avec reconstruction
automatique comme [Patroni](https://github.com/zalando/patroni/pull/2225).

L'option `-C/--config-file` permet de donner à pg_rewind le chemin du fichier
de configuration. Il sera ensuite utilisé par pg_rewind 
lors du démarrage de PostgreSQL (option `-C` du postmaster) :

* afin d'obtenir la configuration de la commande de restauration ;
* afin d'arrêter PostgreSQL proprement avant la réalisation du _rewind_.

</div>
