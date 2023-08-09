<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=3a465cc6783f586096d9f885c3fc544d82eb8f19

Discussion :

* https://postgr.es/m/9e5a8ccddb8355ea9fa4b75a1e3a9edc88a70cd3.camel@vmware.com

-->

<div class="slide-content">

  * Nouveau paramètre de la `libpq`
    + `require_auth`
  * Liste de mots clés séparés par une virgule
  * Mots clés
    + password, md5, gss, sspi, scram-sha-256, creds, none
</div>

<div class="notes">

Le paramètre de connexion `require_auth` permet à un client libpq de définir une
liste de méthodes d'authentification qu'il accepte. Si le serveur ne présente
pas une de ces méthodes d'autentification, les tentatives de connexion échoueront.

La liste des paramètres utilisables est :

* password
* md5
* gss
* sspi
* scram-sha-256
* creds
* none (utile pour contrôler si le serveur accepte des connexions non authentifiées)

Il est également possible d'utiliser `!` avant la méthode pour indiquer que le
serveur ne doit pas utiliser le paramètre en question, comme par exemple `!md5`.

Prenons l'exemple d'une instance PostgreSQL ayant le contenu suivant dans le
fichier `pg_hba.conf`. Il autorise les connexions uniquement en local avec comme
méthode d'authentification `scram-sha-256` :

```sh
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
```

Regardons le comportement d'une connexion avec `psql` et avec des valeurs
différentes de `require_auth` :

```sh
# Une connexion sans spécifier require_auth fonctionne bien
$ psql -U postgres -h 127.0.0.1
Password for user postgres: 

# Avec require_auth=md5, la connexion échoue car cette méthode n'est pas prise en compte par l'instance
$ psql -U postgres -h 127.0.0.1 "require_auth=md5"
psql: error: connection to server at "127.0.0.1", port 5432 failed: authentication method requirement "md5" failed: server requested SASL authentication

# Dès lors que scram-sha-256 est renseigné, la connexion fonctionne
psql -U postgres -h 127.0.0.1 "require_auth=scram-sha-256"
Password for user postgres: 

# Ou encore
psql -U postgres -h 127.0.0.1 "require_auth=md5,scram-sha-256"
Password for user postgres: 

# Si pour une raison, scram-sha-256 ne peut pas être utilisé par le client (utilisation de !)
# la connexion échoue
$ psql -U postgres -h 127.0.0.1 "require_auth=\!scram-sha-256"
psql: error: connection to server at "127.0.0.1", port 5432 failed: authentication method requirement "!scram-sha-256" failed: server requested SASL authentication
```

Bien que ce paramètre permette à un client de restreindre les méthodes
d'authentification qu'il souhaite utiliser, il n'est reste pas moins que c'est
bien le fichier `pg_hba.conf` de l'instance qui va forcer la méthode utilisée.

</div>
