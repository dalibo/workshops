<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/E1nZEA7-001vFV-Lj@gemulon.postgresql.org

-->

<div class="slide-content">

 * `CREATE DATABASE .. STRATEGY WAL_LOG` (valeur par défaut)
   + opération entièrement tracée dans les WAL
   + évite deux checkpoints potentiellement impactant pour les performances
   + manipulation plus sécurisée à la fois sur l'instance primaire et les
     instances qui rejouent les WAL par la suite, notamment les instances
     secondaires

 * `CREATE DATABASE .. STRATEGY FILE_COPY`
   + méthode historique
   + génère moins de WAL
   + plus rapide quand la base modèle est très grosse

</div>

<div class="notes">

Précédemment, lors de la création d'une base de données, PostgreSQL devait
réaliser un checkpoint, copier les fichiers de la base de référence, puis faire
un nouveau checkpoint.

Le premier checkpoint permet de s'assurer que les données des buffers sales
sont sur écrits sur disque, y compris ceux des tables _UNLOGGED_. Il permet
aussi de s'assurer que les commandes de suppressions de fichiers ont été
traitées, ce qui évite la disparition d'un fichier pendant sa copie. 

La copie des fichiers de la base de référence est tracée dans les WAL sous forme
d'un enregistrement unique pour chaque `TABLESPACE` utilisé par la base.
Chacun de ces enregistrements représente l'écriture du répertoire associé. 

Le second checkpoint permet de s'assurer qu'on ne rejouera pas les
enregistrements de WAL du `CREATE DATABASE` en cas de _crash recovery_. La
copie des fichiers pourrait en effet produire un résultat différent car des
modifications ont été faites après la copie mais avant la fin des WAL. Cela
causerait des erreurs dans le rejeu des enregistrements de WAL suivants. 

Un nouveau mécanisme a été mis en place pour permettre de réaliser le `CREATE
DATABASE` sans checkpoint.

Ce changement a plusieurs avantages :

* éviter deux checkpoints qui peuvent être très coûteux en performance à la
  fois pendant le checkpoint et après si `full_page_writes` est configuré à
  `on` (ce qui est la valeur par défaut). Ce problème peut arriver  sur des
  systèmes avec une grosse activité. La nouvelle méthode permet également
  d'améliorer les performances de la commande lorsque la base de référence est
  petite ;
* sécuriser la copie en listant les fichiers copiés à partir des informations
  présentes dans le catalogue au lieu de se baser sur le contenu du système de
  fichier. Cela permet d'éviter de copier des fichiers qui ne devraient pas
  être là ;
* sécuriser le rejeu des WAL en rendant l'opération plus robuste. Les données
  copiées sont toutes tracées dans les WAL au lieu de n'enregistrer qu'un
  marqueur qui signale qu'il faut copier le répertoire de la base modèle ;
* permettre plus de flexibilité pour développer d'autres fonctionnalités, par
  exemple TDE (_Transparent Data Encryption_).

Ce changement augmente cependant la volumétrie de WAL écrits, cela peut être un
problème dans certains cas. De plus, si la base est grosse, la copie de fichier
est plus performante.

Le changement n'étant pas sans pénalité, le choix de la stratégie de création
est laissé à l'utilisateur. `CREATE DATABASE` se voit donc ajouter un paramètre
supplémentaire, appelé `STRATEGY`, qui peut prendre la valeur `WAL_LOG` (valeur
par défaut) ou `FILE_COPY`.

La différence de volume de WAL généré par chaque commande est facilement
observable dans la vue `pg_stat_wal`.

Cas d'une création entièrement tracée dans les WAL :

```sql
SELECT pg_stat_reset_shared('wal');
CREATE DATABASE db_wal_log STRATEGY WAL_LOG;
SELECT wal_records, wal_bytes FROM pg_stat_wal;
```
```text
 wal_records | wal_bytes 
-------------+-----------
        1254 |   4519307
(1 row)
```

Cas d'une création en mode copie de fichier :

```sql
SELECT pg_stat_reset_shared('wal');
CREATE DATABASE db_file_copy STRATEGY FILE_COPY;
SELECT wal_records, wal_bytes FROM pg_stat_wal ;
```
```text
 wal_records | wal_bytes 
-------------+-----------
          11 |       849
(1 row)
```

La commande `ALTER DATABASE .. SET TABLESPACE` repose sur les mêmes mécanismes
que `CREATE DATABASE .. STRATEGY FILE_COPY`. L'opération était initialement
couverte par cette évolution mais la commande est plus complexe à modifier et
le travail n'a pas pu être fait dans les temps pour la sortie de la version 15.

</div>
