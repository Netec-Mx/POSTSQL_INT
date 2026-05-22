

# **Práctica Adicional 2.1 Manejo de INTERVAL en PostgreSQL**

## **Objetivo**

Al finalizar esta práctica, serás capaz de:

* Comprender el uso del tipo de dato `INTERVAL`
* Realizar operaciones aritméticas con fechas y tiempos
* Aplicar intervalos en consultas (`SELECT`, `WHERE`, `UPDATE`)
* Calcular fechas futuras y diferencias de tiempo

<br/><br/>

## **Duración aproximada**

30 minutos.

<br/><br/>

## **Escenario**

Se administrará una tabla de **tareas**, donde cada registro tiene:

* Fecha de inicio
* Duración (INTERVAL)

A partir de estos datos, se calcularán fechas de finalización, filtros por duración y ajustes dinámicos.

<br/><br/>

## **Tabla de ayuda**

| ¿Para qué sirve?        | Ejemplo rápido                |
| ----------------------- | ----------------------------- |
| Crear intervalo         | `INTERVAL '2 days 3 hours'`   |
| Sumar intervalo a fecha | `NOW() + INTERVAL '1 day'`    |
| Restar fechas           | `NOW() - fecha_inicio`        |
| Comparar intervalos     | `duracion > INTERVAL '1 day'` |

<br/><br/>

# **Tarea 1. Creación de la estructura**

## **Paso 1. Crear la tabla**

```sql
DROP TABLE IF EXISTS tareas;

CREATE TABLE tareas (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    fecha_inicio TIMESTAMP DEFAULT NOW(),
    duracion INTERVAL
);
```

<br/><br/>

## **Paso 2. Insertar datos**

```sql
INSERT INTO tareas (nombre, duracion) VALUES
('Tarea corta', INTERVAL '2 hours'),
('Tarea media', INTERVAL '1 day 3 hours'),
('Tarea larga', INTERVAL '2 days 5 hours 30 minutes'),
('Tarea muy larga', INTERVAL '1 year 2 months 10 days');
```

<br/><br/>

## **Paso 3. Verificar datos**

```sql
SELECT * FROM tareas;
```

<br/><br/>

# **Tarea 2. Operaciones con INTERVAL**

## **Paso 1. Calcular fecha de finalización**

```sql
SELECT 
    nombre,
    fecha_inicio,
    duracion,
    fecha_inicio + duracion AS fecha_fin
FROM tareas;
```

>**Nota:** sumando un INTERVAL a una fecha

<br/><br/>

## **Paso 2. Filtrar por duración**

```sql
SELECT *
FROM tareas
WHERE duracion > INTERVAL '1 day';
```

>**Nota:** Comparación directa entre intervalos

<br/><br/>

# **Tarea 3. Actualizaciones con INTERVAL**

## **Paso 1. Aumentar duración global**

```sql
UPDATE tareas
SET duracion = duracion + INTERVAL '1 hour';
```

<br/><br/>

## **Paso 2. Verificar cambios**

```sql
SELECT * FROM tareas;
```

<br/><br/>

## **Paso 3. Actualizar con condición**

```sql
UPDATE tareas
SET duracion = duracion + INTERVAL '30 minutes'
WHERE duracion > INTERVAL '2 days';
```

<br/><br/>

## **Paso 4. Verificar nuevamente**

```sql
SELECT * FROM tareas;
```

<br/><br/>

# **Tarea 4. Uso avanzado de fechas e intervalos**

## **Paso 1. Ajustar fechas**

```sql
SELECT 
    nombre,
    fecha_inicio - INTERVAL '1 day' AS inicio_ajustado
FROM tareas;
```

>**Nota:** Restando tiempo a una fecha

<br/><br/>

## **Paso 2. Calcular tiempo transcurrido**

```sql
SELECT 
    nombre,
    NOW() - fecha_inicio AS tiempo_transcurrido
FROM tareas;
```

>**Nota:** Resultado al restar fechas es de tipo INTERVAL

<br/><br/>

# **Conceptos clave**

* `INTERVAL` **NO almacena fechas**, almacena duración (tiempo relativo)

* Se puede usar en:

  * `SELECT`
  * `WHERE`
  * `UPDATE`

* Operaciones válidas:

  * `fecha + interval`
  * `fecha - interval`
  * `fecha - fecha = interval`

<br/><br/>

# **Notas adicionales**

### **Sintaxis en PostgreSQL**

```sql
INTERVAL '2 days 3 hours'
INTERVAL '5 hours 30 minutes'
```

<br/><br/>

### **Comparación con Oracle**

| PostgreSQL             | Oracle                         |
| ---------------------- | ------------------------------ |
| INTERVAL libre (texto) | Tipos definidos                |
| `'2 days 3 hours'`     | `INTERVAL '2-3' YEAR TO MONTH` |
| Flexible               | Más estructurado               |

<br/><br/>

