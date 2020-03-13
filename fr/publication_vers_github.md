# Publication sur le dépôt Github


  * se positionner dans le repo local formation/workshops
  * créer un remote vers github

```Bash
git remote add github git@github.com:dalibo/workshops.git
```

  * créer au préalable la branche intermédiaire sur le github
  * merger `master` dans cette branche
  * pousser sur github
  
```Bash
git checkout merge_v12_from_gitlab
git merge master
git push
```

  * créer un MR sur github pour merger `merge_v12_from_gitlab` dans `master`
