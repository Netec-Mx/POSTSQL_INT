
# Demo/POC, Uso de FDW con archivos CSV en PostgreSQL

<br/><br/>

## Objetivo

Consultar datos desde un archivo CSV como si fuera una tabla en PostgreSQL usando `file_fdw`.

<br/><br/>

### 1. Preparar archivo CSV

Crea un archivo en tu servidor PostgreSQL (importante: **ruta accesible para el servidor**, no tu cliente).

Ejemplo: `/tmp/empleados.csv`

```csv
id,nombre,departamento,salario
1,Hugo,Ventas,10000
2,Paco,TI,15000
3,Luis,RRHH,12000
4,Greta,TI,18000
5,Blanca,Ventas,11000
```

<br/><br/>


### 2. Instalar extensión FDW

```sql

CREATE EXTENSION file_fdw;

```

Verificación:

```sql

SELECT * FROM pg_extension WHERE extname = 'file_fdw';

```

<br/><br/>

### 3. Crear servidor FDW

```sql

CREATE SERVER csv_server
FOREIGN DATA WRAPPER file_fdw;

```

<br/><br/>


### 4. Crear tabla externa (foreign table)

```sql

CREATE FOREIGN TABLE empleados_csv (
    id INTEGER,
    nombre TEXT,
    departamento TEXT,
    salario NUMERIC
)
SERVER csv_server
OPTIONS (
    filename '/tmp/empleados.csv',
    format 'csv',
    header 'true'
);

```

<br/><br/>

### 5. Consultar como tabla normal

```sql

SELECT * FROM empleados_csv;

```

<br/><br/>

### 6. Ejemplo de análisis (igual que tabla local)

```sql

SELECT 
    departamento,
    COUNT(*) AS total,
    AVG(salario) AS salario_promedio
FROM empleados_csv
GROUP BY departamento;

```

<br/><br/>

### 7. Filtro (para ver comportamiento del planner)

```sql

EXPLAIN ANALYZE
SELECT * 
FROM empleados_csv
WHERE departamento = 'TI';

```

>**Nota:** 
* No hay índices
* Siempre es **Seq Scan externo**
* En este caso la lectura directa del archivo

<br/><br/>


### 8. JOIN con tabla local (clave para FDW)

Primero una tabla local:

```sql

CREATE TABLE departamentos (
    nombre TEXT PRIMARY KEY,
    ubicacion TEXT
);

INSERT INTO departamentos VALUES
('Ventas', 'CDMX'),
('TI', 'Guadalajara'),
('RRHH', 'Monterrey');

```

### Join normal entre tablas

```sql

SELECT e.nombre, e.departamento, d.ubicacion
FROM empleados_csv e
JOIN departamentos d
ON e.departamento = d.nombre;

```

<br/><br/>

### ¿Qué está pasando internamente?

* PostgreSQL **no importa** el CSV
* Lo lee en tiempo real
* El FDW actúa como adaptador

<br/><br/>

### Ventajas

* No necesitas ETL
* Datos siempre actualizados
* Ideal para integración rápida

<br/><br/>


### Limitaciones IMPORTANTES

* Sin índices
* Rendimiento limitado
* No DML (INSERT/UPDATE)
* Típicamente no es seguro usar datos fuera de la base de datos-

<br/><br/>


### 9. Experimento didáctico  

Edita el archivo CSV y agrega una fila:

```csv

6,Leticia,TI,20000

```

Vuelve a ejecutar:

```sql

SELECT * FROM empleados_csv;

```

<br/><br/>

### Tabla resumen 

| Concepto       | FDW CSV               |
| -------------- | --------------------- |
| Almacenamiento | No                    |
| Lectura        | Directa del archivo   |
| Índices        | No                    |
| JOIN           | Si                    |
| DML            | No                    |
| Uso típico     | Integración rápida    |




