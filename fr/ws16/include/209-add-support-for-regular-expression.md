<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=8fea86830e1d40961fd3cba59a73fca178417c78

Discussions :
* https://postgr.es/m/fff0d7c1-8ad4-76a1-9db3-0ab6ec338bf7@amazon.com

-->

<div class="slide-content">

  * Préfixe `/`
    + rupture avec les versions inférieures
  * Champs concernés : base et utilisateur

</div>

<div class="notes">

PostgreSQL supporte désormais l'utilisation d'expressions régulières dans les
fichiers `pg_hba.conf` et `pg_ident.conf`. Elles peuvent être utilisées pour les
champs correspondant aux bases de données et aux utilisateurs. 

Il est nécessaire
d'utiliser le caractère `/` en début de mot pour que PostgreSQL l'évalue comme
une expression régulière. Si une virgule existe dans le mot, il doit être encadré
avec des guillemets doubles pour être pris en compte. Il n'est pas possible d'utiliser
une expression régulière pour les noms d'hôtes.

Ce changement est en rupture avec les anciennes versions de PostgreSQL et la
manière de comprendre les paramètres de ces fichiers. Avant, le caractère `/`
était compris comme un caractère normal pouvant faire partie du nom
d'utilisateur ou de la base de données.

Des fichiers `pg_hba.conf` et `pg_ident.conf` écrits avec des expressions
régulières pour une version 16, ne seront pas supportés par une version
inférieure à 16.

Lors de l'authentification, l'utilisateur ainsi que la base de données sont
vérifiés dans l'ordre suivant :

1. d'abord les mots clés qui n'auront jamais d'expressions régulières (comme
   `all` ou `replication`) ;
1. puis les expressions régulières ;
1. et enfin la correspondance exacte.

Voici un exemple simple où nous mettons à disposition des bases de données
mutualisées sur une même instance. Nous avons un compte administrateur pour les
bases de test (`admin_t`) et un pour celle de pré-production (`admin_p`).
L'utilisation d'expressions particulières est très intéressante.

```bash
# Fichier pg_hba.conf
# TYPE  DATABASE                USER            ADDRESS                 METHOD
host    /client[1-5]_test        admin_t         127.0.0.1/32            scram-sha-256
host    /client[1-5]_preprod     admin_p         127.0.0.1/32            scram-sha-256

# Accès à une base de test avec admin_t

$ psql -U admin_t -d client1_test -h 127.0.0.1
Password for user admin_t: 
psql (16.1)
Type "help" for help.

client1_test=>

# Accès à une base de pré-production avec admin_t
$ psql -U admin_t -d client1_preprod -h 127.0.0.1
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  no pg_hba.conf entry for host "127.0.0.1", user "admin_t", database "client1_preprod", no encryption

# Accès à une base de pré-production avec admin_p
psql -U admin_p -d client5_preprod -h 127.0.0.1
Password for user admin_p: 
psql (16.1)
Type "help" for help.

client5_preprod=>
```

</div>
