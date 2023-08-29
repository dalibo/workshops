<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=2453ea142233ae57af452019c3b9a443dad1cdd0

Discussion

* https://www.postgresql.org/message-id/flat/2b8490fe-51af-e671-c504-47359dc453c5@2ndquadrant.com

-->

<div class="slide-content">

  ```sql
  CREATE PROCEDURE assign(IN a int, OUT b int)
  ```

  * paramètre initialisé à  NULL en début de procédure

</div>

<div class="notes">

La version 11 a introduit les procédures dans PostgreSQL. Jusqu'à maintenant, le
mode des paramètres pouvait être : `IN`, `INOUT` ou `VARIADIC`. Il est
désormais possible de déclarer des paramètres avec le mode `OUT`.

Exemple :

```sql
CREATE PROCEDURE assign(IN a int, OUT b int)
  LANGUAGE plpgsql
AS $$
BEGIN
  -- assigner une valeur à b si a = 10
  IF a = 10 THEN
    b := a;
  END IF;
END;
$$;
-- CREATE PROCEDURE
```

Comme le montre l'exemple ci-dessous, la variable spécifiée comme paramètre de
sortie est initalisée à `NULL` en début de procédure.

```sql
DO $$
DECLARE _a int; _b int;
BEGIN
  _a := 10;
  CALL assign(_a, _b);
  RAISE NOTICE '_a: %, _b: %', _a, _b;

  _a := 100;
  CALL assign(_a, _b);
  RAISE NOTICE '_a: %, _b: %', _a, _b;
END
$$;
-- NOTICE:  _a: 10, _b: 10
-- NOTICE:  _a: 100, _b: <NULL>
-- DO
```

</div>
