


# Demo 3.2: Comparación JOIN vs SUBQUERY vs CTE en PostgreSQL

<br/><br/>

## Objetivo

Al finalizar esta práctica, serás capaz de:

* Comparar el rendimiento de `JOIN`, `subconsultas` y `CTE`
* Analizar planes de ejecución con `EXPLAIN ANALYZE`
* Entender el impacto de los **índices**
* Identificar cuándo una consulta escala mal

<br/><br/>

### Paso 1: Preparación del entorno

```sql
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS categorias;

CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre TEXT
);

CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    categoria_id INT
);
```

<br/><br/>

### Paso 2: Insertar datos

#### Categorías

```sql
INSERT INTO categorias (nombre)
SELECT 'Categoria ' || i
FROM generate_series(1, 10) AS i;
```

<br/><br/>

#### Productos (100,000 registros)

```sql
INSERT INTO productos (nombre, categoria_id)
SELECT 
    'Producto ' || i,
    (random() * 9 + 1)::int
FROM generate_series(1, 100000) AS i;  

-- Juega más adelante y cambia 100000 por 1000000
```

<br/><br/>

### Paso 3: Verificación rápida

```sql
SELECT COUNT(*) FROM productos;
SELECT COUNT(*) FROM categorias;
```

<br/><br/>

## ESCENARIO 1: SIN ÍNDICES


### 1.1 JOIN

```sql
EXPLAIN ANALYZE
SELECT p.nombre
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
WHERE c.nombre = 'Categoria 5';
```

<br/><br/>

### 1.2 SUBCONSULTA

```sql
EXPLAIN ANALYZE
SELECT nombre
FROM productos
WHERE categoria_id IN (
    SELECT id FROM categorias WHERE nombre = 'Categoria 5'
);
```

<br/><br/>

### 1.3 CTE

```sql
EXPLAIN ANALYZE
WITH cat AS (
    SELECT id FROM categorias WHERE nombre = 'Categoria 5'
)
SELECT nombre
FROM productos
WHERE categoria_id IN (SELECT id FROM cat);
```

<br/><br/>

### Observa

* `Seq Scan`
* `Execution Time`
* `Rows Removed by Filter`
* `Buffers`

<br/><br/>

## **Conclusión esperada:**

> Todas son similares (porque no hay índices)

<br/><br/>

## ESCENARIO 2: CON ÍNDICES

<br/><br/>

### Crear índices

```sql
CREATE INDEX idx_productos_categoria ON productos(categoria_id);
CREATE INDEX idx_categorias_nombre ON categorias(nombre);
```

<br/><br/>

### 2.1 JOIN

```sql
EXPLAIN ANALYZE
SELECT p.nombre
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
WHERE c.nombre = 'Categoria 5';
```

<br/><br/>

### 2.2 SUBCONSULTA

```sql
EXPLAIN ANALYZE
SELECT nombre
FROM productos
WHERE categoria_id IN (
    SELECT id FROM categorias WHERE nombre = 'Categoria 5'
);
```

<br/><br/>

### 2.3 CTE

```sql
EXPLAIN ANALYZE
WITH cat AS (
    SELECT id FROM categorias WHERE nombre = 'Categoria 5'
)
SELECT nombre
FROM productos
WHERE categoria_id IN (SELECT id FROM cat);
```

<br/><br/>

### Observa

* `Index Scan` vs `Seq Scan`
* `Bitmap Heap Scan`
* `Buffers: shared hit`
* `Execution Time`

<br/><br/>

## **Conclusión esperada:**

* JOIN y SUBQUERY → muy similares
* CTE → depende si se materializa

<br/><br/>

## ESCENARIO 3: SUBCONSULTA CORRELACIONADA (EL PROBLEMA)


```sql

EXPLAIN ANALYZE
SELECT nombre
FROM productos p
WHERE EXISTS (
    SELECT 1
    FROM categorias c
    WHERE c.id = p.categoria_id
      AND c.nombre = 'Categoria 5'
);

```

<br/><br/>

### Observa

* `Loops`
* Número de ejecuciones del subquery

<br/><br/>

### **Conclusión esperada:**

> Puede ejecutarse miles de veces → peor rendimiento

<br/><br/>

## ESCENARIO 4: FORZAR MATERIALIZACIÓN EN CTE

---

```sql
EXPLAIN ANALYZE
WITH cat AS MATERIALIZED (
    SELECT id FROM categorias WHERE nombre = 'Categoria 5'
)
SELECT nombre
FROM productos
WHERE categoria_id IN (SELECT id FROM cat);
```

<br/><br/>

### Observa

* Se ejecuta primero el CTE
* Puede romper optimización

<br/><br/>

## Tabla de análisis 

| Consulta       | Scan | Tiempo | Uso de índice | Comentario |
| -------------- | ---- | ------ | ------------- | ---------- |
| JOIN           |      |        |               |            |
| SUBQUERY       |      |        |               |            |
| CTE            |      |        |               |            |
| CORRELACIONADA |      |        |               |            |

<br/>

* **Scan:** Busca en el EXPLAIN ANALYZE algo como `Seq Scan`, `Index Scan`, `Bitmap Heap Scan`
* **Tiempo:** Busca en el PLAN `Execution Time: ?? ms`
* **Usp de índice:** Busca el el PLAN si `Index Scan` o `Bitmap Index Scan` o solo `Seq Scan`
* **Comentario:**
    * Usó índice correctamente
    * Hizo Seq Scan porque no hay índice
    * El CTE se materializó
    * La subconsulta fue optimizada como JOIN
    * La correlacionada ejecuta múltiples loops
    * etc.
* No nos interesa que copies el plan, nos interesa que entiendas qué pasó.

<br/><br/>


### Preguntas 

1. ¿Cuál consulta fue más rápida sin índices?
2. ¿Cuál cambió más con índices?
3. ¿El CTE siempre fue igual de rápido?
4. ¿Qué pasó con los `loops` en la correlacionada?
5. ¿Qué operador cambió (Seq Scan vs Index Scan)?

<br/><br/>


# 🏁 Conclusión final

> JOIN y SUBQUERY suelen generar el mismo plan
> CTE depende de su materialización
> Las subconsultas correlacionadas son peligrosas
>
> El verdadero ganador es el **plan de ejecución**

<br/><br/>

## **Notas:**  

Ejecuta dos veces la misma query:

```sql
EXPLAIN ANALYZE SELECT ...
```

> ¿Por qué la segunda vez es más rápida?

* **Buffer Cache (shared hit)**


