<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=5a2832465fd8984d089e8c44c094e6900d987fcd 

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/166

-->

<div class="slide-content">

* Permet de publier toutes les tables d'un schéma
* Possibilité de mixer tables et schéma
* Nouvelle table système `pg_publication_namespace` qui référence les schémas à publier

</div>

<div class="notes">

Cette nouvelle version introduit la possiblité de publier la totalité des tables d'un schéma. Elle 
 permet via les ordres `CREATE / ALTER PUBLICATION` de définir un ou plusieurs schémas pour lesquels 
toutes les tables seront incluses dans la publication (également les tables créées dans le futur).

```sql
CREATE PUBLICATION p1 FOR TABLES IN SCHEMA s1,s2;

ALTER PUBLICATION p1 ADD TABLES IN SCHEMA s3;
```

Comme pour la clause `ALL TABLES`, la clause `TABLES IN SCHEMA` nécessite d'utiliser un role ayant l'attribut `superuser`.

Il est également possible de mixer tables et schémas dans une publication :

```sql
CREATE PUBLICATION p2 FOR TABLE t1,t2,t3, TABLES IN SCHEMA s1;

ALTER PUBLICATION p2 ADD TABLE t4, TABLES IN SCHEMA s2;
```

Les schémas ajoutés dans une publication sont stockés dans une nouvelle vue système `pg_publication_namespace`, 
qui va contenir les `oid` des publications et des schémas publiés.

```sql
SELECT pubname, pnnspid::regnamespace
FROM pg_publication_namespace pn, pg_publication p
WHERE pn.pnpubid = p.oid;

 pubname | pnnspid 
---------+---------
 p1      | s1
 p1      | s2
```

Le plugin `pgoutput` a également été modifié pour prendre en compte ce changement. Maintenant, en cas d'utilisation 
de la clause `TABLES IN SCHEMA`, il va vérifier si la relation fait bien partie des schémas inclus dans la 
publication avant l'envoi des changements au souscripteur.

La commande `\dRp+` a été mise à jour pour prendre en compte cette nouvelle fonctionnalité. Elle affiche donc 
la liste des schémas associés à une publication :

```
postgres=# \dRp+ p1

Publication pub1
Owner     | All tables | Inserts | Updates | Deletes | Truncates | Via root
----------+------------+---------+---------+---------+-----------+----------
postgres  | f          | t       | t       | t       | f         | f

Tables from schemas:
"s1"
"s2"
```

Pour finir, `pg_dump` a également été mis à jour pour identifier si une publication inclut la clause `TABLES IN SCHEMA`.
Voici un exemple de ce que génère `pg_dump` :

```sql
--
-- Name: p1; Type: PUBLICATION; Schema: -; Owner: postgres
--
CREATE PUBLICATION p1 WITH (publish = 'insert, update, delete');
ALTER PUBLICATION p1 OWNER TO postgres;
--
-- Name: p1 s1; Type: PUBLICATION TABLES IN SCHEMA; Schema: s1; Owner: postgres
--
ALTER PUBLICATION p1 ADD TABLES IN SCHEMA s1;
```

</div>
