<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/pg/commitdiff/33d3eeadb21d2268104840cfef6bc2226ddfc680
* https://git.postgresql.org/pg/commitdiff/3e707fbb4009e9ac1d0e8b78b7af9f3f03f4cf1a


Discussions :

* https://www.postgresql.org/message-id/E1mzO8j-0000Yy-WE@gemulon.postgresql.org
* https://www.postgresql.org/message-id/E1ncZPB-000n2a-R2@gemulon.postgresql.org

-->

<div class="slide-content">

* Ajout de nouvelles méta-commandes `psql`
* commande `\dconfig` pour afficher la configuration de l'instance
* commande `\getenv` pour récupérer la valeur d'une variable d'environnement

</div>

<div class="notes">

**Commande `\dconfig`**

La commande `\dconfig` permet d'afficher les paramètres de configuration de 
l'instance.

Son appel sans argument permet d'afficher les paramètres dont les valeurs ne sont
pas celles par défaut :

```sql
postgres=# \dconfig
     List of non-default configuration parameters
         Parameter          |          Value           
----------------------------+--------------------------
 application_name           | psql
 client_encoding            | UTF8
 config_file                | /data/15/postgresql.conf
 data_directory             | /data/15
 default_text_search_config | pg_catalog.english
 hba_file                   | /data/15/pg_hba.conf
 ident_file                 | /data/15/pg_ident.conf
 lc_messages                | en_US.UTF-8
 lc_monetary                | en_US.UTF-8
 lc_numeric                 | en_US.UTF-8
 lc_time                    | en_US.UTF-8
 log_filename               | postgresql-%a.log
 logging_collector          | on
 log_rotation_size          | 0
 log_timezone               | UTC
 log_truncate_on_rotation   | on
 TimeZone                   | UTC
```

L'ajout d'un `+` à la commande permet d'obtenir plus d'informations :

```sql
postgres=# \dconfig+
                           List of non-default configuration parameters
         Parameter          |          Value           |  Type   |  Context   | Access privileges 
----------------------------+--------------------------+---------+------------+-------------------
 application_name           | psql                     | string  | user       | 
 client_encoding            | UTF8                     | string  | user       | 
 config_file                | /data/15/postgresql.conf | string  | postmaster | 
 data_directory             | /data/15                 | string  | postmaster | 
 default_text_search_config | pg_catalog.english       | string  | user       | 
 hba_file                   | /data/15/pg_hba.conf     | string  | postmaster | 
 ident_file                 | /data/15/pg_ident.conf   | string  | postmaster | 
 lc_messages                | en_US.UTF-8              | string  | superuser  | 
 lc_monetary                | en_US.UTF-8              | string  | user       | 
 lc_numeric                 | en_US.UTF-8              | string  | user       | 
 lc_time                    | en_US.UTF-8              | string  | user       | 
 log_filename               | postgresql-%a.log        | string  | sighup     | 
 logging_collector          | on                       | bool    | postmaster | 
 log_rotation_size          | 0                        | integer | sighup     | 
 log_timezone               | UTC                      | string  | sighup     | 
 log_truncate_on_rotation   | on                       | bool    | sighup     | 
 TimeZone                   | UTC                      | string  | user       | 
```

La commande accepte également l'utilisation de _wild card_ :

```sql
postgres=# \dconfig *work_mem*
 List of configuration parameters
         Parameter         | Value 
---------------------------+-------
 autovacuum_work_mem       | -1
 logical_decoding_work_mem | 64MB
 maintenance_work_mem      | 64MB
 work_mem                  | 4MB
```

> l'appel `\dconfig *` permet ainsi de lister l'ensemble des paramètres 
> de l'instance.

**Commande `\getenv`**

La commande `\getenv` permet d'enregistrer la valeur d'une variable
d'environnement dans une variable sql.

```sh
[postgres@pg15 ~]$ export ENV_VAR='foo'
[postgres@pg15 ~]$ psql
psql (15beta2)
Type "help" for help.

postgres=# \getenv sql_var ENV_VAR

postgres=# \echo :sql_var
foo
```

</div>