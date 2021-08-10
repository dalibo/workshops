<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=6568cef26e0f40c25ae54b8e20aad8d1410a854b

Discussion

* https://www.postgresql.org/message-id/flat/CAECtzeXOt4cnMU5+XMZzxBPJ_wu76pNy6HZKPRBL-j7yj1E4+g@mail.gmail.com

-->

<div class="slide-content">

* Option `--extension` ajoutée à la ligne de commande pg_dump
* Permet de spécifier un sous-ensemble d'extensions à exporter
* Permet d'exporter les extensions même lorsque l'option `--schema` est
  spécifiée

</div>

<div class="notes">

Dans les versions précédentes, les extensions d'une base de données étaient
exportées par `pg_dump`, mais il n'était pas possible de préciser les extensions
que l'on souhaitait embarquer dans l'export. De plus, le fait de préciser un
schéma avec l'option `--schema=MOTIF` ou `-n MOTIF` excluait les extensions
de l'export, car elles étaient considérées comme liées à la base de données
plutôt qu'au schéma.

Prenons l'exemple de l'extension `pgcrypto` installée sur une base de
données `workshop` qui contient le schéma `encrypted_data` que l'on souhaite
exporter. Deux exports du schéma `encrypted_data` sont réalisés avec `pg_dump`.
L'option `--extension` n'est spécifiée que pour le second.

```bash
pg_dump --format=custom \
        --dbname=workshop \
        --schema=encrypted_data > /backup/workshop_encrypted_data.dmp

pg_dump --format=custom \
        --dbname=workshop \
        --extension=pgcrypto \
        --schema=encrypted_data > /backup/workshop_encrypted_data_with_ext.dmp
```

La base de données `workshop` est alors supprimée et le premier dump
`encrypted_data.dmp` est importé à l'aide de `pg_restore`.

```bash
dropdb workshop

pg_restore --dbname postgres \
           --create \
           /backup/encrypted_data.dmp
```
On constate alors que l'extension est absente, elle n'a donc pas été incluse
dans le premier dump.

```sql
workshop=# \dx
Liste des extensions installées
-[ RECORD 1 ]-----------------------------
Nom         | plpgsql
Version     | 1.0
Schéma      | pg_catalog
Description | PL/pgSQL procedural language
```

La base de données `workshop` est à nouveau supprimée et le second dump
`workshop_encrypted_data_with_ext.dmp` est importé à l'aide de `pg_restore`.

```bash
dropdb workshop

pg_restore --dbname postgres \
           --create \
           /backup/workshop_encrypted_data_with_ext.dmp
```
En listant les extensions de la base de données, on constate cette fois que
l'extension `pgcrypto` a été restaurée dans la base de données
`workshop`.

```sql
workshop=# \dx

Liste des extensions installées
-[ RECORD 1 ]----------------------------------------------------
Nom         | pgcrypto
Version     | 1.9
Schéma      | public
Description | track planning and execution statistics of all SQL
            | statements executed
-[ RECORD 2 ]----------------------------------------------------
Nom         | plpgsql
Version     | 1.0
Schéma      | pg_catalog
Description | PL/pgSQL procedural language
```
On voit donc que lorsque l'option `--schema` est utilisée, aucune extension n'est
incluse dans l'export, à moins d'utiliser la nouvelle option `--extension`.

</div>
