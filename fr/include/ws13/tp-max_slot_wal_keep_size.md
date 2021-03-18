## TP - Volume maximal de journaux conservé par les slots

<div class="slide-content">

  * Création d'un slot ;
  * Modification de la configuration des slots ;
  * Simulation d'un décrochage.

</div>

<div class="notes">

### Création d'un slot

Sur une machine CentOS 7 ou 8 où les binaires de PostgreSQL sont installés,
créer une instance si elle n'existe pas déjà.

Le volume maximal de WAL produit par la mécanique transactionnelle
(`max_wal_size`) doit être diminué à 200 Mo afin de limiter l'espace nécessaire
au test et rendre plus fréquents les `CHECKPOINT`.

Positionner `synchronous_commit` afin d'accélérer les futures écritures.

En tant que root :

```console
# export PGSETUP_INITDB_OPTIONS='--data-checksums --lc-messages=C'
# /usr/pgsql-13/bin/postgresql-13-setup initdb
# echo "max_wal_size = 200MB" >> ~postgres/13/data/postgresql.conf
# echo "synchronous_commit = off" >> ~postgres/13/data/postgresql.conf
# systemctl start postgresql-13
```

Créer une base avec un peu de volumétrie :

~~~console
# sudo -iu postgres /usr/pgsql-13/bin/pgbench -i -s20
~~~

Créer maintenant un slot physique `slot_tp` conservant dès à présent les WAL
générés (second argument à `true`) :

~~~console
# sudo -iu postgres psql -qc \
    "SELECT * FROM pg_create_physical_replication_slot('slot_tp', true)"
 slot_name |    lsn
-----------+------------
 slot_tp   | 0/1903F6E0

# sudo -iu postgres psql -qc \
    "SELECT slot_name, restart_lsn, wal_status FROM pg_replication_slots"
 slot_name | restart_lsn | wal_status 
-----------+-------------+------------
 slot_tp   | 0/1D014018  | reserved
~~~

### Rétention des slots

Limiter à 400 Mo le volume de WAL que peuvent retenir les slots de réplication :

```console
# sudo -iu postgres psql << _EOF_
ALTER SYSTEM SET max_slot_wal_keep_size = '400MB';
SELECT pg_reload_conf();
_EOF_
```

Vérifier la valeur de `max_slot_wal_keep_size` :

```
# sudo -iu postgres psql -XAtc "show max_slot_wal_keep_size"
400MB
```

### Générer de l'activité et observer le nouveau fonctionnement

Lancer en tâche de fond `pgbench` pour générer de l'activité en écriture et
observer l'évolution du slot de réplication :

```console
# sudo -iu postgres /usr/pgsql-13/bin/pgbench -T 300 &

# while sudo -iu postgres psql -AXtc "
  WITH s AS(
    SELECT count(*)-1 AS wals
    FROM pg_ls_dir('pg_wal')
  )
  SELECT
    slot_name, wal_status,
    pg_size_pretty(safe_wal_size)       AS safe_wal_size,
    pg_size_pretty(16*1024*1024*s.wals) AS wal_size
  FROM pg_replication_slots, s"
do
    sleep 1
done
slot_tp|reserved|287 MB|192 MB
slot_tp|reserved|274 MB|192 MB
slot_tp|reserved|263 MB|192 MB
slot_tp|reserved|252 MB|192 MB
slot_tp|reserved|241 MB|192 MB
slot_tp|reserved|233 MB|192 MB
slot_tp|reserved|225 MB|192 MB
slot_tp|reserved|217 MB|208 MB
slot_tp|reserved|208 MB|208 MB
slot_tp|reserved|201 MB|224 MB
slot_tp|reserved|194 MB|224 MB
slot_tp|extended|187 MB|240 MB
slot_tp|extended|181 MB|240 MB
slot_tp|extended|174 MB|256 MB
slot_tp|extended|168 MB|256 MB
slot_tp|extended|162 MB|256 MB
slot_tp|extended|154 MB|272 MB
slot_tp|extended|144 MB|288 MB
slot_tp|extended|134 MB|288 MB
slot_tp|extended|124 MB|304 MB
slot_tp|extended|115 MB|304 MB
slot_tp|extended|107 MB|320 MB
slot_tp|extended|98 MB|320 MB
slot_tp|extended|90 MB|336 MB
slot_tp|extended|82 MB|336 MB
slot_tp|extended|74 MB|352 MB
slot_tp|extended|67 MB|352 MB
slot_tp|extended|60 MB|368 MB
slot_tp|extended|53 MB|368 MB
slot_tp|extended|47 MB|384 MB
slot_tp|extended|41 MB|384 MB
slot_tp|extended|35 MB|384 MB
slot_tp|extended|29 MB|400 MB
slot_tp|extended|20 MB|400 MB
slot_tp|extended|10 MB|416 MB
slot_tp|extended|1416 kB|416 MB
slot_tp|unreserved|-7352 kB|432 MB
slot_tp|unreserved|-15 MB|432 MB
slot_tp|unreserved|-23 MB|448 MB
slot_tp|unreserved|-30 MB|448 MB
slot_tp|lost||464 MB
slot_tp|lost||464 MB
slot_tp|lost||464 MB
slot_tp|lost||464 MB
^C^C^C
```

Nous observons que la colonne `wal_status` prend la valeur `extended` lorsque
la volumétrie conservée dépasse `max_wal_size` et que le `checkpoint` en cours
se termine. Ce dernier ne peut détruire les WAL en trop et les laisse donc à la
charge des slots.

Peu de temps après que le volume de WAL dépasse la rétention maximale imposée,
le statut passe ensuite brièvement à `unreserved`, là aussi le temps que le
checkpoint en cours se termine, avant de passer définitivement au statut
`lost`. La colonne `safe_wal_size` quant à elle devient négative lorsque le
statut devient `unreserved`, puis devient nulle lorsque le slot est perdu.

Nous constatons aussi que la volumétrie des WAL ne redescend pas une fois le
slot perdu. Même perdu, ce dernier conserve une fenêtre glissante de WAL.
Pour récupérer l'espace disque et nettoyer les WAL de trop, il nous
faut le supprimer et forcer un checkpoint pour éviter d'attendre le suivant :

```console
# sudo -iu postgres psql << _EOF_
SELECT pg_drop_replication_slot('slot_tp');
CHECKPOINT;
_EOF_
```

La volumétrie dans `pg_wal` diminue immédiatement :

```console
# du -Sh ~postgres/13/data/pg_wal
193M    /var/lib/pgsql/13/data/pg_wal
```

</div>
