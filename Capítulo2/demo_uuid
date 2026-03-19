

# Demo/POC – Uso de UUID como Llave Primaria en PostgreSQL

<br/><br/>

## Objetivo

Al finalizar esta práctica, serás capaz de:

* Crear tablas utilizando UUID como llave primaria
* Generar UUID automáticamente en PostgreSQL
* Comparar UUID contra SERIAL / IDENTITY
* Entender en qué escenarios es recomendable usar UUID

<br/><br/>

## Instrucciones

### Paso 1. Habilitar extensión para UUID

```sql

CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

Esto habilita la función:

```sql

select gen_random_uuid();
select gen_random_uuid();
select gen_random_uuid();
```

<br/><br/>

### Paso 2. Crear tablas comparativas

```sql

DROP TABLE IF EXISTS usuarios_serial;
DROP TABLE IF EXISTS usuarios_uuid;

-- Tabla tradicional
CREATE TABLE usuarios_serial (
    id SERIAL PRIMARY KEY,
    nombre TEXT
);

-- Tabla con UUID
CREATE TABLE usuarios_uuid (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT
);
```

<br/><br/>

### Paso 3. Insertar datos

```sql

-- Tabla con SERIAL
INSERT INTO usuarios_serial (nombre)
VALUES ('Hugo'), ('Paco'), ('Luis');

-- Tabla con UUID
INSERT INTO usuarios_uuid (nombre)
VALUES ('Hugo'), ('Paco'), ('Luis');

```

<br/><br/>

## Paso 4. Consultar resultados

```sql

SELECT * FROM usuarios_serial;

SELECT * FROM usuarios_uuid;
```

> **Observaciones:**

* SERIAL genera valores incrementales
* UUID genera valores únicos no secuenciales

<br/><br/>

### Paso 5. Inserción manual de UUID

```sql
INSERT INTO usuarios_uuid (id, nombre)
VALUES ('a1b2c3d4-e5f6-7890-1234-567890abcdef', 'Everardo');
```

<br/><br/>

### Paso 6. Verificar estructura de la tabla

```sql
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'usuarios_uuid';
```

<br/><br/>


## Conclusión

UUID no reemplaza a SERIAL en todos los casos.

UUID es recomendable cuando:
* Se trabaja con microservicios
* Existen múltiples fuentes de inserción
* Se requiere evitar colisiones globales

SERIAL o IDENTITY es recomendable cuando:
* El sistema es monolítico
* Se requiere orden secuencial
* Se prioriza rendimiento en índices



<br/><br/>


## Tablas de ayuda – UUID en PostgreSQL

### Funciones y generación

| Elemento                       | ¿Para qué sirve?                                       | Ejemplo                         |
| ------------------------------ | ------------------------------------------------------ | ------------------------------- |
| `gen_random_uuid()`            | Genera un UUID versión 4 (aleatorio) usando `pgcrypto` | `SELECT gen_random_uuid();`     |
| `uuid_generate_v4()`           | Genera UUID v4 usando `uuid-ossp`                      | `SELECT uuid_generate_v4();`    |
| `uuid_generate_v1()`           | UUID basado en tiempo + MAC (menos usado)              | `SELECT uuid_generate_v1();`    |
| `CREATE EXTENSION pgcrypto`    | Habilita funciones modernas de UUID                    | `CREATE EXTENSION pgcrypto;`    |
| `CREATE EXTENSION "uuid-ossp"` | Alternativa para generar UUID                          | `CREATE EXTENSION "uuid-ossp";` |

<br/><br/>

## Definición en tablas

| Elemento                    | ¿Para qué sirve?                                   | Ejemplo                             |
| --------------------------- | -------------------------------------------------- | ----------------------------------- |
| `UUID`                      | Tipo de dato para almacenar identificadores únicos | `id UUID`                           |
| `DEFAULT gen_random_uuid()` | Genera automáticamente el UUID al insertar         | `id UUID DEFAULT gen_random_uuid()` |
| `PRIMARY KEY`               | Define el UUID como llave primaria                 | `id UUID PRIMARY KEY`               |

<br/><br/>

## Inserción de datos

| Elemento             | ¿Para qué sirve?                   | Ejemplo                                                     |
| -------------------- | ---------------------------------- | ----------------------------------------------------------- |
| Inserción automática | PostgreSQL genera el UUID          | `INSERT INTO tabla(nombre) VALUES ('Hugo');`                |
| Inserción manual     | Permite definir un UUID específico | `INSERT INTO tabla(id, nombre) VALUES ('uuid...', 'Paco');` |

<br/><br/>

## Consultas y operadores

| Elemento   | ¿Para qué sirve?                    | Ejemplo                      |
| ---------- | ----------------------------------- | ---------------------------- |
| `=`        | Comparar UUID exacto                | `WHERE id = 'uuid...'`       |
| `::uuid`   | Convertir texto a UUID              | `WHERE id = 'uuid...'::uuid` |
| `ORDER BY` | Ordenar (no recomendado en UUID v4) | `ORDER BY id`                |


<br/><br/>

## Conversión y manipulación

| Elemento            | ¿Para qué sirve?        | Ejemplo                       |
| ------------------- | ----------------------- | ----------------------------- |
| `::text`            | Convertir UUID a texto  | `SELECT id::text FROM tabla;` |
| `CAST(... AS UUID)` | Convertir string a UUID | `CAST('uuid...' AS UUID)`     |


<br/><br/>

## Índices

| Elemento       | ¿Para qué sirve?            | Ejemplo                             |
| -------------- | --------------------------- | ----------------------------------- |
| `CREATE INDEX` | Crear índice sobre UUID     | `CREATE INDEX idx_id ON tabla(id);` |
| `PRIMARY KEY`  | Crea índice automáticamente | `id UUID PRIMARY KEY`               |

<br/><br/>

## Conceptos clave

| Concepto      | ¿Qué significa?                            | Nota                      |
| ------------- | ------------------------------------------ | ------------------------- |
| UUID          | Identificador único global de 128 bits     | 16 bytes                  |
| UUID v4       | Generado aleatoriamente                    | Más usado                 |
| UUID v1       | Basado en tiempo + MAC                     | Puede exponer información |
| UUID v7       | Basado en tiempo (ordenado)                | Tendencia moderna         |
| RFC 4122      | Estándar de UUID                           | Define estructura         |
| Fragmentación | Desorden en índices por valores aleatorios | Impacta performance       |

<br/><br/>

## Buenas prácticas

| Práctica                       | Recomendación                    |
| ------------------------------ | -------------------------------- |
| Usar `pgcrypto`                | Es la opción más moderna         |
| Evitar UUID en tablas pequeñas | No aporta valor                  |
| Usar UUID en microservicios    | Ideal para sistemas distribuidos |
| Considerar UUID v7             | Mejor para índices (ordenado)    |
| No usar UUID para orden lógico | No son secuenciales              |

<br/><br/>

## Comparación rápida

| Característica | SERIAL / IDENTITY | UUID               |
| -------------- | ----------------- | ------------------ |
| Tipo           | Entero            | Binario (128 bits) |
| Generación     | Base de datos     | BD o cliente       |
| Distribuido    | No                | Sí                 |
| Ordenado       | Sí                | No (v4)            |
| Seguridad      | Baja              | Alta               |

<br/><br/>

## Consulta útil 

```sql
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE data_type = 'uuid';
```

<br/><br/>

## Consulta útil (ver índices sobre UUID)

```sql
SELECT 
    t.relname AS tabla,
    i.relname AS indice
FROM pg_class t
JOIN pg_index ix ON t.oid = ix.indrelid
JOIN pg_class i ON i.oid = ix.indexrelid
WHERE t.relname = 'usuarios_uuid';
```
