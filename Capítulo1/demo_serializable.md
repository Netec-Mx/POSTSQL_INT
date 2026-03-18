#  Demo: Nivel de Aislamiento SERIALIZABLE en PostgreSQL

<br/><br/>

## Objetivo

Comprender cómo PostgreSQL maneja concurrencia en nivel **SERIALIZABLE**, detectando conflictos y evitando inconsistencias.

<br/><br/>

## Duración estimada

20 minutos

<br/><br/>

## Preparación (una sola vez)

```sql
DROP TABLE IF EXISTS productos;

CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    stock INT
);

INSERT INTO productos (nombre, stock)
VALUES ('Laptop', 10);

SELECT * FROM productos;
```

<br/><br/>

## Escenario: Dos sesiones concurrentes

Abre **dos terminales de psql**:

* Sesión A
* Sesión B

<br/><br/>

## Paso 1: Sesión A inicia transacción

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT stock FROM productos WHERE id = 1;

SELECT * FROM productos;

```


>**Nota:**: 
* Se crea un **snapshot**
* Esta transacción “ve” el valor 10

<br/><br/>

## Paso 2: Sesión B inicia transacción

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT stock FROM productos WHERE id = 1;

```


>**Nota:** Ambas sesiones ven el mismo valor, aunque una ya pueda modificarlo después.


<br/><br/>


## Paso 3: Sesión A actualiza

```sql
UPDATE productos
SET stock = stock - 8
WHERE id = 1;
```

>**Nota:** Aún NO se hace COMMIT

<br/><br/>

## Paso 4: Sesión B también actualiza

```sql
UPDATE productos
SET stock = stock - 5
WHERE id = 1;
```

>**Nota:** Aún tampoco se hace COMMIT


<br/><br/>


## Paso 5: Sesión B hace COMMIT

```sql
COMMIT;
```

>**Nota:** Esta transacción normalmente se confirma correctamente

<br/><br/>

## Paso 6: Sesión A intenta COMMIT

```sql
COMMIT;
```

<br/><br/>

## Resultado esperado:

```
ERROR: could not serialize access due to concurrent update
```


### ¿Qué pasó?

* Ambas transacciones leyeron: el valor de `stock`
* Ambas intentaron modificar basado en ese valor
* Si ambas se confirmaran, por ejemplo:
* 10 - 8 - 5 = -3 Error a nivel de negocio, inconsistencia


### ¿Qué hace PostgreSQL?

✔ Detecta el conflicto
✔ Cancela una transacción.


<br/>

### Concepto clave: SERIALIZABLE

PostgreSQL garantiza que:

> El resultado es como si las transacciones se ejecutaran **una después de otra**, no en paralelo.

<br/><br/>


### Diferencia importante 

| Motor                | Estrategia                      |
| -------------------- | ------------------------------- |
| Oracle (tradicional) | Bloqueos                        |
| PostgreSQL           | **MVCC + validación optimista** |


<br/><br/>

### MVCC (recordatorio corto)

* Cada transacción ve una **versión consistente**
* No bloquea lecturas
* Permite alta concurrencia
* Detecta conflictos **al final (COMMIT)**
* Una transacción puede fallar, debes reintentarla


<br/><br/>

## Ejemplo de reintento 

```sql
-- pseudológica
LOOP
  BEGIN;
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

  -- lógica de negocio

  COMMIT;
  EXIT;
EXCEPTION
  WHEN serialization_failure THEN
    ROLLBACK;
END LOOP;
```

<br/><br/>

## Conclusión para mi clase

* SERIALIZABLE **no evita conflictos**
* SERIALIZABLE **los detecta**
* PostgreSQL usa enfoque moderno (**optimista**)
* Las aplicaciones deben manejar **reintentos**
* ¿Cuáles otros niveles de aislamiento en las transacciones hay en PostgreSQL?
