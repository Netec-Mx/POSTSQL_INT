
# Demo/POCs: Tablas externas con FDW - Foreign Data Wrapper

## 1. Crear archivo CSV

Crear el archivo en la ruta: `C:/fdw/empleados.csv`

Contenido del archivo:

```csv
id,nombre,departamento,salario
1,Hugo,Ventas,10000
2,Paco,TI,15000
3,Luis,RRHH,12000
4,Blanca,TI,18000
5,Greta,Ventas,11000
6,Leticia,TI,15000
7,Jose,TI,230000
8,Abril,Sales,3333

```


## 2. Crear extensión

```sql
CREATE EXTENSION file_fdw;
```

## 3. Verificar instalación

```sql
SELECT * 
FROM pg_extension 
WHERE extname = 'file_fdw';
```

## 4. Crear servidor FDW

```sql
CREATE SERVER csv_server
FOREIGN DATA WRAPPER file_fdw;
```

## 5. Crear tabla externa

```sql
CREATE FOREIGN TABLE empleados_csv (
    id INTEGER,
    nombre TEXT,
    departamento TEXT,
    salario NUMERIC
)
SERVER csv_server
OPTIONS (
    filename 'C:/fdw/empleados.csv',
    format 'csv',
    header 'true'
);
```

## 6. Eliminar tabla externa

```sql
DROP FOREIGN TABLE empleados_csv;
```

## 7. Consultar datos

```sql
SELECT * 
FROM empleados_csv;
```

## 8. Agregaciones

```sql
SELECT 
    departamento,
    COUNT(*) AS total,
    AVG(salario) AS salario_promedio
FROM empleados_csv
GROUP BY departamento;
```

## 9. Análisis de ejecución

```sql
EXPLAIN ANALYZE
SELECT * 
FROM empleados_csv
WHERE departamento = 'TI';
```

## 10. Crear tabla local

```sql
DROP TABLE departamentos;

CREATE TABLE departamentos (
    nombre TEXT PRIMARY KEY,
    ubicacion TEXT
);
```

## 11. Insertar datos

```sql
INSERT INTO departamentos VALUES
('Ventas', 'CDMX'),
('TI', 'Guadalajara'),
('RRHH', 'Monterrey');
```

## 12. JOIN entre FDW y tabla local

```sql
SELECT e.nombre, e.departamento, d.ubicacion
FROM empleados_csv e
JOIN departamentos d
ON e.departamento = d.nombre;
```


