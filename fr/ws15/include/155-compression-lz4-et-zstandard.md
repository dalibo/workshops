<!--
Les commits sur ce sujet sont :

* pgsql: Simplify handling of compression level with compression specific
  https://www.postgresql.org/message-id/E1oYIua-000FJa-T7@gemulon.postgresql.org

* pgsql: doc: Simplify description of --with-lz4
  https://www.postgresql.org/message-id/E1nLIyu-00036R-SQ@gemulon.postgresql.org 

* pgsql: Add support for zstd with compression of full-page writes in WAL
  https://www.postgresql.org/message-id/E1nSVoo-000CqO-5E@gemulon.postgresql.org

* pgsql: Add suport for server-side LZ4 base backup compression.
  https://www.postgresql.org/message-id/flat/E1nIWNg-0005L1-2v%40gemulon.postgresql.org

* pgsql: pg_basebackup: Allow client-side LZ4 (de)compression.
  https://www.postgresql.org/message-id/flat/E1nIXEy-0005ck-IR%40gemulon.postgresql.org

* pgsql: Handle compression level in pg_receivewal for LZ4
  https://www.postgresql.org/message-id/E1ngG2z-0010Ou-M6@gemulon.postgresql.org

-->

<div class="slide-content">

* Écritures de page complètes :
  + `pglz` (défaut utilisé pour `on`), `lz4`, `zstd`

* Sauvegardes avec `pg_basebackup` :
  + `--compression [{client|server}-]method:detail`
  + method: `gzip`, `lz4`, `zstd` 
  + detail: `[level=]entier`, `workers=entier` (`zstd`)


* Récupération de WAL avec `pg_receivewal ` :
  + `--compression method:detail`
  + method: `gzip`, `lz4`
  + detail: `[level=]entier`

</div>

<div class="notes">

PostgreSQL permet désormais d'utiliser les algorithmes de compressions _LZ4_,
_Zstandard_ en plus de  _gzip_ pour la compression des sauvegardes, des WAL et
des écritures de page complètes.

**Avantages attendus par type de compression**

`gzip` est la méthode de compression historique de PostgreSQL, elle est
utilisée par défaut.

`lz4` est plus rapide que `gzip` mais a généralement un taux de compression
inférieur.

`zstd` présente l'avantage de permettre la parallélisation de la compression, ce qui permet plus de performances.

**Type de compression et compilation**

L'utilisation de l'algorithme `lz4` nécessite l'utilisation du paramètre
`--with-lz4` lors de la compilation. Ce paramètre avait été ajouté en version
14 pour permettre l'utilisation de `lz4` afin de compresser les TOAST.

Le paramètre `--with-zstd` a été ajouté en version 15 pour permettre
l'utilisation de l'algorithme `zstd`. Ces paramètres sont activés par défaut
sur les distributions de type RockyLinux et Debian.

**Écriture de pages complètes**

Le paramètre `wal_compression` acceptait précédemment deux valeurs `on` et
`off`. Il permettait d'activer ou non la compression des images de page
complètes (_FPI: Full Page Image_) écrites dans les WAL lorsque le paramètre
`full_page_writes` était activé ou pendant une sauvegarde physique.

En version 15, trois nouveaux paramètres sont ajoutés et permettent de
contrôler le type d'algorithme de compression utilisé parmi : `pglz`, `lz4` et
`zstd`. Le mode de compression par défaut est `pglz`, c'est l'algorithme choisi
si l'on valorise `wal_compression` à `on`.

**pg_basebackup**

Il est désormais également possible de spécifier l'algorithme de compression
utilisé par `pg_basebackup` avec l'option `--compression / -Z` dont la nouvelle
spécification est :

```text
-Z level
-Z [{client|server}-]method[:detail]
--compress=level
--compress=[{client|server}-]method[:detail]
```

Les valeurs possibles pour la méthode de compression sont `none`, `gzip`, `lz4`
et `zstd`.  Lorsqu'un algorithme de compression est spécifié, il est possible
d'ajouter des options de compression en ajoutant une série de paramètre précédé
de deux point et séparé par des virgules, sous la forme d'un `mot clé` ou d'un
`mot clé=valeur`. Pour le moment, les mots clé suivants sont supportés :

* `[level=]entier` permet de spécifier le niveau de compression ;
* `workers=entier` permet de spécifier le nombre de processus pour la
  parallélisation de la compression.

Exemples :

```bash
$ pg_basebackup --format t \
                --compress server-lz4:1 \
                --pgdata splz41

$ pg_basebackup --format t \
                --compress server-lz4:level=1 \
                --pgdata splz4l1

$ pg_basebackup --format t \
                --compress server-zstd:level=9,workers=2 \
                --pgdata spzstdl9w2
```

Seule la compression `zstd` accepte le paramètre `workers` :

```bash
$ pg_basebackup -Ft \
                --compress=server-zstd:level=9,workers=2 \
                --pgdata stzstl9w2

$ pg_basebackup -Ft \
                --compress server-lz4:level=9,workers=2 \
                --pgdata stlzl9w2
```
```text
pg_basebackup: error: could not initiate base backup:
+++ERROR:  invalid compression specification: compression algorithm "lz4" does not accept a worker count
pg_basebackup: removing data directory "stlzl9w2"
```

Si aucun algorithme de compression n'est spécifié et que le niveau de
compression est de 0, aucune compression n'est mise en place. Si le niveau de
compression est supérieur à zéro, la compression `gzip` est utilisée avec le
niveau spécifié.

Il est possible de spécifier le lieu où sera effectuée la compression en
précédant le nom de l'algorithme de compression par `client-` ou `server-`.
Activer la compression côté serveur permet de réduire le coût en bande passante
au prix de l'augmentation de la consommation CPU. La valeur par défaut est
`client` à moins que l'option `--target=server...` ne soit spécifiée, dans ce
cas, la sauvegarde est réalisée sur le serveur de base de données, la
compression sera donc réalisée également sur le serveur. La notion de cible est
abordée dans un chapitre séparé.

Exemple d'une sauvegarde réalisée côté serveur :

```bash
$ pg_basebackup --wal-method fetch \
                --target server:/var/lib/postgres/sauvegarde/sstlz4 \
                --compress server-lz4
$ ls ./sstlz4/
```
```text
backup_manifest base.tar.lz4
```

On peut voir que si le format ne peut être spécifié avec une sauvegarde côté
serveur, il est forcé à `tar`.

```bash
$ pg_basebackup --wal-method fetch \
                --format p \
                --target server:/var/lib/postgres/sauvegarde/sstlz4 \
                --compress server-lz4
```
```text
pg_basebackup: error: cannot specify both format and backup target
pg_basebackup: hint: Try "pg_basebackup --help" for more information
```

La compression des WAL côté serveur n'est pas possible quand `-Xstream` (ou
`--wal-method stream`) est utilisé. Pour cela, il faut utiliser `-Xfetch`.

L'exemple ci-dessous montre qu'avec la compression côté serveur et l'option
`-Xstream`, les WAL sont dans un fichier `tar` non compressé : `pg_wal.tar`.

```bash
$ pg_basebackup -Xstream \
                --format t \
                --compress server-gzip \
                --pgdata ./sctgzs
$ ls ./sctgzs/
```
```text
backup_manifest base.tar.gz pg_wal.tar
```

Avec l'option `-Xfetch`, les WAL sont placés dans le répertoire `pg_wal` et
compressés avec le reste de la sauvegarde.

```bash
$ pg_basebackup -Xfetch \
                --format t \
                --compress server-gzip \
                --pgdata ./sctgzf
$ ls ./sctgzf
```
```text
backup_manifest base.tar.gz
```

Si la compression est réalisée côté client et que l'option `-Xstream` est
choisie, l'algorithme de compression sélectionné doit être `gzip`. Dans ce cas,
le fichier `pg_wal.tar` sera compressé en `gzip`. Si un autre algorithme est
choisi, le fichier ne sera pas compressé.

Si le format `tar` est spécifié (`--format=t` / `Ft`) avec `gzip`, `lz4` et
`zstd`, l'extension du fichier de sauvegarde sera respectivement `.gz`, `.lz4`
ou `.zst`.

Dans cet exemple d'une compression avec `gzip`, on voit que `pg_wal.tar` est
compressé et que l'extension des fichiers compressé est `.gz`.

```bash
$ pg_basebackup -Ft --compress=gzip --pgdata tgzip
$ ls ./tgzip/
```
```text
backup_manifest base.tar.gz pg_wal.tar.gz
```

Exemple d'une compression avec `lz4`, on voit que `pg_wal.tar` n'est pas
compressé et que l'extension des fichiers compressé est `.lz4`.

```bash
$ pg_basebackup -Ft --compress=lz4 --pgdata tlz4 --progress
$ ls ./tlz4/
```
```text
backup_manifest base.tar.lz4 pg_wal.tar
```

Exemple d'une compression avec `zstd`, on voit que `pg_wal.tar` n'est pas
compressé et que l'extension des fichiers compressé est `.zst`.

```bash
$ pg_basebackup -Ft --compress=zstd --pgdata tzstd --progress
$ ls ./tzstd/
```
```text
backup_manifest base.tar.zst pg_wal.tar
```

Si le format `plain` est utilisé (`--format=p` / `-Fp`), la compression côté
client ne peut pas être choisie. Elle peut en revanche être spécifiée côté
serveur. Dans ce cas, le serveur va compresser les données pour le transfert et
le client les décompressera ensuite.

```bash
$ pg_basebackup -Fp --compress=lz4 --pgdata plz4
```
```text
pg_basebackup: error: only tar mode backups can be compressed
```

Dans cet exemple, on voit que la sauvegarde est compressée côté serveur et
décompressée sur le client :

```bash
$ pg_basebackup -Fp --compress=server-lz4 --pgdata scplz4
$ ls -al scplz4/
```
```text
total 372
drwx------. 20 postgres postgres   4096 Dec 12 17:49 .
drwxrwxr-x.  6 postgres postgres   4096 Dec 12 17:49 ..
-rw-------.  1 postgres postgres    227 Dec 12 17:49 backup_label
-rw-------.  1 postgres postgres 235587 Dec 12 17:49 backup_manifest
drwx------.  7 postgres postgres   4096 Dec 12 17:49 base
-rw-------.  1 postgres postgres     30 Dec 12 17:49 current_logfiles
drwx------.  2 postgres postgres   4096 Dec 12 17:49 global
drwx------.  2 postgres postgres   4096 Dec 12 17:49 log
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_commit_ts
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_dynshmem
-rw-------.  1 postgres postgres   4789 Dec 12 17:49 pg_hba.conf
-rw-------.  1 postgres postgres   1636 Dec 12 17:49 pg_ident.conf
drwx------.  4 postgres postgres   4096 Dec 12 17:49 pg_logical
drwx------.  4 postgres postgres   4096 Dec 12 17:49 pg_multixact
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_notify
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_replslot
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_serial
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_snapshots
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_stat
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_stat_tmp
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_subtrans
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_tblspc
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_twophase
-rw-------.  1 postgres postgres      3 Dec 12 17:49 PG_VERSION
drwx------.  3 postgres postgres   4096 Dec 12 17:49 pg_wal
drwx------.  2 postgres postgres   4096 Dec 12 17:49 pg_xact
-rw-------.  1 postgres postgres     88 Dec 12 17:49 postgresql.auto.conf
-rw-------.  1 postgres postgres  29665 Dec 12 17:49 postgresql.conf
```

Le test suivant consiste à sauvegarder une base de 630Mo contenant
principalement du _jsonb_ avec les trois algorithmes de compression. Le test
est réalisé sur un portable avec 8 CPU, 8 Go de RAM et un disque SSD.

Le tableau suivant montre le volume des sauvegardes (hors WAL `-Xnone`) par
niveau de compression. On peut voir que l'algorithme le plus performant est
`zstd`.

| Niveau de compression | Vol. gzip    | Vol. lz4     | Vol. zstd    |
|:---------------------:|-------------:|-------------:|-------------:|
| 1                     | 395 Mo (37%) | 498 Mo (20%) | 418 Mo (33%) |
| 2                     | 387 Mo (38%) | 498 Mo (20%) | 391 Mo (37%) |
| 3                     | 379 Mo (39%) | 406 Mo (35%) | 373 Mo (40%) |
| 4                     | 375 Mo (40%) | 401 Mo (36%) | 362 Mo (42%) |
| 5                     | 368 Mo (41%) | 399 Mo (36%) | 353 Mo (43%) |
| 6                     | 365 Mo (42%) | 398 Mo (36%) | 348 Mo (44%) |
| 7                     | 364 Mo (42%) | 397 Mo (36%) | 339 Mo (46%) |
| 8                     | 364 Mo (42%) | 397 Mo (36%) | 337 Mo (46%) |
| 9                     | 364 Mo (42%) | 397 Mo (36%) | 329 Mo (47%) |

Le tableau suivant montre les temps de sauvegarde par niveau de compression.
Pour le mode de compression `zstd`, le chiffre qui suit correspond au nombre de
processus utilisés pour la compression. On voit ici que l'algorithme le plus
rapide est `lz4`. `zstd` permet d'obtenir de meilleures performances si on
augmente le nombre de processus dédiés à la compression.

| Niveau | Vol. gzip | Vol.  lz4 | Vol. zstd 1 | Vol. zstd 2 | Vol. zstd 3 |
|:------:|----------:|----------:|------------:|------------:|------------:|
| 1      |    19.3 s |     3.9 s |       6.2 s |       3.5 s |       3.7 s |
| 2      |    21.0 s |     4.0 s |       7.4 s |       3.8 s |       3.2 s |
| 3      |    24.8 s |    13.1 s |       9.7 s |       5.4 s |       3.7 s |
| 4      |    26.7 s |    15.3 s |      12.1 s |       9.5 s |       8.5 s |
| 5      |    34.5 s |    18.2 s |      14.2 s |       9.4 s |       7.7 s |
| 6      |    44.0 s |    20.5 s |      19.9 s |      10.8 s |       8.6 s |
| 7      |    51.8 s |    21.7 s |      22.1 s |      14.9 s |      12.6 s |
| 8      |    61.0 s |    23.8 s |      26.2 s |      17.1 s |      14.4 s |
| 9      |    67.0 s |    24.7 s |      29.3 s |      21.6 s |      19.3 s |

**pg_receivewal**

Le dernier outil qui bénéficie des nouveaux algorithmes de compression
supportés par PostgreSQL est `pg_receivewal`. Là aussi, l'option
`--compression / -Z` est utilisée et sa nouvelle spécification est :

```text
-Z level
-Z method[:detail]
--compress=level
--compress=method[:detail]
```

Le principe est le même que pour `pg_basebackup` à quelques différences près :

* `pg_receivewal` compresse forcément les WAL côté client ;
* les algorithmes de compression disponible sont `gzip` et `lz4`. Cette
  évolution permettra donc d'avoir le choix entre taux de compression (`gzip`)
  et vitesse de compression (`lz4`).

La compression par défaut est `gzip`, les fichiers produits se terminent donc
pas l'extension `.gz`. Le niveau de compression peut être ajouté après la
méthode de compression sous forme d'un entier ou avec l'ensemble clé valeur
`level=nombre entier`.

```bash
$ pg_receivewal --compress 2
$ pg_receivewal --compress gzip:2
$ pg_receivewal --compress gzip:level=2
```

Avec les commandes précédentes, on obtient :

``` text
0000000100000000000000E6.gz 0000000100000000000000E7.gz.partial
```

Les fichiers compressés avec `lz4` se terminent par `.lz4`.


```bash
$ pg_receivewal --compress lz4:level=1
```

Avec la commande précédente, on obtient :

```
total 80
0000000100000000000000E7.lz4 0000000100000000000000E8.lz4.partial
```

</div>

