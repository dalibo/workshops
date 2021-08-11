<!-- 

Doc v13 identique à v12 !

https://www.postgresql.org/docs/13/runtime-config-resource.html#GUC-EFFECTIVE-IO-CONCURRENCY

Discussion :
https://www.postgresql.org/message-id/flat/CA%2BhUKGJUw08dPs_3EUcdO6M90GnjofPYrWp4YSLaBkgYwS-AqA%40mail.gmail.com

-->

<div class="slide-content">

Paramètre `effective_io_concurrency` :

  * Nombre d'I/O en parallèle pour une session
  * L'échelle change :
    * multiplier les valeurs par 1 à 5

</div>

<div class="notes">

`effective_io_concurrency` sert à contrôler le nombre d'accès simultanés
qu'un **client** peut demander aux disques. En pratique, il ne sert qu'à l'optimiseur
pour juger de l'intérêt d'un accès par _Bitmap Heap Scan_.

Pour des raisons de cohérence, suite à
l'introduction du paramètre `maintenance_io_concurrency`, la valeur de ce
paramètre est modifiée.

La valeur reste entre 0 et 1000. Le défaut était et reste à 1.
Pour des disques mécaniques, compter le nombre
de disques dans une grappe RAID (hors parité).
Pour des SSD, on peut monter à plusieurs centaines.
Le paramètre est au niveau d'un client : on le baissera s'il y a beaucoup de requêtes simultanées.

Si une valeur a été calculée, on peut convertir avec la formule suivante :

```
SELECT  round(sum(ANCIENNE_VALEUR / n::float))
FROM    generate_series(1, ANCIENNE_VALEUR) s(n);
```

Ce qui donne les conversions suivantes :

| **Ancienne valeur**    | **Nouvelle valeur**     |
|:------------------------:|:------------------------:|
| 1| 1|
| 2| 3|
| 3| 6|
| 10| 29|
| 100| 519|

</div>

