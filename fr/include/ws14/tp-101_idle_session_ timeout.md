## TP - `idle_session_timeout`

<div class="slide-content">
Nouveau paramètre
  * `idle_session_timeout`
</div>

<div class="notes">
### `idle_session_timeout`

Se connecter à l'instance

```
$ psql
psql (14beta1)
Type "help" for help.
```

Changer la valeur du paramètre `idle_session_timeout` en mettant la valeur
`5000`.

```
SET idle_session_timeout TO 5000;
SET
```

Attendre 5 secondes.

```
postgres=# 2021-05-25 08:28:45.603 UTC [6594] FATAL:  terminating connection due to idle-session timeout
```

Le processus de la session a été terminée par postgres.

</div>
