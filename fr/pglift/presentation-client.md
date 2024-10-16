---
title : 'Introduction au Socle PostgreSQL v2 Dalibo'
keywords:
- postgres
- postgresql
- workshop
- pglift
- ansible
- industrialisation


linkcolor:

licence : PostgreSQL                                                            
author: Dalibo & Contributors                                                   
revision: 2.15
url : http://dalibo.com/formations

#
# PDF Options
#

#toc: true

## Limiter la profondeur de la table des matières
toc-depth: 4

## Mettre les lien http en pieds de page
links-as-notes: true

## Police plus petite dans un bloc de code

code-blocks-fontsize: small

## Filtre : pandoc-latex-env = cadres de couleurs
## OBSOLETE voir pandoc-latex-admonition                         
latex-environment:
  importantframe: [important]
  warningframe: [warning]
  tipframe: [tip]
  noteframe: [note]
  frshaded: [slide-content]

## Filtre : pandoc-latex-admonition
## order of definition is important
pandoc-latex-admonition:
  - color: LightPink
    classes: [important]
    linewidth: 4
  - color: Khaki
    classes: [warning]
    linewidth: 4
  - color: DarkSeaGreen
    classes: [tip]
    linewidth: 4
  - color: Ivory
    classes: [note]
    linewidth: 4
  - color: DodgerBlue
    classes: [slide-content]
    linewidth: 4

#
# Reveal Options
#

# Taille affichage
width: 1920
height: 1080

## beige/blood/moon/simple/solarized/black/league/night/serif/sky/white
theme: white

## None - Fade - Slide - Convex - Concave - Zoom
transition: None

transition-speed: fast

# Barre de progression
progress: true

# Affiche N° de slide
slideNumber: true

# Le numero de slide apparait dans la barre d'adresse
history: true

# Defilement des slides avec la roulette
mouseWheel: false

# Annule la transformation uppercase de certains themes
title-transform : none

# Cache l'auteur sur la première slide
# Mettre en commentaire pour désactiver
hide_author_in_slide: true

---

# Introduction

<div class="slide-content">

* Né à partir d'un besoin identifié d'un outil pour la gestion de bases de données PostgreSQL
* Intégration avec Ansible pour automatiser le déploiement et la gestion des bases de données

</div>

<div class="notes">


Le Socle PostgreSQL Dalibo a été développé en réponse à un besoin identifié dans la gestion des
bases de données PostgreSQL.

Au fil des années, Dalibo a travaillé pour créer une solution qui répond aux besoins d'industrialisation
et d'homogénéité d'instances de bases de données PostgreSQL.

Aujourd'hui en version 2, le Socle PostgreSQL Dalibo permet désormais l'industrialisation via Ansible.
Cette intégration rend le déploiement et la gestion des instances et bases de données plus automatisés.

</div>

---

## Objectif de la présentation

<div class="slide-content">

* Vue d'ensemble du Socle PostgreSQL Dalibo
  * Industrialisation et gestion des bases de données PostgreSQL.

</div>

<div class="notes">

L'objectif principal de cette présentation est de fournir une vue d'ensemble complète du Socle
PostgreSQL Dalibo, en mettant l'accent sur ses capacités d'industrialisation et gestion des
bases de données PostgreSQL.

</div>

---

# Contexte

<div class="slide-content">

* Défis courants liés à la gestion des bases de données PostgreSQL
* Raisons pour lesquelles une solution d'industrialisation est nécessaire  

</div>

---

## Défis courants liés à la gestion des bases de données PostgreSQL

<div class="slide-content">

* Déploiement :
  * Choix complexes des configurations logicielles
* Maintenance :
  * Veille technologique continue
  * Mises à jour de sécurité et de performance
  * Gestion des problèmes d’indexation et requêtes mal optimisées
* Sauvegarde :
  * Nécessité d'une solution robuste et fiable
  * Tests réguliers de restauration
* Supervision :
  * Surveillance en temps réel de l'état de la BD
  * Performance des requêtes et utilisation des ressources
* Haute Disponibilité :  
  * Mise en place de réplication
  * Gestion du basculement automatique (`failover`)

</div>

<div class="notes">


La gestion des bases de données PostgreSQL présente plusieurs défis qui requièrent une
attention particulière.

En ce qui concerne le déploiement, le choix des configurations logicielles peut être complexe,
surtout lors de déploiements de solutions de haute-disponibilité.

La maintenance, quant à elle, nécessite une veille technologique continue pour appliquer les
mises à jour de sécurité et de performance, ainsi que pour gérer les problèmes d’indexation et
les requêtes mal optimisées qui peuvent affecter les performances.

Le système de sauvegarde doit être robuste et fiable pour prévenir la perte de données, ce qui
implique des tests réguliers de restauration et potentiellement l'adoption de solutions tierces.

La supervision est également cruciale pour une gestion proactive ; elle implique la mise en place
de mécanismes pour surveiller en temps réel l'état de la base de données, les performances des
requêtes et l'utilisation des ressources.

Enfin, la haute disponibilité est souvent un impératif, et mettre en place un système de réplication
ou un cluster peut s’avérer complexe, avec des défis comme le basculement automatique (`failover`)
et la cohérence des données.

Chacun de ces domaines nécessite une expertise spécifique pour garantir une gestion efficace
des bases de données PostgreSQL.

</div>

---

## Industrialisation dans le domaine de PostgreSQL

<div class="slide-content">

* Complexité Croissante
* Automatisation des Processus
* Cadre Standardisé
* Facilite la configuration et la gestion de la Haute Disponibilité.
* Mise en place simplifiée de mécanismes de surveillance.

</div>

<div class="notes">

Dans le domaine de PostgreSQL, une solution d'industrialisation est indispensable pour
diverses raisons cruciales.  

Tout d'abord, à mesure que les entreprises grandissent et que la quantité de données
qu'elles gèrent augmente, la complexité de la gestion des bases de données suit souvent une
courbe ascendante.

Cela se traduit par un besoin croissant de performances, de haute disponibilité, et d'homogénéité.
Une solution d'industrialisation permet d'automatiser de nombreux processus tels que le déploiement,
la maintenance et la supervision, ce qui réduit les marges d'erreur humaines et libère les équipes
techniques pour se concentrer sur des tâches à plus haute valeur ajoutée.

De plus, une approche industrialisée peut offrir un cadre standardisé pour la sauvegarde et la
récupération de données, garantissant ainsi l'intégrité et la durabilité de ces données essentielles.
Elle facilite également la mise en œuvre de pratiques de haute disponibilité en simplifiant leur
configuration et leur gestion.

Enfin, dans un environnement industrialisé, il est plus aisé de mettre en place des mécanismes
de surveillance et d'alerte, indispensables pour une réaction rapide en cas de problèmes.
En somme, l'industrialisation des bases de données PostgreSQL est essentielle pour assurer une gestion
robuste, efficace et évolutive dans des environnements professionnels de plus en plus exigeants.

</div>

---

# Présentation du Socle PostgreSQL v2 Dalibo

<div class="slide-content">

* Architecture technique
* Fonctionnalités clés
* Déploiement et Intégration du Socle PostgreSQL v2 Dalibo
* Cas d'Usage

</div>

---

## Architecture technique

<div class="slide-content">

* Offre flexibilité, automatisation, et robustesse
* Prise en charge de RedHat 8 et 9, Debian 11, Ubuntu 22.04
* Ne nécessite pas les droits administrateur
* Automatisation avec Ansible
* Documentation (DAT, MI, MEX)
* Support pour administrateurs et utilisateurs du Socle PostgreSQL v2 Dalibo

</div>

<div class="notes">

Dans une solution d'industrialisation pour PostgreSQL, l'architecture technique est conçue pour offrir
automatisation et robustesse.

Compatible avec plusieurs systèmes d'exploitation comme RedHat 8 et 9, Debian 11 et Ubuntu 22.04,
cette solution est suffisamment polyvalente pour s'adapter à des environnements diversifiés.

Un avantage clé est qu'elle ne nécessite pas les droits administrateur pour son fonctionnement,
ce qui simplifie les contraintes de sécurité et facilite son adoption dans des organisations avec
des politiques d'accès strictes.

L'utilisation de collections Ansible pour le déploiement permet une automatisation fluide, non seulement
pour installer la solution elle-même mais également pour déployer des instances PostgreSQL, configurer
des bases de données et gérer des rôles au sein de ces bases de données.

En ce qui concerne la documentation, la solution est bien pourvue, offrant une Documentation d'Architecture
Technique (DAT), un Manuel d'Installation (MI) et d'exploitation (MEX) pour aider tant les administrateurs
que les utilisateurs à comprendre et à utiliser le Socle PostgreSQL Dalibo.

</div>

---

## Fonctionnalités clés

<div class="slide-content">

* Déploiement
* Maintenance
* Sauvegardes Logique et Physique
* Supervision
* Haute-disponibilité
* Performance

</div>

<div class="notes">

- **Déploiement**:  
  `pglift` est l'outil permettant le déploiement d'une instance ainsi que ces composants satellite pour la supervision ou encore la Haute-Disponibilité.
  En plus du déploiement d'instance dite standalone, il est possible de créer son instance secondaire à l'aide
  du mécanisme de réplication natif à PostgreSQL.
  `pglift` va permettre également de créer et maintenir les bases de données ainsi que les rôles PostgreSQL.
  Son utilisation est possible au sein d'un terminal ou encore via sa collection Ansible `dalibo.pglift`.  

- **Maintenance**:  
  Lors du déploiement des instances par `pglift`, des services `systemd` sont mis en place afin d'assurer le
  démarrage, redémarrage ainsi que l'arrêt de l'instance. Par défaut, ces services sont déployés en mode
  utilisateur permettant la gestion de ces instance par un utilisateur système n'ayant pas de droits
  administrateur.
  En plus de ces services, il va également être possible de déployer un agent `temboard` permettant la gestion de
  l'instance via la console `temBoard`.

- **Sauvegardes**:  
  - Logiques :
    Par défaut, l'utilitaire `pg_dump` est utilisé par défaut pour la réalisation de sauvegarde logique. Cependant
    il est également possible d'utiliser l'outil `pg_back` permettant la prise en charge de la rotation et la rétention des sauvegardes.
    De plus, les sauvegardes peuvent être déclenchés par un timer `systemd` déployé lors de la création d'instance, afin d'effectuer les sauvegardes périodiquement.

  - Physiques :
    La solution _pgBackrest_ a été choisi pour la réalisation de sauvegardes physiques (PITR).
    Deux méthodes peuvent être mis en place :
      - Avec l'utilisation d'un dépôt de sauvegarde distante.
      - Avec l'utilisation d'un dépôt local.
    Tout comme les sauvegardes logiques, `pglift` déploie un timer `systemd`.

- **Supervision**:  
  La supervision est assurée par l'exporter Prometheus communautaire `postgres-exporter`. Celui-ci est déployé
  lors de la création d'instance et démarré en même temps que l'instance.
  Il est toutefois possible de le mettre en place à posteriori à l'aide de `pglift`.

- **Haute-disponibilité**:  
  La Haute-Disponibilité d'un cluster d'instance PostgreSQL est garanti par la solution `patroni`.
  Patroni assure l’exploitation d’un cluster PostgreSQL en réplication et est capable d’effectuer une bascule
  automatique en cas d’incident sur l’instance primaire.
  Le projet repose sur un DCS externe comme stockage distribué de sa configuration. Via le Socle PostgreSQL Dalibo,
  le DCS `etcd` est utilisé.

- **Performance**:  
  Le Socle PostgreSQL Dalibo livre l'utilitaire PoWA afin d'analyser les performances d'une instance voir d'une
  base de données. Lors du déploiement d'instance, `pglift` est capable de créer la base de données `powa` pour son
  utilisation. Dans le cadre du Socle PostgreSQL Dalibo, l'utilisation de PoWA se fait de manière centralisée,
  un serveur hébergeant la partie Web de PoWA est nécessaire et récupère les métriques de l'ensemble des instances
  ayant l'option PoWA d'activé.  
  En plus de l'utilisation de Powa, il est possible d'utiliser `pgbadger` et `pg_cluu` permettant de générer des
  rapports d'analyse du traffic SQL ainsi que des rapports sur le serveur hôte.

</div>

---

# Déploiement et Intégration du Socle PostgreSQL v2 Dalibo

<div class="slide-content">

* Dépôt Privé :
  * Héberge le paquet d'installation du Socle PostgreSQL v2 Dalibo
  * Maintient un contrôle sur les composants déployés
* Dépôt Public PGDG :
  * Source des paquets liés à PostgreSQL
  * Garantit l'utilisation des dernières versions stables
* Approche Hybride :
  * Flexibilité dans le déploiement
  * Assure que les paquets sont à jour

</div>

<div class="notes">

Le déploiement et l'intégration du Socle PostgreSQL v2 Dalibo s'effectuent de manière structurée,
en utilisant à la fois des dépôts privés et publics pour l'installation des paquets nécessaires.

Le paquet d'installation spécifique au Socle PostgreSQL v2 Dalibo est hébergé dans un dépôt privé,
ce qui permet de maintenir un contrôle sur les composants logiciels déployés.

Parallèlement, les paquets liés à PostgreSQL proviennent du dépôt public PGDG, garantissant ainsi
que les dernières versions stables du système de gestion de base de données sont utilisées.

En combinant ces sources fiables avec des outils d'automatisation pour le déploiement, le Socle
PostgreSQL v2 Dalibo offre une solution robuste et facilement intégrable dans des environnements
de production diversifiés.

</div>

---

# Cas d'Usage

<div class="slide-content">

* Contexte
* Objectif
* Solution
* Étapes d'Implémentation
* Résultats

</div>

---

## Contexte

<div class="slide-content">

* Une entreprise spécialisée dans le e-commerce
* Gestion de son inventaire avec une nouvelle architecture PostgreSQL
* Utilisation de RedHat 8

</div>

<div class="notes">

Une entreprise spécialisée dans le e-commerce souhaite déployer une nouvelle architecture de bases de données pour gérer son inventaire, les commandes des clients et les données analytiques. L'entreprise utilise déjà des serveurs RedHat 8 pour d'autres applications critiques.

</div>

---

## Objectif  

<div class="slide-content">

* Mettre en place une solution de gestion de bases de données PostgreSQL robuste
* Sécurisée
* Facilement maintenable sur un système RedHat 8.

</div>

---

## Solution  

<div class="slide-content">

* Solution d'industrialisation `pglift` pour PostgreSQL
* Compatible RedHat 8
* Ne nécessite pas de droits root

</div>

<div class="notes">

Utilisation de la solution d'industrialisation `pglift` pour PostgreSQL.
Cette solution est compatible avec RedHat 8 et ne nécessite pas de droits root pour le déploiement
d'instance, de bases de données et rôles, ce qui est conforme aux directives de sécurité de l'entreprise.

</div>

---

## Étapes d'Implémentation  

<div class="slide-content">

* Documentation et Formation
* Préparation des Serveurs
* Déploiement Automatisé
* Mise en Place de la Haute Disponibilité
* Sécurité
* Supervision
* Sauvegarde et Restauration
* Création de Bases de Données et Rôles

</div>

<div class="notes">

- Documentation et Formation: Formation des équipes techniques sur la gestion quotidienne et la maintenance de la nouvelle architecture, appuyée par une documentation complète.

- Préparation des Serveurs: Vérification de la compatibilité des serveurs RedHat 8 avec la solution d'industrialisation.

- Déploiement Automatisé: Utilisation de collections Ansible pour déployer la solution sur les serveurs. Cela comprend la configuration initiale et le paramétrage d'instances PostgreSQL.

- Mise en Place de la Haute Disponibilité: Configuration de fonctionnalités de réplication et de bascule automatique pour assurer une haute disponibilité.

- Sécurité: Implémentation de mesures de sécurité telles que l'authentification, en exploitant les fonctionnalités natives de la solution.

- Supervision: Utilisation des outils intégrés de la solution pour surveiller en temps réel la performance et l'état de santé des bases de données (`postgres-exporter` et `temBoard`).

- Sauvegarde et Restauration: Configuration des outils de sauvegarde à l'aide de `pglift`.

- Création de Bases de Données et Rôles: Utilisation des collections Ansible pour automatiser la création de bases de données pour l'inventaire, les commandes et les analyses, ainsi que la définition des rôles et des permissions.

</div>

---

## Résultats

<div class="slide-content">

* Déploiement rapide à l'aide d'Ansible
* Gestion sécurisée des bases de données PostgreSQL
* Haute disponibilité assurée pour les applications critiques
* Simplification de la maintenance

</div>

<div class="notes">

L'utilisation d'Ansible permet un déploiement rapide et précis, en éliminant les erreurs
humaines et accélérant le processus de mise en œuvre.

Pour les opérations essentielles, le Socle v2 garanti une haute disponibilité à l'aide de _Patroni_,
minimisant ainsi les risques de temps d'arrêt et renforçant la résilience des bases de données.

Grâce aux fonctionnalités automatisées de _pglift_ et _Ansible_, la maintenance devient plus
simple et moins chronophage.

En résumé, l'adoption de cette solution d'industrialisation pour PostgreSQL a permis à l'entreprise
de e-commerce de moderniser et de sécuriser sa gestion des bases de données sur RedHat 8, tout
en optimisant l'efficacité opérationnelle et en réduisant les coûts de maintenance.

</div>

---

# Questions

<div class="slide-content">

N'hésitez pas, c'est le moment !

</div>

<div class="notes">

</div>
