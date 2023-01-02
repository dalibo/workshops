<!--
Les commits sur ce sujet sont :

* database oid: https://github.com/postgres/postgres/commit/aa01051418f10afbdfa781b8dc109615ca785ff9
* relfilenode & tablespace oid: https://github.com/postgres/postgres/commit/9a974cbcba005256a19991203583a94b4f9a21a9
* relfilenode & pg_largeobjects: https://www.postgresql.org/message-id/E1o9pA7-001oEo-7O@gemulon.postgresql.org

-->

<div class="slide-content">

  * `pg_upgrade` préserve désormais :
    + les relfilenode
    + les oid de tablespaces
    + les oid de base de données

  * pour :
    + faciliter les analyses post upgrade
    + économiser de la bande passante quand on resynchronise une instance post
      upgrade avec rsync

</div>

<div class="notes">

`pg_upgrade` préserve désormais les _relfilenodes_, _tablespace oid_ et
_database oid_.

Le relfilenode est le nom utilisé par le fichier qui contient les données d'une
relation. Les différents segments et forks de la relation ajoutent un suffixe
au relfilenode (ex: `_vm` pour la _visibility map_). Il peut être différent de
l'oid de l'objet (identitifiant unique d'un objet) car certaines opérations
peuvent conduire à la recréation des fichiers de la relation comme un `VACUUM
FULL`.

Le _tablespace oid_ est l'identifiant unique d'un tablespace. Il est utilisé
pour le lien symbolique placé dans le répertoire `pg_tblspc` et qui pointe vers
le répertoire qui contient les données du tablespace.

Le _database oid_ est l'identifiant unique d'une base de données. Il est
utilisé pour nommer le répertoire qui regroupe toutes les données d'une base
de données dans un tablespace.

Ce changement permet donc limiter les changements de noms de fichiers,
répertoires et lien symboliques suite à une montée de version avec
`pg_upgrade`. Les bénéfices sont multiples :

* faciliter l'analyse en cas de problème lors de la mise à jour ;
* économiser de la bande passante quand on utilise rsync pour faire une mise à
  jour différentielle des fichiers d'une instance après une mise à jour ;
* faciliter l'implémentation de futures fonctionnalités comme le chiffrement
  des blocs pour lesquels le sel pourrait se baser sur le refilenode.

Pour permettre cette modification, il a été décidé que l'oid des bases système
serait fixé et que les bases de données utilisateurs auront un oid supérieur ou
égale à `16384`.

```sql
SELECT datname, oid FROM pg_database
```
```text
   datname    |  oid
--------------+-------
 formation    | 16384
 postgres     |     5
 template1    |     1
 template0    |     4
(4 rows)
```

La commande `CREATE DATABASE` se voit ajouter une nouvelle clause `OID` qui
permet de spécifier manuellement un oid. Cet ajout est principalement destiné à
l'usage de `pg_upgrade` qui est par ailleurs le seul à pouvoir assigner des oid
inférieurs à `16384`.

<!-- Note

pg_largeobject voit aussi son oid fixé, cela peut provoquer l'apparitition de
fichiers orphelins correspondant à la nouvelle version de pg_largeobject. Les
anciens fichiers liés a pg_largeobjects sont toujours présents et correctement
référencé ce qui est le principal.

ça ne me semble pas indispensable donc je le squeeze pour plus d'info voir le
patch dont le lien est la haut.

</div>
