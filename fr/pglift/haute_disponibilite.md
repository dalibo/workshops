---
subtitle : 'Workshop Utilisation de pglift Haute Disponibilité'
title : 'Déployer des instances en Haute Disponibilité avec pglift'
keywords:
- postgres
- postgresql
- workshop
- pglift
- ansible
- industrialisation
- haute-disponibilite
- patroni

linkcolor:

licence : PostgreSQL                                                            
author: Dalibo & Contributors                                                   
revision: 23.08
url : https://dalibo.com/formations

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

Ce module aborde le déploiement et l'administration d'instances PostgreSQL en
Haute Disponibilité avec _patroni_ depuis _pglift_.  

Il sera également évoqué l'installation des outils nécessaires, ainsi que la
supervision de _patroni_.

# Présentation de patroni

## Patroni

_Patroni_ est une solution de Haute Disponibilité pour PostgreSQL écrit en python,
utilisant un _DCS_ (Distributed Consensus Store).

Il va donc permettre de déployer des instances PostgreSQL en Haute Disponibilité et
gérer les bascules de manière automatiques à l'aide d'un _DCS_ (ici _etcd_).

## DCS (Distributed Consensus Store - etcd)

_etcd_ est un cluster de serveurs de configuration distribuée, sous forme de données
"clé-valeur".
Patroni repose sur un _DCS_ afin d'y stocker des paramètres et de les distribuer vers
l'ensemble des nœuds _patroni_.

Il va également permettre de stocker le statut des instances afin que _patroni_ puisse
effectuer une bascule en cas de nœuds défaillant.  

_etcd_ fonctionne également en Haute-Disponibilité en utilisant le protocole _Raft_
qui est implémenté dans celui-ci. Il est donc recommandé de disposer de 3 nœuds
_etcd_.

# Installation

## Pré-requis

- Certificats SSL (voir Annexe : Générer des certificats auto-signés)
- Un cluster _etcd_ (voir Annexe _etcd_)
- PostgreSQL, _pgBackRest_ et _pglift_ (consulter le _workshop Compréhension et utilisation de pglift_)
- La collection _Ansible_ `dalibo.pglift`

## Installation de patroni

L'installation de _patroni_ se fait avec un gestionnaire de paquet (ici `dnf`) depuis
le dépôt communautaire du PGDG (PostgreSQL Global Development Group).

Il est nécessaire d'installer deux paquets : `patroni` et `patroni-etcd`.
```bash
$ dnf install patroni patroni-etcd
```

## Configuration de pglift

Créer le fichier de configuration suivant dans `~/.config/pglift/settings.yaml` en
adaptant les addresses IP des serveurs _etcd_ et le nom des certificats.
```yaml
cli:
  logpath: '/pgdata/log/pglift'
postgresql:
  default_version: '15'
  datadir: '/pgdata/{version}/{name}/data'
  waldir: '/pgdata/{version}/{name}/pgwal'
  logpath: '/pgdata/log/postgresql'
  initdb:
    data_checksums: 'true'
  auth:
    local: 'peer'
    host: 'scram-sha-256'
  socket_directory: '/var/run/postgresql'
  backuprole:
    name: 'backup'
  replrole: 'replication'
  dumps_directory: '/pgdata/backup/dumps/{version}-{name}'
systemd:
  user: true
  sudo: false
  pgbackrest:
    repository:
      path: '/pgdata/backup/pgbackrest'
      mode: 'path'
patroni:
  execpath: /usr/bin/patroni
  configpath: /etc/patroni/{name}.yaml
  logpath: /pgdata/log/patroni
  etcd:
    hosts:
    - 192.168.60.21:2379
    - 192.168.60.22:2379
    - 192.168.60.23:2379
    protocol: https
    cacert: "/etc/ssl/ca-cert.pem"
    cert: "/etc/ssl/srv-pg1.pem"
    key: "/etc/ssl/srv-pg1.key"
  restapi:
    cafile: "/etc/ssl/ca-cert.pem"
    certfile: "/etc/ssl/srv-pg1.pem"
    keyfile: "/etc/ssl/srv-pg1.key"
    verify_client: required
  ctl:
    certfile: "/etc/ssl/srv-pg1.pem"
    keyfile: "/etc/ssl/srv-pg1.key"
  postgresql:      
    use_pg_rewind: true
    passfile: /home/postgres/{name}.pgpass
  watchdog:
    mode: required
    device: /dev/watchdog
    safety_margin: 5
```

Créer un fichier template `pg_hba.conf` dans `~/.config/pglift/postgresql/pg_hba.conf` :
```ini
local all {surole} {auth.local}
local all all {auth.host}
host  all all ::1/128 {auth.host}
local replication {replrole} {auth.host}
host replication {replrole} 127.0.0.1/32 {auth.host}
host replication {replrole} ::1/128 {auth.host}
host replication {replrole} 0.0.0.0/0 {auth.host}
```

Installer la configuration de site `pglift` : 
```bash
$ pglift site-configure install
```

# Déploiement d'instances en Haute Disponibilité avec pglift

Deux méthodes de déploiement sont utilisables, via la ligne de commande ou alors
avec un _playbook Ansible_.

Dans les exemples ci-dessous, l'utilisateur système `postgres` est utilisé.

## CLI

Depuis le serveur primaire :
```bash
$ pglift instance create main --pgbackrest-stanza=main \
         --patroni-cluster maincluster \
         --patroni-node srv-pg1 \
         --patroni-restapi-connect-address "<IP-Machine>:8008" \
         --patroni-restapi-listen "<IP-Machine>:8008" \
         --patroni-postgresql-connect-host <IP-Machine>
```

Depuis le serveur secondaire :
```bash
$ pglift instance create main --pgbackrest-stanza=main \
         --patroni-cluster maincluster \
         --patroni-node srv-pg2 \
         --patroni-restapi-connect-address "<IP-Machine>:8008" \
         --patroni-restapi-listen "<IP-Machine>:8008" \
         --patroni-postgresql-connect-host <IP-Machine>
```

Vérifier l'état du cluster :
```bash
$ patronictl -c /etc/patroni/15-main.yaml list
```

## Ansible

Créer un répertoire `ansible` :
```bash
$ mkdir ~/ansible
```
Le répertoire est créé dans le répertoire HOME de l'utilisateur.


Créer un fichier d'inventaire (`~/ansible/inventory`):
```ini
srv-pg1 ansible_host=<IP-Machine srv-pg1>
srv-pg2 ansible_host=<IP-Machine srv-pg2>

[primary]
srv-pg1

[replica]
srv-pg2
```

Tester la connexion aux machines avec _Ansible_ :
```bash
$ ansible -m ping -i ~/ansible/inventory all
```

Créer un _playbook Ansible_ (`~/ansible/playbook.yml`):
```yaml
- hosts: primary
  gather_facts: yes
  become_user: "postgres"
  become: "yes"

  - name: "Déployer l'instance primaire"
    dalibo.pglift.instance:
      name: main
      state: started
      version: 15
      port: 5432
      surole_password: Passw0rd
      replrole_password: Passw0rd
      pgbackrest:
        password: Passw0rd
        stanza: main-stz
      patroni:
        cluster: maincluster
        node: srv-pg1
        restapi:
          connect_address: "<IP-Machine>:8008"
          listen: "<IP-Machine>:8008"
        postgresql:
          connect_host: <IP-Machine>

- hosts: replica
  gather_facts: yes
  become_user: "postgres"
  become: "yes"

  - name: "Déployer l'instance secondaire"
    dalibo.pglift.instance:
      name: main
      state: started
      version: 15
      port: 5432
      surole_password: Passw0rd
      replrole_password: Passw0rd
      pgbackrest:
        password: Passw0rd
        stanza: main-stz
      patroni:
        cluster: maincluster
        node: srv-pg1
        restapi:
          connect_address: "<IP-Machine>:8008"
          listen: "<IP-Machine>:8008"
        postgresql:
          connect_host: <IP-Machine>
```

Exécuter le _playbook_ précédemment créé pour le déploiement des instances en
Haute-Disponibilité :
```bash
$ ansible-playbook ~/ansible/playbook.yml -i ~/ansible/inventory
```

Se connecter à un serveur et vérifier l'état du cluster (en tant qu'utilisateur
système `postgres`):
```bash
$ patronictl -c /etc/patroni/15-main.yaml list
```

# Administration du cluster de Haute Disponibilité

## Gestion de la configuration du cluster

### Avec Patroni

La configuration modifiée avec _patroni_ est appliquée à l'ensemble du cluster.
Il est possible de changer la configuration _patroni_ ainsi que la configuration
PostgreSQL.

```bash
$ patronictl edit-config maincluster
```

### Configuration de la réplication synchrone

Pour utiliser la réplication synchrone, il est conseillé de configurer _patroni_ pour
qu'il se charge de la configuration selon la topologie du cluster.

Placer la variable de configuration `synchronous_mode` à `true`, en exécutant:
```bash
$ patronictl edit-config maincluster
```

Puis ajouter, dans liste des paramètres du cluster :
```ini
synchronous_mode: true
```

Vérifier que le nœud secondaire est bien synchrone:
```bash
$ patronictl -c /etc/patroni/15-main.yaml list
```

### Avec `pglift`

La configuration modifiée avec _pglift_ est appliquée uniquement à l'instance du nœud
PostgreSQL.
```bash
$ pglift pgconf -i main edit
```

## Statut du cluster

Il est possible d'afficher la topologie du cluster avec la commande `patronictl list` :
```bash
$ patronictl -c /etc/patroni/15-main.yaml list
```

- La valeur `Leader` dans la colonne rôle indique l'instance primaire.
- La valeur `Sync standby` dans la colonne rôle indique l'instance secondaire synchrone si le mode synchrone de _patroni_ est actif.
- La colonne `State` donne l'état du nœud.
- La colonne `TL` indique la timeline des journaux de transactions de l'instance. En fonctionnement nominal, elle doit être identique sur tous les nœuds.
- La colonne `Lag` donne le retard de réplication du nœud par rapport à son instance source (l'instance primaire).

## Switchover

Pour effectuer un _switchover_ immédiat et de force, depuis n'importe quel nœud du cluster, avec la commande `patronictl` :

```bash
$ patronictl -c /etc/patroni/15-main.yaml switchover maincluster
```

## Failover

Pour simuler une panne, le processus `patroni` va être stoppé avec la commande
`pkill -9` sur le serveur primaire :
```bash
$ pkill -9 patroni
```

Depuis le serveur secondaire, vérifier l'état du cluster :
```bash
$ patronictl -c /etc/patroni/15-main.yaml list
```
Il est possible alors de voir que le serveur secondaire est promu `Leader` et ouvert
aux écritures.

Le _watchdog_ étant configuré, le serveur primaire redémarre après avoir utilisé
la commande `pkill` et _patroni_ se charge de reconstruire le primaire en serveur
secondaire.

## Supervision de patroni

_patroni_ expose à travers son _API_ des métriques avec deux _endpoints_ :

- `/patroni` expose les métriques au format _JSON_
- `/metrics` expose les métriques au format exploitable par _Prometheus_.

Dans un premier temps, il est possible de visualiser ces métriques à l'aide de `curl`:
```bash
$ curl --cacert ca-cert.pem https://<IP-srv-pg1>:8008/metrics
```

Pour visualiser les métriques dans _Prometheus_, il est nécessaire d'ajouter la
configuration suivante pour _Prometheus_ sous `scrape_configs`:
```yaml
  - job_name: "patroni"

    static_configs:
      - targets:
        - <IP-srv-pg1>:8008
        - <IP-srv-pg2>:8008
```

:::tip Pour installer Prometheus, voir le _workshop Supervision des instances PostgreSQL avec Prometheus postgres_exporter_ :::


Après application de la configuration, redémarrer le service `prometheus.service` :
```bash
systemctl restart prometheus.service
```

## Restauration d'une sauvegarde physique

Effectuer une sauvegarde physique avec _pglift_ sur le serveur primaire:
```bash
$ pglift instance backup main
```

Stopper Patroni sur tout les noeuds.

- srv-pg2:
```bash
$ pglift instance stop main
```

- srv-pg1:
```bash
$ pglift instance stop main
```

Restaurer l'instance primaire:
```bash
$ pglift instance restore main
```

Démarrer _patroni_ sur l'instance primaire :
```bash
$ pglift instance start main
```

Vérifier l'état du cluster, _patroni_ va sûrement refuser de promouvoir l'instance
car la restauration _PITR_ l'a fait retourner dans le passé sur une _timeline_ différente :
```bash
$ patronictl -c /etc/patroni/15-main.yaml list
```

Lancer un _failover_ manuel pour promouvoir le nœud :
```bash
$ patronictl -c /etc/patroni/15-main.yaml failover
```

Lorsque l'instance primaire restaurée est `Leader`, démarrer le nœud
secondaire et lancer une reconstruction :
```bash
$ pglift instance start main
$ patronictl -c /etc/patroni/15-main.yaml reinit maincluster srv-pg2
```

# Annexe : Générer des certificats auto-signés

```bash
mkdir ~/ssl
cd ~/ssl
IP_srv-pg1=
IP_srv-pg2=
IP_srv-etcd1=
IP_srv-etcd2=
IP_srv-etcd3=
openssl req -x509 -out srv-pg1.pem -days 365 \
        -newkey rsa:2048 -nodes -keyout srv-pg1.key \
        -subj "/C=XX/ST= /L=Default/O=Default/OU= /CN=srv-pg1.lan" \
				-addext "subjectAltName=IP:127.0.0.1,IP:$IP_srv-pg1,DNS:srv-pg1.lan" \
        -addext "extendedKeyUsage=serverAuth,clientAuth"
openssl req -x509 -out srv-pg2.pem -days 365 \
        -newkey rsa:2048 -nodes -keyout srv-pg2.key \
        -subj "/C=XX/ST= /L=Default/O=Default/OU= /CN=srv-pg2.lan" \
				-addext "subjectAltName=IP:127.0.0.1,IP:$IP_srv-pg2,DNS:srv-pg2.lan" \
        -addext "extendedKeyUsage=serverAuth,clientAuth"
openssl req -x509 -out srv-etcd1.pem -days 365 \
        -newkey rsa:2048 -nodes -keyout srv-etcd1.key \
        -subj "/C=XX/ST= /L=Default/O=Default/OU= /CN=srv-etcd1.lan" \
				-addext "subjectAltName=IP:127.0.0.1,IP:$IP_srv-etcd1,DNS:srv-etcd1.lan" \
        -addext "extendedKeyUsage=serverAuth,clientAuth"
openssl req -x509 -out srv-etcd2.pem -days 365 \
        -newkey rsa:2048 -nodes -keyout srv-etcd2.key \
        -subj "/C=XX/ST= /L=Default/O=Default/OU= /CN=srv-etcd2.lan" \
				-addext "subjectAltName=IP:127.0.0.1,IP:$IP_srv-etcd2,DNS:srv-etcd2.lan" \
        -addext "extendedKeyUsage=serverAuth,clientAuth"
openssl req -x509 -out srv-etcd3.pem -days 365 \
        -newkey rsa:2048 -nodes -keyout srv-etcd3.key \
        -subj "/C=XX/ST= /L=Default/O=Default/OU= /CN=srv-etcd3.lan" \
				-addext "subjectAltName=IP:127.0.0.1,IP:$IP_srv-etcd3,DNS:srv-etcd3.lan" \
        -addext "extendedKeyUsage=serverAuth,clientAuth"
cat *.pem > ca-cert.pem
```

Copier les certificats sur l'ensemble des serveurs avec `rsync`:
```bash
$ rsync -avz ~/ssl <IP>:/etc/ssl/
```

# Annexe `etcd`

## Pré-requis

Installer le dépôt PGDG :
```bash
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/\
pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf config-manager --set-enabled pgdg-extra
```

## Installation `etcd`

Sur chacun des nœuds, installer le paquet `etcd` :
```bash
$ dnf install -y etcd
```

## Configuration

Sur chacun des nœuds, éditer le fichier `/etc/default/etcd`.

Sur le nœud 1 :
```ini
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://127.0.0.1:2380,https://<srv-etcd1-ip>:2380"
ETCD_LISTEN_CLIENT_URLS="https://127.0.0.1:2379,https://<srv-etcd1-ip>:2379"
ETCD_NAME="<srv-etcd1-name>"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://<srv-etcd1-ip>:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://<srv-etcd1-ip>:2379"
ETCD_INITIAL_CLUSTER="<srv-etcd1-name>=https://<srv-etcd1-ip>:2380,
<srv-etcd2-name>=https://<srv-etcd2-ip>:2380,<srv-etcd3-name>=https://<srv-etcd3-ip>:2380"
ETCD_INITIAL_CLUSTER_TOKEN="<cluster-token>"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_CERT_FILE="/etc/ssl/srv-etcd1.pem"
ETCD_KEY_FILE="/etc/ssl/srv-etcd1.key"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/ssl/ca-cert.pem"
ETCD_PEER_CERT_FILE="/etc/ssl/srv-etcd1.pem"
ETCD_PEER_KEY_FILE="/etc/ssl/srv-etcd1.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/etc/ssl/ca-cert.pem"
```

Sur le nœud 2 :
```ini
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://127.0.0.1:2380,https://<srv-etcd2-ip>:2380"
ETCD_LISTEN_CLIENT_URLS="https://127.0.0.1:2379,https://<srv-etcd2-ip>:2379"
ETCD_NAME="<srv-etcd2-name>"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://<srv-etcd2-ip>:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://<srv-etcd2-ip>:2379"
ETCD_INITIAL_CLUSTER="<srv-etcd1-name>=https://<srv-etcd1-ip>:2380,
<srv-etcd2-name>=https://<srv-etcd2-ip>:2380,<srv-etcd3-name>=https://<srv-etcd3-ip>:2380"
ETCD_INITIAL_CLUSTER_TOKEN="<cluster-token>"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_CERT_FILE="/etc/ssl/srv-etcd2.pem"
ETCD_KEY_FILE="/etc/ssl/srv-etcd2.key"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/ssl/ca-cert.pem"
ETCD_PEER_CERT_FILE="/etc/ssl/srv-etcd2.pem"
ETCD_PEER_KEY_FILE="/etc/ssl/srv-etcd2.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/etc/ssl/ca-cert.pem"
```

Sur le nœud 3 :
```ini
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://127.0.0.1:2380,https://<srv-etcd3-ip>:2380"
ETCD_LISTEN_CLIENT_URLS="https://127.0.0.1:2379,https://<srv-etcd3-ip>:2379"
ETCD_NAME="<srv-etcd3-name>"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://<srv-etcd3-ip>:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://<srv-etcd3-ip>:2379"
ETCD_INITIAL_CLUSTER="<srv-etcd1-name>=https://<srv-etcd1-ip>:2380,
<srv-etcd2-name>=https://<srv-etcd2-ip>:2380,<srv-etcd3-name>=https://<srv-etcd3-ip>:2380"
ETCD_INITIAL_CLUSTER_TOKEN="<cluster-token>"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_CERT_FILE="/etc/ssl/srv-etcd3.pem"
ETCD_KEY_FILE="/etc/ssl/srv-etcd3.key"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/ssl/ca-cert.pem"
ETCD_PEER_CERT_FILE="/etc/ssl/srv-etcd3.pem"
ETCD_PEER_KEY_FILE="/etc/ssl/srv-etcd3.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/etc/ssl/ca-cert.pem"
```

## Gestion du service

Démarrage et activation du service, à exécuter sur tous les nœuds :
```bash
$ systemctl start etcd
$ systemctl enable etcd
```

A ce niveau, le _cluster etcd_ est fonctionnel.
