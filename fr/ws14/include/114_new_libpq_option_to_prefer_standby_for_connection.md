<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/32/1677/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=ee28cacf619f4d9c23af5a80e1171a5adae97381

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/114

-->

<div class="slide-content">

* Nouvelles options pour le paramètre `target_session_attrs`
  * `read-only`, `primary`, `standby`, et `prefer-standby`

</div>

<div class="notes">

Une chaîne de connexion `libpq` peut contenir plusieurs serveurs.
Le paramètre `target_session_attrs` permet de préciser quel type de serveur
l'on veut[](https://docs.postgresql.fr/14/libpq-connect.html#LIBPQ-MULTIPLE-HOSTS).

En plus des options `any` (qui reste celle par défaut) et `read-write`
(choisir un serveur ouvert en écriture), `target_session_attrs`
supporte désormais les options suivantes :

* `read-only`, le serveur ne doit accepter que les sessions en lecture seule
  (mode _hot standby_ ou `default_transaction_read_only` à `on`) ;
* `primary`, le serveur ne doit pas être en mode _hot standby_ ;
* `standby`, le serveur doit être en mode _hot standby_ ;
* `prefer-standby`, dans un premier temps, essayer de trouver une instance
  secondaire, sinon utilise le mode `any`.

Des exemples de chaînes de connexion avec paramètre sont :

```ini
'postgresql://host1:123,host2:456/somedb?target_session_attrs=any'
'postgresql://host1:123,host2:456/somedb?target_session_attrs=read-write'
'host=serveur1,serveur2,serveur3 port=5432,5433,5434 target_session_attrs=read-only'
```
  
Avec ces nouvelles options, aucune communication réseau supplémentaire ne sera
nécessaire pour obtenir l'état de la session ou du serveur. Les variables GUC
fournies sont suffisantes. Dans les versions plus anciennes, une requête `SHOW`
ou `SELECT` devait être émise afin de détecter si la session était en lecture
seule ou si l'instance était en mode _hot standby_.

</div>
