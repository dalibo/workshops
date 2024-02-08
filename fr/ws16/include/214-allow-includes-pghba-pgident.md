<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a54b658ce77b6705eb1f997b416c2e820a77946c

Discussion :

* https://postgr.es/m/20220223045959.35ipdsvbxcstrhya@jrouhaud

-->

<div class="slide-content">

  * Trois nouveaux mots clés dans `pg_hba.conf` et `pg_ident.conf`
    + `include` : un fichier
    + `include_if_exists`: un fichier s'il existe, l'ignorer autrement
    + `include_dir`: un dossier
  * Champs `file_name` dans `pg_hba_file_rules` et `pg_ident_file_mappings`
    + permet de savoir d'où est tirée la configuration
</div>

<div class="notes">

Les fichiers `pg_hba.conf` et `pg_ident.conf` supportent désormais l'utilisation
des mots clés `include`, `include_if_exists` et `include_dir` afin d'inclure des
fichiers de configuration supplémentaires. Si un fichier contient un espace, il
doit être entouré de guillemets doubles. Les chemins des fichiers ou dossiers
peuvent être relatifs ou absolus.

De plus, les vues `pg_hba_file_rules` et `pg_ident_file_mappings` voient un
champ supplémentaire leur être attribués :`file_name`. Il permet de savoir d'où
est tirée la configuration.

Voici un exemple avec le fichier `pg_hba.conf` qui inclue le fichier
`auth_dba.conf`. Ce dernier contient les autorisations d'accès pour une certaine
adresse IP uniquement : 

```sh
include auth_dba.conf
```

```sh
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# Base de production  
host    production      dba            192.168.1.165/32          scram-sha-256
```

```sql
postgres=# select * from pg_hba_file_rules ;
[...]

-[ RECORD 7 ]-----------------------------------------------
rule_number | 7
file_name   | /etc/postgresql/16/main/auth_dba.conf
line_number | 3
type        | host
database    | {production}
user_name   | {dba}
address     | 192.168.1.165
netmask     | 255.255.255.255
auth_method | scram-sha-256
options     | 
error       | 
``````

</div>
