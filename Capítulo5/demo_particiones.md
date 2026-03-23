
# Práctica5.2 Particionamiento en PostgreSQL

## Tabla de ayuda: Particionamiento en PostgreSQL


| Concepto | Descripción |
|----------|------------|
| Tabla particionada | Tabla lógica que no almacena datos, solo dirige las operaciones |
| Partición | Tabla física donde realmente se almacenan los datos |
| Clave de partición | Columna que define cómo se distribuyen los datos |
| LIST | Divide por valores específicos (categorías) |
| RANGE | Divide por rangos (fechas o números) |
| HASH | Usa función hash para distribuir uniformemente |
| Inserción automática | PostgreSQL decide en qué partición insertar |
| Partition pruning | El optimizador evita leer particiones innecesarias |
| Índice particionado | Índice definido en la tabla padre que se replica en cada partición |
| Estadísticas | Cada partición tiene sus propios histogramas |
| Distribución de datos | Cómo se reparten los registros entre particiones |
| Mantenimiento | Se pueden administrar particiones de forma independiente |
| Escalabilidad | Permite manejar grandes volúmenes de datos eficientemente |
| Error común | No usar la clave de partición en consultas |
| Error común | Pensar que existen índices globales |



<br/><br/>

## 1. Limpieza inicial

```sql
DROP TABLE IF EXISTS empleados CASCADE;
DROP TABLE IF EXISTS logs CASCADE;
DROP TABLE IF EXISTS ventas CASCADE;
````

<br/><br/>

## 2. Particionamiento por LIST

### Crear tabla principal

```sql
CREATE TABLE empleados (
    id SERIAL,
    nombre TEXT,
    departamento TEXT
) PARTITION BY LIST (departamento);
```

### Crear particiones

```sql
CREATE TABLE empleados_ventas
PARTITION OF empleados
FOR VALUES IN ('ventas');

CREATE TABLE empleados_finanzas
PARTITION OF empleados
FOR VALUES IN ('finanzas');

CREATE TABLE empleados_marketing
PARTITION OF empleados
FOR VALUES IN ('marketing');
```

### Insertar datos

```sql
INSERT INTO empleados (nombre, departamento) VALUES
('Hugo', 'ventas'),
('Paco', 'finanzas'),
('Luis', 'marketing'),
('Greta', 'ventas');
```

### Validar distribución

```sql
SELECT tableoid::regclass AS particion, *
FROM empleados;
```


### Prueba sin índice

```sql
EXPLAIN ANALYZE 
SELECT * 
FROM empleados 
WHERE departamento = 'Ventas';
```

### Crear índice

```sql
CREATE INDEX ind_empleados_depto 
ON empleados(departamento);

-- Tipo de índice creado

SELECT 
    tablename,
    indexname
FROM pg_indexes
WHERE tablename LIKE 'empleados%';

```

### Prueba con índice

```sql
EXPLAIN ANALYZE 
SELECT * 
FROM empleados 
WHERE departamento = 'ventas';
```

### Generar estadísticas

```sql
ANALYZE;
```

### Ver histogramas

```sql
SELECT 
    tablename,
    attname,
    histogram_bounds
FROM pg_stats
WHERE tablename = 'empleados';
```

<br/><br/>

## 3. Particionamiento por RANGE

### Crear tabla

```sql
CREATE TABLE ventas (
    id SERIAL,
    fecha_venta DATE NOT NULL,
    producto_id INT,
    cantidad INT,
    precio NUMERIC(10,2)
) PARTITION BY RANGE (fecha_venta);
```

### Crear particiones

```sql
CREATE TABLE ventas_2025_01 PARTITION OF ventas
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE ventas_2025_02 PARTITION OF ventas
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE ventas_2025_07 PARTITION OF ventas
FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
```

### Insertar datos

```sql
INSERT INTO ventas (fecha_venta, producto_id, cantidad, precio) VALUES
('2025-01-15', 101, 2, 50),
('2025-02-10', 102, 1, 120),
('2025-07-03', 103, 3, 25);
```

### Validar distribución

```sql
SELECT tableoid::regclass AS particion, *
FROM ventas;
```

### Ver histogramas

```sql
SELECT 
    tablename,
    attname,
    histogram_bounds
FROM pg_stats
WHERE tablename = 'ventas';
```

<br/><br/>

## 4. Particionamiento por HASH

### Crear tabla

```sql
CREATE TABLE logs (
    id SERIAL,
    mensaje TEXT
) PARTITION BY HASH (id);
```

### Crear particiones

```sql
CREATE TABLE logs_p0 PARTITION OF logs
FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE logs_p1 PARTITION OF logs
FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE logs_p2 PARTITION OF logs
FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE logs_p3 PARTITION OF logs
FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### Insertar datos

```sql
INSERT INTO logs (mensaje) VALUES
('Login usuario'),
('Error sistema'),
('Carga archivo'),
('Cambio contraseña'),
('Login usuario2'),
('Error sistema2'),
('Carga archivo2'),
('Cambio contraseña2');
```

### Validar distribución

```sql
SELECT tableoid::regclass AS particion, *
FROM logs 
ORDER BY 1;
```

### Ver función hash

```sql
SELECT hashint4(10);
```

### Ver histogramas

```sql
SELECT 
    tablename,
    attname,
    histogram_bounds
FROM pg_stats
WHERE tablename = 'logs';
```

<br/><br/>

## 5. Metadata del particionamiento

### Tablas particionadas

```sql
SELECT relname, relkind
FROM pg_class
WHERE relkind = 'p';
```

### Relación padre-hijo

```sql
SELECT
    parent.relname AS tabla_padre,
    child.relname AS particion
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child  ON pg_inherits.inhrelid = child.oid
ORDER BY tabla_padre;
```

### Definición de particiones

```sql
SELECT
    relname,
    pg_get_expr(relpartbound, oid) AS definicion
FROM pg_class
WHERE relpartbound IS NOT NULL;
```

### Tipo de partición

```sql
SELECT
    partrelid::regclass AS tabla,
    partstrat AS tipo,
    partnatts AS num_columnas
FROM pg_partitioned_table;
```


### Tamaño por partición

```sql
SELECT
    relname,
    pg_size_pretty(pg_total_relation_size(oid)) AS tamaño
FROM pg_class
WHERE relname LIKE 'empleados_%'
   OR relname LIKE 'ventas_%'
   OR relname LIKE 'logs_%'
ORDER BY tamaño DESC;
```

<br/><br/>

## 6. Partition Pruning

### Consulta con filtro

```sql
EXPLAIN ANALYZE
SELECT *
FROM ventas
WHERE fecha_venta = '2025-01-15';
```

### Consulta sin filtro

```sql
EXPLAIN ANALYZE
SELECT *
FROM ventas;
```

<br/><br/>

# Resultado esperado

* Inserciones en la partición correcta
* Identificación de partición con tableoid
* Estadísticas disponibles en pg_stats
* Relaciones visibles en pg_inherits
* Uso de partition pruning en consultas con filtro


