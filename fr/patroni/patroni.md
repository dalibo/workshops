---
subtitle : 'Workshop Patroni'
title : 'Haute disponibilité avec Patroni'
keywords:
- postgres
- postgresql
- workshop
- patroni
- etcd
- ha
- haute disponibilité

linkcolor:

licence : PostgreSQL                                                            
author: Dalibo & Contributors
date: février 2023                                                  
revision: 19.02
url : http://dalibo.com/formations

#
# PDF Options
#

toc: false

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

# Haute disponibilité de service avec Patroni


![PostgreSQL](medias/etcd-patroni.png)

<div class="notes">


</div>

---

## Introduction

<div class="slide-content">

  * Principes
  * Mise en place
  * Installation et configuration des services
  * Construction d'un agrégat à bascule automatique
  * Création d'incidents
</div>

<div class="notes">

</div>

---


## Principes

<div class="slide-content">

  * Arbitrage par un quorum : _DCS_ Etcd
  * Service PostgreSQL : désactivé
  * Contrôle complet par Patroni

</div>

<div class="notes">


</div>

---

### DCS : Etcd

<div class="slide-content">

  * Arbitre en cas de bascules
  * Stockage distribué de la configuration
  * Jeton _leader_ (Etcd)
  * Instance primaire PostgreSQL

</div>

<div class="notes">

Pour arbitrer les bascules automatiques, confirmer le primaire PostgreSQL ou distribuer la configuration, Patroni utilise un _DCS_ (_distributed configuration system_).

Pour ce rôle, nous utiliserons Etcd.

</div>

---



## Mise en place de l'infrastructure

<div class="slide-content">

  * Connexion à la VM
  * Récupération du _playbook_ _Ansible_

</div>

<div class="notes">

Vous disposez d'une machine virtuelle dédiée dans laquelle nous construirons 7 conteneurs _lxc_ :

  * 3 Etcd
  * 3 Patroni
  * 1 backup optionnel : (sauvegardes, archivage)

</div>

---

### Connexion à votre machine virtuelle

<div class="slide-content">

un seul point d'entrée : `eformation.dalibo.com`
un port attribué : 22XX

```Bash
  $ ssh -p 22XX dalibo@eformation.dalibo.com
```

</div>


<div class="notes">

Exemple de configuration pour une connexion simplifiée :

```console

# .ssh/config

Host vm38
Hostname eformation.dalibo.com
User dalibo
port 2238

```

```Bash
 $ ssh vm38
```
```console
Last login: Wed Nov 10 13:23:26 2021 from 78.213.160.12
dalibo@vm38:~$ 
```

</div>

---

### Playbook Ansible

<div class="slide-content">

  Récupération du _playbook_ _Ansible_ à cette adresse :


<https://github.com/dalibo/workshops/tree/ws15_patroni/fr/patroni/playbook/etcd-patroni>


| Fichier     | Description     |
| :------------- | :------------- |
| inventory.yml      | inventaire des machines    |
| **setup.yml**       | **_playbook_ principal**    |
| exchange_ssh_keys.yml | échange des clefs ssh |
|        |     |
| demarre_tout.sh      | démarre tous les conteneurs    |
| stoppe_tout.sh      | arrête tous les conteneurs    |
| teardown.yml       | _playbook_ de destruction massive    |

</div>

<div class="notes">

Quatre fichiers Yaml, deux scripts shell.


</div>

---

<div class="slide-content">

L'infrastructure complète peut être créée à l'aide des commandes :

```Bash
 $ sudo apt install -y ansible
 $ sudo ansible-playbook -f 7 -i inventory.yml setup.yml
...
```

Cette opération peut durer jusqu'à une vingtaine de minutes.

</div>


<div class="notes">

Vous pouvez suivre l'évolution de la création des conteneurs dans un autre terminal :

```Bash
 $ watch -n 1 -d sudo lxc-ls -f
```

```console
 $ sudo lxc-ls -f
 NAME   STATE   AUTOSTART GROUPS IPV4 IPV6 UNPRIVILEGED 
 backup STOPPED 0         -      -    -    false        
 e1     STOPPED 0         -      -    -    false        
 e2     STOPPED 0         -      -    -    false        
 e3     STOPPED 0         -      -    -    false        
 pg-1   STOPPED 0         -      -    -    false        
 pg-2   STOPPED 0         -      -    -    false        
 pg-3   STOPPED 0         -      -    -    false
```

L'état final de chaque conteneur étant *RUNNING* avec une adresse *IPV4* attribuée :

```console
 $ sudo lxc-ls -f
 NAME   STATE   AUTOSTART GROUPS IPV4       IPV6 UNPRIVILEGED
 backup RUNNING 0         -      10.0.3.204 -    false
 e1     RUNNING 0         -      10.0.3.101 -    false
 e2     RUNNING 0         -      10.0.3.102 -    false
 e3     RUNNING 0         -      10.0.3.103 -    false
 pg-1   RUNNING 0         -      10.0.3.201 -    false
 pg-2   RUNNING 0         -      10.0.3.202 -    false
 pg-3   RUNNING 0         -      10.0.3.203 -    false

```

Sur toutes les machines, y compris l'hôte, le fichier `/etc/hosts` est automatiquement renseigné par le _playbook_ et devrait contenir au moins :

```ini
10.0.3.101 e1
10.0.3.102 e2
10.0.3.103 e3
10.0.3.201 pg-1
10.0.3.202 pg-2
10.0.3.203 pg-3
10.0.3.204 backup 
```

</div>

---

\newpage 


### Installation d'Etcd

<div class="slide-content">

  * Installation des paquets
  * Configuration
  * Démarrage du service
  * Vérification
  
</div>

<div class="notes">


</div>

---

#### **Installation des paquets**

<div class="slide-content">

  * Paquets essentiels :
    * etcd
    * curl
    * jq
    * iputils-ping

</div>

<div class="notes">



```Bash
 $ for node in e1 e2 e3; do 
 sudo ssh $node sudo apt-get install -qqy etcd curl iputils-ping jq
 done
```

Le démarrage du service est automatique sous Debian.

```Bash
 $ for node in e1 e2 e3; do
 sudo ssh $node  "systemctl status etcd | grep -i active"
 done
 
```

```console 
   Active: active (running) since Wed 2021-11-10 17:48:26 UTC; 3min 28s ago
   Active: active (running) since Wed 2021-11-10 17:48:36 UTC; 3min 18s ago
   Active: active (running) since Wed 2021-11-10 17:48:46 UTC; 3min 8s ago
```

**Vérification de l'état des nœuds**

```Bash
$ for node in e1 e2 e3; do  
sudo ssh $node etcdctl member list
done
```

```console
8e9e05c52164694d: name=e1 peerURLs=http://localhost:2380 
clientURLs=http://localhost:2379 isLeader=true
8e9e05c52164694d: name=e2 peerURLs=http://localhost:2380 
clientURLs=http://localhost:2379 isLeader=true
8e9e05c52164694d: name=e3 peerURLs=http://localhost:2380 
clientURLs=http://localhost:2379 isLeader=true
```

Les nœuds sont tous des _leaders_ indépendants, ce qui ne nous intéresse pas. 
Il faut donc les configurer pour qu'ils fonctionnent en collaboration.

Nous arrêtons donc les services :

```Bash
 $ for node in e1 e2 e3; do
sudo ssh $node "systemctl stop etcd && systemctl status etcd | grep -i active"
done
```
```console
 Active: inactive (dead) since Wed 2021-11-10 17:59:35 UTC; 2min 46s ago
 Active: inactive (dead) since Wed 2021-11-10 17:59:35 UTC; 2min 46s ago
 Active: inactive (dead) since Wed 2021-11-10 17:59:35 UTC; 2min 46s ago
```

</div>

---

#### **Configuration du service Etcd**

<div class="slide-content">

  * Fichier : `/etc/default/etcd`

</div>

<div class="notes">


La configuration du service Etcd se trouve dans le fichier `/etc/default/etcd`, 
elle doit décrire notre agrégat sur chaque nœud :

<!-- **Attention aux espaces insécables dans la chaîne ETCD_INITIAL_CLUSTER -->

<div class="box warning">

> Attention aux caractères invisibles ou aux sauts de ligne 
</div>

**Sur le nœud e1 :**

```sh
ETCD_NAME='e1'

ETCD_DATA_DIR='/var/lib/etcd/default'

ETCD_LISTEN_PEER_URLS='http://127.0.0.1:2380,http://10.0.3.101:2380'
ETCD_LISTEN_CLIENT_URLS='http://127.0.0.1:2379,http://10.0.3.101:2379'
ETCD_INITIAL_ADVERTISE_PEER_URLS='http://10.0.3.101:2380'

ETCD_INITIAL_CLUSTER_STATE='new'
ETCD_INITIAL_CLUSTER_TOKEN='etcd-cluster'

ETCD_INITIAL_CLUSTER='e1=http://10.0.3.101:2380,e2=http://10.0.3.102:2380,e3=http://10.0.3.103:2380'

ETCD_ADVERTISE_CLIENT_URLS='http://10.0.3.101:2379'

ETCD_ENABLE_V2=true
```

**Sur le nœud e2 :**


```sh
ETCD_NAME='e2'

ETCD_DATA_DIR='/var/lib/etcd/default'

ETCD_LISTEN_PEER_URLS='http://127.0.0.1:2380,http://10.0.3.102:2380'
ETCD_LISTEN_CLIENT_URLS='http://127.0.0.1:2379,http://10.0.3.102:2379'
ETCD_INITIAL_ADVERTISE_PEER_URLS='http://10.0.3.102:2380'

ETCD_INITIAL_CLUSTER_STATE='new'
ETCD_INITIAL_CLUSTER_TOKEN='etcd-cluster'

ETCD_INITIAL_CLUSTER='e1=http://10.0.3.101:2380,e2=http://10.0.3.102:2380,e3=http://10.0.3.103:2380'

ETCD_ADVERTISE_CLIENT_URLS='http://10.0.3.102:2379'

ETCD_ENABLE_V2=true
```

**Sur le nœud e3 :**

```sh
ETCD_NAME='e3'

ETCD_DATA_DIR='/var/lib/etcd/default'

ETCD_LISTEN_PEER_URLS='http://127.0.0.1:2380,http://10.0.3.103:2380'
ETCD_LISTEN_CLIENT_URLS='http://127.0.0.1:2379,http://10.0.3.103:2379'
ETCD_INITIAL_ADVERTISE_PEER_URLS='http://10.0.3.103:2380'

ETCD_INITIAL_CLUSTER_STATE='new'
ETCD_INITIAL_CLUSTER_TOKEN='etcd-cluster'

ETCD_INITIAL_CLUSTER='e1=http://10.0.3.101:2380,e2=http://10.0.3.102:2380,e3=http://10.0.3.103:2380'

ETCD_ADVERTISE_CLIENT_URLS='http://10.0.3.103:2379'

ETCD_ENABLE_V2=true
```

</div>

---

#### **Démarrage du service**

<div class="slide-content">

  * Réinitialisation des bases Etcd
  * Démarrage du service `etcd` : `systemctl  start etcd`

</div>

<div class="notes">


Avant de démarrer le service sur chaque nœud, il faut réinitialiser les répertoires de données des nœuds, afin qu'ils reparte sur un répertoire neuf.

Le nœud `e1`, que nous considérons comme premier _leader_ sera démarré en premier mais il est possible qu'un autre nœud prenne le dessus s'il arrive à 
démarrer plus vite :

```Bash
 $ for node in e1 e2 e3; do 
 echo "$node :" ; sudo ssh $node "rm -rf ~etcd/default/*"
 done
```


```Bash
 $ for node in e1 e2 e3; do 
 sudo ssh $node "systemctl start etcd" &
 sleep 1
 done
```

En cas d'échec de démarrage, utilisez la commande _Systemd_ pour en diagnostiquer la cause :

```Bash
 e1:~$ sudo journalctl -xfu etcd
```

**Vérification :**

```Bash
 $ for node in e1 e2 e3; do 
 echo "sur $node :" 
 sudo ssh $node "etcdctl member list"
done
```

```console
sur e1 :
736293150f1cffb7: name=e1 peerURLs=http://10.0.3.101:2380 
clientURLs=http://10.0.3.101:2379,http://10.0.3.102:2379,http://10.0.3.103:2379 isLeader=true
7ef9d5bb55cefbcc: name=e3 peerURLs=http://10.0.3.103:2380 
clientURLs=http://10.0.3.101:2379,http://10.0.3.102:2379,http://10.0.3.103:2379 isLeader=false
97463691c7858a7b: name=e2 peerURLs=http://10.0.3.102:2380
clientURLs=http://10.0.3.101:2379,http://10.0.3.102:2379,http://10.0.3.103:2379 isLeader=false
sur e2 :
736293150f1cffb7: name=e1 peerURLs=http://10.0.3.101:2380
clientURLs=http://10.0.3.101:2379,http://10.0.3.102:2379,http://10.0.3.103:2379 isLeader=true
7ef9d5bb55cefbcc: name=e3 peerURLs=http://10.0.3.103:2380 
clientURLs=http://10.0.3.101:2379,http://10.0.3.102:2379,http://10.0.3.103:2379 isLeader=false
97463691c7858a7b: name=e2 peerURLs=http://10.0.3.102:2380 
clientURLs=http://10.0.3.101:2379,http://10.0.3.102:2379,http://10.0.3.103:2379 isLeader=false
sur e3 :
736293150f1cffb7: name=e1 peerURLs=http://10.0.3.101:2380 
clientURLs=http://10.0.3.101:2379,http://10.0.3.102:2379,http://10.0.3.103:2379 isLeader=true
7ef9d5bb55cefbcc: name=e3 peerURLs=http://10.0.3.103:2380 
clientURLs=http://10.0.3.101:2379,http://10.0.3.102:2379,http://10.0.3.103:2379 isLeader=false
97463691c7858a7b: name=e2 peerURLs=http://10.0.3.102:2380 
clientURLs=http://10.0.3.101:2379,http://10.0.3.102:2379,http://10.0.3.103:2379 isLeader=false
```

</div>

> Le _leader_ doit être identique sur les trois nœuds, 
> les trois nœuds doivent retourner la même liste de membres.

---

### Installation de PostgreSQL / Patroni

<div class="slide-content">

  * Installation 
    * PostgreSQL
    * Patroni
    * pgBackrest
  
</div>

<div class="notes">

Le dépôt _pgdg_ est déjà préconfiguré dans les conteneurs pg-1, pg-2 et pg-3, l'installation est donc triviale :

```Bash
 $ for node in pg-1 pg-2 pg-3; do
sudo ssh $node "apt-get update && apt-get install -qqy postgresql patroni pgbackrest" &
done
```


**Vérification :**

```Bash
 $ for node in pg-1 pg-2 pg-3; do sudo ssh $node "dpkg -l postgresql patroni 
pgbackrest | grep ^ii | cut -d ' ' -f 1,3"; done
ii patroni
ii pgbackrest
ii postgresql
ii patroni
ii pgbackrest
ii postgresql
ii patroni
ii pgbackrest
ii postgresql
```

Le service PostgreSQL doit être désactivé car la gestion totale de l'instance sera déléguée à Patroni :

```Bash
$ for node in pg-1 pg-2 pg-3; do 
sudo ssh $node "systemctl disable --now postgresql@15-main"
done
```

</div>

---

#### **Configuration de Patroni**

<div class="slide-content">

Sur tous les nœuds PostgreSQL/Patroni

  * Configuration du DCS
    * `/etc/patroni/dcs.yml`
  * Génération de la configuration
    * `pg_createconfig_patroni 15 main`


</div>

<div class="notes">

La configuration sous Debian se fait d'abord en renseignant comment contacter le DCS, puis en lançant le script de génération automatique de la configuration de Patroni.

Le port par défaut du service Etcd est le `2379`.


```Bash
$ sudo ssh pg-1
root@pg-1:~# vim /etc/patroni/dcs.yml
```

```yaml
# /etc/patroni/dcs.yml
etcd:
  hosts: 
  - 10.0.3.101:2379
  - 10.0.3.102:2379
  - 10.0.3.103:2379
```

```Bash
 root@pg-1:~# pg_createconfig_patroni 15 main"
```

La configuration `/etc/patroni/15-main.yml` est générée.

</div>

Ces opérations doivent être répétées sur tous les nœuds PostgreSQL/Patroni.

---

#### **Création de l'agrégat**

<div class="slide-content">

  * Démarrage du primaire
  * Création de l'utilisateur de réplication
  * Suppression des instances secondaires
  * Démarrage des instances secondaires

</div>

<div class="notes">

##### **Démarrage du primaire**


La création de l'agrégat commence par la mise en route du primaire sur le nœud `pg-1`, c'est lui qui sera la référence pour les secondaires.

```Bash
root@pg-1:~# systemctl enable --now patroni@15-main
```

L'instance doit être promue pour pouvoir être accessible écriture :

```Bash
root@pg-1:~# sudo -iu postgres psql -c 'select pg_promote();'' 
```

**L'utilisateur permettant la mise en réplication doit être créé sur ce nœud, avec le mot de passe renseigné dans la configuration de Patroni :**

```Bash
root@pg-1:~# sudo -iu postgres psql -c "create user replicator replication password 'rep-pass';" 
```


##### **Superuser d'administration locale**

Chaque nœud doit pouvoir récupérer la _timeline_ et le _LSN_ courants

```Bash
root@pg-1:~# sudo -iu postgres psql -c "create user dba superuser password 'admin'" 
```

Si l'utilisateur est différent de `postgres`, il faudra désactiver le socket unix 
sinon Patroni essaiera la connexion locale authentifiée par la méthode `peer`.
L'utilisateur `dba` n'existant pas au niveau système, il y aurait échec.


La configuration de chaque nœud doit être modifiée :


```yaml
#/etc/patroni/15-main.yaml

postgresql:

    #...

 use_unix_socket: false

 #...

    superuser:
      username: "dba"
      password: "admin"
      #...

```


##### Suppression des instances secondaires

Les instances secondaires ont été initialisées lors de l'installation du paquet Debian, 
il faut donc vider leur répertoire de données car Patroni refusera d'écraser des 
données existantes. Nous utilisons le _wrapper_ Debian :


`pg-1` étant notre primaire :

```Bash
 $ for node in pg-2 pg-3; do sudo ssh  $node "pg_dropcluster 15 main"; done
```

Les secondaires seront recréés automatiquement par Patroni, depuis le primaire 
par réplication.


Le primaire doit être redémarré : 

```Bash
postgres@pg-1:~ $ patronictl restart 15-main pg-1 --force
```

les nœuds secondaires doivent être démarrés :

```Bash
$ for node in pg-2 pg-3; do sudo ssh $node "systemctl start patroni@15-main"; done
```



La vérification se fait dans les traces de Patroni des nœuds secondaires :
\small
```
Feb 09 17:12:38 pg-3 patroni@15-main[1029]: 2023-02-09 17:12:38,984 INFO: Lock owner: pg-1; I am pg-3
Feb 09 17:12:38 pg-3 patroni@15-main[1029]: 2023-02-09 17:12:38,986 INFO: Local timeline=7 lsn=0/5000148
Feb 09 17:12:39 pg-3 patroni@15-main[1029]: 2023-02-09 17:12:39,037 INFO: master_timeline=7

```
\normalsize



</div>

---

##### **Vérifications**

<div class="slide-content">

  * Liste des nœuds Patroni
  * Test de bascule manuelle vers chaque nœud

</div>

<div class="notes">

###### **Liste des nœuds Patroni**

Sur chaque nœud Patroni, modifier le `.profile` de l'utilisateur `postgres` en ajoutant :

```Bash
export PATRONICTL_CONFIG_FILE=/etc/patroni/15-main.yml
```


```Bash
 $ sudo ssh pg-1 sudo -iu postgres patronictl list
```
```console
 + Cluster: 15-main (7029596050496494965) -+----+-----------+
 | Member | Host       | Role    | State   | TL | Lag in MB |
 +--------+------------+---------+---------+----+-----------+
 | pg-1   | 10.0.3.201 | Leader  | running |  3 |           |
 | pg-2   | 10.0.3.202 | Replica | running |  3 |         0 |
 | pg-3   | 10.0.3.203 | Replica | running |  3 |         0 |
```

###### **Test de bascule manuelle vers chaque nœud**

```Bash
 $ sudo ssh pg-1 sudo -iu postgres patronictl switchover
```
```console
Master [pg-1]:
Candidate ['pg-2', 'pg-3'] []: pg-2
When should the switchover take place (e.g. 2021-11-12T12:21 )  [now]:                          
Current cluster topology
+ Cluster: 15-main (7029596050496494965) -+----+-----------+                                    
| Member | Host       | Role    | State   | TL | Lag in MB |                                    
+--------+------------+---------+---------+----+-----------+                                    
| pg-1   | 10.0.3.201 | Leader  | running |  3 |           |                                    
| pg-2   | 10.0.3.202 | Replica | running |  3 |         0 |                                    
| pg-3   | 10.0.3.203 | Replica | running |  3 |         0 |                                    
+--------+------------+---------+---------+----+-----------+                                    
Are you sure you want to switchover cluster 15-main, demoting current master 
pg-1? [y/N]: y     
2021-11-12 11:21:20.08091 Successfully switched over to "pg-2"                                  
+ Cluster: 15-main (7029596050496494965) -+----+-----------+                                    
| Member | Host       | Role    | State   | TL | Lag in MB |                                    
+--------+------------+---------+---------+----+-----------+                                    
| pg-1   | 10.0.3.201 | Replica | stopped |    |   unknown |                                    
| pg-2   | 10.0.3.202 | Leader  | running |  3 |           |                                    
| pg-3   | 10.0.3.203 | Replica | running |  3 |         0 |                                    
+--------+------------+---------+---------+----+-----------+
```

</div>

---

## Création d'incidents

<div class="slide-content">

  * Perte totale du DCS
  * Freeze du nœud primaire Patroni
  * Bascule manuelle

</div>

<div class="notes">


</div>

---

### Perte totale du DCS

<div class="slide-content">

  * Perte de tous les nœuds Etcd

</div>

<div class="notes">

Nous simulons un incident majeur au niveau du _DCS_ :

```Bash
 $ for node in e1 e2 e3; do
  sudo lxc-freeze $node
done
```

La commande classique `patronictl list` échoue faute de _DCS_ pour la renseigner. 

Nous interrogeons directement sur les instances :

```Bash
 $ for node in pg-1 pg-2 pg-3; do 
echo "$node :"
sudo ssh $node "sudo -iu postgres psql -c 'select pg_is_in_recovery()'"
done
```
```console
pg-1 :
 pg_is_in_recovery 
-------------------
 t
(1 ligne)

pg-2 :
 pg_is_in_recovery 
-------------------
 t
(1 ligne)

pg-3 :
 pg_is_in_recovery 
-------------------
 t
(1 ligne)
```

Nous constatons que l'intégralité des nœuds est passée en lecture seule (_stand-by_). 

Nous débloquons la situation :

```Bash
 $ for node in e1 e2 e3; do 
echo "$node :"
sudo lxc-unfreeze $node
done
```

Nous pouvons observer le retour à la normale :

```Bash
 postgres@pg-1:~$ patronictl list -ew 1
```

</div>

---

### Perte du nœud primaire Patroni

<div class="slide-content">

  * Perte du primaire courant
  
</div>

<div class="notes">


Dans un autre terminal, nous observons l'état de l'agrégat sur le nœud `pg-2` :

```Bash
 postgres@pg-2:~$ patronictl list -ew 1
```

Nous simulons une perte du primaire `pg-1` :

```Bash
 $ sudo lxc-freeze pg-1
```

Nous observons la disparition de `pg-1` de la liste des nœuds et une bascule 
automatique se déclenche vers un des nœuds secondaires disponibles :

```console
+ Cluster: 15-main (7029596050496494965) -+----+-----------+
| Member | Host       | Role    | State   | TL | Lag in MB |
+--------+------------+---------+---------+----+-----------+
| pg-2   | 10.0.3.202 | Replica | running |  7 |         0 |
| pg-3   | 10.0.3.203 | Leader  | running |  7 |           |
+--------+------------+---------+---------+----+-----------+
```

Nous rétablissons la situation :

```Bash
$ sudo lxc-unfreeze pg-1

```

```console
+ Cluster: 15-main (7029596050496494965) -+----+-----------+
| Member | Host       | Role    | State   | TL | Lag in MB |
+--------+------------+---------+---------+----+-----------+
| pg-1   | 10.0.3.201 | Replica | running |  6 |         0 |
| pg-2   | 10.0.3.202 | Replica | running |  7 |         0 |
| pg-3   | 10.0.3.203 | Leader  | running |  7 |           |
+--------+------------+---------+---------+----+-----------+
```

Pour un retour à l'état nominal, il suffit de procéder à une bascule manuelle (adapter la commande si votre primaire n'est pas `pg-3`) :

```Bash
postgres@pg-1:~$ patronictl switchover --master pg-3 --candidate pg-1 --force
```
```console
Current cluster topology
+ Cluster: 15-main (7029596050496494965) -+----+-----------+
| Member | Host       | Role    | State   | TL | Lag in MB |
+--------+------------+---------+---------+----+-----------+
| pg-1   | 10.0.3.201 | Replica | running |  7 |         0 |
| pg-2   | 10.0.3.202 | Replica | running |  7 |         0 |
| pg-3   | 10.0.3.203 | Leader  | running |  7 |           |
+--------+------------+---------+---------+----+-----------+
2021-11-12 13:18:36.05884 Successfully switched over to "pg-1"
+ Cluster: 15-main (7029596050496494965) -+----+-----------+
| Member | Host       | Role    | State   | TL | Lag in MB |
+--------+------------+---------+---------+----+-----------+
| pg-1   | 10.0.3.201 | Leader  | running |  7 |           |
| pg-2   | 10.0.3.202 | Replica | running |  7 |         0 |
| pg-3   | 10.0.3.203 | Replica | stopped |    |   unknown |
+--------+------------+---------+---------+----+-----------+
```

</div>

---



## Modification de la configuration

<div class="slide-content">

  * patronictl edit-config

</div>

<div class="notes">

L'un des avantages de bénéficier d'une configuration distribuée est qu'il est possible de modifier cette configuration pour tous les nœuds en une seule opération.

Si le paramètre nécessite un rechargement de la configuration, elle sera lancée sur chaque nœud.

Si la modification nécessite un redémarrage, l' drapeau _pending restart_ sera positionné sur toutes les instances et attendrons une action de votre part pour l'effectuer.

> L'installation de la commande `less` est un pré-requis :
> ```Bash
>  $ for node in pg-1 pg-2 pg-3; do
>      ssh $node apt install less
>    done
> ```

La modification peut se faire sur n'importe quel nœud :

```Bash
postgres@pg-2:~$ patronictl edit-config
```

Nous ajoutons une ligne fille de la ligne ` parameters:`

```yaml
loop_wait: 10
maximum_lag_on_failover: 1048576
postgresql:
  parameters: 
    max_connections: 123
 ...
```

Une confirmation est demandée après la sortie de l'éditeur :

```diff
patronictl edit-config
--- 
+++ 
@@ -1,7 +1,8 @@
 loop_wait: 10
 maximum_lag_on_failover: 1048576
 postgresql:
-  parameters: null
+  parameters: 
+    max_connections: 123
   pg_hba:
   - local   all             all                                     peer
   - host    all             all             127.0.0.1/32            md5

Apply these changes? [y/N]: y
Configuration changed
```

Après modification, il convient de regarder si notre modification ne nécessite pas de redémarrage :

```Bash
postgres@pg-2:~$ patronictl list -e
```
```console
+ Cluster: 15-main (7029596050496494965) -+----+-----------+-----------------+
| Member | Host       | Role    | State   | TL | Lag in MB | Pending restart |
+--------+------------+---------+---------+----+-----------+-----------------+
| pg-1   | 10.0.3.201 | Leader  | running |  8 |           | *               |
| pg-2   | 10.0.3.202 | Replica | running |  8 |         0 | *               | 
| pg-3   | 10.0.3.203 | Replica | running |  8 |         0 | *               |
+--------+------------+---------+---------+----+-----------+-----------------+
``` 

Dans notre cas, un redémarrage de toutes les instances est nécessaire :

```Bash
postgres@pg-2:~$ patronictl restart 15-main
```
```console
+ Cluster: 15-main (7029596050496494965) -+----+-----------+-----------------+
| Member | Host       | Role    | State   | TL | Lag in MB | Pending restart |
+--------+------------+---------+---------+----+-----------+-----------------+
| pg-1   | 10.0.3.201 | Leader  | running |  8 |           | *               |
| pg-2   | 10.0.3.202 | Replica | running |  8 |         0 | *               |
| pg-3   | 10.0.3.203 | Replica | running |  8 |         0 | *               |
+--------+------------+---------+---------+----+-----------+-----------------+
When should the restart take place (e.g. 2021-11-12T14:37)  [now]: 
Are you sure you want to restart members pg-3, pg-2, pg-1? [y/N]: y
Restart if the PostgreSQL version is less than provided (e.g. 9.5.2)  []: 
Success: restart on member pg-3
Success: restart on member pg-2
Success: restart on member pg-1
```



```Bash
postgres@pg-2:~$ patronictl list -e
```
```console
+ Cluster: 15-main (7029596050496494965) -+----+-----------+-----------------+
| Member | Host       | Role    | State   | TL | Lag in MB | Pending restart |
+--------+------------+---------+---------+----+-----------+-----------------+
| pg-1   | 10.0.3.201 | Leader  | running |  8 |           |                 |
| pg-2   | 10.0.3.202 | Replica | running |  8 |         0 |                 |
| pg-3   | 10.0.3.203 | Replica | running |  8 |         0 |                 |
+--------+------------+---------+---------+----+-----------+-----------------+
```

```Bash
 $ for node in pg-1 pg-2 pg-3; do
  echo "$node :"
  sudo ssh $node "sudo -iu postgres psql -c 'show max_connections'"
  done
```
```console
pg-1 :
 max_connections 
-----------------
 123
(1 ligne)

pg-2 :
 max_connections 
-----------------
 123
(1 ligne)

pg-3 :
 max_connections 
-----------------
 123
(1 ligne)
```


L'application d'un paramètre qui ne nécessite pas de redémarrage est transparente, le rechargement de la configuration sur tous les nœuds est automatiquement déclenchée par Patroni.

</div>

---

## Sauvegardes

<div class="slide-content">

  * Installation pgBackrest
  * Configuration
  * Détermination du primaire
  * Archivage
  * Sauvegarde

</div>


<div class="notes">

### Détermination du primaire

Nous proposons de déclencher la sauvegarde sur le primaire courant, il faut donc d'abord l'identifier.
 
Le script suivant est une solution permettant de récupérer le primaire de notre agrégat à partir d'un nœud Etcd et de l'API mise à disposition :

```Bash
#! /bin/bash
SCOPE=$(grep -i scope: /etc/patroni/15-main.yml | cut -d '"' -f 2)
curl -s http://e1:2379/v2/keys/postgresql-common/"$SCOPE"/leader | jq -r .node.value
```

### Configuration de pgBackrest

**Sur chacun des nœuds**, il faut configurer le _stanza_ et l'initialiser :

```ini
# /etc/pgbackrest.conf
[main]
pg1-path=/var/lib/postgresql/15/main
pg1-socket-path=/var/run/postgresql
pg1-port=5432

[global]
log-level-file=detail
log-level-console=detail
repo1-host=backup
repo1-host-user=postgres

```

Tous les nœuds doivent permettre la connexion _ssh_ sans mot de passe, le _playbook_ _Ansible_ nommé `exchange_ssh_keys` permet de faire ce travail rapidement :

```Bash
 $ sudo ansible-playbook -i inventory.yml exchange_ssh_keys.yml  -f 7
```

La première connexion ssh entre `backup` et les nœuds PostgreSQL demande une 
confirmation. Il faut donc lancer les trois commandes :

``` Bash
postgres@backup:~ $ ssh pg-1

postgres@backup:~ $ ssh pg-2

postgres@backup:~ $ ssh pg-3
```

Nous pouvons alors tenter de créer le _stanza_ sur le primaire :

```Bash
postgres@pg-1:~$ pgbackrest --stanza main stanza-create
postgres@pg-1:/var/lib/pgbackrest$ pgbackrest --stanza  main check
ERROR: [087]: archive_mode must be enabled
```

L'archivage est en erreur puisque non configuré.


#### **Configuration de l'archivage**

Toutes les instances doivent être en mesure d'archiver leurs journaux de transactions au moyen de pgBackrest :

```Bash
postgres@pg-1:~$ patronictl edit-config
```
```yaml
postgresql:
  parameters:
    max_connections: 123
    archive_mode: 'on'
    archive_command: pgbackrest --stanza=main archive-push %p
```

Notre configuration n'a pas encore été appliquée sur les instances car un redémarrage est requis :

```Bash
postgres@pg-1:~$ patronictl list -e
```
```console
+ Cluster: 15-main (7029596050496494965) -+----+-----------+-----------------+
| Member | Host       | Role    | State   | TL | Lag in MB | Pending restart |
+--------+------------+---------+---------+----+-----------+-----------------+
| pg-1   | 10.0.3.201 | Leader  | running |  8 |           | *               |
| pg-2   | 10.0.3.202 | Replica | running |  8 |         0 | *               |
| pg-3   | 10.0.3.203 | Replica | running |  8 |         0 | *               |
+--------+------------+---------+---------+----+-----------+-----------------+
```

```Bash
postgres@pg-1:~$ patronictl restart 15-main --force
+ Cluster: 15-main (7029596050496494965) -+----+-----------+-----------------+
| Member | Host       | Role    | State   | TL | Lag in MB | Pending restart |
+--------+------------+---------+---------+----+-----------+-----------------+
| pg-1   | 10.0.3.201 | Leader  | running |  8 |           | *               |
| pg-2   | 10.0.3.202 | Replica | running |  8 |         0 | *               |
| pg-3   | 10.0.3.203 | Replica | running |  8 |         0 | *               |
+--------+------------+---------+---------+----+-----------+-----------------+
Success: restart on member pg-1
Success: restart on member pg-3
Success: restart on member pg-2
```

Test de la configuration de l'archivage sur le nœud `pg-1` :

```Bash
postgres@pg-1:~$ pgbackrest --stanza main check
```
```console
2021-11-12 15:57:04.000 P00   INFO: check command begin 2.35: --exec-id=13216-
4a7c4a92 --log-level-console=detail --log-level-file=detail --pg1-path=/var/lib/
postgresql/15/main --pg1-port=5432 --pg1-socket-path=/var/run/postgresql --
repo1-host=backup --repo1-host-user=postgres --stanza=main
2021-11-12 15:57:04.616 P00   INFO: check repo1 configuration (primary)
2021-11-12 15:57:05.083 P00   INFO: check repo1 archive for WAL (primary)
2021-11-12 15:57:08.425 P00   INFO: WAL segment 000000080000000000000005 
successfully archived to '/var/lib/pgbackrest/archive/main/15-1/
0000000800000000/000000080000000000000005-
b0929d740c7996974992ecd7b9b189b37d06a896.gz' on repo1
2021-11-12 15:57:08.528 P00   INFO: check command end: completed successfully 
(4531ms)
```

#### **Configuration sur la machine hébergeant les sauvegardes**

Sur la machine `backup`, créer le script de détermination du _leader_ (le rendre exécutable) :

```Bash
postgres@backup:~$ vim ~/leader.sh && chmod +x leader.sh
```


```Bash
#! /bin/bash
SCOPE='15-main'
curl -s http://e1:2379/v2/keys/postgresql-common/"$SCOPE"/leader | jq -r .node.value
```

##### **Configuration de pgBackrest**

Nous avons choisit d'opérer en mode _pull_, les sauvegardes seront exécutées 
sur la machine `backup` et récupérées depuis le primaire courant.
 
La configuration se fait dans le fichier `/etc/pgbackrest.conf` :

```ini
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
start-fast=y
log-level-console=info
log-level-file=info

[main]
pg1-path=/var/lib/postgresql/15/main
pg1-host-user=postgres
pg1-user=postgres
pg1-port=5432
```

On déterminera l'instance qui sera utilisée pour récupérer la sauvegarde, au 
moment de la sauvegarde. 

**Test d'une sauvegarde**

```Bash
postgres@backup:~$ pgbackrest --stanza main --pg1-host=$(./leader.sh) backup 
--type=full
```
```console

2023-02-09 18:43:38.424 P00   INFO: backup command begin 2.44: --exec-id=1116-00f26290 
--log-level-console=info --log-level-file=info --pg1-host=pg-1 --pg1-host-user=postgres --
pg1-path=/var/lib/postgresql/15/main --pg1-port=5432 --pg1-user=postgres --repo1-path=/var/
lib/pgbackrest --repo1-retention-full=2 --stanza=main --start-fast --type=full
2023-02-09 18:43:39.363 P00   INFO: execute non-exclusive backup start: backup begins 
after the requested immediate checkpoint completes
2023-02-09 18:43:40.475 P00   INFO: backup start archive = 000000070000000000000013, lsn = 0/13000028
2023-02-09 18:43:40.475 P00   INFO: check archive for prior segment 000000070000000000000012
2023-02-09 18:44:06.600 P00   INFO: execute non-exclusive backup stop and wait for all WAL segments to archive
2023-02-09 18:44:06.905 P00   INFO: backup stop archive = 000000070000000000000013, lsn = 0/13000138
2023-02-09 18:44:06.955 P00   INFO: check archive for segment(s) 
000000070000000000000013:000000070000000000000013
2023-02-09 18:44:07.533 P00   INFO: new backup label = 20230209-184339F
2023-02-09 18:44:07.798 P00   INFO: full backup size = 29.2MB, file total = 1261
2023-02-09 18:44:07.819 P00   INFO: backup command end: completed successfully (29396ms)
2023-02-09 18:44:07.819 P00   INFO: expire command begin 2.44: --exec-id=1116-00f26290 
--log-level-console=info --log-level-file=info --repo1-path=/var/lib/pgbackrest 
--repo1-retention-full=2 --stanza=main
2023-02-09 18:44:07.822 P00   INFO: repo1: expire full backup 20230209-183850F
2023-02-09 18:44:07.892 P00   INFO: repo1: remove expired backup 20230209-183850F
2023-02-09 18:44:07.971 P00   INFO: repo1: 15-1 remove archive, start = 000000070000000000000008, 
stop = 00000007000000000000000A
2023-02-09 18:44:07.971 P00   INFO: expire command end: completed successfully (152ms)

```

Vérification de l'état de la sauvegarde :

```Bash
postgres@backup:~$ pgbackrest --stanza main info
```
```console
stanza: main
    status: ok
    cipher: none

    db (current)
        wal archive min/max (14): 000000010000000000000001/00000008000000000000000B

        full backup: 20211112-163233F
            timestamp start/stop: 2021-11-12 16:32:33 / 2021-11-12 16:32:45
            wal start/stop: 00000008000000000000000B / 00000008000000000000000B
            database size: 25.1MB, database backup size: 25.1MB
            repo1: backup set size: 3.2MB, backup size: 3.2MB
```

</div>

---

## Réplication synchrone

La réplication synchrone permet de garantir que les données sont 
écrites sur un ou plusieurs secondaires lors de la validation des 
transactions.

Elle permet de réduire quasi-totalement la perte de donnée lors d'un incident 
(RPO).

Il faut un minimum de trois paramètres ajoutés à la configuration dynamique pour 
décrire la réplication synchrone : 

```
synchronous_mode: true
synchronous_node_count: 1
synchronous_standby_names: '*'
```

Après quelques secondes, l'un des réplicas passe en mode synchrone :


```
postgres@pg-1:~$ patronictl list
+ Cluster: 15-main (7198182122558146054) ------+----+-----------+
| Member | Host       | Role         | State   | TL | Lag in MB |
+--------+------------+--------------+---------+----+-----------+
| pg-1   | 10.0.3.201 | Leader       | running |  7 |           |
| pg-2   | 10.0.3.202 | Replica      | running |  7 |         0 |
| pg-3   | 10.0.3.203 | Sync Standby | running |  7 |         0 |
+--------+------------+--------------+---------+----+-----------+
```

  * La prochaine bascule ne sera possible que sur le nœud synchrone.
  * Si le nœud synchrone est défaillant, un des secondaires restant passera en 
  mode synchrone (`synchronous_standby_names` et `synchronous_node_count` l'autorisent)

**Perte du secondaire synchrone :**

```Bash
$ sudo lxc-freeze pg-3
```

**Quelques secondes plus tard :**

```
+ Cluster: 15-main (7198182122558146054) ------+----+-----------+
| Member | Host       | Role         | State   | TL | Lag in MB |
+--------+------------+--------------+---------+----+-----------+
| pg-1   | 10.0.3.201 | Leader       | running |  7 |           |
| pg-2   | 10.0.3.202 | Sync Standby | running |  7 |         0 |
+--------+------------+--------------+---------+----+-----------+
```

---


## Mise à jour mineure sans interruption de service

Rappel : la réplication physique peut être mise en œuvre entre deux instances de 
versions mineures différentes. (ex: 15.1 vers 15.2)
 
La mise à jour mineure peut être faite nœud par nœud en commençant par les 
secondaires asynchrones, puis par les secondaires synchrones.

Dès qu'un deuxième secondaire synchrone est présent, le mise peut être faîte sur 
le premier secondaire synchrone.

Une fois tous les secondaires mis à jour, une bascule sur un des secondaires 
synchrone à jour pourra être faite et l'ancien primaire sera alors mis à jour 
de la même manière, puis redémarré :


**État de départ :**

```
+ Cluster: 15-main (7198182122558146054) ------+----+-----------+
| Member | Host       | Role         | State   | TL | Lag in MB |
+--------+------------+--------------+---------+----+-----------+
| pg-1   | 10.0.3.201 | Leader       | running |  7 |           |
| pg-2   | 10.0.3.202 | Replica      | running |  7 |         0 |
| pg-3   | 10.0.3.203 | Sync Standby | running |  7 |         0 |
+--------+------------+--------------+---------+----+-----------+
```


**Mise à jour jour et redémarrage du premier secondaire asynchrone `pg-2` :**

```Bash
...
$ patronictl restart 15-main pg-2
```

**Passage à 2 nœuds synchrones :**

```Bash
$ patronictl edit-config

```
```yaml
...
synchronous_node_count: 2
...

```

```
+ Cluster: 15-main (7198182122558146054) ------+----+-----------+
| Member | Host       | Role         | State   | TL | Lag in MB |
+--------+------------+--------------+---------+----+-----------+
| pg-1   | 10.0.3.201 | Leader       | running | 10 |           |
| pg-2   | 10.0.3.202 | Sync Standby | running | 10 |         0 |
| pg-3   | 10.0.3.203 | Sync Standby | running | 10 |         0 |
+--------+------------+--------------+---------+----+-----------+
```

**Mise à jour du nœud synchrone `pg-3` :**

```Bash
...
$ patronictl restart 15-main pg-3
```

**Bascule vers le secondaire synchrone mis à jour :**

```Bash
...
$ patronictl switchover --master pg-1 --candidate pg-3 --force
```

**Mise à jour du primaire :**

```Bash
...
$ patronictl restart 15-main pg-1 --force
```

**Effectuer la promotion et remettre le nombre de nœuds synchrone à `1` :**


```Bash
$ patronictl switchover --candidate pg-1 --master pg-3 --force
```

```
+ Cluster: 15-main (7198182122558146054) ------+----+-----------+
| Member | Host       | Role         | State   | TL | Lag in MB |
+--------+------------+--------------+---------+----+-----------+
| pg-1   | 10.0.3.201 | Leader       | running | 11 |           |
| pg-2   | 10.0.3.202 | Sync Standby | running | 11 |         0 |
| pg-3   | 10.0.3.203 | Sync Standby | running | 11 |         0 |
+--------+------------+--------------+---------+----+-----------+
```

```Bash
$ patronictl edit-config

```
```yaml
...
synchronous_node_count: 1
...

```

**Après quelques secondes :**

```
+ Cluster: 15-main (7198182122558146054) ------+----+-----------+
| Member | Host       | Role         | State   | TL | Lag in MB |
+--------+------------+--------------+---------+----+-----------+
| pg-1   | 10.0.3.201 | Leader       | running | 11 |           |
| pg-2   | 10.0.3.202 | Sync Standby | running | 11 |         0 |
| pg-3   | 10.0.3.203 | Replica      | running | 11 |         0 |
+--------+------------+--------------+---------+----+-----------+
```

Aucun arrêt de service et aucune perte de données due à l'opération.



---

## Références

<div class="slide-content">

  * Etcd : <https://etcd.io/docs/>
  * Patroni : <https://patroni.readthedocs.io/en/latest/>
  * Formation HAPAT : <https://dalibo.com/formation-postgresql-haute-disponibilite>
  * Dalibo : <https://dalibo.com>
  
</div>

<div class="notes">

</div>

---
