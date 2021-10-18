<!-- Les commits sur ce sujet sont :

| Sujet                    | Lien                                                                                                        |
|==========================|=============================================================================================================|
| Notion de trusted ext    | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=50fc694e43742ce3d04a5e9f708432cb022c5f0d |
| Liste d'extensions trust | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=eb67623c965b4759a96309cdb58a17339fc5d401 |
| Sécurisation d'ext       | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=7eeb1d9861b0a3f453f8b31c7648396cdd7f1e59 |

-->

<!-- #### Trusted extension -->

<div class="slide-content">

  * Objet extension depuis la version 9.1
  * Installation uniquement par un superutilisateur
  * Apparaît la notion de _trusted extension_
    * installation par les utilisateurs ayant le droit CREATE sur la base
  * Quelques extensions des _contribs_ sont déclarées TRUSTED
</div>

<div class="notes">

Les extensions existent depuis la version 9.1 de PostgreSQL. Leur principal
inconvénient est que seul un superutilisateur peut les installer. C'est une
mesure de sécurité. Les langages sont aussi des extensions, et cette mesure de
sécurité a été vue comme une régression par rapport aux versions précédentes.
En effet, sur les versions antérieures à la 9.1, le propriétaire d'une base de
données pouvait installer un langage sans avoir besoin d'un superutilisateur
pour le faire. Cette régression était déjà gênante mais le problème a empiré
avec l'arrivée des PaaS et du cloud. En effet, dans ce cas, l'acheteur d'une
solution cloud avec PostgreSQL se trouve généralement propriétaire de la base,
mais n'est jamais superutilisateur. Il n'a donc aucun moyen d'installer les
extensions qu'il souhaite. Soit elles sont préinstallées, soit il doit
demander l'installation, soit il doit s'en passer.

La version 13 améliore cela en proposant des extensions que tout utilisateur
ayant le droit CREATE sur une base peut installer lui-même. Toutes les
extensions ne le permettent pas. Elles doivent avoir l'attribut TRUSTED.
Certaines extensions fournies dans les _contribs_ ont cet attribut, d'autres non.
Tout dépend du contexte d'utilisation de l'extension et des potentiels risques
au niveau de la sécurité.

Voici quelques requêtes sur le catalogue pour montrer la notion d'extension de
confiance :

```
-- Nombre d'extensions disponibles depuis les modules contrib

SELECT count(*) FROM pg_available_extensions;

 count
-------
    43
(1 row)

-- Nombre d'extensions TRUSTED et non TRUSTED

SELECT trusted, count(DISTINCT name)
FROM pg_available_extension_versions
GROUP BY 1;

 trusted | count
---------+-------
 f       |    22
 t       |    21
(2 rows)

-- Liste d'extensions TRUSTED

SELECT name, max(version) AS version_max
FROM pg_available_extension_versions
WHERE trusted
GROUP BY 1
ORDER BY 1;

      name       | version_max 
-----------------+-------------
 btree_gin       | 1.3
 btree_gist      | 1.5
 citext          | 1.6
 cube            | 1.4
 dict_int        | 1.0
 fuzzystrmatch   | 1.1
 hstore          | 1.7
 intarray        | 1.3
 isn             | 1.2
 lo              | 1.1
 ltree           | 1.2
 pg_trgm         | 1.5
 pgcrypto        | 1.3
 plpgsql         | 1.0
 seg             | 1.3
 tablefunc       | 1.0
 tcn             | 1.0
 tsm_system_rows | 1.0
 tsm_system_time | 1.0
 unaccent        | 1.1
 uuid-ossp       | 1.1
(21 rows)
```

Et voici un exemple d'installation d'une extension à partir d'un utilisateur
ayant le droit `CREATE` sur la base :

```
-- création de la base b1
postgres=# create database b1;
CREATE DATABASE

-- création du rôle u1
postgres=# create role u1 login;
CREATE ROLE

-- affectation du droit CREATE sur la base b1 pour le rôle u1
postgres=# grant create on database b1 to u1;
GRANT

-- connexion à b1 en tant que u1
postgres=# \c b1 u1
You are now connected to database "b1" as user "u1".

-- installation (réussie) d'une extension TRUSTED
b1=> create extension hstore;
CREATE EXTENSION

-- installation (échouée) d'une extension NON TRUSTED
b1=> create extension pg_buffercache;
ERROR:  permission denied to create extension "pg_buffercache"
HINT:  Must be superuser to create this extension.
```

</div>
