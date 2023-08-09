<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=7781f4e3e711ace6bcf9b6253a104b180cb78fcf

Discussion :

* Discussion: https://postgr.es/m/929fbf3c-24b8-d454-811f-1d5898ab3e91%40migops.com

-->

<div class="slide-content">

  * Deux nouvelles options à `vacuumdb`
    + `--schema`
    + `--exclude-schema`
</div>

<div class="notes">

Deux nouvelles options sont maintenant disponibles dans l'utilitaire `vacuumdb`.
`--schema` et `--exclude-schema` permettent soit d'effectuer l'opération de
`VACUUM` sur toutes les tables des schémas indiqués, soit, à l'inverse, de les
exclure de l'opération.

Ces options peuvent respectivement être appelées avec les options `-n` et `-N`.
Il n'est pas possible d'utiliser ces nouvelles options avec les options `-a` et
`-t`. Un message d'erreur explicite sera renvoyé.

```bash
$ vacuumdb --schema public -U postgres -d postgres -t pgbench_accounts
vacuumdb: error: cannot vacuum all tables in schema(s) and specific table(s) at the same time
```

Une des raisons qui est à l'origine de cette amélioration est la trop forte
fragmentation du schéma `pg_catalog` lorsque de nombreux objets temporaires sont
créés. Jusqu'à présent, il n'y avait pas de moyen simple pour lancer des
opérations de `VACUUM` sur ce schéma, il fallait donc passer sur chacune des
tables. Dans un contexte de production, si on sait que de nombreuses opérations
sont faites sur la majorité des tables d'un schéma, cette option permet de
gagner du temps en indiquant le schéma sur lequel effectuer le `VACUUM` et non
plus les tables une à une.

</div>
