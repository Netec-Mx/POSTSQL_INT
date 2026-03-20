

# Demo/POC 3.1 - Planes de Ejecución de JOIN en PostgreSQL

## Objetivo

Al finalizar esta demo, serás capaz de identificar y comparar cómo PostgreSQL ejecuta un JOIN usando:

* Nested Loop
* Hash Join
* Merge Join

y cómo influyen los índices y la configuración del optimizador.

<br/><br/>

###  Paso 1. Preparación del entorno

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


<br/><br/>

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


<br/><br/>

### Paso 3. Escenario 1 – Sin índices, comportamiento normal

```sql

-- Restaura el parámetro a su valor por defecto

RESET enable_hashjoin;  

RESET enable_mergejoin;

RESET enable_nestloop;


EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;

```

#### Resultado esperado

* Hash Join
* PostgreSQL elige Hash Join porque no hay índices y normalmente es el plan más barato.


<br/><br/>

### Paso 4. Escenario 2 – Sin índices, forzar Nested Loop

```sql

-- A nivel de sesión

SET enable_hashjoin = off;

SET enable_mergejoin = off;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;

```

#### Resultado esperado

* Nested Loop
* Se eliminan otras opciones, PostgreSQL usa Nested Loop aunque no sea óptimo.


<br/><br/>

### Paso 5. Escenario 3 – Sin índices, forzar Merge Join

```sql
SET enable_hashjoin = off;
SET enable_nestloop = off;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;
```

#### Resultado esperado

* Merge Join (con Sort)
* Como no hay orden, PostgreSQL debe ordenar antes de hacer el merge.
* o no?

<br/><br/>

### Paso 6. Reset de configuración

```sql

RESET enable_hashjoin;

RESET enable_mergejoin;

RESET enable_nestloop;

```


<br/><br/>

### Paso 7. Crear índice

```sql

CREATE INDEX idx_emp_depto ON empleados(departamento_id);

```


<br/><br/>

### Paso 8. Escenario 4 – Con índice, comportamiento normal

```sql

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;

```

#### Resultado esperado (puede variar)

* Nested Loop + Index Scan
* Hash Join
* Ahora PostgreSQL tiene más opciones y elige la menos costosa.


<br/><br/>

### Paso 9. Escenario 5 – Con índice, forzar Nested Loop

```sql

SET enable_hashjoin = off;

SET enable_mergejoin = off;

EXPLAIN ANALYZE
SELECT e.nombre, d.nombre
FROM empleados e
JOIN departamentos d 
ON e.departamento_id = d.id;

```

#### Resultado esperado

* Nested Loop + Index Scan
* Posible uso de Memoize
* El índice hace eficiente el Nested Loop.


<br/><br/>

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

### Resultado esperado

* Merge Join
* El índice puede ayudar a evitar operaciones de ordenamiento.


<br/><br/>

## Tabla de ayuda

| Tipo de JOIN | Cómo funciona       | Cuándo aparece                |
| ------------ | ------------------- | ----------------------------- |
| Nested Loop  | Itera fila por fila | Tablas pequeñas o con índices |
| Hash Join    | Usa hash en memoria | Sin índices                   |
| Merge Join   | Requiere orden      | Datos ordenados o indexados   |



<br/><br/>


>**Notas importantes**
>
> `SET enable_*` solo afecta la sesión actual
> No se recomienda en producción
> PostgreSQL puede ignorar configuraciones inválidas


<br/><br/>

## Ideas clave que deberíamos de entender al "jugar" con esto

1. El mismo query puede ejecutarse de distintas formas.
2. Los índices no obligan, influyen.
3. PostgreSQL elige el plan más barato, no el más obvio.

