<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=98681675002d852d926a49d7bc4d4b4856b2fc4a

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/135

-->

<div class="slide-content">

* Donne des statistiques sur l'utilisation des _slots_ de réplication logique
* Ajout de la fonction `pg_stat_reset_replication_slot`

</div>

<div class="notes">

Il est maintenant possible d'obtenir des statistiques d'utilisation des _slots_ de 
réplication logique via la vue système `pg_stat_replication_slots`. 

Voici la description des colonnes de cette vue :

* `slot_name` : nom du _slot_ de réplication
* `spill_txns` : nombre de transactions écritent sur disque lorsque la mémoire 
utilisée pour décoder les changements depuis les WAL a dépassé la valeur du 
paramètre `logical_decoding_work_mem`. Ce compteur est incrémenté pour les 
transactions de haut niveau et pour les sous-transactions.
* `spill_count` : nombre de fois où des transactions ont été écrites sur disque
lors du décodage des changements depuis les WAL. Ce compteur est incrémenté
à chaque fois qu'une transaction est écrite sur disque. Une même transaction 
peut être écrite plusieurs fois.
* `spill_bytes` : quantité de données écrite sur disque lors du décodage des 
changements depuis les WAL. Ce compteur et ceux liés aux écritures sur disque
peuvent servir pour mesurer les I/O générés pendant le décodage logique
et permettre d'optimiser le paramètre `logical_decoding_work_mem`.
* `stream_txns` : nombre de transactions en cours envoyées directement au plugin 
de décodage logique lorsque la mémoire utilisée pour le décodage des changements 
depuis les WAL a dépassé le paramètre `logical_decoding_work_mem`. Le flux de 
réplication ne fonctionne que pour les transactions de haut niveau (les 
sous-transactions ne sont pas envoyées indépendemment), ainsi le compteur 
n'est pas incrémenté pour les sous-transactions.
* `stream_count` : nombre de fois où des transactions en cours ont été envoyées
au plugin de décodage logique lors du décodage des changements depuis les WAL.
Ce compteur est incrémenté chaque fois qu'une transaction est envoyée. La même 
transaction peut être envoyée plusieurs fois.
* `stream_bytes` : quantité de données envoyée par flux au plugin de décodage 
logique lors du décodage des changements depuis les WAL. Ce compteur et ceux 
liés aux plugin de décodage logique peuvent servir pour optimiser le 
paramètre `logical_decoding_work_mem`.
* `total_txns` : nombre de transactions décodées et envoyées au plugin de décodage 
logique. Ne comprend que les transactions de haut niveau (pas de sous-transaction). 
Cela inclut les transactions écrites sur disques et envoyées par flux.
* `total_bytes` : quantité de données décodée et envoyée au plugin de décodage logique 
lors du décodage des changements depuis les WAL. Cela inclut les transactions 
envoyées par flux et écrites sur disques.
* `stats_reset` : date de remise à zéro des statistiques.

Concernant les colonnes `stream_txns`, `stream_count` et `stream_count`, celles-ci 
ne seront renseignées qu'en cas d'utilisation du mode _streaming in-progress_. Il 
faudra pour cela ajouter la clause `(streaming=on)` lors de la création de la 
souscription.

```sql
CREATE SUBSCRIPTION sub_streaming CONNECTION 'connection string' 
PUBLICATION pub 
WITH (streaming = on);
```

Une nouvelle fonction est également disponible : `pg_stat_reset_replication_slot`. 
Elle permet la remise à zéro des statisques de la vue `pg_stat_replication_slots` 
et peut prendre comme paramètre `NULL` ou le nom d'un _slot_ de réplication. Dans le 
cas de `NULL`, toutes les statistiques seront remises à zéro. Si un nom de _slot_ 
est précisé, seules les statistiques du _slot_ en question seront réinitialisées.

```sql
-- RAZ pour un slot précis
SELECT pg_stat_reset_replication_slot(slot_name);

-- RAZ pour tous les slots
SELECT pg_stat_reset_replication_slot(NULL);
```

</div>