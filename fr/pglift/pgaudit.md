---
subtitle : 'Workshop pgAudit'
title : 'Implémentation et Utilisation de pgAudit avec pglift'
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
revision: 23.08
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
width: 1200
height: 768

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

Ce module aborde le déploiement d' une instance PostgreSQL avec l'extension `pgaudit`
depuis `pglift`.  

Ce module aborde le déploiement d'une instance PostgreSQL avec l'extension _pgAudit_
depuis _pglift_.  

Il sera également évoqué la configuration et l'exploitation des traces de _pgAudit_.

# Présentation de pgaudit

L'extension PostgreSQL _pgAudit_ permet d'obtenir des informations détaillées sur
l'activité des sessions ainsi que sur des objets directement dans les traces de l'instance
PostgreSQL.  

En complément des traces sur les requêtes produites par l'option PostgreSQL `log_statement = all`
les entrées de _pgAudit_ donneront plus de détails sur les opérations effectuées pour un audit.

# Installation

## Pré-requis

- Avoir le dépôt **PGDG** (PostgreSQL Global Development Group) de configuré
- PostgreSQL et _pglift_ (consulter le _workshop Compréhension et utilisation de pglift_)
- Déployer une instance PostgreSQL avec _pglift_

## Installation de pgAudit

Installer le paquet `pgaudit17_15`.

```bash
$ dnf install pgaudit17_15
```

# Déploiement d'une base de données avec pgAudit

## CLI

Dans un premier temps, _pgAudit_ nécessite d'être chargé dans `shared_preload_libraries` :
```bash
$ pglift pgconf set 'shared_preload_libraries=pg_stat_statements, pgaudit'
```
Le changement de l'option `shared_preload_libraries` nécessite un redémarrage de
l'instance. _pglift_ propose donc de redémarrer l'instance après l'application de
cette configuration.

Créer la base de données, en précisant l'ajout de l'extension _pgAudit_ :
```bash
$ pglift database create db1 --extension pgaudit
```

## Ansible

L'opération de création d'instance et de la base de données avec _pgAudit_ peut être réalisée
depuis un _playbook Ansible_.

Voici un exemple de _playbook_ :
```yaml
- name: my postgresql instances
  hosts: localhost
  tasks:
    - name: production instance
      dalibo.pglift.instance:
        name: prod
        state: started
        port: 5432
        settings:
          shared_preload_libraries: "pg_stat_statements, pgaudit"
        roles:
          - name: bob
            login: true
            password: "{{ prod_bob_password }}"
        databases:
          - name: db1
            owner: bob
            extensions:
              - name: pgaudit
                schema: public
```

# Configuration de pgAudit

La configuration de _pgAudit_ peut être faite de manière globale (via le fichier
`postgresql.conf` ou encore la commande `ALTER SYSTEM ... SET`), spécifique à une base
avec la commande `ALTER DATABASE ... SET` ou alors pour un rôle en utilisant
`ALTER ROLE ... SET`.

Voici la liste des paramètres pour _pgAudit_ :

**pgaudit.log** :
Spécifie quel type de requêtes vont êtres tracés par _pgAudit_. Les valeurs possibles sont les
suivantes :
- _READ_ : `SELECT` et `COPY` lorsque la source est une relation ou une requête.
- _WRITE_ : `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE` et `COPY` lorsque la destination est une relation.
- _FUNCTION_ : appels de fonction et blocs `DO`.
- _ROLE_ : requêtes relatives aux rôles et aux privilèges : `GRANT`, `REVOKE`, `CREATE/ALTER/DROP ROLE`.
- _DDL_ : toutes les commandes `DDL` qui ne sont pas incluses dans _ROLE_.
- _MISC_ : commandes diverses, par exemple : `DISCARD`, `FETCH`, `CHECKPOINT`, `VACUUM`, `SET`.
- _MISC_SET_ : Diverses commandes `SET`.
- _ALL_ : Inclut toutes les commandes ci-dessus.

Plusieurs valeurs peuvent être mentionnées en les séparant par une virgules et également
soustraites en préfixant avec le caractère `-`.
(ex. `pgaudit.log = ALL, -MISC, -MISC_SET`)

**pgaudit.log_catalog** : 
Spécifie si les requêtes sur le `pg_catalog` doivent être tracées ou non. Si ce paramètre
est désactivé, cela permet d'éviter les traces provenant d'outils tels que `psql`
ou _pgAdmin_ qui interrogent fortement le catalogue.

**pgaudit.log_client** :
Spécifie si les traces de _pgAudit_ seront visibles par un processus client tel que `psql`.
Il est recommandé de laisser ce paramètre désactivé, mais il peut être utile à des fins de
debug.

**pgaudit.log_level** :
Utilisable uniquement si `pgaudit.log_client` est actif, il permet de spécifier
le niveau de traces généré par _pgAudit_. Les valeurs autorisées sont :
`DEBUG1 .. DEBUG5`, `INFO`, `NOTICE`, `WARNING`

**pgaudit.log_parameter** :
Spécifie si _pgAudit_ doit également inclure dans ses traces les paramètres passés aux requêtes.
Ces informations sont incluses au format `CSV`.

**pgaudit.log_parameter_max_size** :
Les paramètres des requêtes qui dépassent cette limite ne sont pas tracés, mais remplacés par `<long param suppressed>`. Cette limite est définie en octets, et non en
caractères, elle ne tient donc pas compte des caractères multi-octets dans l'encodage d'un paramètre de texte.
Ce paramètre n'a aucun effet si `log_parameter` est désactivé. Si `pgaudit.log_parameter_max_size` est réglé sur 0 (la valeur par
défaut), tous les paramètres des requêtes sont enregistrés quelle que soit leur longueur.

**pgaudit.log_relation** :
Spécifie si l'audit de session doit créer une trace distincte pour chaque relation (`TABLE`, `VUE`, etc.)
référencée dans une instruction `SELECT` ou `DML`. C'est un raccourci utile pour une journalisation exhaustive
sans utiliser l'audit d'objet.

Ce paramètre est désactivé par défaut.

**pgaudit.log_rows** :
Spécifie si les traces de _pgAudit_ doivent inclure les lignes récupérées ou affectées par une
requête. Lorsqu'il est activé, le champ des lignes sera inclus après le champ des paramètres.

**pgaudit.log_statement** :
Spécifie si les traces de _pgAudit_ doivent inclure la requête ainsi que ces paramètres.

**pgaudit.log_statement_once** :
Indique si les traces doivent inclure le texte de la requête et les paramètres lors de la première entrée de
trace pour une combinaison requête/sous-requête ou lors de chaque entrée. L'activation de ce paramètre
entraîne des traces moins verbeuses, mais peut rendre plus difficile la détermination de la requête qui a
généré une entrée de trace, bien que la paire requête/sous-requête ainsi que l'identifiant du processus
devraient suffire à identifier le texte de la requête tracée lors d'une entrée précédente.

Ce paramètre est désactivé par défaut.

**pgaudit.role** :
Spécifie le rôle principal à utiliser pour les traces de _pgAudit_. 
Plusieurs rôles peuvent être définis en les attribuant au rôle principal. 
Cela permet à plusieurs groupes d'être en charge de différents aspects 
des traces de _pgAudit_.

## Utilisation au sein d'une session

Il est possible d'activer la journalisation de _pgAudit_ sur toutes les requêtes exécutées dans une
session.  
Pour cela il est nécessaire de spécifier `all` au paramètre `pgaudit.log` :
\scriptsize

```
$ psql db1
db1=# SET pgaudit.log = 'all';

db1=# create table account (id int, name text, password text, description text);

db1=# insert into account (id, name, password, description) values (1, 'user1', 'HASH1', 'user1 description');

db1=# select * from account ;

```

\normalsize

Dans les traces, on retrouve les requêtes auditées :

\scriptsize

```
AUDIT: SESSION,1,1,MISC,SET,,,SET pgaudit.log = 'all';,<not logged>

AUDIT: SESSION,2,1,DDL,CREATE TABLE,TABLE,public.account,"create table account
        (
            id int,
            name text,
            password text,
            description text
        );",<not logged>

AUDIT: SESSION,3,1,WRITE,INSERT,,,"insert into account (id, name, password, description) values (1, 'user1', 'HASH1', 'user1 description');",<not logged>

AUDIT: SESSION,4,1,READ,SELECT,,,"SELECT c.relname, NULL::pg_catalog.text FROM pg_catalog.pg_class c 
        WHERE c.relkind IN ('r', 'S', 'v', 'm', 'f', 'p') AND (c.relname) LIKE 'accou%' AND pg_catalog.pg_table_is_visible(c.oid) 
        AND c.relnamespace <> (SELECT oid FROM pg_catalog.pg_namespace WHERE nspname = 'pg_catalog')
        UNION ALL
        SELECT NULL::pg_catalog.text, n.nspname FROM pg_catalog.pg_namespace n WHERE n.nspname LIKE 'accou%' AND n.nspname NOT LIKE E'pg\\_%'
        LIMIT 1000",<not logged>

AUDIT: SESSION,5,1,READ,SELECT,,,select * from account ;,<not logged>
```

\normalsize

## Objet

L'audit niveau objet est implémenté via la mécanique des rôles. Le paramètre `pgaudit.role` défini le
rôle utilisé pour les traces des audits.
Une relation sera auditée si le rôle dédié à _pgAudit_ a les permissions pour la requête exécutée.

Créer un rôle dédié à _pgAudit_ :
```shell
$ pglift role create --login auditor
```

Spécifier le rôle `auditor` à l'option `pgaudit.role` et accorder les permissions ci-dessous :
```
$ psql db1

db1=# SET pgaudit.role = 'auditor';

db1=# grant select (password) on public.account to auditor;

db1=# grant update (name, password) on public.account to auditor;
```

Puis exécuter les requêtes suivantes :
```
db1=# select id, name from account;

db1=# select password from account;

db1=# update account set description = 'another description';

db1=# update account set password = 'HASH2';
```

Dans les logs de PostgreSQL, seules les traces de _pgAudit_ des requêtes sur la colonne `password` sont présentes :
\scriptsize

```
AUDIT: OBJECT,1,1,READ,SELECT,TABLE,public.account,select password from account;,<not logged>
AUDIT: OBJECT,2,1,WRITE,UPDATE,TABLE,public.account,update account set password = 'HASH2';,<not logged>
```

\normalsize
