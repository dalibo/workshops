## TP - Suivi de l'exécution des sauvegardes

<div class="slide-content">

  * Suivi d'une sauvegarde simple ;
  * Suivi sans estimation de la taille.

</div>

<div class="notes">

### Mise en place

Mettre en place les bases de données pour le test :

```
psql <<EOF
CREATE DATABASE bench1;
CREATE TABLESPACE bench2
       LOCATION 'CHEMIN_VERS_LE_TABLESPACE'
CREATE DATABASE bench2
       WITH TABLESPACE 'bench2';
EOF
```

Générer des données avec `pg_bench` :

```
pgbench --initialize --scale 100 bench1
pgbench --initialize --scale 100 bench2
```

Remarque : un facteur d'échelle de 100 génère une base de données
d'approximativement 1,5 Go.


### Sauvegarde simple

Dans une session, lancer une commande  `watch` pour observer le contenu de la
vue système `pg_stat_progress_basebackup` :

```
watch "psql  \
  --expanded \
  --command=\"SELECT * FROM pg_stat_progress_basebackup\""
```

Dans une autre session, lancer une sauvegarde :

```
pg_basebackup \
  --format=t --gzip \
  --pgdata=CHEMIN_VERS_LE_BACKUP
```

Observer le déroulement de la sauvegarde dans la vue système.

Exemple :

```
-[ RECORD 1 ]--------+-------------------------
pid                  | 321128
phase                | streaming database files
backup_total         | 3177546240
backup_streamed      | 2496398336
tablespaces_total    | 2
tablespaces_streamed | 1
```

On constate que :

* `pid` correspond bien au _walsender_ qui sert le `pg_base_backup` :

  ```
  $ psql \
      --expanded \
      --command="SELECT pid, backend_type, application_name \
                 FROM pg_stat_activity \
                 WHERE pid = 321313"
  -[ RECORD 1 ]----+--------------
  pid              | 321313
  backend_type     | walsender
  application_name | pg_basebackup
  ```

* Le champ `phase` passe sucessivement par les états : `initializing`, `waiting
  for checkpoint to finish`, `estimating backup size`, `streaming database
  files`, `waiting for wal archiving to finish` et `transferring wal
  files`. Certaines phases sont très courtes et peuvent ne pas être
  observables.

* L'estimation de la taille de la base de données correspond bien à la taille
  de PGDATA, plus la taille du tablespace, moins celle des journaux de
  transactions.

  ```
  $ du -sh $PGDATA
  2.5G	$PGDATA
  $ du -sh $PGDATA/pg_tblspc/16385/
  1.5G	$PGDATA/pg_tblspc/16385/
  $ du -sh $PGDATA/pg_wal
  1.1G	$PGDATA/pg_wal
  ```

* Le compteur de tablespace est bien incrémenté.

### Sauvegarde sans estimation de la taille

Lancer la commande suivante en utilisant un chemin différent pour la
sauvegarde :

```
$ pg_basebackup \
  --format=t --gzip \
  --no-estimate-size \
  --pgdata=CHEMIN_VERS_LE_BACKUP
```


Cette fois-ci, on observe que le champ `backup_total` est vide. En effet, la
phase `estimating backup size` n'a pas été exécutée. Pour des instances
particulièrement grosses, cela peut permettre de diminuer le temps de
sauvegarde.

</div>
