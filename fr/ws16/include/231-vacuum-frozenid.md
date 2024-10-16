<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a46a7011b27188af526047a111969f257aaf4db8

Discussion :

* Discussion: https://www.postgresql.org/message-id/17717-6c50eb1c7d23a886@postgresql.org
Nom de la fonction dans le code : vac_update_datfrozenxid()
-->

<div class="slide-content">

  * Gestion de la mise à jour des statistiques pour VACUUM
  * Nouvelles options de VACUUM
    + `SKIP_DATABASE_STATS`
    + `ONLY_DATABASE_STATS`
  * Intégré à vacuumdb
    + `SKIP_DATABASE_STATS` activé par défaut en v16
    + `ONLY_DATABASE_STATS` si pas d'ANALYZE par étapes

</div>

<div class="notes">

Durant l'exécution d'un VACUUM, ou d'un autovacuum, une fonction particulière est appelée.
Elle permet de mettre à jour l'entrée `datfrozenxid` de la table `pg_database` pour
chaque base de données présente dans l'instance.

Cette entrée permet de connaitre l'identifiant de transaction le plus petit de
la base et est utilisée pour déterminer si une table de cette base doit être
nettoyée ou non.

Cette fonction passe en revue toutes les lignes de la
table `pg_class` pour une base donnée. Elle le fait de manière séquentiel. Les
performances se voyaient être dégradées sur des bases de données avec des dizaines
de milliers de tables.

De plus, des outils comme `vacuumdb` exécutent les commandes de `VACUUM` sur
chaque table. Ainsi à chaque passage sur une table, la fonction
est appelée. On comprend bien que plus il y a de
tables, plus le temps et les performances seront dégradés.

L'option `SKIP_DATABASE_STATS` (true ou false) permet d'indiquer si `VACUUM` doit ignorer la
mise à jour de l'identifiant de transaction.

L'option `ONLY_DATABASE_STATS` (true ou false) permet d'indiquer que `VACUUM` ne
doit rien faire d'autre à part mettre à jour l'identifiant.

L'outil `vacuumdb` a été mis à jour pour utiliser automatiquement l'option
`SKIP_DATABASE_STATS` si le serveur est au minimum en version 16. Il utilise
ensuite, tout aussi automatiquement, l'option `ONLY_DATABASE_STATS` une fois
qu'il a traité toutes les tables à condition que l'option `--analyze-in-stages`
ne soit pas indiquée.

</div>
