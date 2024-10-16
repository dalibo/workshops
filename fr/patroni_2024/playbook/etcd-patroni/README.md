# Playbooks infrastructure HA

## Création des containers


L'inventory_local.yml doit être mis à jour avec la liste des vm concernées :

```yaml
---

all:
  hosts:
    vm1:
    vm2:
    vm3:
  vars:
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    ansible_ssh_extra_args: '-o StrictHostKeyChecking=no'
    ansible_python_interpreter: "/usr/bin/python3"
    postgresql_version: "15"
    postgresql_instance: "main"
```

On créé les containers sur les vm en lançant localement sur son poste
(et pas sur les vm) le playbook :

```bash
$ ansible-playbook -i inventory_local.yml setup.yml -f 7
```

Il créera 7 containers sur chacune des vm :

| Nom     | adresse ip |
| :------ | :--------- |
| e1      | 10.0.3.101 |
| e2      | 10.0.3.102 |
| e3      | 10.0.3.103 |
| pg1     | 10.0.3.201 |
| pg2     | 10.0.3.202 |
| pg3     | 10.0.3.203 |
| backup  | 10.0.3.204 |

## Destruction des containers

### Depuis la vm

Pour supprimer **tous les containers** d'une vm il suffit de lancer le playbook
`teardown.yml` avec l'inventaire des containers `inventory.yml`, sur la vm
concernée :

```bash
local:~$ ssh vm1
formateur@vm-formation1:~$ sudo -i
root@vm-formation1:~# ansible-playbook -i inventory.yml teardown.yml
```

### Depuis son poste

On peut aussi lancer le playbook teardown_local.yml depuis son poste pour
supprimer tous les containers de toutes les vm.

```bash
local:~$ ansible-playbook -i inventory_local.yml teardown_local.yml -f 7
```

<div class="box tip">

On peut limiter l'action du playbook à une liste de vm avec l'option `-l` ou
`--limit` :

```bash
local:~$ ansible-playbook -i inventory_local.yml -f 7 teardown_local.yml  --limit vm1,vm3
```
</div> <!-- box-tip -->

---
