<!-- 

Commit :

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=70a7b4776be4e776221e578d8ca53b2b9f8118c0

-->

<div class="slide-content">

  * Ajout d'un nouvel échappement (`%b`) à `log_line_prefix` pour
    tracer le type de backend.
  * Le type de backend est également ajouté aux traces formatées en csv.

</div>

<div class="notes">

Le paramètre `log_line_prefix` dispose d'un nouveau caractère d'échappement :
`%b`.  Ce caractère permet de tracer le type de backend à l'origine d'un
message.  Il reprend le contenu de la colonne `pg_stat_activity.backend_type`
cependant d'autres type de backend peuvent apparaître dont `postmaster`.

Exemple pour la configuration suivante de `log_line_prefix = '[%b:%p] '`.

```
[postmaster:6783] LOG:  starting PostgreSQL 13.0 on x86_64-pc-linux-gnu, 
+++compiled by gcc (GCC) 9.3.1 20200408 (Red Hat 9.3.1-2), 64-bit
[postmaster:6783] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5433"
[startup:6789] LOG:  database system was interrupted; last known up at 
+++2020-11-02 12:02:32 CET
[startup:6789] LOG:  database system was not properly shut down; 
+++automatic recovery in progress
[startup:6789] LOG:  redo starts at 1/593E1038
[startup:6789] LOG:  invalid record length at 1/593E1120: wanted 24, got 0
[startup:6789] LOG:  redo done at 1/593E10E8
[postmaster:6783] LOG:  database system is ready to accept connections
[checkpointer:6790] LOG:  checkpoints are occurring too frequently (9 seconds apart)
[autovacuum worker:7969] LOG:  automatic vacuum of table 
+++"postgres.public.grosfic": index scans: 0
   pages: 0 removed, 267557 remain, 0 skipped due to pins, 0 skipped frozen
   tuples: 21010000 removed, 21010000 remain, 0 are dead but not yet removable, 
+++oldest xmin: 6196
   buffer usage: 283734 hits, 251502 misses, 267604 dirtied
   avg read rate: 10.419 MB/s, avg write rate: 11.086 MB/s
   system usage: CPU: user: 16.78 s, system: 8.53 s, elapsed: 188.58 s
   WAL usage: 802621 records, 267606 full page images, 2318521769 bytes
[autovacuum worker:7969] LOG:  automatic analyze of table "postgres.public.grosfic" 
+++system usage: CPU: user: 0.54 s, system: 0.58 s, elapsed: 5.93 s
```

Le type de backend a également été ajouté aux traces formatées en csv
(`log_destination = 'csvlog'`).

</div>
