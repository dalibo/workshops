# Démarrer un nouveau workshop

  * Créer le sous-répertoire dans le dossier `fr/` ou/et `en/` (ex: `ws14`)
  * Créer un fichier `.md` à la racine de ce répertoire
  * Créer une nouvelle branche portant le même nom
  * Modifier la variable `BRANCH_TARGET` dans le fichier `.gitlab-ci.yml`
  * Activer les options "Delete source branch" et "Squash commits" dans la MR Gitlab

# Publication sur le dépôt Github

  * Se positionner dans le dépôt local formation/workshops
  * Créer un remote vers Github

```bash
git remote add github git@github.com:dalibo/workshops.git
```

  * Créer au préalable la branche intermédiaire sur le github
  * Merger `master` dans cette branche
  * Pousser sur github
  
```bash
git checkout merge_v12_from_gitlab
git merge master
git push
```

  * Créer un MR sur Github pour merger `merge_v12_from_gitlab` dans `master`
