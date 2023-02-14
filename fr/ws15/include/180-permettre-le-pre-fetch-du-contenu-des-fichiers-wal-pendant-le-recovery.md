<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/flat/20220904075450.6g4nm4hralyw3tab%40alvherre.pgsql#b09ec140fdc8247989ef4ba6442aa58c

-->

<div class="slide-content">
  * Accélération du recovery grâce au _prefetch_ des blocs de données
    accédés dans les enregistrements de WAL
    + `recovery_prefetch` : `try, on, off`
    + `wal_decode_buffer_size` distance à laquelle on peut lire les WAL en
      avance de phase
  * nouvelle vue : `pg_stat_recovery_prefetch`

</div>

<div class="notes">

Le nouveau paramètre `recovery_prefetch` permet d'activer le _prefetch_ lors du
rejeu des WAL. Il permet de lire à l'avance les WAL et d'initier la lecture
asynchrone des blocs de données qui ne sont pas dans le cache de l'instance.
Tous les OS ne permettent pas d'implémenter cette fonctionnalité, le paramètre
a donc trois valeurs possibles `try`, `on` et `off`. La valeur par défaut est
`try`.

`wal_decode_buffer_size` permet de limiter la distance à laquelle on peut lire
les WAL en avance de phase. Sa valeur par défaut est de 512 ko.

Le GUC `maintenance_io_concurrency` est également utilisé pour limiter le
nombre d'I/O concurrentes autorisées, ainsi que le nombre de blocs à lire en
avance. Le calcul utilisé est le suivant : `maintenance_io_concurrency * 4`
blocs.

Cette nouvelle fonctionnalité devrait accélérer grandement la recovery suite à
un crash, une restauration ou lorsque la réplication utilise le _log shipping_.

Précédemment, pour réaliser ce genre d'optimisation, il fallait passer des
outils externes comme [pg_prefaulter] qui a servi d'inspiration à cette
fonctionnalité.

[pg_prefaulter]: https://github.com/TritonDataCenter/pg_prefaulter


Création d'un environnement de test :

```bash
PGDATA=/home/benoit/var/lib/postgres/testpg15
PGDATASAV=/home/benoit/var/lib/postgres/testpg15-save
PGUSER=postgres
PGPORT=5432

initdb --username "$PGUSER" "$PGDATA"
```

Démarrer PostgreSQL en forçant des checkpoints très éloignés les un des
autres. Pour cela on augmente le timeout et la quantité maximale de WAL avant
le déclenchement du checkpoint. On désactive aussi les _full page writes_ pour
éviter que les pages complètes soient dans les WAL. En effet dans ce cas, le
préfetch est inutile.

```bash
pg_ctl -D "$PGDATA" \
       -o "-c checkpoint_timeout=60min -c max_wal_size=10GB -c full_page_writes=off" \
       -W \
       start
```

Ajouter des données avec pgbench pour générer des WAL.

```bash
pgbench -i -s300 postgres
psql postgres -c checkpoint
pgbench -T300 -Mprepared -c4 -j4 postgres
```

Tuer PostgreSQL pour forcer une restauration au redémarrage de PostgreSQL.

```
killall -9 postgres
```

Sauvegarder le répertoire de données.

```bash
cp -R "$PGDATA" "$PGDATASAV"
```

Démarrer PostgreSQL avec le prefetch désactivé :

```bash
pg_ctl -D "$PGDATA" \
       -o "-c recovery_prefetch=off" \
       -W \
       start
```

Voici les traces du démarrage :

```text
LOG:  starting PostgreSQL 15.1 on x86_64-pc-linux-gnu,
      compiled by gcc (GCC) 12.2.1 20220819 (Red Hat 12.2.1-2), 64-bit
LOG:  listening on IPv6 address "::1", port 5432
LOG:  listening on IPv4 address "127.0.0.1", port 5432
LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
LOG:  database system was interrupted; last known up at 2023-02-10 23:17:43 CET
LOG:  database system was not properly shut down; automatic recovery in progress
LOG:  redo starts at 0/E7A522B8
LOG:  redo in progress, elapsed time: 10.00 s, current LSN: 0/E82D8528
LOG:  redo in progress, elapsed time: 20.00 s, current LSN: 0/E8B3A690
LOG:  redo in progress, elapsed time: 30.00 s, current LSN: 0/E93F3D98
LOG:  redo in progress, elapsed time: 40.00 s, current LSN: 0/E9C57E60
LOG:  redo in progress, elapsed time: 50.00 s, current LSN: 0/EA4EB5A8
FATAL:  the database system is not yet accepting connections
DETAIL:  Consistent recovery state has not been yet reached.
LOG:  redo in progress, elapsed time: 60.00 s, current LSN: 0/EAD8F530
FATAL:  the database system is not yet accepting connections
DETAIL:  Consistent recovery state has not been yet reached.
LOG:  invalid record length at 0/EB4CAF48: wanted 24, got 0
LOG:  redo done at 0/EB4CAF10 system usage: CPU: user: 6.75 s, system: 15.58 s, elapsed: 67.99 s
LOG:  checkpoint starting: end-of-recovery immediate wait
LOG:  checkpoint complete:
      wrote 10366 buffers (63.3%);
      0 WAL file(s) added, 4 removed, 0 recycled;
      write=0.325 s, sync=0.010 s, total=0.367 s;
      sync files=23, longest=0.005 s, average=0.001 s;
      distance=59875 kB, estimate=59875 kB
LOG:  database system is ready to accept connections
```

Arrêter PostgreSQL, copier de la sauvegarde du répertoire de données et
démarrer PostgreSQL avec le prefetch activé :

```bash
pg_ctl -D "$PGDATA" \
       -m fast \
       stop

rm -fr "$PGDATA"
cp -r "$PGDATASAV" "$PGDATA"

pg_ctl -D "$PGDATA" \
       -o "-c recovery_prefetch=try" \
       -W \
       start
```

```sh
LOG:  starting PostgreSQL 15.1 on x86_64-pc-linux-gnu,
      compiled by gcc (GCC) 12.2.1 20220819 (Red Hat 12.2.1-2), 64-bit
LOG:  listening on IPv6 address "::1", port 5432
LOG:  listening on IPv4 address "127.0.0.1", port 5432
LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
LOG:  database system was interrupted; last known up at 2023-02-10 23:17:43 CET
LOG:  database system was not properly shut down; automatic recovery in progress
LOG:  redo starts at 0/E7A522B8
LOG:  redo in progress, elapsed time: 10.00 s, current LSN: 0/EAD67BC0
LOG:  invalid record length at 0/EB4CAF48: wanted 24, got 0
LOG:  redo done at 0/EB4CAF10 system usage: CPU: user: 3.57 s, system: 7.26 s, elapsed: 11.46 s
LOG:  checkpoint starting: end-of-recovery immediate wait
LOG:  checkpoint complete:
      wrote 10179 buffers (62.1%);
      0 WAL file(s) added, 4 removed, 0 recycled;
      write=0.322 s, sync=0.039 s, total=0.429 s;
      sync files=23, longest=0.017 s, average=0.002 s;
      distance=59875 kB, estimate=59875 kB
LOG:  database system is ready to accept connections
```

On voit que le _redo_ a duré 11.46s au lieu de 1min 8s du test lors du
précédent.

Des statistiques peuvent être lues dans la nouvelle vue
`pg_stat_recovery_prefetch` :

```sql
SELECT * FROM pg_stat_recovery_prefetch \gx
```
```sh
stats_reset    | 2023-02-10 23:35:55.873179+01
prefetch       | 200524
hit            | 416757
skip_init      | 2308
skip_new       | 0
skip_fpw       | 0
skip_rep       | 140012
wal_distance   | 0
block_distance | 0
io_depth       | 0
```

La signification des colonnes est la suivante :

* prefetch : Nombre de blocs récupérés avec le prefetch parce que le les blocs
  ne sont pas le buffer pool ;
* hit : Nombre de blocs qui n'ont pas été récupérés avec le prefetch car ils
  étaient déjà dans le buffer pool ;
* skip_init : Nombre de blocs qui n'ont pas été récupérés avec le prefetch car
  ils auraient été initialisé à zéro ;
* skip_init : Nombre de blocs qui n'ont pas été récupérés avec le prefetch car
  ils n'existaient pas encore ;
* skip_fpw : Nombre de blocs qui n'ont pas été récupérés avec le prefetch car
  une lecture de page complête était incluse dans le WAL ;
* skip_rep : Nombre de blocs qui n'ont pas été récupérés avec le prefetch car
  elles ont déjà été préfetchées récemment ;
* wal_distance : De combien de bytes le prefetcher est entrain de lire en
  avance ; block_distance : De combien de blocs le prefetcher est en train de
  lire en avance ;
* io_depth : Combien de prefetch ont été initialisés mais ne sont pas encore
  terminés.

</div>
