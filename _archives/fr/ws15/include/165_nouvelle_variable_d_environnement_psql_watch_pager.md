<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=7c09d2797ecdf779e5dc3289497be85675f3d134

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/165

-->

<div class="slide-content">

* Permet de définir un _pager_ pour la commande `\watch`
* Privilégier le pager _pspg_
* Fonctionne uniquement sous Unix

</div>

<div class="notes">

La méta-commande `\watch [durée]` de psql peut être placée juste après un ordre SQL pour le 
réexécuter à intervalle régulier.

```sh
[local]:5445 postgres@postgres=# SELECT 'hello world' \watch 1
Thu 18 Aug 2022 02:11:59 PM CEST (every 1s)

  ?column?   
-------------
 hello world
(1 row)

Thu 18 Aug 2022 02:12:00 PM CEST (every 1s)

  ?column?   
-------------
 hello world
(1 row)
```

Afin de faciliter la lecture du résultat des requêtes exécutées de cette manière, il 
est maintenant possible de définir un _pager_ via la variable d'environnement `PSQL_WATCH_PAGER`.

N'importe quel _pager_ peut être utilisé. Cependant, seul _pspg_ semble pour le moment réussir à interpréter correctement 
le flux renvoyé par la commande `\watch`. Des _pager_ traditionnels peuvent être utilisés (`less` par exemple), 
mais le résultat n'est pas particulièrement pratique à analyser et il finit généralement par être inutilisable.

Pour que _pspg_ puisse interpréter correctement le flux envoyé par la commande `\watch`, il faudra utiliser l'option 
`--stream`. Voici comment le définir :

```bash
export PSQL_WATCH_PAGER="pspg --stream"
```

</div>
