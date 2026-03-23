
# Conclusiones sobre Demo/POC 3.1

## Planes de Ejecución del JOIN en PostgreSQL 

<br/><br/>

## 1. Tipo de operación

Identificar cómo está accediendo a los datos

* Seq Scan: lee toda la tabla
* Index Scan: acceso eficiente
* Bitmap Heap Scan
* Nested Loop: cómo se combinan las tablas
* Hash Join
* Merge Join

<br/><br/>

## 2. Flujo del plan

PostgreSQL ejecuta:

* Primero las líneas más profundas
* Luego sube hasta el nodo raíz

El resultado se construye de abajo hacia arriba.

<br/><br/>

## 3. Costos estimados

```
(cost=0.43..5676.04)
```

Estos costos son estimados, no reales. Sirven para comparar planes.

* Primer número: costo inicial
* Segundo número: costo total

Pregunta clave:
¿Qué tan caro cree PostgreSQL que será?

<br/><br/>

## 4. Tiempo real

```
(actual time=0.022..63.585)
```

¿Qué tan rápido fue realmente?

* Inicio
* Primer registro
* Fin último registro

<br/><br/>

## 5. Filas (rows)

```
rows=100000 (estimado)
rows=100000.00 (real)
```

Comparar siempre estimado vs real.

Si hay mucha diferencia, el problema son las estadísticas (`ANALYZE`).

<br/><br/>

## 6. Loops

Veces que se ejecuta:

```
loops=1
```

¿Cuántas veces se repite esta operación?

<br/><br/>

## 7. Buffers (memoria vs disco)

Pregunta clave: ¿esto fue RAM o disco?

```
Buffers: shared hit=50668
```

* hit: memoria (rápido)
* read: disco (lento)

<br/><br/>

## 8. Condiciones

Las condiciones aparecen como:

* Filter
* Index Cond
* Join Cond

Ejemplos:

```
Filter: salario > 5000
Index Cond: categoria = 'X'
Merge Cond: e.id = d.id
```

Diferencia clave:

* Index Cond → usa índice
* Filter → filtra después

<br/><br/>

## 9. Operaciones costosas

Buscar:

* Seq Scan en tablas grandes
* Sort (especialmente en disco)
* Hash
* Bitmap Heap Scan
* Nested Loop con muchas filas

<br/><br/>

## 10. Ancho de fila (width)

```
width=22
```

Tamaño estimado por fila en bytes.

A mayor tamaño:

* Más memoria
* Generalmente más lento

<br/><br/>

## 11. Planning vs Ejecución

```
Planning Time: 0.253 ms
Execution Time: 67.431 ms
```

* Planning casi siempre es pequeño
* Execution es lo importante

<br/><br/>

# Cómo leer un Query Plan de forma rápida

1. Tipo de acceso
   Seq Scan vs Index Scan

2. Tipo de Join
   Nested / Hash / Merge

3. Filas estimadas vs reales
   Detectar problemas de estadísticas

4. Buffers
   Memoria vs disco

5. Tiempo real
   Dónde se está yendo el tiempo

<br/><br/>

# Script SQL usado

### Paso 1. Preparación del entorno

```sql
DROP TABLE IF EXISTS empleados;
DROP TABLE IF EXISTS departamentos;

CREATE TABLE departamentos (
    id SERIAL PRIMARY KEY,
    nombre TEXT
);

CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    departamento_id INT
);
```


### Paso 2. Carga de datos

```sql
INSERT INTO departamentos (nombre)
SELECT 'Depto ' || i
FROM generate_series(1, 100) i;

INSERT INTO empleados (nombre, departamento_id)
SELECT 
    'Empleado ' || i,
    (random()*99 + 1)::int
FROM generate_series(1, 100000) i;
```

### Paso 3. Sin índices (comportamiento normal)

```sql
RESET enable_hashjoin;  
RESET enable_mergejoin;
RESET enable_nestloop;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```

### Paso 4. Forzar Nested Loop

```sql
SET enable_hashjoin = off;
SET enable_mergejoin = off;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```


### Paso 5. Forzar Merge Join

```sql
SET enable_hashjoin = off;
SET enable_nestloop = off;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```

### Paso 6. Reset

```sql
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;
```

### Paso 7. Crear índice

```sql
CREATE INDEX idx_emp_depto ON empleados(departamento_id);
```


### Paso 8. Con índice (normal)

```sql
EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```


### Paso 9. Con índice forzando Nested Loop

```sql
SET enable_hashjoin = off;
SET enable_mergejoin = off;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```

### Paso 10. Con índice forzando Merge Join

```sql
SET enable_hashjoin = off;
SET enable_nestloop = off;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```

<br/><br/>

### Resultados comparados

| Escenario                | Mejor plan  | Tiempo (ms) | Razón                       |
| ------------------------ | ----------- | ----------- | --------------------------- |
| Sin índice               | Hash Join   | 69          | No requiere orden ni índice |
| Sin índice (Nested Loop) | Nested Loop | 74          | Memoize ayuda               |
| Sin índice (Merge Join)  | Merge Join  | 226         | Sort en disco               |
| Con índice               | Hash Join   | 54          | Sigue siendo óptimo         |
| Con índice (Nested Loop) | Nested Loop | 116         | Muchas iteraciones          |
| Con índice (Merge Join)  | Merge Join  | 67          | Índice evita sort           |


<br/><br/>

### Observaciones

* El optimizador elige correctamente: Hash Join fue el mejor
* El índice no siempre mejora el plan
* Memoize mejora Nested Loop significativamente
* Merge Join depende del orden
* Sort en disco es señal de problema
* Forzar planes es solo para laboratorio

<br/><br/>

### Conclusión final

El mejor plan no depende solo del índice, sino del volumen de datos, la distribución y el tipo de operación.

PostgreSQL evalúa múltiples estrategias y elige la más barata.

Un índice puede mejorar o empeorar un plan dependiendo del contexto, y operadores como Memoize hacen viables estrategias que tradicionalmente eran consideradas ineficientes.