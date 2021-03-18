## TP - Partitionnement, déclencheur `BEFORE`

<div class="slide-content">

* Création / suppression d'un déclencheur `BEFORE` sur une table partitionnée ;
* Cas d'un déclencheur `BEFORE` qui modifie la partition cible. 

</div>

<div class="notes">

### Création de la table partitionnée

Créer d'une table partitionnée :

```
psql << EOF
DROP TABLE IF EXISTS log;

CREATE TABLE log (
   id serial,
   details text,
   creation_ts timestamp with time zone,
   created_by text
) PARTITION BY RANGE (creation_ts);

CREATE TABLE log_202011
   PARTITION OF log
   FOR VALUES FROM ('2020-11-01 00:00:00+01'::timestamp with time zone)
                TO ('2020-12-01 00:00:00+01'::timestamp with time zone);
CREATE TABLE log_202012
   PARTITION OF log
   FOR VALUES FROM ('2020-12-01 00:00:00+01'::timestamp with time zone)
                TO ('2021-01-01 00:00:00+01'::timestamp with time zone);
EOF
```

### Création d'un déclencheur `BEFORE`

Créer un déclencheur `BEFORE` pour mettre le nom de l'utilisateur :

```
psql << 'EOF'
CREATE OR REPLACE FUNCTION log_user() RETURNS trigger AS $log_user$
    BEGIN
        NEW.created_by := current_user;
        RETURN NEW;
    END;
$log_user$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS log_user ON log;

CREATE TRIGGER log_user BEFORE INSERT ON log
    FOR EACH ROW EXECUTE FUNCTION log_user();
EOF
```

Afficher la description de la table partitionnée et d'une partition :

```
psql << EOF
\d+ log
\d log_202011
EOF
```

On obtient :

```
                          Partitioned table "public.log"
...
Triggers:
   log_user BEFORE INSERT ON log FOR EACH ROW EXECUTE FUNCTION log_user()
Partitions: 
   log_202011 FOR VALUES FROM ('2020-11-01 00:00:00+01') 
                           TO ('2020-12-01 00:00:00+01'),
   log_202012 FOR VALUES FROM ('2020-12-01 00:00:00+01')
                           TO ('2021-01-01 00:00:00+01')

                             Table "public.log_202011"
...
Partition of: log 
   log FOR VALUES FROM ('2020-11-01 00:00:00+01') 
                    TO ('2020-12-01 00:00:00+01')
Triggers:
   log_user BEFORE INSERT ON log_202011 FOR EACH ROW EXECUTE FUNCTION log_user(), 
                ON TABLE log
```

Test d'insertion d'une ligne dans la partition :

```
psql << EOF
INSERT INTO log(details, creation_ts) 
       VALUES ('Message', '2020-12-07 10:07:54'::timestamp);
SELECT tableoid::regclass, * FROM log;
EOF
```

On observe que le déclencheur a fonctionné comme attendu :

```
  tableoid  | id | details |      creation_ts       | created_by
------------+----+---------+------------------------+------------
 log_202012 |  1 | Message | 2020-12-07 10:07:54+01 | postgres
(1 row)
```

### Déclencheur `BEFORE` qui modifie la partition cible

Créer un déclencheur `BEFORE` qui modifie l'horodatage de création :

```
psql << 'EOF'
CREATE OR REPLACE FUNCTION log_antidate_stamp() RETURNS trigger AS $log_stamp$
    BEGIN
        NEW.creation_ts := NEW.creation_ts - INTERVAL '1 MONTH';
        RETURN NEW;
    END;
$log_stamp$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS log_antidate_stamp ON log;

CREATE TRIGGER log_antidate_stamp BEFORE INSERT ON log
    FOR EACH ROW EXECUTE FUNCTION log_antidate_stamp();
EOF
```

Test d'insertion d'une ligne dans la partition :

```
psql -v ON_ERROR_STOP=1 << EOF
INSERT INTO log(details, creation_ts) 
       VALUES ('Message', '2020-12-07 10:07:54'::timestamp with time zone);
SELECT * FROM log;
EOF
```

Un message nous informe qu'il est impossible de modifier la partition cible
d'une ligne avec un déclencheur `BEFORE`.

```
ERROR:  moving row to another partition during a BEFORE FOR EACH ROW trigger
+++ is not supported
DETAIL:  Before executing trigger "log_antidate_stamp", the row was to be in
+++ partition "public.log_202012".
```


### Supprimer le déclencheur

Supprimer le déclencheur `log_antidate_stamp` :

```
psql << EOF
DROP TRIGGER log_antidate_stamp ON log;
DROP FUNCTION log_antidate_stamp;
EOF
```

Afficher les informations détaillées sur la table partitionnée `log` et sa
partition `log_202011`. Confirmer que le déclencheur a été supprimé de la
partition :

```
                          Partitioned table "public.log"
...
Triggers:
   log_user BEFORE INSERT ON log FOR EACH ROW EXECUTE FUNCTION log_user()
Partitions: 
   log_202011 FOR VALUES FROM ('2020-11-01 00:00:00+01') 
                           TO ('2020-12-01 00:00:00+01'),
   log_202012 FOR VALUES FROM ('2020-12-01 00:00:00+01') 
                           TO ('2021-01-01 00:00:00+01')

                             Table "public.log_202011"
...
Partition of:
   log FOR VALUES FROM ('2020-11-01 00:00:00+01') 
                    TO ('2020-12-01 00:00:00+01')
Triggers:
   log_user BEFORE INSERT ON log_202011 FOR EACH ROW EXECUTE FUNCTION log_user(),
                ON TABLE log
```

</div>
