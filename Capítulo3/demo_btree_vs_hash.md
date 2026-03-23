
# Demo/POCs para probar BTREE vs HASH

### 1. Crear tabla

```sql

DROP TABLE IF EXISTS demo_indices;

CREATE TABLE demo_indices (
    id BIGSERIAL PRIMARY KEY,
    codigo TEXT NOT NULL,
    relleno TEXT NOT NULL
);

```

<br/><br/>

### 2. Cargar datos

Aquí generamos muchos valores repetibles y una columna `relleno` para que la tabla no sea tan pequeña.

```sql

INSERT INTO demo_indices (codigo, relleno)
SELECT
    'COD-' || lpad((i % 500000)::text, 6, '0'),
    repeat(md5(i::text), 4)
FROM generate_series(1, 3000000) AS i;

```

Esto crea 3 millones de filas y 500 mil códigos distintos, así que cada código aparece varias veces.

<br/><br/>

### 3. Estadísticas

```sql

ANALYZE demo_indices;

```

<br/><br/>

### 4. Consulta base sin índice

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo = 'COD-123456';

-- Aquí normalmente veremos **Seq Scan**.

```

<br/><br/>

## Escenario A. Uso de B-tree

### 5. Crear índice B-tree

```sql

CREATE INDEX idx_demo_codigo_btree ON demo_indices (codigo);

ANALYZE demo_indices;
```

<br/><br/>


### 6. Empujar al optimizador a usar índice

```sql

SET enable_seqscan = off;
SET enable_bitmapscan = on;
SET enable_indexscan = on;

```

Ahora prueba:

```sql

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo = 'COD-123456';

```

Lo usual aquí es ver algo como:
* `Index Scan using idx_demo_codigo_btree`, o
* `Bitmap Index Scan + Bitmap Heap Scan`

<br/><br/>


### 7. Medir varias veces

```sql

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo = 'COD-123456';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo = 'COD-123456';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo = 'COD-123456';

```

La primera vez puede tardar más por lectura física o por cache frío; luego normalmente baja.

<br/><br/>


### 8. Medir tamaño del índice B-tree

```sql

SELECT 'btree' AS tipo,
    pg_size_pretty(pg_relation_size('idx_demo_codigo_btree')) AS tam_indice;

```

<br/><br/>


## Escenario B: Hash

### 9. Quitar B-tree

```sql

DROP INDEX IF EXISTS idx_demo_codigo_btree;

```

<br/><br/>

### 10. Crear índice Hash

```sql

CREATE INDEX idx_demo_codigo_hash ON demo_indices USING hash (codigo);

ANALYZE demo_indices;
```


Los índices hash están orientados a búsquedas por igualdad `=` y pueden ser más pequeños cuando indexan valores largos, porque almacenan el valor hash y no el valor completo. También son “lossy” y no sirven para rangos ni unicidad. 

<br/><br/>


### 11. Forzar que no haga Seq Scan

```sql

SET enable_seqscan = off;
SET enable_bitmapscan = on;
SET enable_indexscan = on;

```

Ahora ejecuta:

```sql

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo = 'COD-123456';

```

>**Nota:**
* Bitmap Index Scan on idx_demo_codigo_hash.
* Bitmap Heap Scan on demo_indices.
* Con hash es común ver más el camino bitmap.

<br/><br/>

### 12. Medir varias veces

```sql

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo = 'COD-123456';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo = 'COD-123456';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo = 'COD-123456';

```

<br/><br/>

### 13. Medir tamaño del índice Hash

```sql
SELECT
    'hash' AS tipo,
    pg_size_pretty(pg_relation_size('idx_demo_codigo_hash')) AS tam_indice;
```

<br/><br/>

# Escenario C: demostrar que Hash no sirve para rangos

### 14. Con Hash, probar rango

```sql

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo > 'COD-123456';

```

Aunque exista el índice hash, no debería ayudarte para eso, porque hash solo soporta `=`. 

<br/><br/>

### 15. Cambiar a B-tree y repetir

```sql

DROP INDEX IF EXISTS idx_demo_codigo_hash;

CREATE INDEX idx_demo_codigo_btree
ON demo_indices (codigo);

ANALYZE demo_indices;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM demo_indices
WHERE codigo > 'COD-123456';

```

<br/><br/>

### Consulta resumen para comparar tamaños

```sql

SELECT
    c.relname AS indice,
    pg_size_pretty(pg_relation_size(c.oid)) AS tamano
FROM pg_class c
WHERE c.relname IN ('idx_demo_codigo_btree', 'idx_demo_codigo_hash');

```

<br/><br/>

### En B-tree

Buscamos si aparece:

* Index Scan
* Bitmap Index Scan
* menos o más `Buffers`
* tiempo total de ejecución

### En Hash

Buscamos si aparece:

* `Bitmap Index Scan on idx_demo_codigo_hash`
* `Bitmap Heap Scan`
* tiempo total
* tamaño del índice

<br/><br/>

# Conclusión esperada de la POC

| Caso                | Resultado esperado                                               |
| ------------------- | ---------------------------------------------------------------- |
| Sin índice          | `Seq Scan`, más tiempo                                           |
| Con B-tree y `=`    | Muy buen desempeño, flexible                                     |
| Con Hash y `=`      | Puede competir bien en igualdad, especialmente en tablas grandes |
| Con Hash y rangos   | No ayuda                                                         |
| Con B-tree y rangos | Sí ayuda                                                         |

