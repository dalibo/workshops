<!--

* Add tab-complete for full name backslash commands
commit : https://commitfest.postgresql.org/34/3268/
discussion : https://www.postgresql.org/message-id/flat/OS0PR01MB61136018064660F095CB57A8FB129@OS0PR01MB6113.jpnprd01.prod.outlook.com

* Tab completion for EXECUTE after EXPLAIN
commit : https://commitfest.postgresql.org/34/3279/
discussion : https://www.postgresql.org/message-id/flat/871r75gd0i.fsf@wibble.ilmari.org

* Tab completion for ALTER TABLE … ADD …
commit : https://commitfest.postgresql.org/34/3280/
discussion : https://www.postgresql.org/message-id/flat/87bl6ehhpl.fsf@wibble.ilmari.org

* psql tab auto-complete for CREATE PUBLICATION
commit : https://commitfest.postgresql.org/34/3249/
discussion : https://www.postgresql.org/message-id/flat/CAHut+Ps-vkmnWAShWSRVCB3gx8aM=bFoDqWgBNTzofK0q1LpwA@mail.gmail.com

* (LOCK TABLE options) “ONLY” and “NOWAIT” are not yet implemented in tab-complete
commit : https://commitfest.postgresql.org/35/3334/
discussion : https://www.postgresql.org/message-id/flat/a322684daa36319e6ebc60b541000a3a@oss.nttdata.com

* Support tab completion for upper character inputs in psql
commit : https://commitfest.postgresql.org/36/3432/
discussion : https://www.postgresql.org/message-id/flat/a63cbd45e3884cf9b3961c2a6a95dcb7@G08CNEXMBPEKD05.g08.fujitsu.local

* CREATE tab completion
commit : https://commitfest.postgresql.org/36/3418/
discussion : https://www.postgresql.org/message-id/flat/8d370135aef066659eef8e8fbfa6315b@oss.nttdata.com

* ALTER tab completion
commit : https://commitfest.postgresql.org/36/3428/
discussion : https://www.postgresql.org/message-id/flat/9497ae9ca1b31eb9b1e97aded1c2ab07@oss.nttdata.com

* DROP tab completion
commit : https://commitfest.postgresql.org/36/3429/
discussion : https://www.postgresql.org/message-id/flat/0fafb73f3a0c6bcec817a25ca9d5a853@oss.nttdata.com

-->

<div class="slide-content">

* Recherche insensible à la casse
* Affichage des noms complets des commandes plutôt que leurs abréviations
* Amélioration de l'auto-complétion de différentes commandes _SQL_ :
  + `EXPLAIN EXECUTE`
  + `LOCK TABLE ONLY | NOWAIT`
  + `ALTER TABLE ... ADD`
  + `CREATE`, `ALTER`, `DROP`

</div>

<div class="notes">

L'auto-complétion dans `psql` a été améliorée à différents niveaux.

**Recherche insensible à la casse**

L'auto-complétion est désormais capable de suggérer ou compléter une commande
même si la casse n'est pas respectée.

La complétion par une double tabulation de la saisie suivante permet d'afficher
la liste des paramètres des traces, alors que les versions précédentes ne 
renvoyait rien :

```sql
postgres=# set LOG_
```
La saisie est automatiquement transformée en minuscule, et les différentes 
suggestions apparaissent :

```sql
postgres=# set log_
log_duration                       log_lock_waits                     log_min_messages                   log_planner_stats                  log_statement_stats                
log_error_verbosity                log_min_duration_sample            log_parameter_max_length           log_replication_commands           log_temp_files                     
log_executor_stats                 log_min_duration_statement         log_parameter_max_length_on_error  log_statement                      log_transaction_sample_rate        
logical_decoding_work_mem          log_min_error_statement            log_parser_stats                   log_statement_sample_rate   
```

**Noms de paramètres**

La complétion d'un `\` via une double tabulation permet de lister les commandes 
disponibles. Cette liste affiche désormais le nom complet de chaque commande, 
alors que certaines commandes apparaissaient sous la forme d'abréviations. La commande
`\l` devient ainsi `\list`, `\o` devient `\out`, `\e` devient `\echo`, etc.

```sql
postgres=# \
Display all 106 possibilities? (y or n)
\!                 \dAp               \dFp               \dRs               \errverbose        \lo_export         \sv
\?                 \db                \dFt               \ds                \ev                \lo_import         \t
\a                 \dc                \dg                \dt                \f                 \lo_list           \T
\C                 \dC                \di                \dT                \g                 \lo_unlink         \timing
\cd                \dconfig           \dl                \du                \gdesc             \out               \unset
\connect           \dd                \dL                \dv                \getenv            \password          \warn
\conninfo          \dD                \dm                \dx                \gexec             \print             \watch
\copy              \ddp               \dn                \dX                \gset              \prompt            \write
\copyright         \dE                \do                \dy                \gx                \pset              \x
\crosstabview      \des               \dO                \echo              \help              \qecho             \z
\d                 \det               \dp                \edit              \html              \quit              
\da                \deu               \dP                \ef                \if                \reset             
\dA                \dew               \dPi               \elif              \include           \s                 
\dAc               \df                \dPt               \else              \include_relative  \set               
\dAf               \dF                \drds              \encoding          \ir                \setenv            
\dAo               \dFd               \dRp               \endif             \list              \sf  
```
**EXPLAIN EXECUTE**

La complétion de la commande `EXPLAIN` ajoute l'option `EXECUTE`.

```sql
postgres=# EXPLAIN 
ANALYZE      DECLARE      DELETE FROM  EXECUTE      INSERT INTO  MERGE        SELECT       UPDATE       VERBOSE 
```

**LOCK TABLE**

La commande LOCK TABLE permet désormais la complétion de l'option `ONLY` avant 
le nom de la table :

```sql
postgres=# LOCK TABLE 
information_schema.  ONLY                 public.              t1
```

Idem pour l'option `NOWAIT`, à préciser après le nom de la table :

```sql
postgres=# LOCK TABLE t1 
IN      NOWAIT
```


**`CREATE`, `ALTER`, `DROP`**

Enfin, diverses améliorations ont été apportées aux options de complétion de 
plusieurs commandes `CREATE`, `ALTER` et `DROP` :

* `CREATE CONVERSION`, `CREATE DOMAIN`, `CREATE LANGUAGE`, `CREATE SCHEMA`, `CREATE SEQUENCE`, `CREATE TRANSFORM`
* `ALTER DEFAULT PRIVILEGES`,`ALTER FOREIGN DATA WRAPPER`, `ALTER SEQUENCE`, `ALTER VIEW`
* `DROP MATERIALIZED VIEW`, `DROP OWNED BY`, `DROP POLICY`, `DROP TRANSFORM`

</div>
