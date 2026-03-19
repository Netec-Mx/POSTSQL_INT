# Demo-POC: Índices GiST y búsquedas por proximidad (PostGIS)

## Objetivo

Al finalizar esta práctica serás capaz de:

* Crear una base de datos geoespacial
* Usar PostGIS
* Crear un índice **GiST**
* Realizar búsquedas por cercanía con `<->`
* Ejecutar operaciones CRUD

<br/><br/>

## Duración aproximada

20 minutos

<br/><br/>

## Instrucciones

### Paso 1. Crear base de datos

```sql
CREATE DATABASE geodb;

\c geodb
```

<br/><br/>

### Paso 2. Habilitar PostGIS

```sql
CREATE EXTENSION postgis;

SELECT PostGIS_Version();
```

<br/><br/>

### Paso 3. Crear tabla

```sql
DROP TABLE IF EXISTS pizzerias;

CREATE TABLE pizzerias (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    ubicacion GEOGRAPHY(POINT, 4326)
);
```

<br/><br/>

### Paso 4. Insertar datos reales

```sql
INSERT INTO pizzerias (nombre, ubicacion) VALUES
('Joe''s Pizza', ST_SetSRID(ST_MakePoint(-74.0018, 40.7306), 4326)::geography),
('Lombardi''s Pizza', ST_SetSRID(ST_MakePoint(-73.9950, 40.7216), 4326)::geography),
('Prince Street Pizza', ST_SetSRID(ST_MakePoint(-73.9946, 40.7231), 4326)::geography),
('Di Fara Pizza', ST_SetSRID(ST_MakePoint(-73.9617, 40.6250), 4326)::geography),
('Juliana''s Pizza', ST_SetSRID(ST_MakePoint(-73.9936, 40.7026), 4326)::geography);
```

<br/><br/>

### Paso 5. Consulta básica

```sql
SELECT nombre, ST_AsText(ubicacion::geometry)
FROM pizzerias;
```

<br/><br/>

### Paso 6. Crear índice GiST (CLAVE)

```sql
CREATE INDEX idx_pizzerias_ubicacion
ON pizzerias
USING GIST (ubicacion);
```

>**Nota:**: PostgreSQL crea un índice espacial que permite búsquedas eficientes por ubicación

<br/><br/>

### Paso 7. Consultas espaciales

<br/><br/>

### Consulta 1: Distancia a un punto (Times Square)

```sql
SELECT 
    nombre,
    ubicacion <-> ST_SetSRID(ST_MakePoint(-73.9855, 40.7580), 4326)::geography AS distancia_metros
FROM pizzerias;
```

<br/><br/>

### Consulta 2: Las 3 pizzerías más cercanas

```sql
SELECT 
    nombre,
    ubicacion <-> ST_SetSRID(ST_MakePoint(-73.9855, 40.7580), 4326)::geography AS distancia
FROM pizzerias
ORDER BY ubicacion <-> ST_SetSRID(ST_MakePoint(-73.9855, 40.7580), 4326)::geography
LIMIT 3;
```

>**Nota:** Aquí es donde GiST + `<->` muestran su poder (KNN)

<br/><br/>

### Consulta 3: Dentro de 5 km

```sql
SELECT nombre
FROM pizzerias
WHERE ST_DWithin(
    ubicacion,
    ST_SetSRID(ST_MakePoint(-73.9855, 40.7580), 4326)::geography,
    5000
);
```

<br/><br/>

### Consulta 4: Ver uso del índice

```sql
EXPLAIN ANALYZE
SELECT nombre
FROM pizzerias
ORDER BY ubicacion <-> ST_SetSRID(ST_MakePoint(-73.9855, 40.7580), 4326)::geography
LIMIT 3;

-- Localizar índices y su tipo

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'pizzerias';

-- Opción man completa tomada

SELECT 
    i.relname AS index_name,
    t.relname AS table_name,
    am.amname AS index_type
FROM pg_class t
JOIN pg_index ix ON t.oid = ix.indrelid
JOIN pg_class i ON i.oid = ix.indexrelid
JOIN pg_am am ON i.relam = am.oid
WHERE t.relname = 'pizzerias';


-- Identificar si se usa o no el índice
SELECT  
   schemaname,  
   relname AS tabla,  
   indexrelname AS indice, 
   idx_scan AS veces_usado
FROM pg_stat_user_indexes
WHERE relname = 'pizzerias'
ORDER BY idx_scan DESC;

-- Instrucción interesante, las estad´siticas se reinician al reiniciar el servidor de DB
-- O cuando ejecutas la instrucción siguiente

SELECT pg_stat_reset();


```

>**Nota:** Debes observar algo como:

```
Index Scan using idx_pizzerias_ubicacion
```

<br/><br/>

### DML
### Paso 8. UPDATE

Mover una pizzería (simulación)

```sql
UPDATE pizzerias
SET ubicacion = ST_SetSRID(ST_MakePoint(-73.9900, 40.7300), 4326)::geography
WHERE nombre = 'Joe''s Pizza';
```

<br/><br/>

### Paso 9. DELETE

Eliminar una pizzería

```sql
DELETE FROM pizzerias
WHERE nombre = 'Di Fara Pizza';
```

<br/><br/>

### Paso 10. Verificación final

```sql
SELECT * FROM pizzerias;
```

<br/><br/>

### Conceptos clave para reforzar en clase

**GiST:**

* Índice espacial
* No es B-Tree
* Organiza por proximidad

**Operador** `<->`:

* Usa el índice
* Permite búsquedas KNN

**`ST_DWithin`:**

* Filtrado por distancia

<br/><br/>


### Tabla de ayuda – Operadores y funciones espaciales (PostGIS)

| Tipo           | Elemento                | ¿Para qué sirve?                  | Ejemplo rápido                       |
| -------------- | ----------------------- | --------------------------------- | ------------------------------------ |
| Constructor | `ST_MakePoint(x,y)`     | Crea un punto (lon, lat)          | `ST_MakePoint(-99.13,19.43)`         |
| SRID        | `ST_SetSRID(geom,4326)` | Asigna sistema de referencia      | `ST_SetSRID(ST_MakePoint(...),4326)` |
| Conversión  | `::geography`           | Usa cálculos reales (metros)      | `geom::geography`                    |
| Texto       | `ST_AsText(geom)`       | Convierte a formato legible (WKT) | `ST_AsText(geom)`                    |

<br/><br/>

### Distancias y proximidad

| Tipo         | Elemento            | ¿Para qué sirve?                       | Ejemplo rápido         |
| ------------ | ------------------- | -------------------------------------- | ---------------------- |
| Distancia | `ST_Distance(a,b)`  | Calcula distancia entre dos geometrías | `ST_Distance(a,b)`     |
| KNN       | `<->`               | Distancia optimizada (usa índice)      | `geom <-> punto`       |
| Radio     | `ST_DWithin(a,b,d)` | Verifica si están dentro de distancia  | `ST_DWithin(a,b,5000)` |

<br/><br/>

### Relaciones espaciales

| Tipo            | Elemento             | ¿Para qué sirve?        | Ejemplo rápido            |
| --------------- | -------------------- | ----------------------- | ------------------------- |
| Intersección | `ST_Intersects(a,b)` | Si se cruzan            | `ST_Intersects(a,b)`      |
| Contención   | `ST_Contains(a,b)`   | Si A contiene a B       | `ST_Contains(area,punto)` |
| Dentro de    | `ST_Within(a,b)`     | Si A está dentro de B   | `ST_Within(punto,area)`   |
| Toca         | `ST_Touches(a,b)`    | Si solo se tocan bordes | `ST_Touches(a,b)`         |


<br/><br/>

### Geometría

| Tipo      | Elemento            | ¿Para qué sirve?        | Ejemplo rápido                  |
| --------- | ------------------- | ----------------------- | ------------------------------- |
| Crear  | `ST_GeomFromText()` | Crear desde WKT         | `ST_GeomFromText('POINT(...)')` |
| Área   | `ST_Area(geom)`     | Área de un polígono     | `ST_Area(poligono)`             |
| Centro | `ST_Centroid(geom)` | Centro de una geometría | `ST_Centroid(poligono)`         |
| Buffer | `ST_Buffer(geom,d)` | Área alrededor          | `ST_Buffer(punto,1000)`         |


<br/><br/>

### Índices y optimización

| Tipo      | Elemento       | ¿Para qué sirve?      | Ejemplo rápido                |
| --------- | -------------- | --------------------- | ----------------------------- |
| Índice  | `USING GIST`   | Índice espacial       | `CREATE INDEX ... USING GIST` |
| Ordenar | `ORDER BY <->` | Búsqueda por cercanía | `ORDER BY geom <-> punto`     |


<br/><br/>

### Recordatorio

Diferencia crítica:

* `geometry` → trabaja en plano (grados si SRID 4326)
* `geography` → trabaja sobre la Tierra (metros )

