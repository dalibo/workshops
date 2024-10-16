<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=b073c3ccd06e4cb845e121387a43faa8c68a7b62

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/163

-->

<div class="slide-content">

* `USAGE` par défaut pour le rôle `PUBLIC`
* `CREATE` et `USAGE` par défaut pour le rôle `pg_database_owner`
* adaptation de `pg_dump` pour extraire ces changements
* Attention lors des montées de version !

</div>

<div class="notes">

Cette nouvelle version supprime le privilège par défaut `CREATE` sur le schéma `public` 
pour le rôle `PUBLIC`. Pour rappel, `PUBLIC` peut être vu comme un rôle 
implicitement défini qui inclut en permanence tous les rôles. Le  propriétaire
par défaut du schéma `public` n'est 
plus `postgres` mais le rôle `pg_database_owner`. Ce mécanisme permet au propriétaire 
de la base de données d'obtenir implicitement le droit `CREATE` sur le schéma `public`.

Voici ce que ça donne en comparant avec une instance en version 14 :

```sql
# En version 14
postgres=# \dn+
                           Liste des schémas
  Nom   | Propriétaire |    Droits d'accès    |      Description       
--------+--------------+----------------------+------------------------
 public | postgres     | postgres=UC/postgres+| standard public schema
        |              | =UC/postgres         | 

# En version 15
postgres=# \dn+
                                      Liste des schémas
  Nom   |   Propriétaire    |             Droits d'accès             |      Description       
--------+-------------------+----------------------------------------+------------------------
 public | pg_database_owner | pg_database_owner=UC/pg_database_owner+| standard public schema
        |                   | =U/pg_database_owner                   | 
```

On constate bien le changement de propriétaire et la perte de l'abréviation `C` sur la ligne `=U/pg_database_owner` 
qui correspond aux privilèges par défaut du rôle `PUBLIC`.

Même si la configuration des privilèges est reprise lors d'une montée de version, il convient de réaliser une étape 
préalable de vérification afin de déterminer d'éventuel impact que pourrait avoir ce changement. Notamment, si un 
rôle doit créer des objets dans le schéma `public`, qu'il n'est pas propriétaire de la base de données et, qu'aucun
privilège `CREATE` spécifique n'a été donné car on se basait sur le privilège 
`CREATE` qui était implicitement donné au rôle `PUBLIC`.

Ces changements sur le schéma public ont donné lieu à des ajustements dans
l'outil `pg_dump`. Il extrait désormais correctement le propriétaire du schéma,
les privilèges et [_security labels_] sur le schéma public même s'il a été
supprimé puis recréé.

[security labels]: https://www.postgresql.org/docs/15/sql-security-label.html


</div>
