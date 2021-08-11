<!--

Commit :
    https://www.postgresql.org/message-id/E1iwonu-0005Bd-6j%40gemulon.postgresql.org

Fail if recovery target is not reached.

Before, if a recovery target is configured, but the archive ended
before the target was reached, recovery would end and the server would
promote without further notice.  That was deemed to be pretty wrong.
With this change, if the recovery target is not reached, it is a fatal
error.

Discussion :
    https://www.postgresql.org/message-id/E1iwonu-0005Bd-6j%40gemulon.postgresql.org

-->

<div class="slide-content">

Erreur fatale quand la cible précisée n'est pas
atteinte en fin de restauration :

`FATAL: recovery ended before configured recovery target was reached`

</div>

<div class="notes">

Avant PostgreSQL 13, si une cible de restauration est configurée, mais que le rejeu
des archives s'arrête avant que cette cible ne soit atteinte, l'instance
finissait son démarrage normalement.

Voici un exemple de traces avec une `recovery_target_timeline` qui ne peut être
atteint sur une instance PostgreSQL 12.

```
LOG:  database system was interrupted; last known up at 2020-11-24 15:36:08 CET
ERROR: could not find /backup/pitrery-pgsql-12/archived_wal/00000002.history
LOG:  starting point-in-time recovery to 2020-11-24 19:00:00+01
LOG:  restored log file "00000001000000180000005B" from archive
LOG:  redo starts at 18/5B000028
LOG:  consistent recovery state reached at 18/5B000138
LOG:  database system is ready to accept read only connections
ERROR: could not find /backup/pitrery-pgsql-12/archived_wal/00000001000000180000005C
LOG:  redo done at 18/5B000138
LOG:  restored log file "00000001000000180000005B" from archive
ERROR: could not find /backup/pitrery-pgsql-12/archived_wal/00000002.history
LOG:  selected new timeline ID: 2
LOG:  archive recovery complete
ERROR: could not find /backup/pitrery-pgsql-12/archived_wal/00000001.history
LOG:  database system is ready to accept connections
```

Dans ces messages, l'instance ne produit pas de message d'erreur en lien avec le
`recovery_target_timeline`. Les erreurs remontées sont normales dans le cadre
d'une restauration. Le dernier message nous informe que l'instance a démarré.

Avec la version 13 de PostgreSQL, si la cible de restauration ne peut être
atteinte, une erreur fatale est émise et l'instante s'arrête :

```
LOG:  database system was interrupted; last known up at 2020-11-24 15:48:09 CET
ERROR: could not find /backup/pitrery-pgsql-13/archived_wal/00000002.history
LOG:  starting point-in-time recovery to 2020-11-24 19:00:00+01
LOG:  restored log file "000000010000000B000000EA" from archive
LOG:  redo starts at B/EA000028
LOG:  consistent recovery state reached at B/EA000100
LOG:  database system is ready to accept read only connections
ERROR: could not find /backup/pitrery-pgsql-13/archived_wal/000000010000000B000000EB
LOG:  redo done at B/EA000100
FATAL:  recovery ended before configured recovery target was reached
LOG:  startup process (PID 229173) exited with exit code 1
LOG:  terminating any other active server processes
LOG:  database system is shut down
```

L'instance produit bien désormais un message d'erreur `FATAL` en lien avec la
`recovery_target_timeline`. Le dernier message nous informe que l'instance est
arrêtée.

Cette modification de comportement à deux intérêts :

1. Informer l'administrateur du fait que la restauration ne s'est pas déroulée
   comme prévu.
2. Permettre d'ajouter des WAL pour la restauration et d'atteindre la
   `recovery_target` dans le cas où on aurait oublié de tous les fournir.

</div>
