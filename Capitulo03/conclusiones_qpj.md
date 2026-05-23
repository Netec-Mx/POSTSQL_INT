
# Conclusiones sobre Demo/POC 3.1 Planes de Ejecución del JOIN en PostgreSQL 

<br/><br/>

## 1. Tipo de operación

Identificar cómo está accediendo a los datos

* Seq Scan: lee toda la tabla
* Index Scan: acceso eficiente
* Bitmap Heap Scan
* Nested Loop: cómo se combinan las tablas
* Hash Join
* Merge Join

## 2. Flujo del plan

PostgreSQL ejecuta:

* Primero las líneas más profundas
* Luego sube hasta el nodo raíz

El resultado se construye de abajo hacia arriba

## 3. Costos estimados

`(cost=0.43..5676.04)`

Estos costos son estimados, no reales. Sirven para poder comparar planes

* Primer número es el costo inicial
* Segundo número es el costo total

¿Qué tan caro cree PostgreSQL que será?

## 4. Tiempo real

`(actual time=0.022..63.585)`

¿Qué tan rápido fue realmente?

* Inicio
* Primer registro
* Fin del último registro

## 5. Filas (rows)

* rows=100000 (estimado)
* rows=100000.00 (real)

Comparar siempre estimado vs real. Si hay mucha diferencia, el problema son las estadísticas (ANALYZE)

## 6. Loops

Veces que se ejecuta

* loops=1

¿Cuántas veces se repite esta operación?

## 7. Buffers (memoria vs disco)

Pregunta clave: ¿esto fue RAM o disco?

* Buffers: shared hit=50668

Hit es memoria, usualmente rápido
Read: se fue a disco, usualmente lento

## 8. Condiciones

Las condiciones aparecen como: Filter, Index Cond, Join Cond

* Filter: salario > 5000
* Index Cond: categoria = 'X'
* Merge Cond: e.id = d.id

Diferencia clave:

* Index Cond usa índice
* Filter filtra después

## 9. Operaciones costosas

Aquí buscamos el performance real

Buscamos:

* Seq Scan en tablas grandes
* Sort, y sorts que hayan utilizado disco
* Hash
* Bitmap Heap Scan
* Nested Loop con muchas filas

## 10. Ancho de fila (width)

* width=22

Tamaño estimado por fila en bytes. Entre más grande (más ancho), más memoria y generalmente más lento

## 11. Planning vs Ejecución

¿Dónde está el tiempo realmente?

* Planning casi siempre es pequeño
* Execution es el más importante

```
Planning Time: 0.253 ms
Execution Time: 67.431 ms
```

<br/><br/>

## Cómo leer un Query Plan de forma rápida

1. Tipo de acceso

   * Seq Scan vs Index Scan

2. Tipo de Join

   * Nested / Hash / Merge

3. Filas estimadas vs reales

   * Detectar problemas de estadísticas

4. Buffers

   * Memoria vs disco

5. Tiempo real

   * Dónde se está yendo el tiempo

<br/><br/>

## Script SQL usado

## Paso 1. Preparación del entorno

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

## Paso 2. Carga de datos

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

## Paso 3. Escenario 1 – Sin índices, comportamiento normal

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

## Paso 4. Escenario 2 – Sin índices, forzar Nested Loop

```sql
SET enable_hashjoin = off;
SET enable_mergejoin = off;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```

## Paso 5. Escenario 3 – Sin índices, forzar Merge Join

```sql
SET enable_hashjoin = off;
SET enable_nestloop = off;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```

## Paso 6. Reset de configuración

```sql
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;
```

## Paso 7. Crear índice

```sql
CREATE INDEX idx_emp_depto ON empleados(departamento_id);
```

## Paso 8. Escenario 4 – Con índice, comportamiento normal

```sql
EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```

## Paso 9. Escenario 5 – Con índice, forzar Nested Loop

```sql
SET enable_hashjoin = off;
SET enable_mergejoin = off;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```

## Paso 10. Escenario 6 – Con índice, forzar Merge Join

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


## Resultados comparados

| Escenario               | Mejor plan  | Tiempo aproximado (ms) | Razón                       |
| ----------------------- | ----------- | ---------------------- | --------------------------- |
| Sin índice              | Hash Join   | 69                     | No requiere orden ni índice |
| Sin índice (forzado NL) | Nested Loop | 74                     | Memoize ayuda               |
| Sin índice (forzado MJ) | Merge Join  | 226                    | Sort en disco               |
| Con índice              | Hash Join   | 54                     | Sigue siendo óptimo         |
| Con índice (forzado NL) | Nested Loop | 116                    | Muchas iteraciones          |
| Con índice (forzado MJ) | Merge Join  | 67                     | Índice evita sort           |


<br/><br/>

## Observaciones

* El optimizador sí sabe lo que hace. Hash Join fue elegido naturalmente y fue el mejor. No confíes en tu intuición, confía en PostgreSQL/Planner.
* El índice no siempre mejora el plan. Hash Join no cambió mucho. Crear índices no garantiza cambios en el plan.
* Memoize cambió el juego. Nested Loop no fue tan malo como esperábamos. PostgreSQL optimiza patrones repetitivos automáticamente.
* Merge Join depende del orden. Sin índice hay alto consumo de recursos; con índice se vuelve bastante eficiente.
* La peor cosa que nos puede pasar: SORT + DISK (`Sort Method: external merge`, `temp read/write`). Si vemos esto en los planes, hay un problema.
* Forzar planes es peligroso. Solo para laboratorios, nunca en producción.

<br/><br/>

## Conclusión final

El mejor plan no depende solo del índice, sino del volumen de datos, la distribución y el tipo de operación. PostgreSQL evalúa múltiples estrategias y elige la más barata. Un índice puede mejorar o empeorar un plan dependiendo del contexto, y operadores como Memoize hacen que estrategias clásicamente malas, como Nested Loop, sean viables en escenarios reales.

