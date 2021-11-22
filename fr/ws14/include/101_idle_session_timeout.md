<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/31/2646/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9877374bef76ef03923f6aa8b955f2dbcbe6c2c7

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/101

-->

<div class="slide-content">

* Nouveau paramètre `idle_session_timeout`
* Temps d'attente avant d'interrompre une session inactive
  * Désactivé par défaut (valeur `0`)
  * Comportement voisin de `idle_in_transaction_session_timeout`
  * Paramètre de session, ou globalement pour l'instance

</div>

<div class="notes">

Le paramètre `idle_session_timeout` définit la durée maximale sans activité entre 
deux requêtes lorsque l'utilisateur n'est pas dans une transaction. Son
comportement est similaire à celui du paramètre `idle_in_transaction_session_timeout`
introduit dans PostgreSQL 9.6, qui ne concerne que les session en statut
`idle in transaction`.

Ce paramètre a pour conséquence d'interrompre toute session inactive depuis plus 
longtemps que la durée indiquée par ce paramètre. Cela permet de limiter la 
consommation de ressources des sessions inactives (mémoire
notamment) et de diminuer le coût de maintenance des sessions connectées à l'instance
en limitant leur nombre.

Si cette valeur est indiquée sans unité, elle est comprise comme un nombre en
millisecondes. La valeur par défaut de `0` désactive cette fonctionnalité. Le
changement de la valeur du paramètre `idle_session_timeout` ne requiert pas de
démarrage ou de droit particulier.

```sql
SET idle_session_timeout TO '5s';
-- Attendre 5 secondes.

SELECT 1;
```
```text
FATAL:  terminating connection due to idle-session timeout
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
```

Un message apparaît dans les journaux d'activité :

```text
FATAL:  terminating connection due to idle-session timeout
```
</div>
