
# **Demo/POC: JSONB en PostgreSQL**

<br/><br/>

## Objetivo

Al finalizar esta demo, serás capaz de:

* Entender cómo se ve el JSON junto con los resultados
* Usar operadores (`->`, `->>`, `?`, `@>`)
* Filtrar dentro del JSON
* Validar uso de índices

<br/><br/>

## Instrucciones

### 1. Creación de la tabla

```sql
DROP TABLE IF EXISTS productos;

CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    categoria VARCHAR(50),
    precio NUMERIC(10,2),
    detalles_extra JSONB
);
```
<br/>

[JSON ORG](https://www.json.org/json-en.html)

<br/><br/>


### 2. Inserción de datos

```sql
INSERT INTO productos (nombre, categoria, precio, detalles_extra)
VALUES
(
 'Laptop Ultrabook X1', 'Electrónica', 1200.00,
 '{
   "procesador": "Intel i7",
   "ram_gb": 16,
   "almacenamiento_gb": 512,
   "conectividad": ["WiFi 6", "Bluetooth 5.2"]
 }'
),
(
 'Silla de Oficina Ergonómica', 'Muebles', 350.00,
 '{
   "material": "Malla y Aluminio",
   "ajustes": {
     "altura": true,
     "lumbar": true,
     "reposabrazos": true
   }
 }'
),
(
 'Libro Viaje al Centro de la Tierra', 'Libros', 25.50,
 '{
   "autor": "Julio Verne",
   "isbn": "978-0140447927",
   "genero": "Aventura"
 }'
);
```

<br/><br/>

### 3. Visualizar JSON completo

```sql
SELECT nombre, detalles_extra
FROM productos;
```

>**Nota:** 
* Aquí vemos el JSON tal cual está almacenado.
* A partir de aquí empezamos a "recorrerlo o parsearlo".

<br/><br/>


### 4. Extraer valores de los campos (->> TEXTO)

```sql
SELECT nombre, detalles_extra, detalles_extra->>'procesador' AS procesador
FROM productos
WHERE categoria = 'Electrónica';
```

>**Nota:** 
* `->>` devuelve texto
* Se usa para mostrar o comparar


<br/><br/>

### 5. Extraer sub-objetos (-> JSON)

```sql
SELECT nombre, detalles_extra, detalles_extra->'ajustes' AS ajustes
FROM productos
WHERE categoria = 'Muebles';
```

>**Nota:**
* `->` mantiene estructura JSON
* Ideal cuando quieres seguir navegando

<br/><br/>

### 6. Acceso a arrays en el JSON

```sql
SELECT nombre, detalles_extra,
       detalles_extra->'conectividad'->>1 AS primera_conexion
FROM productos
WHERE categoria = 'Electrónica';
```

>**Nota:**
* `->` entra al array
* `->>1` obtiene el elemento 1 como texto
* Índices empiezan en **0**

<br/><br/>

### 7. Buscar por existencia de clave

```sql
SELECT nombre, categoria, detalles_extra
FROM productos
WHERE detalles_extra ? 'isbn';
```

>**Nota:**
* `?` = “¿existe esta clave?”
* Muy común en búsquedas dinámicas

<br/><br/>


### 8. Filtrar valores dentro del JSON

```sql
SELECT nombre, precio, detalles_extra->>'ram_gb'
FROM productos
WHERE categoria = 'Electrónica'
AND (detalles_extra->>'ram_gb')::INT = 16;
```

>**Nota:**
* `->>` devuelve texto
* Se convierte con `::INT` para comparar

<br/><br/>

### 9. Búsqueda por contenido (@>)

```sql
SELECT nombre, detalles_extra
FROM productos
WHERE detalles_extra @> '{"procesador": "Intel i7"}';
```

>**Nota:**
* Busca si el JSON contiene ese fragmento
* Muy potente + indexable

<br/><br/>

### 10. Crear índice GIN

```sql
CREATE INDEX idx_productos_jsonb ON productos USING GIN (detalles_extra);
```

>**Nota:** 
* Especial para JSONB
* Mejora búsquedas con `?`, `@>`

<br/><br/>

### 11. Ver plan de ejecución

```sql
EXPLAIN ANALYZE
SELECT nombre
FROM productos
WHERE detalles_extra ? 'isbn';
```

>**Nota:** 
* Antes → Seq Scan
* Después → Index Scan / Bitmap


<br/><br/>

### 12. Validar uso del índice (sin EXPLAIN)

```sql
SELECT 
    schemaname,
    relname AS tabla,
    indexrelname AS indice,
    idx_scan AS veces_usado
FROM pg_stat_user_indexes
WHERE relname = 'productos'
ORDER BY idx_scan DESC;
```

>**Nota:**
* `idx_scan = 0` signigica que no se usa
* `> 0` sí se usa

<br/><br/>

### 13. Consulta final 

```sql
SELECT 
    nombre,
    detalles_extra->>'procesador' AS cpu,
    detalles_extra->>'ram_gb' AS ram,
    detalles_extra->'conectividad'->>0 AS conexion
FROM productos
WHERE detalles_extra ? 'procesador';
```

>**Nota:**
* Combina varias cosas vistas:
  * extracción
  * filtros
  * arrays
  * JSONB real

<br/><br/>

## Tablas de ayuda

### JSON vs JSONB en PostgreSQL

| Tipo  | ¿Para qué sirve?                            | Ejemplo rápido            |
| ----- | ------------------------------------------- | ------------------------- |
| JSON  | Almacena texto JSON tal cual                | `'{"nombre":"Ana"}'`      |
| JSONB | Almacena JSON en formato binario optimizado | Más rápido para consultas |

<br/><br/>

### Operadores JSONB

| Operador    | ¿Para qué sirve?             | Ejemplo rápido                |
| ----------- | ---------------------------- | ----------------------------- |
| `->`        | Extrae un valor como JSON    | `detalles->'ajustes'`         |
| `->>`       | Extrae un valor como TEXTO   | `detalles->>'procesador'`     |
| `?`         | Verifica si existe una clave | `detalles ? 'isbn'`           |
| `@>`        | Verifica si contiene un JSON | `detalles @> '{"ram_gb":16}'` |
| `-> index`  | Accede a posición en array   | `detalles->'tags'->0`         |
| `->> index` | Accede a array como texto    | `detalles->'tags'->>0`        |


<br/><br/>

### Funciones útiles JSONB

| Función                  | ¿Para qué sirve?           | Ejemplo                                         |
| ------------------------ | -------------------------- | ----------------------------------------------- |
| `jsonb_pretty()`         | Formatea JSON para lectura | `SELECT jsonb_pretty(detalles)`                 |
| `jsonb_object_keys()`    | Lista claves del JSON      | `SELECT jsonb_object_keys(detalles)`            |
| `jsonb_array_elements()` | Expande arrays             | `SELECT jsonb_array_elements(detalles->'tags')` |
| `jsonb_typeof()`         | Tipo de dato JSON          | `SELECT jsonb_typeof(detalles->'ram_gb')`       |

<br/><br/>

### Conversión de tipos

| Caso            | Ejemplo                          | Nota                       |
| --------------- | -------------------------------- | -------------------------- |
| Texto a número  | `(detalles->>'ram_gb')::INT`     | Necesario para comparar    |
| Texto a boolean | `(detalles->>'activo')::BOOLEAN` | Para filtros               |
| JSON a texto    | `->>`                            | Ya lo hace automáticamente |

<br/><br/>

### Índices JSONB

| Tipo de índice | ¿Para qué sirve?          | Ejemplo                                          |
| -------------- | ------------------------- | ------------------------------------------------ |
| GIN            | Búsquedas dentro del JSON | `CREATE INDEX idx ON tabla USING GIN (columna);` |
| BTREE          | Comparaciones simples     | No ideal para JSONB                              |

