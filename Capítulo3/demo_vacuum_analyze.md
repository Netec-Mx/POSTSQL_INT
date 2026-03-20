

# **Demo 3.3: ANALYZE vs VACUUM en PostgreSQL**


### **1. Preparación del entorno**

```sql

DROP TABLE IF EXISTS empleados;

CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    salario NUMERIC
);

INSERT INTO empleados (nombre, salario)
SELECT 
    'Empleado ' || i,
    (random() * 10000)::numeric
FROM generate_series(1, 1000000) i;

-- COMMIT;

```

<br/><br/>

### **2. Estado inicial**

```sql
SELECT count(*) FROM empleados;

SELECT * FROM empleados LIMIT 10;

```

### Estadísticas de columnas (ANTES)

```sql

SELECT 
    attname,
    n_distinct,
    most_common_vals,
    histogram_bounds
FROM pg_stats
WHERE tablename = 'empleados';

```

* Estadísticas vacías o poco representativas

<br/><br/>

### **3. Generar problema real (bloat + stats desactualizadas)**

```sql

UPDATE empleados
SET salario = salario * 10
WHERE id <= 500000;

UPDATE empleados
SET nombre = nombre || '---------------------------------------------------------------- 10';

UPDATE empleados
SET nombre = nombre || repeat('X', 100);

DELETE FROM empleados
WHERE id <= 100000;

-- COMMIT;

```

* MUCHAS versiones muertas (dead tuples)
* Estadísticas incorrectas

<br/><br/>

### **4. Validación ANTES de ANALYZE**


```sql
EXPLAIN ANALYZE
SELECT *
FROM empleados
WHERE salario > 500000;
```

<br/>
 
* Estimación vs realidad (rows)
* El optimizador está “ciego”

<br/><br/>

### Estadísticas actuales

```sql

SELECT 
    attname,
    n_distinct,
    most_common_vals,
    histogram_bounds
FROM pg_stats
WHERE tablename = 'empleados';

```

* Siguen sin reflejar los cambios

<br/><br/>

### **5. Ejecutar ANALYZE**

```sql
ANALYZE empleados;
```

<br/><br/>

### **6. Validación DESPUÉS de ANALYZE**

#### Estadísticas actualizadas

```sql
SELECT 
    attname,
    n_distinct,
    most_common_vals,
    histogram_bounds
FROM pg_stats
WHERE tablename = 'empleados';
```

<br/>

* histogram_bounds cambia
* distribución más realista

<br/><br/>


### Plan de ejecución mejorado

```sql
EXPLAIN ANALYZE
SELECT *
FROM empleados
WHERE salario > 50000;
```

* Mejor estimación de filas
* Posible cambio de plan

<br/><br/>

### CLAVE DIDÁCTICA

* ANALYZE NO libera espacio
* ANALYZE SOLO mejora decisiones del optimizador

<br/><br/>

### **7. Validación ANTES de VACUUM**

#### Tuplas vivas vs muertas

```sql
SELECT 
    n_live_tup,
    n_dead_tup
FROM pg_stat_user_tables
WHERE relname = 'empleados';
```

* MUCHOS `n_dead_tup`

<br/><br/>

### **8. Ejecutar VACUUM**

```sql

VACUUM ANALYZE empleados;

```

<br/><br/>

### **9. Validación DESPUÉS de VACUUM**

#### Dead tuples

```sql
SELECT 
    n_live_tup,
    n_dead_tup
FROM pg_stat_user_tables
WHERE relname = 'empleados';
```

* `n_dead_tup` deberá de bajar, casi 0 o 0 

<br/><br/>

### Tamaño 

```sql
SELECT 
    pg_size_pretty(pg_relation_size('empleados')) AS tabla,
    pg_size_pretty(pg_indexes_size('empleados')) AS indices,
    pg_size_pretty(pg_total_relation_size('empleados')) AS total;
```

* NO cambia el tamaño
* solo se libera espacio interno reutilizable

<br/><br/>


### **10. VACUUM FULL (compactación real)**

```sql
VACUUM FULL empleados;
```

<br/><br/>

### **11. Validación DESPUÉS de VACUUM FULL**

```sql
SELECT 
    pg_size_pretty(pg_relation_size('empleados')) AS tabla,
    pg_size_pretty(pg_indexes_size('empleados')) AS indices,
    pg_size_pretty(pg_total_relation_size('empleados')) AS total;
```

* tamaño debería decrecer

<br/><br/>

### **12. Monitoreo avanzado (lo importante en producción)**

#### Estado de autovacuum

```sql
SHOW autovacuum;
```

<br/><br/>

### Configuración relevante

```sql
-- frecuencia de activación
-- autovacuum_vacuum_threshold = 50
-- autovacuum_vacuum_scale_factor = 0.2
```

<br/><br/>

### Ajuste fino por tabla

```sql

ALTER TABLE empleados SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_vacuum_threshold = 10
);

```

 

 
