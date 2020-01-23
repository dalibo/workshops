## Zheap

> Le présent README a pour objectif principal de donner un aperçu de la situation
actuelle conception de zheap, un nouveau format de stockage pour PostgreSQL. 
Ce projet a trois objectifs majeurs:

  * Fournir un meilleur contrôle sur le ballonnement. Dans le tas existant, nous
créons toujours
une nouvelle version de tuple lors de sa mise à jour. Ces nouvelles versions
sont postérieures
éliminés par élagage à vide ou à chaud, mais cela ne libère de la place pour la
réutilisation que par
futures insertions ou mises à jour; rien n'est retourné au système
d'exploitation. UNE
problème similaire se produit pour les tuples qui sont supprimés. zheap
empêchera le gonflement
(a) en autorisant les mises à jour sur place dans les cas courants et (b) en
réutilisant l’espace comme
Dès qu'une transaction ayant effectué une suppression ou une mise à jour non en
place a
engagé. En bref, avec ce nouveau stockage, nous évitons autant que possible
créer des ballonnements en premier lieu.
  * Réduisez l’amplification en écriture en évitant la réécriture des pages de
tas et en
permettant de faire une mise à jour qui touche les colonnes indexées sans
mettre à jour tous les index.
  * Réduisez la taille du tuple de (a) réduire l’en-tête du tuple et
(b) en éliminant la plupart des marges d'alignement.

Les mises à jour sur place seront prises en charge sauf lorsque (a) le nouveau
tuple est plus grand
que l'ancien tuple et l'augmentation de la taille, il est impossible d'adapter
le
tuple plus grand sur la même page ou (b) une colonne est modifiée, ce qui est
couvert par un index qui n'a pas été modifié pour prendre en charge le «marquage
par suppression».
Nous n'avons pas encore commencé à travailler sur le support de
suppression-marquage pour les index, mais nous avons l'intention
pour le supporter au moins pour les index btree.

### Idée générale de zheap avec undo

Chaque serveur est attaché à un journal d'annulation distinct dans lequel il
écrit
enregistrements. Chaque enregistrement annulé est identifié par un pointeur
d’enregistrement annulé de 64 bits:
dont les 24 premiers bits sont utilisés pour le numéro de journal et les 40 bits
restants
sont utilisés pour un décalage dans ce journal d'annulation. Une seule
transaction à la fois
peut écrire dans un journal d'annulation donné, de sorte que les enregistrements
d'annulation pour une transaction donnée
sont toujours consécutifs.

Chaque page zheap a un ensemble fixe de slots de transaction, chacun contenant
le
informations de transaction (transaction id et epoch) et dernier enregistrement
d'annulation
pointeur pour cette transaction. À ce jour, nous avons quatre créneaux de
transaction par
page, mais cela peut être changé. Actuellement, il s’agit d’une option de
compilation; nous
peut décider ultérieurement si une telle option est généralement souhaitable
pour les utilisateurs.
Chaque emplacement de transaction occupe 16 octets. Nous permettons aux créneaux
de transaction d'être
réutilisé après que la transaction est engagée, ce qui nous permet de
fonctionner sans
besoin de trop de créneaux horaires. Nous pouvons autoriser la réutilisation des
créneaux après une transaction.
annulez également, une fois que les actions d'annulation sont terminées. Nous
avons observé que plus petit
les tables indiquent qu’avoir très peu de pages nécessite généralement plus de
fentes; pour les grandes tables,
quatre emplacements suffisent. Lors de nos tests internes, nous avons constaté
que 16 emplacements
donner une très bonne performance, mais plus de tests sont nécessaires pour
identifier le bon
nombre d'emplacements. Le seul problème connu avec le nombre fixe de créneaux
horaires est que
peut conduire à une impasse, nous prévoyons donc d’ajouter un mécanisme
permettant à la
tableau des emplacements de transactions à poursuivre sur une page de
dépassement distincte. nous
également besoin d’un tel mécanisme pour prendre en charge les cas où un grand
nombre de
les transactions acquièrent des verrous SHARE ou KEY SHARE sur une seule page.
Le débordement
les pages seront stockées dans le zheap lui-même, avec des pages régulières.
Ces pages de débordement seront marquées de manière à permettre des analyses
séquentielles.
ignore les. Nous aurons une méta page dans zheap à partir de laquelle toutes les
pages de débordement
sera suivi.

En règle générale, chaque opération zheap qui modifie une page doit d'abord
allouer un
emplacement de transaction sur cette page, puis préparez un enregistrement
d'annulation pour l'opération.
Ensuite, dans une section critique, il doit écrire l’enregistrement
d'annulation, effectuer la
opération sur la page de tas, met à jour le slot de transaction dans une page,
et enfin
écrire un enregistrement WAL pour l'opération. Ce que nous écrivons dans le
cadre d'un enregistrement d'annulation
et WAL dépend de l'opération.

**Insert :** Outre les informations génériques, nous écrivons le TID (numéro de bloc
et offset
numéro) du tuple dans l’annulation pour identifier l’enregistrement lors de la
relecture.
En WAL, nous écrivons le numéro de décalage et le tuple, plus quelques valeurs
minimales.
informations qui seront nécessaires pour régénérer l’annulation lors de la
relecture.

**Supprimer :** Nous écrivons le tuple complet dans l’enregistrement d'annulation
même si nous pouvions obtenir
loin avec simplement écrire le TID comme nous le faisons pour une opération
d'insertion. Ceci permet
nous réutiliser l'espace occupé par l'enregistrement supprimé dès que la
transaction
qui a effectué l'opération commet. En WAL, nous devons écrire le tuple
uniquement si les écritures de page complètes ne sont pas activées. Si les
écritures pleine page sont activées, nous
peut compter sur l'état de la page pour être le même pendant la récupération que
pendant la
opération réelle, afin que nous puissions récupérer le tuple de la page pour le
copier dans le
annuler l'enregistrement.

**Mise à jour :** pour les mises à jour sur place, nous devons écrire l'ancien tuple
dans le journal d'annulation
et le nouveau tuple dans le zheap. Nous pourrions optimiser et
Envoyer des commentaires
Historique
Enregistré
Communauté

