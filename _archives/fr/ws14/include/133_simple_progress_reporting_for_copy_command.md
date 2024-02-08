<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/31/2923/
* https://commitfest.postgresql.org/32/2977
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=8a4f618e7ae3cb11b0b37d0f06f05c8ff905833f

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/133

-->

<div class="slide-content">

* Possibilité de suivre l'avancement d'un `COPY` avec la vue `pg_stat_progress_copy`

</div>

<div class="notes">

Il est maintenant possible de surveiller la progression d'une instruction `COPY`
grâce à la vue système `pg_stat_progress_copy`. Celle-ci retourne une ligne par
_backend_ lançant un `COPY`.

```sql
CREATE TABLE test_copy (i int);
INSERT INTO test_copy SELECT generate_series (1,10000000);
COPY test_copy TO '/tmp/test_copy';

SELECT * FROM pg_stat_progress_copy \gx
```
```sh
-[ RECORD 1 ]----+---------
pid              | 39148
datid            | 16384
datname          | test
relid            | 36500
command          | COPY TO
type             | FILE
bytes_processed  | 43454464
bytes_total      | 0
tuples_processed | 5570696
tuples_excluded  | 0
```

Parmi ces informations, on retrouve le type de `COPY` exécuté (`command`), le
type d'entrée/sortie utilisé (`type`), ainsi que le nombre d'octets déjà traités 
(`bytes_processed`) et le nombre de lignes déjà insérées (`tuples_processed`).

<!-- TODO a:jouter exemple avec % de progression ? -->

Pour le champ `tuples_excluded`, il n'est renseigné qu'en cas d'utilisation d'une
clause `WHERE` et remonte le nombre de lignes exclues par cette même clause.

```sql
COPY test_copy FROM '/tmp/test_copy' WHERE i > 1000;

SELECT * FROM pg_stat_progress_copy \gx
```
```sh
-[ RECORD 1 ]----+----------
pid              | 39148
datid            | 16384
datname          | test
relid            | 36500
command          | COPY FROM
type             | FILE
bytes_processed  | 17563648
bytes_total      | 78888897
tuples_processed | 2329752
tuples_excluded  | 1000
```

Le champ `bytes_total` correspond à la taille en octets de la source de données.
Il n'est renseigné que dans le cadre d'un `COPY FROM` et si la source de données
est située sur le même serveur que l'instance PostgreSQL. Il ne sera pas renseigné
si le champ `type` est à `PIPE`, ce qui équivaut à `COPY FROM … STDIN` ou à
une commande psql `\copy`.

```sql
\copy test_copy FROM '/tmp/test_copy' WHERE i > 1000;

SELECT * FROM pg_stat_progress_copy \gx
```
```sh
-[ RECORD 1 ]----+----------
pid              | 39148
datid            | 16384
datname          | test
relid            | 36500
command          | COPY FROM
type             | PIPE
bytes_processed  | 17150600
bytes_total      | 0
tuples_processed | 2281713
tuples_excluded  | 1000
```

Pour la même raison, `bytes_total` n'est pas renseigné lors d'une restauration
de sauvegarde logique avec `pg_restore` :

```sql
SELECT pid, p.datname, relid::regclass, command, type, a.application_name,
bytes_processed, bytes_total, tuples_processed, tuples_excluded,
a.query, a.query_start
FROM pg_stat_progress_copy p INNER JOIN pg_stat_activity a USING(pid) \gx
```
```sh
-[ RECORD 1 ]----+-------------------------------------------------------
pid              | 223301
datname          | scratch
relid            | textes
command          | COPY FROM
type             | PIPE
application_name | pg_restore
bytes_processed  | 111194112
bytes_total      | 0
tuples_processed | 839619
tuples_excluded  | 0
query            | COPY public.textes (livre, ligne, contenu) FROM stdin;+
                 | 
query_start      | 2021-11-23 11:11:15.685557+01
```

De même lors d'une sauvegarde logique (ici avec `pg_dumpall`) :
```sh
-[ RECORD 1 ]----+--------------------------------------------------------------
pid              | 223652
datname          | magasin
relid            | 256305
command          | COPY TO
type             | PIPE
application_name | pg_dump
bytes_processed  | 22817772
bytes_total      | 0
tuples_processed | 402261
tuples_excluded  | 0
query            | COPY magasin.lots (numero_lot, transporteur_id, numero_suivi,
                   date_depot, date_expedition, date_reception) TO stdout;
query_start      | 2021-11-23 11:14:09.755587+01
```

</div>
