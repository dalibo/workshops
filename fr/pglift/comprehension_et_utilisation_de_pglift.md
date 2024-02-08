---
subtitle : 'Workshop pglift'
title : 'Compréhension et utilisation de pglift'
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

<div class="notes">

Ce workshop a pour but de détailler le déploiement et l'administration
d'instances PostgreSQL avec _pglift_.

</div>

---

# Présentation de pglift

<div class="slide-content">
- Permet de déployer et gérer des instances PostgreSQL uniformisées
- Instances prêtes pour la production dès leur déploiement
- Capable de déployer des instances en réplication avec _patroni_
- Prend en charge _pgBackRest_ en mode local ou distant
</div>

<div class="notes">

_pglift_ est un outil qui permet de déployer et gérer des instances PostgreSQL
uniformisées. Les instances peuvent être prêtes pour la production dès leur
déploiement, c'est à dire qu'elles sont installées avec une sauvegarde configurée
et un _endpoint_ de supervision accessible.

Pour les besoins de haute disponibilité, _pglift_ est capable de déployer
des instances en réplication avec _patroni_.

Pour effectuer des sauvegarde physiques, _pglift_ prend en charge _pgBackRest_ en
mode local ou distant.

Par défaut, _pglift_ se contente de déployer et de gérer PostgreSQL, les composants
pris en charge sont optionnels, à activer dans sa configuration.

</div>

---

## CLI

<div class="slide-content">
- L'ensemble de ses fonctionnalités exposées dans une interface en ligne de commande
</div>

<div class="notes">

_pglift_ expose l'ensemble de ses fonctionnalités dans une interface en ligne de
commande.

```bash
[postgres@srv-pg1 ~]$ pglift

Usage: pglift [OPTIONS] COMMAND [ARGS]...

  Deploy production-ready instances of PostgreSQL

Options:
  -L, --log-level [DEBUG|INFO|WARNING|ERROR|CRITICAL]
                                  Set log threshold (default to INFO when
                                  logging to stderr or WARNING when logging to
                                  a file).
  -l, --log-file LOGFILE          Write logs to LOGFILE, instead of stderr.
  --interactive / --non-interactive
                                  Interactively prompt for confirmation when
                                  needed (the default), or automatically pick
                                  the default option for all choices.
  --version                       Show program version.
  --completion [bash|fish|zsh]    Output completion for specified shell and
                                  exit.
  --help                          Show this message and exit.

Commands:
  instance           Manage instances.
  pgconf             Manage configuration of a PostgreSQL instance.
  role               Manage roles.
  database           Manage databases.
  patroni            Handle Patroni service for an instance.
  postgres_exporter  Handle Prometheus postgres_exporter
```

La commande permet de créer et gérer des instances PostgreSQL et les services
associés. Elle permet également de créer des bases de données et des rôles dans
une instance existante.

L'aide de chaque commande citées ci-dessus peut être affichée. Par exemple,
pour l'aide de la commande `instance` :

```bash
[postgres@srv-pg1 ~]$ pglift instance --help

Usage: pglift instance [OPTIONS] COMMAND [ARGS]...

  Manage instances.

Options:
  --schema  Print the JSON schema of instance model and exit.
  --help    Show this message and exit.

Commands:
  alter       Alter PostgreSQL INSTANCE
  backups     List available backups for INSTANCE
  create      Initialize a PostgreSQL instance
  drop        Drop PostgreSQL INSTANCE
  env         Output environment variables suitable to handle to...
  exec        Execute command in the libpq environment for PostgreSQL...
  get         Get the description of PostgreSQL INSTANCE.
  list        List the available instances
  logs        Output PostgreSQL logs of INSTANCE.
  privileges  List privileges on INSTANCE's databases.
  promote     Promote standby PostgreSQL INSTANCE
  reload      Reload PostgreSQL INSTANCE
  restart     Restart PostgreSQL INSTANCE
  restore     Restore PostgreSQL INSTANCE
  start       Start PostgreSQL INSTANCE
  status      Check the status of instance and all satellite components.
  stop        Stop PostgreSQL INSTANCE
  upgrade     Upgrade INSTANCE using pg_upgrade
```

Il en va de même pour les sous-commandes, par exemple, pour l'aide de `pglift instance alter` :

```bash
[postgres@srv-pg1 ~]$ pglift instance alter --help
Usage: pglift instance alter [OPTIONS] [INSTANCE]

  Alter PostgreSQL INSTANCE

  INSTANCE identifies target instance as <version>/<name> where the <version>/
  prefix may be omitted if there is only one instance matching <name>.
  Required if there is more than one instance on system.

Options:
  --port PORT                     TCP port the postgresql instance will be
                                  listening to. If unspecified, default to
                                  5432 unless a 'port' setting is found in
                                  'settings'.
  --data-checksums / --no-data-checksums
                                  Enable or disable data checksums. If
                                  unspecified, fall back to site settings
                                  choice.
  --state [started|stopped]       Runtime state.
  --powa-password TEXT            Password of PostgreSQL role for PoWA.
  --prometheus-port PORT          TCP port for the web interface and telemetry
                                  of Prometheus.
  --prometheus-password TEXT      Password of PostgreSQL role for Prometheus
                                  postgres_exporter.
  --patroni-restapi-connect-address CONNECT_ADDRESS
                                  IP address (or hostname) and port, to access
                                  the Patroni's REST API.
  --patroni-restapi-listen LISTEN
                                  IP address (or hostname) and port that
                                  Patroni will listen to for the REST API.
                                  Defaults to connect_address if not provided.
  --patroni-postgresql-connect-host CONNECT_HOST
                                  Host or IP address through which PostgreSQL
                                  is externally accessible.
  --patroni-postgresql-replication-ssl-cert CERT
                                  Client certificate.
  --patroni-postgresql-replication-ssl-key KEY
                                  Private key.
  --patroni-postgresql-replication-ssl-password TEXT
                                  Password for the private key.
  --patroni-postgresql-rewind-ssl-cert CERT
                                  Client certificate.
  --patroni-postgresql-rewind-ssl-key KEY
                                  Private key.
  --patroni-postgresql-rewind-ssl-password TEXT
                                  Password for the private key.
  --patroni-etcd-username USERNAME
                                  Username for basic authentication to etcd.
  --patroni-etcd-password TEXT    Password for basic authentication to etcd.
  --help                          Show this message and exit.
```

</div>

---

## Ansible (Collection dalibo.pglift)

<div class="slide-content">
- Fonctionnalités de _pglift_ accessibles depuis la collection `dalibo.pglift`
- Permet d'intégrer _pglift_ dans un processus de déploiement automatisé _ansible_
</div>

<div class="notes">

Les fonctionnalités de _pglift_ sont également accessibles depuis la collection
`dalibo.pglift`. Celle-ci fourni les modules _ansible_ permettant d'intégrer les
opérations de _pglift_ dans un processus de déploiement automatisé déclaratif
à l'aide d'_ansible_ (_infrastructure as code_).

</div>

---

# Installation

---

## Pré-requis

<div class="slide-content">
- Dépôts Powertools, epel, PGDG et Dalibo Labs
- Utilisateur système `postgres`
- Activer le **lingering**
</div>

<div class="notes">

Les machines suivantes sont utilisées pour réaliser les procédures techniques
des workshops _pglift_ :

| Serveur         | OS           | Rôle                                 |
|-----------------|--------------|--------------------------------------|
| srv-pg1         | RockyLinux 8 | Serveur de bases de données          |
| srv-pg2         | RockyLinux 8 | Serveur de bases de données          |
| srv-helper      | RockyLinux 8 | Serveur de sauvegarde et supervision |
| srv-etcd1       | RockyLinux 8 | Serveur DCS 1                        |
| srv-etcd2       | RockyLinux 8 | Serveur DCS 2                        |
| srv-etcd3       | RockyLinux 8 | Serveur DCS 3                        |

L'ensemble des tâches de ce module seront effectuées sur serveur `srv-pg1`. Les
autres serveurs seront utilisés dans les workshops suivants.

Activer le dépôt additionnel `PowerTools` :

```shell
[root@srv-pg1 ~]# dnf config-manager -y --set-enabled powertools
```

Installer le dépôt _EPEL_ :
```shell
[root@srv-pg1 ~]# dnf install -y epel-release
```

Installer le dépôt _PGDG_ de la communauté PostgreSQL :

```shell
[root@srv-pg1 ~]# dnf install -y \
https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/\
pgdg-redhat-repo-latest.noarch.rpm
```

Désactiver le module dnf `postgresql` afin de pouvoir installer les paquets
PostgreSQL de la communauté :

```shell
[root@srv-pg1 ~]# dnf -y module disable postgresql
```

Installer le dépôt _Dalibo Labs_ :
```
[root@srv-pg1 ~]# dnf -y install \
https://yum.dalibo.org/labs/dalibo-labs-4-1.noarch.rpm
```

Installer _python 3.9_ sur les serveurs PostgreSQL :

```shell
[root@srv-pg1 ~]# dnf -y install python39
```

Créer l'utilisateur `postgres`

```shell

[root@srv-pg1 ~]# useradd -U -d /home/postgres -s /bin/bash postgres
```

:::tip
L'utilisateur est créé avant d'installer PostgreSQL pour avoir le contrôle
sur le répertoire _home_ utilisé.
:::

Créer le répertoire pour l'arborescence des données :

```shell
[root@srv-pg1 ~]# mkdir /pgdata && chown postgres:postgres /pgdata
```

Créer les répertoires de configuration de _pglift_ dans `~/.config` en tant que
`postgres` :

```shell
[root@srv-pg1 ~]# su - postgres << EOF
mkdir -p ~/.config/pglift/postgresql
mkdir -p ~/.config/pglift/pgbackrest
EOF
```

Configurer le `lingering` sur l'utilisateur `postgres`, ce qui lui permettra de
faire fonctionner des services système, au même titre que `root` :

```shell
[root@srv-pg1 ~]# loginctl enable-linger postgres
```

</div>

---

## Installation de PostgreSQL

Installer PostgreSQL 15 :

```shell
[root@srv-pg1 ~]# dnf install -y postgresql15 postgresql15-server postgresql15-contrib
```

---

## Installation des composants satellite

Installer les paquets `pgbackrest` et `prometheus-postgres-exporter` :

```shell
[root@srv-pg1 ~]# dnf install -y pgbackrest prometheus-postgres-exporter
```

---

## Installation de pglift

---

### pipx

Installer _pglift_ avec `pipx`, en tant que `postgres` :

```shell
[root@srv-pg1 ~]# su - postgres << EOF
  pip3.9 install pipx
  ~/.local/bin/pipx install pglift==1.0.0
  ~/.local/bin/pipx ensurepath
EOF
```

:::warn
Ouvrir une nouvelle session est nécessaire pour que le binaire `pglift` soit dans
le `${PATH}` de l'utilisateur `postgres`
:::

---

## Configuration initiale

<div class="slide-content">
- Fichier de configuration _pglift_ :
  - `~/.config/pglift/settings.yaml`
  - `/etc/pglift/settings.yaml`
- Template de configuration PostgreSQL et pgBackRest
- Installer la configuration de site : `pglift site-configure install`
</div>

<div class="notes">

Le fichier de configuration principal de _pglift_ déclare le fonctionnement de
ses opérations. C'est un fichier au format _YAML_.

Une première version assez basique de cette configuration est déposée
dans le fichier `~/.config/pglift/settings.yaml`

```yaml
!include include/comprehension_et_utilisation_de_pglift/settings.yaml.j2
```

_pglift_ substitue des variables à partir des caractéristiques de l'instance à
déployer. Ainsi, les variables `{version}` et `{name}`, qui sont obligatoires
pour l'option `datadir`, seront remplacées par la version PostgreSQL de l'instance
et le nom qui est renseigné à sa création.

En plus de ce fichier, _pglift_ supporte l'utilisation de _templates_ de fichiers
de configuration. Ces derniers peuvent être utilisés pour modifier globalement
les paramètres associés aux instances qui seront ensuite déployées sur le nœud local.

Les templates suivants sont déposés sur les nœuds PostgreSQL :

* `~/.config/pglift/postgresql/postgresql.conf` : Configuration  de l'instance
PostgreSQL

```ini
!include include/comprehension_et_utilisation_de_pglift/postgresql.conf.j2
```

* `~/.config/pglift/postgresql/pg_hba.conf` : Configuration de l'authentification
PostgreSQL

```ini
!include include/comprehension_et_utilisation_de_pglift/pg_hba.conf.j2
```

* `~/.config/pglift/postgresql/pg_ident.conf` : Mapping des utilisateurs système
avec des rôles PostgreSQL

```ini
!include include/comprehension_et_utilisation_de_pglift/pg_ident.conf.j2
```

* `~/.config/pglift/pgbackrest/pgbackrest.conf` : Configuration globale de _pgBackRest_

```ini
!include include/comprehension_et_utilisation_de_pglift/pgbackrest.conf.j2
```

_pglift_ substitue certaines variables dans les _templates_ à partir de son
paramètrage, ou bien des spécifications du système. Par exemple :

* `shared_buffers = 25%` : La valeur du paramètre sera transformée en 25% de la
quantité totale de mémoire sur le serveur lors du déploiement.
* `{surole}` sera remplacé par le nom du super-utilisateur choisi (`postgres` par défaut)
* `{auth.host}` correspondra à la valeur `postgresql.auth.host` de la configuration
de _pglift_.

Avant de pouvoir créer des instances, il faut préparer le système à accueillir
des instances _pglift_ selon la configuration actuelle. Pour ce faire, exécuter
la commande `pglift site-configure install`

```shell
[postgres@srv-pg1 ~]$ pglift site-configure install
INFO     installed pglift-postgres_exporter@.service systemd unit at
> /var/lib/pgsql/.local/share/systemd/user/pglift-postgres_exporter@.service
INFO     installed pglift-backup@.service systemd unit at
> /var/lib/pgsql/.local/share/systemd/user/pglift-backup@.service
INFO     installed pglift-backup@.timer systemd unit at
> /var/lib/pgsql/.local/share/systemd/user/pglift-backup@.timer
INFO     installed pglift-postgresql@.service systemd unit at
> /var/lib/pgsql/.local/share/systemd/user/pglift-postgresql@.service
INFO     installing base pgbackrest configuration
INFO     creating pgbackrest include directory
INFO     creating pgbackrest repository path
INFO     creating common pgbackrest directories
INFO     creating postgresql log directory
```

</div>

---

# Déploiement d'une instance (CLI)

<div class="slide-content">
```shell
[postgres@srv-pg1 ~]$ pglift instance create main --pgbackrest-stanza=main
```
</div>

<div class="notes">
Déployer une instance à l'aide de la ligne de commande `pglift` :

```shell
[postgres@srv-pg1 ~]$ pglift instance create main --pgbackrest-stanza=main
INFO     initializing PostgreSQL
INFO     configuring PostgreSQL authentication
INFO     configuring PostgreSQL
INFO     starting PostgreSQL 15-main
INFO     creating role 'prometheus'
INFO     creating role 'backup'
INFO     altering role 'backup'
INFO     configuring Prometheus postgresql 15-main
INFO     configuring pgBackRest stanza 'main' for pg1-path=/pgdata/15/main/data
INFO     creating pgBackRest stanza main
INFO     starting Prometheus postgres_exporter 15-main
```

La commande `pglift instance list` permet de lister les instances :

```shell
[postgres@srv-pg1 ~]$ pglift instance list
+--------------------------------------------------------+
| name | version | port | datadir              | status  |
+------+---------+------+----------------------+---------+
| main | 15      | 5432 | /pgdata/15/main/data | running |
+------+---------+------+----------------------+---------+
```

Pour faciliter la connexion à l'instance, ou même l'administration des composants
satellites qui lui sont associés, il est très utile de charger les variables
d'environnement de l'instance. La commande `pglift instance env main` permet de
les afficher :

\tiny
```shell
[postgres@srv-pg1 ~]$ pglift instance env main
PATH=/usr/pgsql-15/bin:/home/postgres/.local/bin:/home/postgres/bin:
>/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
PGBACKREST_CONFIG_PATH=/home/postgres/.local/share/pglift/etc/pgbackrest
PGBACKREST_STANZA=main
PGDATA=/pgdata/15/main/data
PGHOST=/var/run/postgresql
PGPASSFILE=/home/postgres/.pgpass
PGPORT=5432
PGUSER=postgres
PSQLRC=/pgdata/15/main/data/.psqlrc
PSQL_HISTORY=/pgdata/15/main/data/.psql_history
```
\normalsize

Exporter le résultat de cette commande permet de charger les variables
d'environnement de l'instance `main` sur la session courante.

```shell
[postgres@srv-pg1 ~]$ export $(pglift instance env main)
```

L'instance est alors accessible via `psql` sans option :

```shell
[postgres@srv-pg1 ~]$ psql
psql (15.5)
Type "help" for help.

[15/main] postgres@~=#
```

:::tip
Certaines commandes utilisées dans la suite de cet atelier nécessiteront que
l'environnement de l'instance `main` soit chargé dans la session.
:::

</div>

---

# Déploiement d'une instance (Ansible)

<div class="slide-content">
- Module `dalibo.pglift.instance`
</div>

<div class="notes">
L'instance peut également être déployée par _ansible_, via le module
`dalibo.pglift.instance`. Pour cela, les serveurs doivent être accessibles
depuis le poste local sur un compte utilisateur `sudoer`. Le compte utilisateur
`ansible` est utilisé à cet effet sur les machines du workshop.
</div>

---

## Inventaire

<div class="slide-content">
- Inventaire comprenant hôtes et groupes d'hôtes
</div>


<div class="notes">
Sur le poste local, faisant office de nœud de contrôle _ansible_, créer un répertoire
pour les ressources _ansible_ dans le `$HOME` de l'utilisateur.

```shell
[user@desktop1 ~]$ mkdir ~/ansible && cd ~/ansible
```

Déposer dans ce répertoire, un inventaire _ansible_ `~/ansible/inventory` comprenant
les serveurs du workshop :

```ini
!include include/ansible/inventory
```
</div>

---

## Collection

<div class="slide-content">
```shell
[user@desktop1 ~]$ ansible-galaxy collection install dalibo.pglift
```
</div>

<div class="notes">

Installer la collection `dalibo.pglift`, permettant de manipuler les opérations
de _pglift_ à travers _ansible_, avec `ansible-galaxy` :

```shell
[user@desktop1 ~]$ ansible-galaxy collection install dalibo.pglift
```
</div>

\newpage

---

## Playbook

<div class="slide-content">
```yaml
---
- hosts: "srv-pg1"
  become: "yes"
  become_user: "postgres"
  tasks:
    - name: Créer une instance
      dalibo.pglift.instance:
        name: "main"
        state: started
        version: 15
        port: 5432
        pgbackrest:
          stanza: main-app
        replrole_password: secret
        prometheus:
          port: 9187
```
</div>

<div class="notes">

Créer le _playbook_ `~/ansible/instance_main.yml` qui appelle le module
`dalibo.pglift.instance` dans une tâche à destination de `srv-pg1` :

```yaml
---
- hosts: "srv-pg1"
  become: "yes"
  become_user: "postgres"
  tasks:
    - name: Créer une instance
      dalibo.pglift.instance:
        name: "main"
        state: started
        version: 15
        port: 5432
        pgbackrest:
          stanza: main-app
        replrole_password: secret
        prometheus:
          port: 9187
```

Exécuter le _playbook_ sur l'inventaire établi :

```shell
ansible-playbook -u ansible instance_main.yml
```

</div>

---

# Gestion d'une instance

<div class="slide-content">
```shell
[postgres@srv-pg1 ~]$ pglift instance status main
[postgres@srv-pg1 ~]$ pglift instance stop main
[postgres@srv-pg1 ~]$ pglift instance start main
[postgres@srv-pg1 ~]$ pglift instance restart main
```
</div>

<div class="notes">

L'instance créée avec _pglift_ peut être gérée depuis l'interface de ligne de
commande :

```shell
[postgres@srv-pg1 ~]$ pglift instance status main
PostgreSQL: running

[postgres@srv-pg1 ~]$ pglift instance stop main
INFO     stopping PostgreSQL 15-main
[postgres@srv-pg1 ~]$ pglift instance status main
PostgreSQL: not running

[postgres@srv-pg1 ~]$ pglift instance start main
INFO     starting PostgreSQL 15-main
[postgres@srv-pg1 ~]$ pglift instance status main
PostgreSQL: running

[postgres@srv-pg1 ~]$ pglift instance restart main
INFO     restarting instance 15/main
[postgres@srv-pg1 ~]$ pglift instance status main
PostgreSQL: running
```

</div>

---

# Gestion des bases de données et rôles PostgreSQL

---

## Rôles

<div class="slide-content">
```shell
[postgres@srv-pg1 ~]$ pglift role create bob --password secret --login
[postgres@srv-pg1 ~]$ pglift role list
```
</div>

<div class="notes">

Créer un rôle dans l'instance :

```shell
[postgres@srv-pg1 ~]$ pglift role create bob --password secret --login
INFO     creating role 'user1'
```

Afficher la liste des rôles présents dans l'instance :

\scriptsize
```
[postgres@srv-pg1 ~]$ pglift role list
+----------+--------------+---------+-------+-----------+----------+------------+-------------+
| name     | has_password | inherit | login | superuser | createdb | createrole | replication |
+----------+--------------+---------+-------+-----------+----------+------------+-------------+
| backup   | False        | True    | True  | True      | False    | False      | False       |
| bob      | True         | True    | True  | False     | False    | False      | False       |
| postgres | False        | True    | True  | True      | True     | True       | True        |
+----------+--------------+---------+-------+-----------+----------+------------+-------------+
```
</div>

\normalsize

\newpage

---

## Bases de données

<div class="slide-content">
```shell
[postgres@srv-pg1 ~]$ pglift database create ws1
[postgres@srv-pg1 ~]$ pglift database create ws2 --owner bob --schema s1 --schema s2
[postgres@srv-pg1 ~]$ pglift database list
```
</div>

<div class="notes">
_pglift_ permet d'interagir avec les bases de données d'une instance. Il est ainsi
possible de créer, altérer, lister ou supprimer des bases de données depuis la
ligne de commande.

Créer une base de données `ws1` :

```shell
[postgres@srv-pg1 ~]$ pglift database create ws1
INFO     creating 'ws1' database in 15/main
```

Créer une base de données `ws2` dont `bob` est le propriétaire et contenant les schémas
`s1` et `s1` :

```shell
[postgres@srv-pg1 ~]$ pglift database create ws2 --owner bob --schema s1 --schema s2
INFO     creating 'ws2' database in 15/main
INFO     creating schema 's1' in database ws2
INFO     creating schema 's2' in database ws2
```

Lister les bases de données :

\tiny
```
[postgres@srv-pg1 ~]$ pglift database list
+-----------+----------+--------+-----+-------+-----------------------+--------+---------------------------+------------------+
| name      | owner    | encod. | col.| ctype | acls                  | size   | description               | tablespace       |
+-----------+----------+--------+-----+-------+-----------------------+--------+---------------------------+------------------+
│ postgres  │ postgres │ UTF8   │ C   │ C     │                       │ 7.6 MB │ default administrative    │ name: pg_default │
│           │          │        │     │       │                       │        │ connection database       │ location:        │
│           │          │        │     │       │                       │        │                           │ size: 37.9 MB    │
│ template1 │ postgres │ UTF8   │ C   │ C     │ =c/postgres,          │ 7.6 MB │ default template for new  │ name: pg_default │
│           │          │        │     │       │ postgres=CTc/postgres │        │ databases                 │ location:        │
│           │          │        │     │       │                       │        │                           │ size: 37.9 MB    │
│ ws1       │ postgres │ UTF8   │ C   │ C     │                       │ 7.5 MB │                           │ name: pg_default │
│           │          │        │     │       │                       │        │                           │ location:        │
│           │          │        │     │       │                       │        │                           │ size: 37.9 MB    │
│ ws2       │ bob      │ UTF8   │ C   │ C     │                       │ 7.7 MB │                           │ name: pg_default │
│           │          │        │     │       │                       │        │                           │ location:        │
| postgres  | postgres | UTF8   | C   | C     |                       | 7.6 MB | default administrative    | name: pg_default |
|           |          |        |     |       |                       |        | connection database       | location:        |
|           |          |        |     |       |                       |        |                           | size: 37.9 MB    |
| template1 | postgres | UTF8   | C   | C     | =c/postgres,          | 7.6 MB | default template for new  | name: pg_default |
|           |          |        |     |       | postgres=CTc/postgres |        | databases                 | location:        |
|           |          |        |     |       |                       |        |                           | size: 37.9 MB    |
| ws1       | postgres | UTF8   | C   | C     |                       | 7.5 MB |                           | name: pg_default |
|           |          |        |     |       |                       |        |                           | location:        |
|           |          |        |     |       |                       |        |                           | size: 37.9 MB    |
| ws2       | bob      | UTF8   | C   | C     |                       | 7.7 MB |                           | name: pg_default |
|           |          |        |     |       |                       |        |                           | location:        |
|           |          |        |     |       |                       |        |                           | size: 37.9 MB    |
+-----------+----------+--------+-----+-------+-----------------------+--------+---------------------------+------------------+
```
</div>
\normalsize

---

# Gestion des sauvegardes

---

## Sauvegardes Physiques (PITR)

<div class="slide-content">
- Sauvegarde PITR assurée par _pgBackRest_
- Dépôt de sauvegarde local ou distant
- Commande d'archivage des WAL configurée par _pglift_
</div>

<div class="notes">

Les instances déployées par _pglift_ ont une sauvegarde _pgBackRest_ configurée dès
leur création. Dans la configuration basique de ce premier atelier, la sauvegarde
est réalisée localement mais il est aussi possible d’interfacer _pglift_ avec un
serveur de sauvegarde centralisé, comme cela sera abordé dans un prochain workshop.

L'archivage des journaux de transactions, qui assurent le _recover_ des données à
un état cohérent à la suite d'une restauration, est automatiquement configuré
et actif dès l'initialisation de l'instance.
</div>

---

### Sauvegarde pgBackRest

<div class="slide-content">
```shell
[postgres@srv-pg1 ~]$ pglift instance backup main
[postgres@srv-pg1 ~]$ pglift instance backups
```
</div>

<div class="notes">

Effectuer une sauvegarde de l'instance `main` avec _pglift_.

```shell
[postgres@srv-pg1 ~]$ pglift instance backup main
```

Lister les sauvegardes présentes :

\scriptsize
```
[postgres@srv-pg1 ~]$ pglift instance backups
                        Available backups for instance 15/main
+------------------+---------+-----------+---------------------------+------+--------------------+
| label            | size    | repo_size | date_start                | type | databases          |
+------------------+---------+-----------+---------------------------+------+--------------------+
│ 20231110-230314F │ 38.0 MB │ 5.1 MB    │ 2023-11-10 23:03:14+00:00 │ full │ postgres, ws1, ws2 │
+------------------+---------+-----------+---------------------------+------+--------------------+
```
</div>

\normalsize

---

### Restauration pgBackRest

<div class="slide-content">
```shell
[postgres@srv-pg1 ~]$ pglift instance stop
[postgres@srv-pg1 ~]$ pglift instance restore
[postgres@srv-pg1 ~]$ pglift instance start main
```
</div>

<div class="notes">

Pour restaurer l'instance depuis la sauvegarde, l'arrêter :

```shell
[postgres@srv-pg1 ~]$ pglift instance stop
INFO     stopping PostgreSQL 15-main
```

Effectuer le restore avec _pglift_ :

```shell
[postgres@srv-pg1 ~]$ pglift instance restore
INFO     restoring instance 15/main with pgBackRest
```

Enfin, démarrer l'instance :

```shell
[postgres@srv-pg1 ~]$ pglift instance start main
INFO     starting PostgreSQL 15-main
```
</div>

---

## Sauvegardes Logiques

<div class="slide-content">
- Utilisation de `pg_dump` par défaut
```bash
[postgres@srv-pg1 ~]$ pglift database dump ws1
```
</div>

<div class="notes">
La sauvegarde logique est prise en charge par _pglift_ via la commande
`pglift database dump`. Celle-ci exécute l'export des données selon la
configuration de site qui est active. Par défaut, l'outil standard `pg_dump` est
utilisé :

Sauvegarder la base de données `ws1` :

```bash
[postgres@srv-pg1 ~]$ pglift database dump ws1
INFO     backing up database 'ws1' on instance 15/main

```

Vérifier la présence du _dump_ dans le répertoire de sauvegarde :

```bash
[postgres@srv-pg1 ~]$ ls -l /pgdata/backup/dumps/15-main/
total 8
-rw-rw-r--. 1 postgres postgres 794 Nov 20 11:18 ws1_2023-11-20T11:18:50+00:00.dump
```
</div>

---

## Restauration d'une base de données

<div class="slide-content">
```shell
[postgres@srv-pg1 ~]$ pglift database drop ws1
[postgres@srv-pg1 ~]$ pg_restore -d postgres --create --verbose \
/pgdata/backup/dumps/15-main/ws1_2023-11-20T11:18:50+00:00.dump
```
</div>

<div class="notes">
Supprimer la base de données `ws1` :

```shell
[postgres@srv-pg1 ~]$ pglift database drop ws1
INFO     dropping 'ws1' database
```

Restaurer le _dump_ exporté à l'étape précédente avec `pg_restore` :

```shell
[postgres@srv-pg1 ~]$ pg_restore -d postgres --create --verbose \
/pgdata/backup/dumps/15-main/ws1_2023-11-20T11:18:50+00:00.dump
pg_restore: connecting to database for restore
pg_restore: creating DATABASE "ws1"
pg_restore: connecting to new database "ws1"
```
</div>

---

# Supervision avec l'exporter prometheus-postgres-exporter

<div class="slide-content">
- Supervision assurée par l'exporter _postgres-exporter_
- Actif dès le déploiement de l'instance
```shell
curl http://localhost:9187/metrics | grep -v ^#
```
</div>

<div class="notes">

Les instances sont déployées avec l'exporter _prometheus_ du fait de son activation
dans la configuration de _pglift_. Par défaut, ce dernier fonctionne sur le port `9187`.

Il est possible d'afficher les métriques exportées via la commande  `curl` :

```shell
curl http://localhost:9187/metrics | grep -v ^#
```

L'exploitation de ces métriques de supervision sera abordé dans un autre
workshop.
</div>

---

# Nettoyage

<div class="slide-content">
```shell
[postgres@srv-pg1 ~]$ pglift instance drop
[postgres@srv-pg1 ~]$ pglift site-configure uninstall
```
</div>

<div class="notes">

Afin de poursuivre sur les workshops suivants sans conflit de port ou
de configuration, il est nécessaire de supprimer toute instance existante
et désinstaller la configuration de site de _pglift_.

Supprimer l'instance `main` sur `srv-pg1` :

```shell
[postgres@srv-pg1 ~]$ pglift instance drop
INFO     dropping instance 15/main
> Confirm complete deletion of instance 15/main? [y/n] (y): y
INFO     stopping PostgreSQL 15-main
INFO     stopping Prometheus postgres_exporter 15-main
INFO     deconfiguring Prometheus postgres_exporter 15-main
> Confirm deletion of 1 backup(s) for stanza main-app? [y/n] (n): y
INFO     deconfiguring pgBackRest
> Confirm deletion of database dump(s) for instance 15/main? [y/n] (y): y
INFO     deleting PostgreSQL cluster
```
Désinstaller la configuration de site de _pglift_ :

```shell
[postgres@srv-pg1 ~]$ pglift site-configure uninstall
INFO     removing pglift-postgres_exporter@.service systemd unit
         (/home/postgres/.local/share/systemd/user/pglift-postgres_exporter@.service)
INFO     removing pglift-backup@.service systemd unit (/home/postgres/.local/share/systemd/user/pglift-backup@.service)
INFO     removing pglift-backup@.timer systemd unit (/home/postgres/.local/share/systemd/user/pglift-backup@.timer)
INFO     removing pglift-postgresql@.service systemd unit (/home/postgres/.local/share/systemd/user/pglift-postgresql@.service)
INFO     deleting pgbackrest include directory
INFO     uninstalling base pgbackrest configuration
> Delete pgbackrest repository path /pgdata/backup/pgbackrest? [y/n] (n): y
INFO     deleting pgbackrest repository path
INFO     deleting common pgbackrest directories
INFO     deleting postgresql log directory
```
</div>
