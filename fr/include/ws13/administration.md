## Administration

<div class="slide-content">

  * Nouveautés sur le `VACUUM`

</div>

<div class="notes">

</div>

----

### Nouveautés du VACUUM

<div class="slide-content">

  * _parallel vacuum_

</div>

<div class="notes"></div>

----

### Parallel vacuum 

<div class="slide-content">

  * parallélisation de l'action de vacuum sur les index

</div>

<div class="notes">

```
Allow vacuum command to process indexes in parallel.

This feature allows the vacuum to leverage multiple CPUs in order to
process indexes.  This enables us to perform index vacuuming and index
cleanup with background workers.  This adds a PARALLEL option to VACUUM
command where the user can specify the number of workers that can be used
to perform the command which is limited by the number of indexes on a
table.  Specifying zero as a number of workers will disable parallelism.
This option can't be used with the FULL option.

Each index is processed by at most one vacuum process.  Therefore parallel
vacuum can be used when the table has at least two indexes.

The parallel degree is either specified by the user or determined based on
the number of indexes that the table has, and further limited by
max_parallel_maintenance_workers.  The index can participate in parallel
vacuum iff it's size is greater than min_parallel_index_scan_size.Allow vacuum
command to process indexes in parallel.

This feature allows the vacuum to leverage multiple CPUs in order to
process indexes.  This enables us to perform index vacuuming and index
cleanup with background workers.  This adds a PARALLEL option to VACUUM
command where the user can specify the number of workers that can be used
to perform the command which is limited by the number of indexes on a
table.  Specifying zero as a number of workers will disable parallelism.
This option can't be used with the FULL option.

Each index is processed by at most one vacuum process.  Therefore parallel
vacuum can be used when the table has at least two indexes.

The parallel degree is either specified by the user or determined based on
the number of indexes that the table has, and further limited by
max_parallel_maintenance_workers.  The index can participate in parallel
vacuum iff it's size is greater than min_parallel_index_scan_size.
```


</div>

----
