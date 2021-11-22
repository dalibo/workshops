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
_backend_ lancant un `COPY`.

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

Parmis ces informations, on retrouve le type de `COPY` exécuté (`command`), le
type d'entrée/sortie utilisé (`type`), ainsi que le nombre d'octets déjà traités 
(`bytes_processed`) et le nombre de lignes déjà insérées (`tuples_processed`).

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
Il n'est valorisé que dans le cadre d'un `COPY FROM` et si la source de données
est située sur le même serveur que l'instance PostgreSQL. Il ne sera pas renseigné
si le champ `type` est à `PIPE`, ce qui équivaut à `COPY FROM ... STDIN` ou à
une commande psql `\copy`.

```sql
\copy test_copy from '/tmp/test_copy' where i > 1000;

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

</div>