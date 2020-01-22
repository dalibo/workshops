## TP Monitoring

<div class="slide-content">

  * échantillon des requêtes dans les logs
  * Vues de progression pour `CREATE INDEX`, `CLUSTER`, `VACUUM`
  * pg_ls_archive_statusdir() et pg_ls_tmpdir()
  * pg_stat_replication : timestamp du dernier message reçu du standby

</div>

<div class="notes">

</div>

---

###  Échantillon des requêtes dans les logs
 
<div class="slide-content">

  * log_transaction_sample_rate

</div>

<div class="notes">

#### Activation des paramètres

Les deux paramètres sont à modifier dans le fichier `postgresql.conf` de l'instance :

```ini

# on récupère toute l'activité
log_min_duration_statement = 0

# 80% des transactions
log_transaction_sample_rate = 0.80
```

</div>

---

### Vues de progression pour `CREATE INDEX`, `CLUSTER`, `VACUUM`

<div class="slide-content">

  * pg_stat_progress_create_index
  * pg_stat_progress_vacuum

</div>

<div class="notes">

#### pg_stat_progress_create_index

Lancer dans une sessions `psql` les commandes :  

```SQL
$ SELECT
  datname,
  relid::regclass,
  command,
  phase,
  tuples_done
FROM
  pg_stat_progress_create_index;

$ \watch 1
  
``` 


Lancer une réindexation dans une autre session : 

```SQL
$ CREATE TABLE a_table (
  i int,
  a text,
  b text
);

$ INSERT INTO a_table
SELECT
  i,
  md5(i::text),
  md5(i::text)
FROM
  generate_series(1, 100000) i;


$ CREATE INDEX ON a_table (i, a, b);

```

Observer les phases de la création de l'index dans la première session.

#### pg_stat_progress_vacuum

On se propose de suivre la progression des vacuum d'une base.

```SQL
$ CREATE TABLE tab (i int , j text);
$ INSERT INTO tab SELECT i, md5(i::text)
  FROM generate_series(1,1000000) s(i);
$ DELETE FROM tab;
$ INSERT INTO tab SELECT i, md5(i::text)
  FROM generate_series(1,1000000) s(i);
-- L'autovacuum devrait se déclencher
$ SELECT * FROM pg_stat_progress_vacuum;
$ \watch 1
```

</div>
----

### Archive status et fichiers temporaires

<div class="slide-content">

  * `pg_ls_archive_statusdir()`
  * `pg_ls_tmpdir()`

</div>


<div class="notes">

Déclenchez la rotation des journaux de transaction et donc l'archivage :

```sql
$ select pg_switch_wal();
$ select pg_switch_wal();
$ select pg_switch_wal();
$ select pg_ls_archive_statusdir();

                  pg_ls_archive_statusdir                   
------------------------------------------------------------
 (0000000100000001000000BC.done,0,"2019-07-29 14:12:08+02")
 (0000000100000001000000BB.done,0,"2019-07-29 14:11:36+02")
 (0000000100000001000000BD.done,0,"2019-07-29 14:12:15+02")
(3 rows)

```

Lancer une requête effectuant un tri assez conséquent pour dépasser la `work_mem` et créer des fichiers temporaires :

```sql
$ select pg_ls_tmpdir();
                     pg_ls_tmpdir                     
------------------------------------------------------
 (pgsql_tmp16064.9,24395776,"2019-07-29 14:05:49+02")
(1 row)

```
</div>

---

### timestamp du dernier message reçu du standby

<div class="slide-content">

  * pg_stat_replication

</div>

<div class="notes">

#### Réplication sur le serveur primaire

Nous allons mettre en place une réplication logique entre deux instances v12.

Récupérer les sources, compiler installer dans `/usr/local/pgsql`.
Créer un répertoire `12` dans le `home`  de l'utilisateur et initialiser un cluster dedans :

```
$ /usr/local/pgsql/bin/initdb -D data
```

Créer deux scripts simples de démarrage et d'arrêt :

```bash
#! /bin/bash
# start.sh

/usr/local/pgsql/bin/pg_ctl -D data -l logfile start
```

```bash
#! /bin/bash
# stop.sh

kill $(cat data/postmaster.pid | head -1)
```

Activation de la réplication logique sur le primaire :

**postgresql.conf**

```ini
wal_level = logical
```
création de l'utilisateur de réplication :

```sql
$ create user repli with password 'repli';
CREATE ROLE
$ alter user repli  with replication ;
$ grant select on all tables in schema public to repli;
GRANT
```

Création de la publication sur la table `a_table` :

```sql
$ create table a_table (i int primary key, a text,b text);
$ insert into a_table select i,i::text,i::text from generate_series (1,1000000) i ;
$ create user repli with replication;
$ CREATE publication a_table_publication for table a_table;
```

**pg_hba.conf**

```ini
host all repli 127.0.0.1/32 md5
```

Création de la structure de la table répliquée depuis le serveur primaire :

```bash
$ pg_dump -s -t a_table -U postgres |/usr/local/pgsql/bin/psql -p 5412 postgres
```

#### Souscription sur le serveur secondaire

```sql
$ create subscription a_table_subscription 
CONNECTION 'host=127.0.0.1 port=5432 user=repli dbname=postgres password=repli' 
publication a_table_publication ;
```

#### Vérification de la Réplication
```sql
$ select usename,application_name,reply_time from pg_stat_replication ;
 usename |   application_name   |          reply_time           
---------+----------------------+-------------------------------
 repli   | a_table_subscription | 2019-07-30 12:14:41.934615+02
(1 row)

```

Nous avons l'heure exacte du dernier contact avec la souscription _a_table_subscription_.


</div>

----


