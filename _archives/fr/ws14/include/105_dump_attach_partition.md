<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9a4c0e36fbd671b5e7426a5a0670bdd7ba2714a0

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/105

-->

<div class="slide-content">

* `pg_dump` au format _custom_, _directory_ ou _tar_
  * L'instruction `CREATE TABLE` ne dépend plus du résultat de la commande `ATTACH`
* `pg_restore` et l'option `--table`
  * Restauration possible d'une partition en tant que simple table
  * Plus simple qu'une restauration avec un _fichier liste_ (_table of contents_)

</div>

<div class="notes">

La restauration d'une partition en tant que simple table est particulièrement
utile lors de la restauration d'une archive ou d'une copie d'environnement avec
les données les plus récentes. Bien qu'il était auparavant possible de restaurer
la table partitionnée et l'une de ses partitions avec `pg_restore` et l'option
`-L / --use-list`, le format des archives _custom_, _directory_ et _tar_ a évolué pour
simplifier cette opération.

Prenons l'exemple d'une table des ventes, partitionnée sur la colonne `date_vente`
avec une partition pour chaque année écoulée.

<!--
```sql
CREATE TABLE ventes (
  date_vente date NOT NULL,
  projet_id bigint,
  montant numeric
) PARTITION BY RANGE (date_vente);

SELECT format(
    $$CREATE TABLE ventes_y%1$s PARTITION OF ventes
        FOR VALUES FROM ('%1$s-01-01') TO ('%2$s-01-01')$$,
    y, y+1)
  FROM generate_series(2001,2022) y;
\gexec

INSERT INTO ventes
SELECT date_vente,
       projet_id, 
       round(random() * 30001 + 1000)::int
  FROM generate_series(
         '2001-01-01'::timestamp,
         '2022-12-31'::timestamp,
         '1 day'
       ) date_vente,
       generate_series(1,300) projet_id;
```
-->

```sh
           Partitioned table "ventes"
   Column   |  Type   | Collation | Nullable | Default 
------------+---------+-----------+----------+---------
 date_vente | date    |           | not null | 
 projet_id  | bigint  |           |          | 
 montant    | numeric |           |          | 
Partition key: RANGE (date_vente)
Number of partitions: 22 (Use \d+ to list them.)
Partitions: ventes_y2001 FOR VALUES FROM ('2001-01-01') TO ('2002-01-01'),
            ventes_y2002 FOR VALUES FROM ('2002-01-01') TO ('2003-01-01'),
            ...
            ventes_y2021 FOR VALUES FROM ('2021-01-01') TO ('2022-01-01'),
            ventes_y2022 FOR VALUES FROM ('2022-01-01') TO ('2023-01-01')
```

Dans un souci de gestion des données à archiver, la table la plus ancienne
`ventes_y2001` est exportée pour libérer l'espace disque. À l'aide de la commande
`pg_dump` au format _custom_, nous procédons à la création du fichier d'archive.

```bash
pg_dump -Fc -d workshop -t ventes_y2001 -f ventes.dump
# pg_dump: dumping contents of table "ventes_y2001"
```

Le fichier dispose de la liste des instructions dans le contenu d'archive (ou
_table of contents_), dont la nouvelle ligne `ATTACH` pour la partition exportée.

```bash
pg_restore -l ventes.dump
```

```sh
; Selected TOC Entries:
;
210; 1259 18728 TABLE public ventes_y2001 user
2449; 0 0 TABLE ATTACH public ventes_y2001 user
2589; 0 18728 TABLE DATA public ventes_y2001 user
```

La restauration de cette seule partition est possible, même en l'absence de la 
table partitionnée sur la base cible.

```bash
pg_restore -v -d staging -t ventes_y2001 ventes.dump
```
```sh
pg_restore: connecting to database for restore
pg_restore: creating TABLE "ventes_y2001"
pg_restore: processing data for table "ventes_y2001"
```

Dans les versions précédentes, l'erreur suivante empêchait ce type de restauration
et la table principale devait être présente pour aboutir au résultat souhaité.

```sh
pg_restore: connecting to database for restore
pg_restore: creating TABLE "ventes_y2001"
pg_restore: while PROCESSING TOC:
pg_restore: from TOC entry 201; 1259 25987 TABLE ventes_y2001 user
pg_restore: error: could not execute query:
ERROR:  relation "ventes" does not exist
Command was: CREATE TABLE ventes_y2001 (
    date_vente date NOT NULL,
    projet_id bigint,
    montant numeric
);
ALTER TABLE ONLY ventes ATTACH PARTITION ventes_y2001 
  FOR VALUES FROM ('2001-01-01') TO ('2002-01-01');

pg_restore: error: could not execute query: 
ERROR:  relation "ventes_y2001" does not exist
Command was: ALTER TABLE ventes_y2001 OWNER TO user;

pg_restore: processing data for table "ventes_y2001"
pg_restore: from TOC entry 2286; 0 25987 TABLE DATA ventes_y2001 user
pg_restore: error: could not execute query: 
ERROR:  relation "ventes_y2001" does not exist
Command was: COPY ventes_y2001 (date_vente, projet_id, montant) FROM stdin;
pg_restore: warning: errors ignored on restore: 3
```
</div>
