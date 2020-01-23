## Incompatibilités

<div class="slide-content">

  * Disparition du `recovery.conf`
  * `max_wal_senders` plus inclus dans `max_connections`
  * Noms des clés étrangères
  * Tables `WITH OIDS` n'existent plus
  * Types de données supprimés
  * Fonctions `to_timestamp` et `to_date`
  * Outil `pg_checksums`

</div>

<div class="notes"></div>
----

### Disparition du fichier recovery.conf. 

<div class="slide-content">

* Fichier `recovery.conf` fusionné avec les paramètres normaux
</div>

<div class="notes">


Les paramètres de l'ancien `recovery.conf` deviennent des `GUC`
(_Grand Unified Configuration_) comme tous les autres paramètres. À ce titre,
ils peuvent donc être positionnés dans le fichier `postgresql.conf` ou tout
autres moyens (au démarrage, commande `ALTER SYSTEM`, fichier inclus, etc).
L'ancien fichier `recovery.conf` quant à lui disparaît.

En conséquence, la présence d'un fichier `recovery.conf` dans le répertoire
racine d'une instance PostgreSQL 12 bloque son démarrage.

Attention, les scripts et outils de gestion des PITR (eg. générant
automatiquement le fichier `recovery.conf`) doivent donc être mis à mettre à
jour en même temps que l'instance PostgreSQL 12.

De même, la gestion d'instance secondaire en réplication est aussi impactée.
Tout l'outillage mis en œuvre doit être mis à jour.

</div>

----

### `max_wal_senders` n'est plus inclus dans `max_connections`

<div class="slide-content">

* Les `wal senders` ne sont plus comptabilisés dans `max_connections`
* Impact potentiel sur les seuils de supervision
* Impact plus anecdotique pour ces paramètres 
</div>

<div class="notes">

Les processus _WAL senders_ sont chargés d'envoyer le contenu des WAL aux
instances en réplication. Chaque instance secondaire maintient une connexion
sur l'instance de production au travers de son wal sender attitré.

Depuis la version 12, le nombre de _wal senders_ n'est plus décompté du nombre
maximum de connexions (`max_connections`) autorisé.

Si des outils de supervision prenaient en compte le calcul (`max_connections` -
`max_wal_senders` par exemple), les sondes peuvent renvoyer des informations
légèrement faussées.

</div>

----

### Noms des clés étrangères autogénérées


<div class="slide-content">

* Changement de norme de nommage des FK
* Inclut désormais toutes les colonnes concernées
* Impact potentiel sur les outils
</div>


<div class="notes">

La génération automatique des noms de clés étrangères, prend désormais en
compte le nom de toutes les colonnes de la clé. Cela peut entraîner une
incompatibilité dans certains scripts qui se basent sur le nom des clés
étrangères générées par PostgreSQL avec une colonne.

**Exemple** :

```sql
pg12=> CREATE TABLE t2(id INT, id2 INT, comm VARCHAR(50),
FOREIGN KEY (id, id2) REFERENCES t1(id, id2)) ;
CREATE TABLE
postgres=> \d t2
Table "public.t2"
 Column |         Type          | Collation | Nullable | Default 
--------+-----------------------+-----------+----------+---------
 id     | integer               |           |          | 
 id2    | integer               |           |          | 
 comm   | character varying(50) |           |          | 
Foreign-key constraints:
    "t2_id_id2_fkey" FOREIGN KEY (id, id2) REFERENCES t1(id, id2)

```

</div>

----

### WITH OIDS

<div class="slide-content">

* Attribut `WITH OIDS` supprimé en version 12
* Colonnes `oid` « système » deviennent visibles
</div>

<div class="notes">

L'option `WITH OIDS` (instruction `CREATE TABLE`) est supprimée. Il n'est plus
possible de créer des tables avec une colonne `oid` « cachée ».

L'option `WITHOUT OIDS` est toujours supportée, et le paramètre
`default_with_oids` n'existe qu'en lecture seule avec comme valeur `off`.

**Exemple :** impossible de créer une table avec WITH OIDS

```sql
pg12=#  CREATE TABLE t3(id INT) WITH OIDS ;
psql: ERROR:  syntax error at or near "OIDS"
LINE 1: CREATE TABLE t3(id INT) WITH OIDS ;
```

Si cette colonne vous est utile, il faudra la créer explicitement. Elle
apparaît alors auprès des autres colonnes lors de requêtes de type `SELECT *
FROM ...` ou `TABLE ...`.

Coté catalogue système, toutes les colonnes `oid` deviennent visibles. Un
`SELECT *` sur ces tables affiche donc la colonne supplémentaire.

**Exemple :** la table pg_class à une colonne `oid` visible

```sql
pg12=#  postgres=# \d pg_class
                     Table "pg_catalog.pg_class"
       Column        |     Type     | Collation | Nullable | Default 
---------------------+--------------+-----------+----------+---------
 oid                 | oid          |           | not null | 
 relname             | name         |           | not null | 
 relnamespace        | oid          |           | not null | 
 reltype             | oid          |           | not null | 
 .......
```

L'option `-o` ou `--oids` de la commande `pg_dump` a également été supprimée.

</div>

----


### Type de données supprimés

<div class="slide-content">

Suppression des types suivants:

  * `abstime`
  * `reltime`
  * `tinterval`

</div>

<div class="notes">

Les types de données suivant ont été supprimés:

  * `abstime`
  * `reltime`
  * `tinterval`

L'utilisation de ces types était explicitement découragée et dépréciée dans la documentation depuis la version...7.0, en l'an 2000.

Ces types peuvent être avantageusement remplacés par les types `timestamp` et
`interval`, ou leurs dérivés.

Le type `abstime` de la colonne `valuntil` de la vue `pg_shadow` a été en
conséquence remplacé par `timestamp with time zone`.
</div>

----

### Fonctions to_timestamp et to_date

<div class="slide-content">

* Correction des fonctions `to_timestamp` et `to_date`
* Changement de comportement
</div>

<div class="notes">

Les espaces inutiles sont supprimés dans les modèles de formatage des
fonctions `to_timestamp` et `to_date`.

**Exemple :**

Jusqu'en version 11, cet appel de fonction renvoie une erreur ou un résultat
faux :

```sql
pg11=> SELECT TO_DATE('2019/08/25', ' YYYY/MM/DD') ;
  to_date
------------
0019-08-25

pg11=> SELECT TO_DATE('2019/08/25', ' YYYY/  MM/DD') ;
ERREUR:  valeur « /2 » invalide pour « MM »
DÉTAIL : La valeur doit être un entier
```

Dans PostgreSQL 12, les espaces inutiles sont supprimés et ignorés:

```sql
pg12=> SELECT TO_DATE('2019/08/25', ' YYYY/MM/DD') ;
  to_date
------------
2019-08-25

pg12=> SELECT TO_DATE('2019/08/25', ' YYYY/  MM/DD') ;
  to_date
------------
2019-08-25
```

Ce comportement peut potentiellement (quoique très rarement) avoir un impact
sur la couche applicative.
</div>

----

### `pg_verify_checksums` renommée en `pg_checksums`

<div class="slide-content">

L'outil `pg_verify_checksums` devient `pg_checksums`

</div>

<div class="notes">

La fonction `pg_verify_checksums` n'existe plus, elle est remplacée par
`pg_checksums` avec les mêmes fonctionnalités.

Attention à vos scripts de supervision ou de vérification !

</div>

----
