<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=216a784829c2c5f03ab0c43e009126cbb819e9b2

Discussion :

* https://postgr.es/m/CAA4eK1+wyN6zpaHUkCLorEWNx75MG0xhMwcFhvjqm2KURZEAGw@mail.gmail.com

-->

<div class="slide-content">

  * Réplication logique
    + parallélisme lors de l'application
    + paramètre `streaming` d'une souscription

</div>

<div class="notes">

Avant la version 16, des transactions volumineuses
étaient transmises par morceaux par le publieur et reçues par
le souscripteur pour être appliquées. Avant d'être appliqués, les changements
apportés par les transactions étaient écrits dans des fichiers temporaires,
puis lorsque le commit était reçu, alors un worker lisait le contenu de ces
fichiers temporaires pour les appliquer. Ceci était notamment fait afin d'éviter qu'un `ROLLBACK` inutile soit fait sur le souscripteur.

Ces changements peuvent désormais être appliqués de manière parallélisée et les fichiers
temporaires ne sont plus utilisés. Un worker leader va recevoir
les transactions à appliquer puis enverra les changements à un worker ou
plusieurs workers qui travailleront en parallèle. L'échange des changements se
fait désormais via la mémoire partagée. Dans le cas où le worker leader n'arrive
plus à communiquer avec ses workers parallèles, il passera en mode
"sérialisation partielle" et écrira les modifications dans un fichier temporaire
pour conserver modifications à apporter.

Le parametre `streaming` d'un objet SUBSCRIPTION permet désormais de choisir si
l'application des changements se fait de manière parallèle ou non grâce à la valeur `parallel` :

- `off` : Toutes les transactions sont décodées du côté du publieur puis
  envoyées entièrement au souscripteur.
- `on` : Les transactions sont décodées sur le publieur puis envoyées au fil de
  l'eau. Les changements sont écrits dans des fichiers temporaires du côté du
  souscripteur et ne sont appliqués que lorsque le commit a été fait sur le
  publieur et reçu par le souscripteur.
- `parallel` : Les changements sont directement appliqués en parallèle par des
  workers sur le souscripteur, si des workers sont disponibles.

</div>
