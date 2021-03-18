<!--

Le commit sur ce sujet est :
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=a7e8ece41cf7a96d8a9c4c037cdfef304d950831

Discussion générale :
* https://www.postgresql.org/message-id/a3acff50-5a0d-9a2c-b3b2-ee36168955c1@postgrespro.ru



 #### `pg_rewind` sait restaurer des journaux
-->

<div class="slide-content">

* `-c/--restore-target-wal` permet de restaurer les archives de journaux de
  transactions de l'instance cible.

</div>

<div class="notes">

[`pg_rewind`](https://www.postgresql.org/docs/13/app-pgrewind.html) permet de
synchroniser le répertoire de données d'une instance avec un autre répertoire
de données de la même instance. Il est notamment utilisé pour réactiver une
ancienne instance primaire en tant qu'instance secondaire répliquée depuis la
nouvelle instance primaire suite à une bascule.

Dans la terminologie de l'outil, on parle de source pour la nouvelle primaire
et cible pour l'ancienne.

`pg_rewind` identifie le point de divergence entre la cible et la source.
Il doit ensuite identifier tous les blocs modifiés sur la cible après le point
de divergence afin de pouvoir les corriger avec les données de la source. Pour
réaliser cette tâche, l'outil doit parcourir les journaux de transactions
générés par la cible.

Avant PostgreSQL 13, ces journaux de transactions devaient être présents dans le
répertoire `PGDATA/pg_wal` de la cible. Dans les cas où la cible n'a pas été
arrêtée rapidement après la divergence, cela peut poser problème, car les
WAL nécessaires ont potentiellement déjà été recyclés.

Il est désormais possible d'utiliser l'option `-c` ou `--restore-target-wal`
afin que l'outil utilise la commande de restauration `restore_commande` de
l'instance cible pour récupérer ces journaux de transactions à l'endroit où ils
ont été archivés.

Note : certains fichiers ne sont pas protégés par les WAL et sont donc copiés
entièrement. Voici quelques exemples :

* les fichiers de configuration : `postgresql.conf`, `pg_ident.conf`,
  `pg_hba.conf` ;
* la _visibility map_ (fichiers `*_vm`), et la _free space map_ (fichiers
  `*_fsm`) ;
* le répertoire `pg_clog`.

</div>
