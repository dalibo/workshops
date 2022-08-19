<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/36/3312/

Discussion

* https://www.postgresql.org/message-id/flat/CAH7T-aqswBM6JWe4pDehi1uOiufqe06DJWaU5=X7dDLyqUExHg@mail.gmail.com

-->



<div class="slide-content">
* Nouveau format de sortie pour les fichiers trace : `jsonlog`
</div>

<div class="notes">

Le paramètre `log_destination` se voit enrichi d'une nouvelle option `jsonlog` 
qui permet d'obtenir une journalisation au format _JSON_.

```sql
postgres=# show log_destination ;
 log_destination 
-----------------
 jsonlog
```

Voici un exemple d'une ligne de trace, la première générée au démarrage de l'instance :

```json
{
  "timestamp": "2022-07-26 10:26:36.370 UTC",
  "pid": 3330,
  "session_id": "62dfc15c.d02",
  "line_num": 2,
  "session_start": "2022-07-26 10:26:36 UTC",
  "txid": 0,
  "error_severity": "LOG",
  "message": "starting PostgreSQL 15beta2 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-10), 64-bit",
  "backend_type": "postmaster",
  "query_id": 0
}

```

Les traces au format _JSON_ peuvent s'avérer utile pour alimenter les traces de 
l'instance dans un autre programme. _pg_badger_ supporte déjà l'analyse de traces 
dans ce format, car il supportait auparavant l'extension `jsonlog` qui ajoutait 
cette fonctionnalité avant qu'elle soit intégrée en standard dans PostgreSQL.

Par ailleurs, l'utilisation de l'outil `jq` permet de rechercher des clés 
spécifiques dans les traces, par exemple pour n'afficher que les erreurs :

```sh
[postgres@pg1 log]$ jq 'select(.error_severity == "ERROR" )' postgresql-Tue.json 
{
  "timestamp": "2022-07-26 10:45:16.563 UTC",
  "user": "postgres",
  "dbname": "postgres",
  "pid": 3361,
  "remote_host": "[local]",
  "session_id": "62dfc250.d21",
  "line_num": 1,
  "ps": "INSERT",
  "session_start": "2022-07-26 10:30:40 UTC",
  "vxid": "3/20",
  "txid": 0,
  "error_severity": "ERROR",
  "state_code": "42P01",
  "message": "relation \"t2\" does not exist",
  "statement": "insert into t2 values ('missing_table_test');",
  "cursor_position": 13,
  "application_name": "psql",
  "backend_type": "client backend",
  "query_id": 0
}
```

</div>