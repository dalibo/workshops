<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=b577743000cd0974052af3a71770a23760423102

Discussion :

* https://postgr.es/m/F72E7BC7-189F-4B17-BF47-9735EB72C364@yesql.se

-->

<div class="slide-content">

  * Nouveau paramètre `scram_iterations`
    + détermine le nombre d'itérations à effectuer lors du chiffrement d'un mot
      de passe avec SCRAM
  * Valeur par défaut 
    + 4096
</div>

<div class="notes">

Il est désormais possible de configurer le nombre d'itérations effectuées
par l'algorithme de hachage lors de l'utilisation du mécanisme
d'authentification SCRAM. La valeur par défaut de 4096 itérations était écrite
en dur dans le code, suivant ainsi la recommandation de la [RFC 7677](https://datatracker.ietf.org/doc/html/rfc7677).

Augmenter ce paramètre permet d'obtenir des mots de passe plus résistants aux
attaques par force brute, étant donné que le coût de calcul est plus important
lors de la connexion. Si ce paramètre est réduit, le coût de calcul est
logiquement réduit.

Ce paramètre nécessite uniquement un rechargement de la configuration de
l'instance si il est modifié.

</div>
