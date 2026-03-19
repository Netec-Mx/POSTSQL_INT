

# DEMO/POC: Tipos RANGE en PostgreSQL

## Objetivo

Comprender cómo usar los tipos de rango en PostgreSQL para modelar intervalos de datos y realizar consultas avanzadas.

<br/><br/>

### 1. Crear tabla con diferentes tipos RANGE

```sql

DROP TABLE IF EXISTS periodos;

CREATE TABLE periodos (
    id SERIAL PRIMARY KEY,
    rango_int4 int4range,
    rango_int8 int8range,
    rango_num numrange,
    rango_ts tsrange,
    rango_tstz tstzrange,
    rango_date daterange
);

```

<br/><br/>

### 2. Insertar datos

```sql

INSERT INTO periodos (
    rango_int4,
    rango_int8,
    rango_num,
    rango_ts,
    rango_tstz,
    rango_date
) 
VALUES
(
    '[1,10)',                    -- incluye 1, excluye 10
    '[10000000000,10000000010]',
    '[10.5,20.75]',
    '[2025-01-01 10:00,2025-01-01 18:00)',
    '[2025-01-01 10:00+00,2025-01-01 18:00+00]',
    '[2025-01-01,2025-01-10]'
);
```

<br/><br/>

### 3. Consultar los datos

```sql

SELECT * FROM periodos;

SELECT count(*) from periodos;

```

<br/><br/>

### 4. ¿Un valor está dentro del rango? (`@>`)

```sql

SELECT *
FROM periodos
WHERE rango_int4 @> 5;

--  ¿El rango contiene el valor 5?

```


<br/><br/>

### 5. ¿Dos rangos se traslapan? (`&&`)

```sql

SELECT *
FROM periodos
WHERE rango_date && '[2025-01-05,2025-01-15]';

-- ¿Se cruzan los periodos?

```


<br/><br/>

### 6. Obtener límites del rango

```sql

SELECT 
    lower(rango_int4) AS inicio,
    upper(rango_int4) AS fin
FROM periodos;


```

<br/><br/>

### 7. Ver si el límite es inclusivo

```sql

SELECT 
    lower_inc(rango_int4) AS incluye_inicio,
    upper_inc(rango_int4) AS incluye_fin
FROM periodos;

```

<br/><br/>

### 8. Caso de negocio 

#### Reservaciones

```sql

SELECT *
FROM periodos
WHERE rango_date && '[2025-01-03,2025-01-04]';

-- Buscamos habitaciones disponibles en estas fechas… 
-- PostgreSQL automáticamente detecta conflictos de fechas

```


<br/><br/>

### 9. Crear índice para mejorar rendimiento

```sql

CREATE INDEX idx_rango_date ON periodos USING GIST (rango_date);

```

<br/><br/>

### 10. Ver uso del índice

```sql

EXPLAIN ANALYZE SELECT * FROM periodos WHERE rango_date && '[2025-01-05,2025-01-15]';

```

<br/><br/>

### TABLAS DE AYUDA 


| Tipo      | Descripción                 |
| --------- | --------------------------- |
| int4range | Rango de enteros            |
| int8range | Rango de enteros grandes    |
| numrange  | Rango de decimales          |
| tsrange   | Rango de timestamp sin zona |
| tstzrange | Rango con zona horaria      |
| daterange | Rango de fechas             |

<br/><br/>

### Operadores clave

| Operador | Significado    | Ejemplo            |  
| -------- | -------------- | ------------------ |  
| @>       | Contiene valor | rango @> 5         |   
| <@       | Está dentro de | 5 <@ rango         |   
| &&       | Se traslapan   | rango1 && rango2   |    
| `-\|-`     | Son adyacentes | rango1 `-\|-` rango2 |


<br/><br/>


### Funciones útiles

| Función     | Descripción      |
| ----------- | ---------------- |
| lower()     | Límite inferior  |
| upper()     | Límite superior  |
| lower_inc() | ¿Incluye inicio? |
| upper_inc() | ¿Incluye fin?    |


<br/><br/>

>**Notas:**
>
> Un RANGE no guarda un valor… guarda un intervalo.
> PostgreSQL entiende matemáticamente ese intervalo, por eso nos permite responder cosas como:
>
> * si algo está dentro
> * si dos periodos chocan
> * si están pegados
>
> Sin que escribir lógica compleja

