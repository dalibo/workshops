<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=d627ce3b706de16279d8eb683bfeda34ad7197fe

Discussion :

* https://www.postgresql.org/message-id/20220914222736.GA3042279%40nathanxps13

-->

<div class="slide-content">

* `archive_library` et `archive_command` ne peuvent pas être configurés en même
  temps
* Une erreur FATAL est renvoyée
* Avant `archive_library` prenait le dessus

</div>

<div class="notes">

Il n'est désormais plus possible de définir les paramètres `archive_library` et
`archive_command` en même temps. Si c'est le cas, une erreur est remontée dans
les traces. Par exemple :

```bash
2023-08-22 16:49:12.620 CEST [2082970] LOG:  database system was shut down at 2023-08-22 16:49:12 CEST
2023-08-22 16:49:12.631 CEST [2082967] LOG:  database system is ready to accept connections
2023-08-22 16:49:12.631 CEST [2082973] FATAL:  both archive_command and archive_library set
2023-08-22 16:49:12.631 CEST [2082973] DETAIL:  Only one of archive_command, archive_library may be set.
```

L'archivage des fichiers ne se fera pas tant que les deux paramètres seront
présents. Le fichier de transaction sera marqué comme `ready` et sera archivé
lors d'un rechargement de la configuration une fois corrigée.

</div>
