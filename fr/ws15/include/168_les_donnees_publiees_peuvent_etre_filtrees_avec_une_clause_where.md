<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=52e4f0cd472d39d07732b99559989ea3b615be78 

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/168

-->

<div class="slide-content">

* Ajout de la clause `WHERE` pour filtrer les données d'une table à publier
* Filtre uniquement par table
* Pas de restriction de colonne pour l'opération `INSERT`
* Restrictions pour les opérations `UPDATE` et `DELETE` (colonnes couvertes par `REPLICA IDENTITY`)
* Ne fonctionne qu'avec des expressions simples (y compris fonctions de base et opérateurs logiques)

</div>

<div class="notes">

Autre grosse nouveauté pour la réplication logique, il est maintenant possible d'appliquer un filtre 
pour ne répliquer que partiellement une table. Ce filtre est géré par l'option `WHERE` au niveau de 
la publication et est spécifique à une table.

```sql
CREATE PUBLICATION p1 FOR TABLE t1 WHERE (ville = 'Reims');
```

Cette clause `WHERE` n'autorise que des expressions simples (y compris les fonctions de base et les 
opérateurs logiques) et ne peut faire référence qu'aux colonnes de la table sur laquelle la publication 
est mise en place. Il n'est pour le moment pas possible d'utiliser de fonctions, d'opérateurs, de types 
et de collations qui sont définis par un utilisateur. Les fonctions non immutables et les colonnes système 
sont également inutilisables.

Si une publication ne publie que des ordres INSERT, il n'y a pas de limitation sur les colonnes
utilisées dans le filtre. En revanche, si la publication concerne les ordres UPDATE et DELETE,
il faut que les colonnes du filtre fassent partie de l'identité de réplica. Cela signifie que
ces colonnes doivent faire partie de la clé primaire si `` [`REPLICA IDENTITY`](https://www.postgresql.org/docs/current/logical-replication-publication.html) ``
est laissé à sa valeur par défaut. Si un index unique est créé et utilisé pour la clause
`REPLICA IDENTITY USING INDEX`, ces colonnes doivent en faire partie. Enfin, si 
`REPLICA IDENTITY` est valorisé à `FULL`, n'importe quelle colonne peut faire partie du filtre.
Cette dernière configuration est cependant peu performante.

Si on déclare un filtre sur une colonne qui ne fait pas partie de l'identité de réplica,
PostgreSQL refuse les mises à jour et renvoie le message suivant. Il faut donc être
très vigilant lors de la mise en place d'un filtre sur une publication.

```sql
ERROR:  cannot update table "rep"
DETAIL:  Column used in the publication WHERE expression is not part of the replica identity.

ERROR:  cannot delete from table "rep"
DETAIL:  Column used in the publication WHERE expression is not part of the replica identity.
```

Voici comment est mis en place le filtre :

- il est appliqué **avant** de décider de la publication d'une modification ;
- si la validation du filtre renvoie `NULL` ou `false`, la modification ne sera 
  pas publiée ;
- les `TRUNCATE` sont ignorés puisqu'ils modifient l'ensemble de la table 
  et sont répliqués depuis PostgreSQL 11 ;
- les `INSERT` et les `DELETE` sont répliqués normalement du moment que 
  le filtre est validé ;
- les UPDATE sont plus compliqué. Les exemples suivant décrivent les
  trois cas de figure et la façon dont PostgreSQL les gère. 

  ```sql
  # Sur le publieur

  # Création de la table rep
  pub=# CREATE TABLE rep (i INT PRIMARY KEY);
  CREATE TABLE

  # Insertion de données
  pub=# INSERT INTO rep SELECT generate_series(1,10);
  INSERT 0 10

  # Création de la publication avec filtre
  pub=# CREATE PUBLICATION p1 FOR TABLE rep WHERE (i > 5);
  CREATE PUBLICATION
  ```

  ```sql
  # Sur le souscripteur

  # Création de la table rep
  sub=# CREATE TABLE rep (i INT PRIMARY KEY);
  CREATE TABLE
  
  # Mise en place de la souscription
  sub=# CREATE SUBSCRIPTION s1
  sub-# CONNECTION 'host=/var/run/postgresql port=5449 user=postgres dbname=pub'
  sub-# PUBLICATION p1
  sub-# WITH (copy_data = true);
  CREATE SUBSCRIPTION
  
  # Vérification des données
  sub=# SELECT * FROM rep;
    i  
  ----
    6
    7
    8
    9
   10
  ```

  Réalisation d'un `UPDATE` où l'ancienne et la nouvelle version de ligne valident le filtre.

  ```sql
  # Sur le publieur
  pub=# UPDATE rep SET i = 20 WHERE i = 10;

  # Sur le souscripteur
  sub=# SELECT * FROM rep;
    i  
  ----
    6
    7
    8
    9
    20

  # Dans la log du souscripteur au niveau DEBUG5
  CONTEXT: processing remote data for replication origin "pg_16395" during message  
           type "UPDATE" in transaction 766, finished at 2/D602FC30
  ```

  Dans le cas contraire, voici ce qui se passe :

  + si l'ancienne version de la ligne ne valide pas le filtre (donc que la ligne n'existe 
    pas sur le souscripteur), un `INSERT` sera envoyé au souscripteur plutôt qu'un `UPDATE` ;

  ```sql
  # Sur le publieur
  pub=# UPDATE rep SET i = 15 WHERE i = 1;

  # Sur le souscripteur
  sub=# SELECT * FROM rep;
    i  
  ----
    6
    7
    8
    9
    20
    15

  # Dans la log du souscripteur au niveau DEBUG5
  CONTEXT:  processing remote data for replication origin "pg_16395" during message  
            type "INSERT" in transaction 767, finished at 2/D602FD28
  ```

  + dans le cas contraire, si la nouvelle ligne ne valide pas le filtre (donc que la ligne 
    ne doit plus exister sur le souscripteur), un `DELETE` remplacera l'`UPDATE`.

  ```sql
  # Sur le publieur
  pub=# UPDATE rep SET i = 0 WHERE i = 6;

  # Sur le souscripteur
  sub=# SELECT * FROM rep;
    i  
  ----
    7
    8
    9
    20
    15

  # Dans la log du souscripteur au niveau DEBUG5
  CONTEXT:  processing remote data for replication origin "pg_16395" during message  
            type "DELETE" in transaction 768, finished at 2/D602FE20
  ```

Si l'option `copy_data = true` est utilisée lors du `CREATE SUBSCRIPTION`, seules 
les données préexistantes satisfaisant le filtre seront répliquées durant la copie initiale des données. Si le souscripteur 
est dans une version inférieure à la 15, l'initialisation des données se fera sans utilisation 
du filtre. Les lignes publiées par la suite seront correctement filtrées.

Il est également possible d'avoir pour une même souscription, plusieurs publications pour une même table avec des filtres différents. Dans un 
tel cas, ces filtres seront combinés avec un `OR` de sorte que les modifications qui répondent à n'importe quel filtre seront répliquées.

```sql
# Sur le publieur

pub=# SELECT * FROM rep;
  i  
----
  1
  2
  3
  4
  5
  6
  7
  8
  9
  10

# Création première publication
pub=# CREATE PUBLICATION pub1 FOR TABLE rep WHERE (i < 4);
CREATE PUBLICATION

# Création deuxième publication
pub=# CREATE PUBLICATION pub2 FOR TABLE rep WHERE (i > 7);
CREATE PUBLICATION

# Sur le souscripteur

# Création de la première souscription
sub=# CREATE SUBSCRIPTION sub1
sub-# CONNECTION 'host=/var/run/postgresql port=5449 user=postgres dbname=pub'
sub-# PUBLICATION pub1
sub-# WITH (copy_data = true);
CREATE SUBSCRIPTION

# Création de la deuxième souscription
sub=# CREATE SUBSCRIPTION sub2
sub-# CONNECTION 'host=/var/run/postgresql port=5449 user=postgres dbname=pub'
sub-# PUBLICATION pub2
sub-# WITH (copy_data = true);
CREATE SUBSCRIPTION

sub=# SELECT * FROM rep;
  i  
----
  1
  2
  3
  8
  9
  10
```

Afin de faciliter l'administration, les méta-commandes `\d` et `\dRp+` ont été modifiées 
pour prendre en compte la mise en place d'un filtre pour une publication :

\scriptsize

```
pub=# \dRp+
                                            Publication pub1
 Propriétaire | Toutes les tables | Insertions | Mises à jour | Suppressions | Tronque | Via la racine 
--------------+-------------------+------------+--------------+--------------+---------+---------------
 postgres     | f                 | t          | t            | t            | t       | f
Tables :
    "public.rep" WHERE (i < 4)

                                            Publication pub2
 Propriétaire | Toutes les tables | Insertions | Mises à jour | Suppressions | Tronque | Via la racine 
--------------+-------------------+------------+--------------+--------------+---------+---------------
 postgres     | f                 | t          | t            | t            | t       | f
Tables :
    "public.rep" WHERE (i > 7)

pub=# \d rep
                    Table « public.rep »
 Colonne |  Type   | Collationnement | NULL-able | Par défaut 
---------+---------+-----------------+-----------+------------
 i       | integer |                 | not null  | 
Index :
    "rep1_pkey" PRIMARY KEY, btree (i)
Publications :
    "pub1" WHERE (i < 4)
    "pub2" WHERE (i > 7)
```

\normalsize

Concernant les tables partitionnées publiées, l'application du filtre dépendra du paramètre 
`publish_via_partition_root`. Si celui-ci est à `true`, le filtre sera appliqué pour chaque
partition. Par contre, s'il est à `false` (qui est la valeur par défaut), il ne sera pas appliqué
sur la table partitionnée.

</div>
