## Fonctionnalités futures

<div class="slide-content">

  * _Pluggable storage_
    * _HEAP storage_, historique et par défaut
    * _columnar storage_
    * _Zed Heap_
    * _blackhole_
</div>

<div class="notes">

Jusqu'à lors, le stockage des données s'effectuait dans les tables à l'aide
d'un mécanisme appellé _Heap Storage_. Cette méthode était l'unique
implémentation du stockage dans PostgreSQL pour le contenu des tables ou des
vues matérialisées.

Avec la version 12, l'ajout des _pluggable storages_ apporte une nouvelle couche
d'abstraction dans la gestion des accès aux données des tables et des vues.

D'autres méthodes de stockage sont en cours de développement et permettront
de choisir un format en fonction de l'utilisation des données stockées, table
par table. Cette amélioration permettra de répondre à des attentes utilisateurs
déjà présentes dans les autres moteurs SGBD du marché.

<!--
![*Heap storage* actuel](medias/schema_pluggable_storage_heap.png)
![*Pluggable Storage*](medias/schema_pluggable_storage.png)
-->

Pour aller plus loin : [Présentation d'Andres Freund PGConf-EU 2018 ](https://anarazel.de/talks/2018-10-25-pgconfeu-pluggable-storage/pluggable.pdf)
</div>

---

### Pluggable storage 

#### HEAP storage

<div class="slide-content">

  * `HEAP storage`
  * Méthode de stockage par défaut
  * Seule méthode supportée pour le moment
</div>

<div class="notes">

La méthode de stockage traditionnelle de PostgreSQL pour ses objets, a été
adaptée en tant qu'_Access Method_ utilisant la nouvelle architecture. Cette
méthode a été simplement appelée `HEAP` et est pour le moment la seule
supportée.

<!--
FIXME je ne comprends pas, cette méthode ne fait pas partie du futur ? cette
slide devrait être supprimée à mon sens

(florent) Selon moi ce slide est nécessaire pour comprendre que la nouvelle 
architecture s'appuie sur une implémentation déjà existante et reste transparente
pour la version en cours, et permet de faire le lien avec les méthodes à venir.
-->

</div>

---

#### Méthode d'accès ZedStore (Columnar storage)


<div class="slide-content">

  * Méthode orientée colonne
  * Données compressées
  * Nom temporaire !
</div>


<div class="notes">

**Heikki Linnakangas de Pivotal** travaille sur le **_columnar storage_**, une
méthode de stockage orientée « colonne » et permettant entre autres, la
compression des données des colonnes.

Bénéfices :

  * Optimisation en cas de nombreuses mises à jour sur une même colonne ;
  * Suppression de colonne instantanée ;
  * Possibilité de réécrire une colonne plutôt que toute la table.

Pour plus d'informations sur cette méthode de stockage et ses développements,
voir [les slides de conférence](https://www.postgresql.eu/events/pgconfeu2019/schedule/session/2738-zedstore-column-store-for-postgresql/)
de Heikki Linnakangas à ce sujet.

</div>

---

#### Méthode d'accès zHeap

<div class="slide-content">

  * Meilleur contrôle du _bloat_
  * Réduction de l'amplification des écritures
  * Réduction de la taille des entêtes
  * Méthode basée sur les différences 
  
</div>

<div class="notes">

**EnterpriseDB** travaille actuellement sur une méthode de stockage nommée
_zHeap_ dont le fonctionnement repose sur un système UNDO en lieu et place du
REDO actuel. Le principe est de modifier les enregistrements "sur place"
lorsque c'est possible et de conserver dans les journaux de transaction
l'information suffisante pour retourner à l'état précédent en cas de ROLLBACK.

Les bénéfices observés seraient :
 
  * un meilleur contrôle du _bloat_
  * la réduction de l'amplification des écritures comparativement à la
    méthode `HEAP`
  * stockage plus performant en réduisant la taille des entêtes

Pour aller plus loin : [Article du contributeur Amit Kapila d'EntrepriseDB](https://www.enterprisedb.com/blog/zheap-storage-engine-provide-better-control-over-bloat)

</div>

---

#### Méthode d'accès _Blackhole_

<div class="slide-content">

  * Sert de base pour créer une extension _Access Method_
  * Toute donnée ajoutée est envoyée dans le néant
  
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
