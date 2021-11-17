<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=aaf043257205ec523f1ba09a3856464d17cf2281

	Thanks. +1 to remove the pg_wait_for_backend_termination function. The
	patch basically looks good to me. I'm attaching an updated patch. I
	corrected a minor typo in the commit message, took docs and code
	comment changes suggested by Justin Pryzby.

Discussion

* https://www.postgresql.org/message-id/flat/CALj2ACUBpunmyhYZw-kXCYs5NM+h6oG_7Df_Tn4mLmmUQifkqA@mail.gmail.com

-->

<div class="slide-content">

```
pg_terminate_backend ( pid integer, timeout bigint DEFAULT 0 )
```

* Possibilité d'attendre l'arrêt du backend
* Nouveau paramètre `timeout`

</div>

<div class="notes">

Il est désormais possible d'attendre l'arrêt du backend ciblé par l'exécution
de `pg_terminate_backend()` pendant un temps configuré avec le nouveau
paramètre `timeout` de cette fonction :

```text
# \df pg_terminate_backend

List of functions
-[ RECORD 1 ]-------+--------------------------------------
Schema              | pg_catalog
Name                | pg_terminate_backend
Result data type    | boolean
Argument data types | pid integer, timeout bigint DEFAULT 0
Type                | fun
```

Ce paramètre est exprimé en millisecondes et est configuré à 0 par défaut, ce
qui signifie que l'on n'attend pas.

En le configurant à une valeur positive, on attendra que le backend soit arrêté
ou que le timeout configuré soit atteint. Si le timeout est atteint, un message
d'avertissement sera affiché à l'écran et la fonction renverra `false` :

```sql
# SELECT pg_terminate_backend(358855, 200);
```
```text
WARNING:  backend with PID 358818 did not terminate within 200 milliseconds
-[ RECORD 1 ]--------+--
pg_terminate_backend | f
```

</div>
