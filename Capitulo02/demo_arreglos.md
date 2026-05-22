
# Demo/POC: Uso de Arrays en PostgreSQL (y problemas de modelado)

## Objetivo

Demostrar cómo trabajar con arreglos en PostgreSQL, operadores especializados y funciones, así como evidenciar los problemas de diseño al almacenar arrays como `TEXT`.

<br/><br/>

## Instrucciones

### Paso 1. Preparar el escenario

```sql

-- Tipo ENUM
CREATE TYPE nivel_satisfaccion AS ENUM ('muy_bajo', 'bajo', 'medio', 'alto', 'muy_alto');

-- Limpiar tabla
DROP TABLE IF EXISTS encuestas;

-- NOTA: respuestas está mal modelado (TEXT en lugar de TEXT[])
CREATE TABLE encuestas (
    id SERIAL PRIMARY KEY,
    respuestas TEXT,
    satisfaccion nivel_satisfaccion,
    fecha DATE DEFAULT CURRENT_DATE
);

```


<br/><br/>

### Paso 2. Insertar datos simulados

```sql

INSERT INTO encuestas (respuestas, satisfaccion)
SELECT
    (ARRAY['si', 'no', 'tal vez'])[:(random()*3+1)::int],
    (ARRAY['muy_bajo', 'bajo', 'medio', 'alto', 'muy_alto'])[(random()*4+1)::int]::nivel_satisfaccion
FROM generate_series(1, 500);
```


<br/><br/>

### Paso 3. Exploración inicial

```sql

SELECT COUNT(*) FROM encuestas;

SELECT * FROM encuestas LIMIT 10;

```


<br/><br/>

### Paso 4. Índice 

```sql

CREATE INDEX idx_respuestas_satisfaccion 
ON encuestas (respuestas, satisfaccion);

```

```sql
EXPLAIN ANALYZE 
SELECT * 
FROM encuestas 
WHERE satisfaccion = 'muy_alto';
```

>**Nota:** 
* Este índice **sí ayuda para `satisfaccion`**, pero no para búsquedas sobre arrays.


<br/><br/>

### Paso 5. Análisis por negocio

#### ¿Cuántas encuestas por nivel?

```sql

SELECT satisfaccion, COUNT(*) 
FROM encuestas
GROUP BY satisfaccion
ORDER BY satisfaccion;
```


<br/><br/>

#### Distribución porcentual

```sql
SELECT 
    satisfaccion,
    COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS porcentaje
FROM encuestas
GROUP BY satisfaccion
ORDER BY satisfaccion;
```

>**Observación:**
* GROUP BY
* Funciones de agregación 
* Window functions (OVER())
* Calulamos el total de encuentas por nivel de satisfacción
* Además el porcentaje que representa cada nivel respecto al total
* OVER() convierte una función (SUM, AVG, COUNT, ete.) en una window function, es decir, calcula un valor sobre un conjunto de filas (window/ventana) sin agruparlas o colapsarlar.
* OVER() sin nada, no divide los datos, usa todas las filas para el resultado, es una ventana global
* Fórmula: porcentaje = (parte / total) * 100
* 80/ 500 * 100 = 16%


<br/><br/>

### Paso 6. Uso de operadores de arrays (con CAST)

#### Contiene “si”

```sql
SELECT COUNT(*)
FROM encuestas
WHERE respuestas::TEXT[] @> ARRAY['si'];
```

<br/><br/>

#### Intersección (overlap)

```sql
SELECT COUNT(*)
FROM encuestas
WHERE respuestas::TEXT[] && ARRAY['no','tal vez'];
```

<br/><br/>

#### Validación adicional (evitar NULL)

```sql
SELECT COUNT(*)
FROM encuestas
WHERE 
    respuestas IS NOT NULL
    AND respuestas::TEXT[] @> ARRAY['si'];
```

<br/><br/>

### Paso 7. Alternativas de búsqueda

#### Uso de ANY

```sql
SELECT COUNT(*)
FROM encuestas
WHERE 'si' = ANY(respuestas::TEXT[]);
```

<br/><br/>

#### Uso de EXISTS + unnest

```sql
SELECT COUNT(*)
FROM encuestas
WHERE EXISTS (
    SELECT 1
    FROM unnest(respuestas::TEXT[]) r
    WHERE r IN ('no','tal vez')
);
```

<br/><br/>

### Paso 8. Explotar el arreglo (unnest)

```sql
SELECT r, COUNT(*)
FROM encuestas,
LATERAL unnest(respuestas::TEXT[]) AS r
GROUP BY r
ORDER BY COUNT(*) DESC;
```

>**Observación:**
* Esto convierte el arreglo en filas (muy útil para analytics)

<br/><br/>


## Conclusión (mensaje clave para clase)

* PostgreSQL **sí soporta arrays de forma nativa**
* Pero **si los guardas como TEXT, se pierden:**

<br/><br/>

## Tabla de ayuda: Arrays en PostgreSQL

| Concepto / Operador | ¿Para qué sirve?                | Ejemplo                           |
| ------------------- | ------------------------------- | --------------------------------- |
| `ARRAY[...]`        | Crear un arreglo                | `ARRAY['si','no']`                |
| `@>`                | Contiene                        | `ARRAY['si','no'] @> ARRAY['si']` |
| `<@`                | Está contenido en               | `ARRAY['si'] <@ ARRAY['si','no']` |
| `&&`                | Intersección (overlap)          | `ARRAY['si'] && ARRAY['si','no']` |
| `ANY`               | Buscar valor dentro del array   | `'si' = ANY(respuestas)`          |
| `unnest()`          | Convertir array en filas        | `SELECT unnest(ARRAY['a','b'])`   |
| `LATERAL`           | Permite usar funciones por fila | `FROM tabla, LATERAL unnest(...)` |
| `::TEXT[]`          | Cast a array                    | `respuestas::TEXT[]`              |
| `generate_series()` | Generar datos                   | `generate_series(1,100)`          |

<br/><br/>

