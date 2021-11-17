<!--
Les commits sur ce sujet sont :

| Sujet                    | Lien                                                                                                        |
|==========================|=============================================================================================================|
| backup manifest          | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=0d8c9c1210c44b36ec2efcb223a1dfbe897a3661 |
| rename pg_verifybackup   | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=dbc60c5593f26dc777a3be032bff4fb4eab1ddd1 |

Discussion générale:
* https://www.postgresql.org/message-id/CA+TgmoZV8dw1H2bzZ9xkKwdrk8+XYa+DC9H=F7heO2zna5T6qg@mail.gmail.com

Discussion du renommage pg_validatebackup => pg_verifybackup :
* https://www.postgresql.org/message-id/172c9d9b-1d0a-1b94-1456-376b1e017322@2ndquadrant.com
* https://www.postgresql.org/message-id/CA+TgmobLgMh6p8FmLbj_rv9Uhd7tPrLnAyLgGd2SoSj=qD-bVg@mail.gmail.com

-->

### Fichiers manifestes

<div class="slide-content">

* `pg_basebackup` crée une liste des fichiers présents dans les sauvegardes :
  le fichier manifeste.

* Trois nouvelles options :

  * `--no-manifest`
  * `--manifest-force-encode`
  * `--manifest-checksums=[NONE|CRC32C|SHA224|SHA256|SHA384|SHA512]`

</div>

<div class="notes">

`pg_basebackup` crée désormais par défaut un fichier manifeste. C'est un
fichier `json`. Il contient pour chaque fichier inclus dans la sauvegarde :

* le chemin relatif à `$PGDATA` ;
* la taille du fichier ;
* la date de dernière modification ;
* l'algorithme de calcul de somme de contrôle utilisé ;
* la somme de contrôle.

Il contient également, un numéro de version de manifeste, sa propre somme de
contrôle et la plage de journaux de transactions nécessaire à la restauration.

```json
$ cat backup_manifest | jq
{
  "PostgreSQL-Backup-Manifest-Version": 1,
  "Files": [
    {
      "Path": "backup_label",
      "Size": 225,
      "Last-Modified": "2020-05-12 15:58:59 GMT",
      "Checksum-Algorithm": "CRC32C",
      "Checksum": "c7b34439"
    },
    {
      "Path": "tablespace_map",
      "Size": 0,
      "Last-Modified": "2020-05-12 15:58:59 GMT",
      "Checksum-Algorithm": "CRC32C",
      "Checksum": "00000000"
    },
    ...
  ],
  "WAL-Ranges": [
    {
      "Timeline": 1,
      "Start-LSN": "0/4000028",
      "End-LSN": "0/4000100"
    }
  ],
  "Manifest-Checksum": "1107abd51[...]732d7b24f217b5e4"
}
```

Le fichier manifeste nommé `backup_manifest` est créé quel que soit le format
de sauvegarde choisi (`plain` ou `tar`).

`pg_basebackup` dispose de trois options relatives aux fichiers manifestes :

* `--no-manifest` : ne pas créer de fichier manifeste pour la sauvegarde.

* `--manifest-force-encode` : forcer l'encodage de l'intégralité des noms de
  fichiers de la sauvegarde en hexadécimal. Sans cette option, seuls les
  fichiers dont le nom n'est pas encodé en UTF-8 sont encodés en hexadécimal.
  Cette option est destinée aux tests des outils tiers qui manipulent des
  fichiers manifestes.

* `--manifest-checksums=[NONE|CRC32C|SHA224|SHA256|SHA384|SHA512]` : permet de
  spécifier l'algorithme de somme de contrôle appliqué à chaque fichier inclus
  dans la sauvegarde. L'algorithme par défaut est `CRC32C`. La valeur `NONE` a
  pour effet de ne pas inclure de somme de contrôle dans le fichier manifeste.

L'impact du calcul des sommes de contrôle sur la durée de la sauvegarde est
variable en fonction de l'algorithme choisi.

Voici les mesures faites sur un ordinateur portable Intel(R) Core(TM) i7-10510U
CPU @ 1.80GHz avec 8 CPU et équipé d'un disque dur SSD. L'instance fait 6 Go et
a été générée en utilisant `pgbench` avec un facteur d'échelle de `400`.

| algorithme       | nombre de passes | temps moyen (s) |
|:----------------:|:----------------:|:---------------:|
| pas de manifeste | 50               | 33.6308         |
| NONE             | 50               | 32.7352         |
| CRC32C           | 50               | 33.6722         |
| SHA224           | 50               | 56.3702         |
| SHA256           | 50               | 55.664          |
| SHA384           | 50               | 45.754          |
| SHA512           | 50               | 46.1696         |

Le calcul des sommes de contrôle avec l'algorithme `CRC32C` a donc un impact
peu important sur la durée de la sauvegarde. L'impact est beaucoup plus
important avec les algorithmes de type `SHA`. Les sommes de contrôle `SHA` avec
un grand nombre de bits sont plus performantes. Ces observations sont en accord
avec celles faites pendant le développement de cette fonctionnalité.

Un intérêt des sommes de contrôle `SHA` avec un nombre de bits élevé
est de diminuer les chances de produire un faux positif. Mais surtout,
dans les milieux les plus sensibles, il permet de
parer à toute modification mal intentionnée d'un backup,
théoriquement possible avec des algorithmes trop simples.
Le manifeste doit alors être copié séparément.
<!-- dixit la doc https://www.postgresql.org/docs/13/app-pgbasebackup.html -->

</div>

----

### Nouvel outil pg_verifybackup

<div class="slide-content">

* Fonction : vérifier une sauvegarde au format `plain` grâce au fichier
  manifeste.

* 4 étapes :
  * vérification de la présence du manifeste et de sa somme de contrôle
  * vérification de la présence des fichiers écrits dans le manifeste
  * vérification des sommes de contrôle des fichiers présents dans le
    manifeste
  * vérification des WALs (présence, somme de contrôle des enregistrements)

* Ne dispense pas de tester les sauvegardes en les restaurant !

</div>

<div class="notes">

`pg_verifybackup` permet de vérifier que le contenu d'une sauvegarde au format
`plain` correspond bien à ce que le serveur a envoyé lors de la sauvegarde.

La vérification se déroule en quatre étapes. Il est possible de demander à
l'outil de s'arrêter à la première erreur avec `-e`, `--exit-on-error`. On peut
également faire en sorte d'ignorer certains répertoires avec `-i`,
`--ignore=RELATIVE_PATH`.

* La première étape consiste à vérifier la présence du fichier manifeste et
  l'exactitude de sa somme de contrôle. Par défaut, l'outil cherche le fichier
  de manifeste dans le répertoire de sauvegarde donné en paramètre. Il est
  également possible d'utiliser l'option `-m` ou `--manifest-path=PATH` pour
  spécifier le chemin vers le fichier de manifeste.

* La seconde étape consiste à vérifier que les fichiers présents dans le
  manifeste sont bien présents dans la sauvegarde. Les fichiers manquants ou
  supplémentaires sont signalés à l'exception de : `postgresql.auto.conf`,
  `standby.signal`, `recovery.signal`, le fichier manifeste lui-même ainsi que
  le contenu du répertoire `pg_wal`.

* La troisième étape consiste à vérifier les sommes de contrôle des fichiers
  présents dans le manifeste.

* La dernière étape permet de vérifier la présence et l'exactitude des journaux
  de transactions nécessaires à la restauration. Cette étape peut être ignorée
  en spécifiant le paramètre `-n, --no-parse-wal`. Le répertoire contenant les
  journaux de transactions peut être spécifié avec le paramètre `-w,
  --wal-directory=PATH`. Par défaut, l'outil cherche un répertoire `pg_wal`
  présent dans le répertoire de sauvegarde. Les journaux sont analysés avec
  `pg_waldump` pour vérifier les sommes de contrôle des enregistrements qu'ils
  contiennent.  Seule la plage de journaux de transactions présente dans le
  fichier manifeste est vérifiée.

`pg_verifybackup` permet donc de vérifier que ce que contient la sauvegarde est
conforme avec ce que le serveur a envoyé. Cependant, cela ne garantit pas que
la sauvegarde est exempte d'autres problèmes. Il est donc toujours nécessaire
de tester les sauvegardes réalisées en les restaurant.

Actuellement, seules des sauvegardes produites par `pg_basebackup` ou des
outils qui l'utilisent comme `Barman` en mode _streaming-only_ peuvent être
vérifiées. Les autres outils de sauvegarde tels que `pgBackRest`, `pitrery` ou
`Barman` (en mode rsync) ne permettent pas encore de générer des fichiers
manifestes compatibles avec PostgreSQL. Cela pourrait changer dans un avenir
proche.

</div>
