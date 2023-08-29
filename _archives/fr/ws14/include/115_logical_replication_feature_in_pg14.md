<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/29/1927/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=45fdc9738b36d1068d3ad8fdb06436d6fd14436b
* https://commitfest.postgresql.org/30/2727/
* https://www.dalibo.info/home/benoit/public/vip_management?&#vip_manager

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/115

-->

<div class="slide-content">

* Nouveau mode _streaming in-progress_ pour la réplication logique
  + à activer
* Informations supplémentaires pour les messages d'erreur de type `columns are missing`
* Ajout de la syntaxe `ALTER SUBSCRIPTION… ADD/DROP PUBLICATION…`

</div>

<div class="notes">

**Streaming in-progress**

Lorsque l'on utilise la réplication logique, le processus _walsender_ va procéder 
au décodage logique et réordonner les modifications depuis les fichiers WAL 
avant de les envoyer à l'abonné. Cette opération est faite en mémoire mais en 
cas de dépassement du seuil indiqué par le paramètre `logical_decoding_work_mem`, 
ces données sont écrites sur disque.

Ce comportement à deux inconvénients :

* il peut provoquer l'apparition d'une volumétrie non négligeable dans le répertoire 
`pg_replslot` et jouer sur les I/O ;
* il n'envoie les données à l'abonné qu'au `COMMIT` de la transaction, ce qui 
peut engendrer un fort retard dans la réplication. Dans le cas de grosses transactions, 
le réseau et l'abonné peuvent également être mis à rude épreuve car toutes les 
données seront envoyées en même temps.

Avec cette nouvelle version, il est maintenant possible d'avoir un comportement 
différent. Lorsque la mémoire utilisée pour décoder les changements depuis 
les WAL atteint le seuil de `logical_decoding_work_mem`, plutôt que d'écrire 
les données sur disque, la transaction consommant le plus de mémoire de décodage 
va être sélectionnée et diffusée en continu et ce même si elle n'a pas encore 
reçu de `COMMIT`.

Il va donc être possible de réduire la consommation I/O et également la latence entre 
le publieur et l'abonné.

Ce nouveau comportement n'est pas activé par défaut ; il faut ajouter 
l'option `streaming = on` à l'abonné :

```sql
CREATE SUBSCRIPTION sub_stream 
  CONNECTION 'connection string' 
  PUBLICATION pub WITH (streaming = on);

ALTER SUBSCRIPTION sub_stream SET (streaming = on);
```

Certains cas nécessiteront toujours des écritures sur disque. Par exemple
dans le cas où le seuil mémoire de décodage est atteint, mais qu'un tuple 
n'est pas complètement décodé.

**Messages d'erreur plus précis**

Le message d'erreur affiché dans les traces lorsqu'il manque certaines colonnes à
une table présente sur un abonné, a été amélioré. Il indique maintenant
la liste des colonnes manquantes et non plus simplement le message `is missing
some replicated columns`.

```sql
-- En version 13
ERROR:  logical replication target relation "public.t" 
        is missing some replicated columns

-- En version 14
ERROR:  logical replication target relation "public.t" 
        is missing replicated column: "champ"
```

**ALTER SUBSCRIPTION… ADD/DROP PUBLICATION…**

Jusqu'alors, dans le cas d'une mise à jour de publication dans une souscription,
il était nécessaire d'utiliser la commande `ALTER SUBSCRIPTION… SET PUBLICATION…`
et de connaître la liste des publications sous peine d'en perdre.

Avec la version 14, il est désormais possible d'utiliser la syntaxe
`ALTER SUBSCRIPTION… ADD/DROP PUBLICATION…` pour manipuler plus facilement les
publications.

```sql
-- on dispose d'une souscription avec 2 publications
\dRs
```
```sh
          Liste des souscriptions
 Nom | Propriétaire | Activé | Publication 
-----+--------------+--------+-------------
 sub | postgres     | t      | {pub,pub2}
```
```sql
-- en version 13 et inférieures, pour ajouter une nouvelle publication, il était
-- nécessaire de connaître les autres publications pour actualiser la souscription
ws14=# ALTER SUBSCRIPTION sub SET PUBLICATION pub,pub2,pub3;

-- en version 14, les clauses ADD et DROP simplifient ces modifications
ws14=# ALTER SUBSCRIPTION sub ADD PUBLICATION pub3;
```

</div>
