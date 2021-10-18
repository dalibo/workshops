
<!--
Les commits sur ce sujet sont :

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=41c184bc642b25f67fb1d8ee290f28805fa5a0b4

Discussion : 

https://www.postgresql.org/message-id/CAHGQGwHCK6f77yeZD4MHOnN+PaTf6XiJfEB+Ce7SksSHjeAWtg@mail.gmail.com

-->

<div class="slide-content">

* `ignore_invalid_pages` permet de continuer la récupération quand les WAL font
  référence à des pages invalides
* Peut (et va) causer des crashs, pertes de données, cacher et propager des
  corruptions
* Permet de démarrer en cas de corruption
* À utiliser sur une copie de l'instance incidentée

</div>

<div class="notes"> 

La détection d'enregistrements de WAL qui font références à des pages invalides
pendant la récupération d'une instance cause normalement une erreur de type
_`PANIC`_. Ce qui interrompt la récupération et le démarrage de PostgreSQL.

Activer le paramètre `ignore_invalid_pages` permet au système d'ignorer ces
enregistrements et de continuer la récupération après avoir écrit un message
d'erreur de type _`WARNING`_ dans les traces de l'instance.

Il est important de travailler sur une __copie__ de l'instance incidentée lorsqu'on
utilise ce paramètre. En effet, son utilisation peut causer des crashs, des
pertes de données, ainsi que propager ou cacher des corruptions. Elle permet
cependant de continuer la récupération et démarrer le serveur dans des
situations désespérées. 

</div>
