<!--

Commit :
  https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=cec2edfa7859279f36d2374770ca920c59c73dd8
  
  Instead of deciding to serialize a transaction merely based on the
  number of changes in that xact (toplevel or subxact), this makes
  the decisions based on amount of memory consumed by the changes.
  
  The memory limit is defined by a new logical_decoding_work_mem GUC,
  so for example we can do this
  
      SET logical_decoding_work_mem = '128kB'
  
  to reduce the memory usage of walsenders or set the higher value to
  reduce disk writes. The minimum value is 64kB.
  
  When adding a change to a transaction, we account for the size in
  two places. Firstly, in the ReorderBuffer, which is then used to
  decide if we reached the total memory limit. And secondly in the
  transaction the change belongs to, so that we can pick the largest
  transaction to evict (and serialize to disk).
  
  We still use max_changes_in_memory when loading changes serialized
  to disk. The trouble is we can't use the memory limit directly as
  there might be multiple subxact serialized, we need to read all of
  them but we don't know how many are there (and which subxact to
  read first).
  
  We do not serialize the ReorderBufferTXN entries, so if there is a
  transaction with many subxacts, most memory may be in this type of
  objects. Those records are not included in the memory accounting.
  
  We also do not account for INTERNAL_TUPLECID changes, which are
  kept in a separate list and not evicted from memory. Transactions
  with many CTID changes may consume significant amounts of memory,
  but we can't really do much about that.
  
  The current eviction algorithm is very simple - the transaction is
  picked merely by size, while it might be useful to also consider age
  (LSN) of the changes for example. With the new Generational memory
  allocator, evicting the oldest changes would make it more likely
  the memory gets actually pfreed.
  
  The logical_decoding_work_mem can be set in postgresql.conf, in which
  case it serves as the default for all publishers on that instance.

Attention, le paramètre n'est pas seulement limité aux walsenders contrairement
à ce que laisse entendre le message de commit.

-->

<div class="slide-content">

  * Nouveau paramètre `logical_decoding_work_mem` 
    + Défaut : 64 Mo par session
  * Contrôle la mémoire allouée au décodage logique avant de déborder sur disque
  * Concerne toute session consommant un slot logique, y compris les walsenders
  * Meilleur contrôle de la consommation mémoire des walsenders

</div>

<div class="notes">

Le décodage logique des journaux applicatifs peut consommer beaucoup de mémoire
sur l'instance d'origine. Il n'existait jusqu'à présent aucun moyen de
contrôler la quantité de mémoire réservée à cette opération. L'opération
pouvait déborder sur disque une transaction seulement si le nombre de
changements de cette dernière était supérieur à 4096. Or, les transactions
étant entremêlées dans les journaux de transaction, le décodage peut rapidement
mener à maintenir en mémoire les données de plusieurs d'entre elles en même
temps, avant de pouvoir les envoyer au destinataire. Il n'était pas possible de
modifier ce comportement.

Le nouveau paramètre `logical_decoding_work_mem` permet désormais de contrôler
finement à quel moment le décodage d'une transaction doit déborder sur
disque en définissant une limite en matière de mémoire consommée. Sa valeur
par défaut est de `64MB`.

Il est donc possible de limiter la consommation mémoire des `walsenders` en
abaissant ce paramètre, au prix d'une perte de performance, d'une latence
supplémentaire sur la réplication logique et d'I/O supplémentaires. Au
contraire, augmenter ce paramètre permet de privilégier la réplication logique
et sa latence au prix d'une consommation mémoire supérieure et d'I/O
supplémentaires.

Le paramètre peut être modifié pour tout le monde, ou au sein d'une session
(par exemple, en utilisant l'API SQL de décodage), ou encore pour un rôle de
réplication logique ou une base de donnée seulement.</div>
