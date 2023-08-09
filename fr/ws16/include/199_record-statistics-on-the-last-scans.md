<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=c03747183

Discussion

* https://postgr.es/m/CA+OCxozrVHNFVEPkweUHMZje+t1tfY816d9MZYc6eZwOOusOaQ@mail.gmail.com

-->

<div class="slide-content">

* Donne la date et heure du dernier parcours de table et d'index
* Ajout de deux colonnes pour pg_stat_all_tables
  + last_seq_scan, dernier parcours séquentiel de table
  + last_idx_scan, dernier parcours d'index
* Ajout d'une colonne pour pg_stat_all_indexes
  + last_idx_scan, dernier parcours d'index

</div>

<div class="notes">

Avant cette version, il était possible de connaître le nombre total de parcours
séquentiel et de parcours d'index par table, ainsi que le nombre total de
parcours d'index pour chaque index. Ces informations sont intéressantes mais pas
suffisantes.

En effet, si le nombre de parcours d'index est de 0, nous savons qu'il n'a
jamais été utilisé depuis sa création ou depuis la dernière réinitialisation des
statistiques de l'index. Cependant, s'il vaut, par exemple, 200, il est
impossible de savoir quand ces 200 lectures ont eu lieu. Et notamment, il est
impossible de savoir si la dernière lecture date d'hier ou d'il y a 3 ans. Dans
ce dernier cas, la suppression de l'index serait correctement motivée.

Les développeurs de PostgreSQL ont donc ajouté deux colonnes dans la vue
`pg_stat_all_tables` pour connaître la date et heure du dernier parcours
de table (colonne `last_seq_scan`) et la date et heure du dernier parcours
d'index pour cette table (colonne `last_idx_scan`).

La vue `pg_stat_all_indexes` contient elle aussi une colonne `last_idx_scan`.

Voici un exemple complet :

\tiny

```sql
CREATE TABLE t1(id integer);

SELECT relname, seq_scan, last_seq_scan, idx_scan, last_idx_scan
FROM pg_stat_user_tables
WHERE relname='t1' \gx

-[ RECORD 1 ]---------------------------------
relname       | t1
seq_scan      | 0
last_seq_scan |
idx_scan      |
last_idx_scan |

SELECT * FROM t1;

 id
----
(0 rows)

SELECT relname, seq_scan, last_seq_scan, idx_scan, last_idx_scan
FROM pg_stat_user_tables
WHERE relname='t1' \gx

-[ RECORD 1 ]---------------------------------
relname       | t1
seq_scan      | 1
last_seq_scan | 2023-08-10 15:51:58.199368+02
idx_scan      |
last_idx_scan |

INSERT INTO t1 SELECT generate_series(1, 1000000);
CREATE INDEX ON t1(id);

SELECT * FROM t1 WHERE id=1;
 id
----
  1
(1 row)

SELECT relname, seq_scan, last_seq_scan, idx_scan, last_idx_scan
FROM pg_stat_user_tables
WHERE relname='t1' \gx

-[ RECORD 1 ]---------------------------------
relname       | t1
seq_scan      | 2
last_seq_scan | 2023-08-10 15:52:12.243123+02
idx_scan      | 1
last_idx_scan | 2023-08-10 15:52:18.068182+02
```
\normalsize

</div>
