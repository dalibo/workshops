<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/30/2693/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=8d9a935965f01b7759a8c23ff6291000b670a2bf
* https://commitfest.postgresql.org/32/2859/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=ff99918c625a84c91e7391db9032112ec8653623

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/129

-->

<div class="slide-content">

* Permet de monitorer l'activité des WAL
* Nouveau paramètre : `track_wal_io_timing`

</div>

<div class="notes">

La nouvelle vue système `pg_stat_wal` permet d'obtenir des statistiques sur l'activité des WAL. Elle est composée des champs suivants :

* `wal_records` : Nombre total d'enregistrement WAL 
* `wal_fpi` : Nombre total d'enregistrement _full page images_
* `wal_bytes` : Quantité totale de WAL générés en octets
* `wal_buffers_full` : Nombre de fois où des enregistrements WAL ont été ecrit sur disque car le _WAL buffers_ était plein 
* `wal_write` : Nombre de fois ou les données du _WAL buffers_ ont été écrit sur disque via une requête `XLogWrite`
* `wal_sync` : Nombre de fois ou les données du _WAL buffers_ ont été synchronisées sur disque via une requête `issue_xlog_fsync`
* `wal_write_time` : Temps total passé à écrire les données du _WAL buffers_ sur disque via une requête `XLogWrite`
* `wal_sync_time` : Temps total passé à synchroniser les données du _WAL buffers_ sur disque via une requête `issue_xlog_fsync`
* `stats_reset` : Date de la dernière remise à zéro des statistiques

Cette vue introduit également un nouveau paramètre : `track_wal_io_timing`. Il permet d'activer ou non le chronométrage des appels d'entrées/sorties pour les WAL. Par défaut celui-ci est à `off`. En raison d'appels répétés au système d'exploitation, l'activation de ce paramètre peut entraîner une surcharge importante. Une mesure de ce surcoût pourra être réalisée avec l'outil `pg_test_timing`. Seul un super utilisateur peut modifier ce paramètre.

L'activation de `track_wal_io_timing` est nécessaire afin d'obtenir des données pour les colonnes `wal_write_time` et `wal_sync_time` de la vue `pg_stat_wal`.

</div>