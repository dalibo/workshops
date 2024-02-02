Pour lancer l'installation avec ansible :

```
ansible-playbook -i inventory install.yml --extra-vars="ansible_ssh_pass=<fixme>"
```

On trouve les mots de passe ici: https://gitlab.dalibo.info/formation/infra/dba1/-/jobs/422335/artifacts/download?file_type=archive