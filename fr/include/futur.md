## Fonctionnalités futures

<div class="slide-content">

  * _Pluggable storage_
    * _HEAP storage_
    * _column storage_
    * _Zed Heap_
    * _blackhole_
</div>

<div class="notes">

Les _pluggable storage_ déterminent comment les données sont stockées
dans les tables et les vues. Les bases de cette API ont été publiées dans
cette version 12.

D'autres méthodes de stockages sont en cours de développement et permettront
de choisir un format en fonction de l'utilisation et/ou des données stockées,
table par table.

![*Heap storage* actuel](medias/schema_pluggable_storage_heap.png)


![*Pluggable Storage*](medias/schema_pluggable_storage.png)

FIXME c'est bien joli mais ils servent à quoi, ces deux graphiques ? il
faudrait un texte les expliquant s'ils ont un intérêt. Pour moi, ils n'en ont
pas et devraient donc être supprimés.

(source : [présentation d'Andres Freund PGConf-EU 2018 ](https://anarazel.de/talks/2018-10-25-pgconfeu-pluggable-storage/pluggable.pdf) )
</div>

---

### Pluggable storage 

#### HEAP storage

<div class="slide-content">
  * `HEAP storage`
  * méthode de stockage par défaut
  * seule méthode supportée pour le moment
</div>

<div class="notes">

La méthode de stockage traditionnelle de PostgreSQL pour ses objets, a été
adaptée en tant qu'_Access Method_ utilisant la nouvelle architecture. Cette
méthode a été simplement appelée `HEAP` et est pour le moment la seule
supportée.

FIXME je ne comprends pas, cette méthode ne fait pas partie du futur ? cette
slide devrait être supprimée à mon sens

</div>

---

#### Zedstore: Column storage


<div class="slide-content">
  * méthode orientée colonne
  * données compressées
  * nom temporaire !
</div>


<div class="notes">

**Heikki Linnakangas de Pivotal** travaille sur le **_column storage_**, une
méthode de stockage orientée "colonne" et permettant entre autres la
compression des données des colonnes.

Bénéfices :

  * optimisation en cas de nombreuses mises à jour sur une même colonne
  * suppression de colonne instantanée
  * possibilité de réécrire une colonne plutôt que toute la table

Pour plus d'information sur cette méthode de stockage et ses développements,
voir [les slides de conférence](https://www.postgresql.eu/events/pgconfeu2019/schedule/session/2738-zedstore-column-store-for-postgresql/)
de Heikki Linnakangas à ce sujet.

</div>

---

#### zHeap

<div class="slide-content">

  * meilleur contrôle du _bloat_
  * réduction de l'amplification des écritures
  * réduction de la taille des entêtes
  * méthode basée sur les différences 
  
</div>

<div class="notes">

**Enterprise DB** travaille actuellement sur une méthode de stockage nommée
_zHeap_ dont le fonctionnement repose sur un système UNDO en lieu et place du
REDO actuel. Le principe est de modifier les enregistrements "sur place"
lorsque c'est possible et de conserver dans les journaux de transaction
l'information suffisante pour retourner à l'état précédent en cas de ROLLBACK.

Les bénéfices observés seraient :
 
  * un meilleur contrôle du _bloat_
  * la réduction de l'amplification des écritures comparativement à la
    méthode `HEAP`
  * stockage plus performant en réduisant la taille des entêtes

</div>

---

#### Méthode d'accès _Blackhole_

<div class="slide-content">

  * sert de base pour créer une extension _Access Method_
  * toute donnée ajoutée est envoyée dans le néant
  
</div>

<div class="notes">

Cette extension écrite par
[Michael Paquier](https://github.com/michaelpq/pg_plugins/tree/master/blackhole_am),
fournit une base pour l'écriture des extensions pour les méthodes d'accès.
Toutes les données sont envoyées dans le néant. 

```sql
$ CREATE EXTENSION blackhole_am;
CREATE EXTENSION
$ \dx+ blackhole_am
   Objects in extension "blackhole_am"
           Object description
-----------------------------------------
 access method blackhole_am
 function blackhole_am_handler(internal)
(2 rows)

$ CREATE TABLE blackhole_tab (id int) USING blackhole_am;
CREATE TABLE
$ INSERT INTO blackhole_tab VALUES (generate_series(1,100));
INSERT 0 100
$ SELECT * FROM blackhole_tab;
 id
----
(0 rows)
```
</div>

---

