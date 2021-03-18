<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=f5dff45962

Discussion générale:

* https://www.postgresql.org/message-id/574b4ea3-e0f9-b175-ead2-ebea7faea855@oss.nttdata.com

-->

<div class="slide-content">

* `wal_keep_segments` devient `wal_keep_size`
* La quantité de WAL à conserver est maintenant spécifiée en taille et plus en
  nombre de fichiers

</div>

<div class="notes">

Avant PostgreSQL 13, le paramètre `wal_keep_segments` avait pour fonction de
spécifier le nombre de WAL à conserver pour les instances secondaires. Ce
mécanisme est intéressant pour permettre à une instance secondaire de se
raccrocher à l'instance primaire suite à une déconnexion. Il permet également
de garantir que si cet état dure longtemps, le système de fichiers qui contient
les journaux de transactions ne se remplira pas, contrairement au mécanisme de 
slot de réplication.

Concernant les slots, le nouveau paramètre `max_slot_wal_keep_size`, a été créé
pour appliquer une limite similaire aux WAL conservés par des slots de réplication.
Ce paramètre permet de spécifier la valeur de cette limite en mégaoctets.
Les paramètres `min_wal_size` et `max_wal_size` spécifient également les
limites avant déclenchement d'un checkpoint en mégaoctets.

Afin d'harmoniser les noms et unités des paramètres GUC qui permettent de
spécifier des quantités de WAL, il a été décidé de :

* renommer `wal_keep_segments` en `wal_keep_size` ;
* utiliser l'unité `MB` pour spécifier la quantité de WAL à conserver grâce à ce
  paramètre.

Par exemple, sachant qu'un journal vaut généralement 16 Mo, on remplacera :
```
wal_keep_segments = 100
```
par :
```
wal_keep_size = 1600MB
```

Toutefois, une minorité des installations sera concernée par ce changement,
car la valeur par défaut est 0. De nos jours, une réplication est plutôt
sécurisée par _log shipping_ ou par slot de réplication.

</div>
