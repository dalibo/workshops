## TP - Fichiers manifeste et vérification des sauvegardes 

<div class="slide-content">

  * Création d'une sauvegarde ;
  * Vérification du fichier manifeste ;
  * Test de corruptions.

</div>

<div class="notes">

### Création de la sauvegarde

Réaliser une sauvegarde au format `plain` et observer le résultat :

```
$ export BKP_DIR=/bkp
$ pg_basebackup --format=p --pgdata=$BKP_DIR/bkp_plain
$ ls -al $BPK_DIR/bkp_plain
total 260
drwx------. 19 postgres postgres   4096 May 13 11:20 .
drwxrwxr-x.  5 postgres postgres   4096 May 13 11:20 ..
-rw-------.  1 postgres postgres    225 May 13 11:20 backup_label
-rw-------.  1 postgres postgres 135117 May 13 11:20 backup_manifest
drwx------.  5 postgres postgres   4096 May 13 11:20 base
drwx------.  2 postgres postgres   4096 May 13 11:20 global
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_commit_ts
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_dynshmem
-rw-------.  1 postgres postgres   4513 May 13 11:20 pg_hba.conf
-rw-------.  1 postgres postgres   1636 May 13 11:20 pg_ident.conf
drwx------.  4 postgres postgres   4096 May 13 11:20 pg_logical
drwx------.  4 postgres postgres   4096 May 13 11:20 pg_multixact
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_notify
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_replslot
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_serial
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_snapshots
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_stat
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_stat_tmp
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_subtrans
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_tblspc
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_twophase
-rw-------.  1 postgres postgres      3 May 13 11:20 PG_VERSION
drwx------.  3 postgres postgres   4096 May 13 11:20 pg_wal
drwx------.  2 postgres postgres   4096 May 13 11:20 pg_xact
-rw-------.  1 postgres postgres     88 May 13 11:20 postgresql.auto.conf
-rw-------.  1 postgres postgres  27902 May 13 11:20 postgresql.conf
```

Réaliser une sauvegarde au format `tar` compressé et observer le résultat :

```
$ export BKP_DIR=/bkp
$ pg_basebackup --format=t --gzip --pgdata= $BKP_DIR/bkp_compresse
$ ls -al $BKP_DIR/bkp_compresse
total 3132
drwx------. 2 postgres postgres    4096 May 13 11:15 .
drwxrwxr-x. 3 postgres postgres    4096 May 13 11:15 ..
-rw-------. 1 postgres postgres  135258 May 13 11:15 backup_manifest
-rw-------. 1 postgres postgres 3037500 May 13 11:15 base.tar.gz
-rw-------. 1 postgres postgres   17073 May 13 11:15 pg_wal.tar.gz
```

### Fichier manifeste

Lister les fichiers présents dans le manifeste : 

```
$cat $BKP_DIR/bkp_plain/backup_manifest | jq '.Files[] .Path'
```

Lister les informations sur les journaux de transactions nécessaire à la
restauration :

```
$ cat $BKP_DIR/bkp_plain/backup_manifest | jq -r '."WAL-Ranges"[]'
{
  "Timeline": 1,
  "Start-LSN": "0/8000028",
  "End-LSN": "0/8000100"
}
```

### Vérifier les sauvegardes

#### Vérification d'une sauvegarde au format `plain`

Vérifier la sauvegarde faite au format `plain` :

```
$ pg_verifybackup $BKP_DIR/bkp_plain
backup successfully verified
```

#### Ajout de fichier à la sauvegarde

Ajouter des fichiers a la sauvegarde : 

```
$ mkdir $BKP_DIR/bkp_plain/conf
$ touch $BKP_DIR/bkp_plain/conf/postgresql.conf
```

Vérifier la sauvegarde :

```
$ pg_verifybackup $BKP_DIR/bkp_plain
pg_verifybackup: error: "conf/postgresql.conf" is present on disk but not in \
  the manifest
```

Ajouter des fichiers peut être utile si vous souhaitez sauvegarder votre
configuration avec les données sur des installations de PostgreSQL du type
DEBIAN/UBUNTU.

Refaire la vérification en ignorant le répertoire de configuration : 

```
$ pg_verifybackup --ignore=conf /$BKP_DIR/bkp_plain
backup successfully verified
```

#### Corruption d'un journal de transactions

Corrompre un journal de transactions dans la sauvegarde : 

```
$ cp $BKP_DIR/bkp_plain/pg_wal/000000010000000000000008 .
$ printf 'X' \
  | dd conv=notrunc of=$BKP_DIR/bkp_plain/pg_wal/000000010000000000000008 \
       bs=1 seek=10
```

Vérifier la sauvegarde : 
```
$ pg_verifybackup --ignore=conf $BKP_DIR/bkp_plain
pg_waldump: fatal: could not find a valid record after 0/8000028
pg_verifybackup: error: WAL parsing failed for timeline 1
```

Effectuer la même vérification en ignorant les journaux de transactions :
```
$ pg_verifybackup --ignore=conf --no-parse-wal $BKP_DIR/bkp_plain
backup successfully verified
```

#### Plus de corrumptions des fichiers dans la sauvegarde

Modifier le fichier `PG_VERSION` :

```
$ cp $BKP_DIR/bkp_plain/PG_VERSION .
$ echo "##" >> $BKP_DIR/bkp_plain/PG_VERSION
```

Retirer le fichier `backup_label` et le wal modifié précédemment :

```
$ mv $BKP_DIR/bkp_plain/backup_label .
$ rm $BKP_DIR/bkp_plain/pg_wal/000000010000000000000008
```

Compter les fichiers dans le répertoire `pg_twophase` puis déplacer le
répertoire :

```
$ find $BKP_DIR/bkp_plain/pg_twophase/ -type f | wc -l
0
$ mv $BKP_DIR/bkp_plain/pg_twophase .
```

Vérifier la sauvegarde : 

```
$ pg_verifybackup --ignore=conf $BKP_DIR/bkp_plain
pg_verifybackup: error: "PG_VERSION" has size 6 on disk but size 3 in the manifest
pg_verifybackup: error: "backup_label" is present in the manifest but not on disk
pg_waldump: fatal: could not find any WAL file
pg_verifybackup: error: WAL parsing failed for timeline 1
```

`pg_verifybackup` ne vérifie que les fichiers, c'est pour cette raison qu'il
n'y a pas d'erreurs associées à la suppression du répertoire `pg_twophase`.

La base de données a beaucoup grandi et la sauvegarde est volumineuse.
Vérifier la sauvegarde en sortant dès la première erreur :

```
$ pg_verifybackup --ignore=conf --exit-on-error $BKP_DIR/bkp_plain
pg_verifybackup: error: "PG_VERSION" has size 6 on disk but size 3 in the manifest
```

#### Vérifier une sauvegarde au format `tar`

Tenter de vérifier la sauvegarde compressée :

```
$ pg_verifybackup $BKP_DIR/bkp_compresse/
```

On peut observer que la vérification échoue, car il faut que la sauvegarde soit
décompressée et décompactée pour que les fichiers soient accessibles.

</div>
