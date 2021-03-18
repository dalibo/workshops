
<!--
Les commits sur ce sujet sont :

| Sujet                    | Lien                                                                                                        |
|==========================|=============================================================================================================|
| initial commit           | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=e65497df8f85ab9b9084c928ff69f384ea729b24 |
| add \-\-no-estimate-size | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=fab13dc50ba5e7a12b474a7366024681bc169ac8 |

Discussion : 
* https://www.postgresql.org/message-id/9ed8b801-8215-1f3d-62d7-65bff53f6e94@oss.nttdata.com

#### Suivit de l'exécution des sauvegardes
-->


<div class="slide-content">

* Nouvelle vue : `pg_stat_progress_basebackup`

* Permet de surveiller :

  * la phase de la sauvegarde ;
  * la volumétrie sauvegardée et restant à sauvegarder ;
  * le nombre de tablespaces sauvegardés et restant à sauvegarder.

</div>

<div class="notes"> 

La vue
[`pg_stat_progress_basebackup`](https://www.postgresql.org/docs/13/progress-reporting.html#BASEBACKUP-PROGRESS-REPORTING)
est composée des champs suivants :

* `pid` : le pid du processus _wal sender_ associé à la sauvegarde ;
* `phase` : la phase de la sauvegarde ;
* `backup_total` : l'estimation de la volumétrie totale à sauvegarder ;
* `backup_streamed` : la volumétrie déjà sauvegardée ;
* `tablespaces_total` : le nombre de tablespaces à traiter ;
* `tablespaces_streamed` : le nombre de tablespaces traités.

La sauvegarde se déroule en plusieurs étapes qui peuvent être suivies
grâce au champ `phase` de la vue :

* `initializing` : cette phase est très courte et correspond au moment où le
  _wal sender_ se prépare à démarrer la sauvegarde.

* `waiting for checkpoint to finish` : cette phase correspond au moment où le
  processus _wal sender_ réalise un `pg_start_backup` et attend que PostgreSQL
  fasse un `CHECKPOINT`.

* `estimating backup size` : c'est la phase où le _wal sender_ estime la
  volumétrie à sauvegarder. Cette étape peut être longue et coûteuse en
  ressource si la base de données est très grosse. Elle peut être évitée en
  spécifiant l'option `--no-estimate-size` lors de la sauvegarde. Dans ce cas, 
  la colonne `backup_total` est laissée vide.

* `streaming database files` : ce statut signifie que le processus _wal sender_
  est en train d'envoyer les fichiers de la base de données.

* `waiting for wal archiving to finish` : le _wal sender_ est en train de
  réaliser le `pg_stop_backup` de fin de sauvegarde et attend que l'ensemble
  des journaux de transactions nécessaires à la restauration soient archivés.
  C'est la dernière étape de la sauvegarde quand les options
  `--wal-method=none` ou `--wal-method=stream` sont utilisées.

* `transferring wal files` : le _wal sender_ est en train de transférer les
  journaux nécessaires pour restaurer la sauvegarde. Cette phase n'a lieu que si
  l'option `--wal-method=fetch` est utilisée dans `pg_basebackup`. 

</div>
