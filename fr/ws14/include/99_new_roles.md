<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=6c3ffd697e2242f5497ea4b40fffc8f6f922ff60
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a14a0118a1fecf4066e53af52ed0f188607d0c4b

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/99

-->

<div class="slide-content">

  * `pg_read_all_data`
  * `pg_write_all_data`
  * `pg_database_owner` (_template_)

</div>

<div class="notes">

Les rôles `pg_read_all_data`, `pg_write_all_data` et `pg_database_owner` viennent 
compléter la liste des rôles proposés par PostgreSQL. Les deux premiers de ces 
rôles permettent d'éviter d'avoir à appliquer des droits de lecture ou d'écriture 
sur des nouvelles tables à des utilisateurs nominatifs après un déploiement.

* `pg_read_all_data`

Le rôle `pg_read_all_data` permet de donner un droit de lecture sur toutes les 
tables de tous les schémas et de toutes les bases de données de l'instance 
PostgreSQL à un rôle spécifique. Ce type  de droit est utile lorsque la politique 
de sécurité mise en place autour de vos instances PostgreSQL implique la création
d'un utilisateur spécifique pour la sauvegarde via l'outil `pg_dump`.

Dans l'exemple ci-dessous, seul un utilisateur _superadmin_ ou disposant de l'option
_admin_ sur le rôle `pg_read_all_data` peut octroyer ce nouveau rôle.

```sql
GRANT pg_read_all_data TO dump_user;
```

Par le passé, une série de commandes était nécessaire pour donner les droits de
lecture à un rôle spécifique sur les tables existantes et à venir d'un schéma au
sein d'une base de données.

```sql
GRANT USAGE ON SCHEMA public TO dump_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO dump_user;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO dump_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO dump_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO dump_user;
```

Cependant, dès qu'un nouveau schéma était créé dans la base, l'export par `pg_dump` 
échouait avec le message `ERROR:  permission denied for schema <name>`. Il fallait 
alors réaffecter les droits précédents sur le nouveau schéma pour corriger le problème.

* `pg_write_all_data`

Le rôle `pg_write_all_data` permet de donner un droit d'écriture sur toutes les 
tables de tous les schémas de l'instance PostgreSQL à un rôle spécifique. Ce rôle
peut être utile lors de traitement d'import de type ETL, où les données 
existantes ne doivent pas être lues pour des raisons de sécurité.

* `pg_database_owner`

Le rôle `pg_database_owner`, contrairement à `pg_read_all_data` et `pg_write_all_data`, 
n'a pas de droits par défaut. Il représente le propriétaire d'une base de données, 
afin de faciliter l'application de droits d'une base de données _template_, prête 
à être déployée. À la création d'une nouvelle base à partir de ce _template_, les droits 
qui lui ont été donnés s'appliqueront au propriétaire de cette base de données.

Le rôle `pg_database_owner` ne peut pas être octroyé directement à un autre rôle,
comme le montre le message ci-dessous. PostgreSQL considère qu'il ne peut y avoir
qu'un seul propriétaire par base de données.

```sql
GRANT pg_database_owner TO atelier;
-- ERROR:  role "pg_database_owner" cannot have explicit members
```

Lorsqu'un changement de propriétaire survient dans la base, les droits sur les
objets appartenant au rôle `pg_database_owner` sont alors transmis à ce nouveau
rôle. Le précédent propriétaire n'aura plus accès au contenu des tables ou des 
vues.

```sql
CREATE TABLE tab (id int);
ALTER TABLE tab OWNER TO pg_database_owner;

-- avec un compte superutilisateur
ALTER DATABASE test OWNER TO role1;

SET role = role1;
INSERT INTO tab VALUES (1), (2), (3);
-- INSERT 0 3

-- avec un compte superutilisateur
ALTER DATABASE test OWNER TO role2;

SET role = role1;
INSERT INTO tab VALUES (4), (5), (6);
-- ERROR:  permission denied for table tab
```

Pour conclure, les rôles `pg_write_all_data`, `pg_read_all_data` et `pg_database_owner`
peuvent se voir donner des droits sur d'autres objets de la base de données au 
même titre que tout autre rôle.

</div>
