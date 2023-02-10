<!-- 

release note:

https://www.postgresql.org/docs/current/release-15.html#id-1.11.6.7.4

-->

<div class="slide-content">

* Fin du support de Python 2.x
  + Retrait des langages procéduraux `plpython2u` et `plpythonu`

</div>

<div class="notes">

Cette version marque la fin du support de Python 2 comme langage procédurale pour 
les fonctions PostgreSQL.

Le langage procédural `plpython2u`, qui implémente _PL/Python_ avec Python 2, 
est ainsi retiré. Seul le langage `plpython3u`, qui implémente _PL/Python_ avec 
Python 3, est désormais utilisable.

Le langage procédural `plpythonu`, qui pouvait pointer sur la version 2 ou 3 
en fonction du paramètre par défaut configuré dans chaque version de PostgreSQL,
a également été retiré puisqu'il n'a plus d'utilité.

</div>