<!-- 

commit :

https://commitfest.postgresql.org/36/3401/

discussion : 

https://www.postgresql.org/message-id/flat/CALj2ACX-rW_OeDcp4gqrFUAkf1f50Fnh138dmkd0JkvCNQRKGA@mail.gmail.com

-->

<div class="slide-content">

* Changement des valeurs par défaut des paramètres de journalisation :
  - `log_checkpoints` par défaut à `on`
  - `log_autovacuum_min_duration` par défaut à 10 minutes.

</div>

<div class="notes">

**`log_checkpoints`**

Le paramètre `log_checkpoints` est désormais à `on` par défaut, chaque 
`CHECKPOINT` sera par conséquent journalisé dans les traces de l'instance.

Les traces générées par  ce paramètre contiennent des informations sur la durée
des `CHECKPOINT` et sur les écritures effectuées :

```sh
2022-07-15 09:40:01.393 UTC [4198] LOG:  checkpoint starting: wal
2022-07-15 09:42:16.273 UTC [4198] LOG:  checkpoint complete: wrote 67 buffers (0.4%); 
   0 WAL file(s) added, 0 removed, 134 recycled; 
   write=134.352 s, sync=0.001 s, total=134.880 s; sync files=9, longest=0.001 s, average=0.001 s; 
   distance=2192214 kB, estimate=2193764 kB
2022-07-15 09:42:29.121 UTC [4198] LOG:  checkpoint starting: wal
2022-07-15 09:43:56.646 UTC [4198] LOG:  checkpoint complete: wrote 81 buffers (0.5%); 
   0 WAL file(s) added, 0 removed, 134 recycled; 
   write=86.438 s, sync=0.026 s, total=87.525 s; sync files=8, longest=0.012 s, average=0.004 s;
   distance=2198655 kB, estimate=2198655 kB
2022-07-15 09:43:58.331 UTC [4198] LOG:  checkpoint starting: wal
2022-07-15 09:45:34.024 UTC [4198] LOG:  checkpoint complete: wrote 29 buffers (0.2%); 
   0 WAL file(s) added, 0 removed, 134 recycled;
   write=94.874 s, sync=0.028 s, total=95.693 s; sync files=9, longest=0.016 s, average=0.004 s; 
   distance=2192128 kB, estimate=2198003 kB
```
**`log_autovacuum_min_duration`**

Le paramètre `log_autovacuum_min_duration` est désormais configuré à 10 minutes.
Cela signifie que chaque opération d'_autovacuum_ qui dépasse ce délai sera 
tracée.

Les traces générées par ce paramètre permettent d'obtenir un rapport détaillé 
sur les opérations de `VACUUM` et `ANALYZE` exécutées par l'_autovacuum_ :

```sh
2022-07-15 09:53:05.049 UTC [6563] LOG:  automatic vacuum of table "postgres.public.db_activity": index scans: 0
	pages: 0 removed, 108334 remain, 75001 scanned (69.23% of total)
	tuples: 0 removed, 9926694 remain, 2591536 are dead but not yet removable
	removable cutoff: 1024, which was 2 XIDs old when operation ended
	index scan not needed: 0 pages from table (0.00% of total) had 0 dead item identifiers removed
	avg read rate: 62.039 MB/s, avg write rate: 16.120 MB/s
	buffer usage: 91282 hits, 58777 misses, 15272 dirtied
	WAL usage: 1 records, 1 full page images, 2693 bytes
	system usage: CPU: user: 1.34 s, system: 0.22 s, elapsed: 7.40 s
2022-07-15 09:53:08.658 UTC [6563] LOG:  automatic analyze of table "postgres.public.db_activity"
	avg read rate: 55.129 MB/s, avg write rate: 27.167 MB/s
	buffer usage: 4746 hits, 25467 misses, 12550 dirtied
	system usage: CPU: user: 0.37 s, system: 0.15 s, elapsed: 3.60 s
```


</div>