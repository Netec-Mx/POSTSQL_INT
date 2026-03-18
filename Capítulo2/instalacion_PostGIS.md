# Validación: Instalación de PostGIS en PostgreSQL 16 (Linux)

### 1. Verificar PostgreSQL


```bash
psql --version
```

También puedes validar el servicio:

```bash
sudo systemctl status postgresql
```

<br/><br/>

### 2. Instalación de PostGIS 

>**Nota:** `sudo apt install postgis` NO siempre instala la versión correcta para PostgreSQL 16

### Forma recomendada

```bash
sudo apt update
sudo apt install postgresql-16-postgis-3
```

* `postgis` (genérico) puede instalar otra versión falla hasta crear la extensión
* `postgresql-16-postgis-3` asegura compatibilidad exacta

### Opcional

```bash
apt search postgis
```

Para mostrar las versiones disponibles.

<br/><br/>

### 3. Acceso a psql

```bash
sudo -u postgres psql
```

<br/><br/>

### 4. Opcionalemente crear una nueva base de datos

```sql
CREATE DATABASE geodb;
\c geodb
```

Puedes validar conexión:

```sql
\conninfo
```

<br/><br/>

### 5. Habilitar extensión PostGIS

```sql
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology; -- opcional, no la he probado
```

>**Nota:**

* `postgis` → suficiente en 90% de los casos
* `postgis_topology` → más avanzado (modelado topológico)

<br/><br/>

### 6. Validación de instalación

Correcto:

```sql
SELECT PostGIS_Version();
```

```sql
SELECT ST_AsText(ST_GeomFromText('POINT(1 2)'));
```

```sql
SELECT * 
FROM pg_available_extensions 
WHERE name LIKE '%postgis%';

\dx   --Para ver extensiones ya instaladas
```

## Resultado esperado:

```
POINT(1 2)
```

  
<br/><br/>

>**Notas**:
> “PostGIS no es solo una extensión lógica, también es un paquete del sistema operativo.
> Si no instalas la versión correcta (alineada con PostgreSQL), la extensión **no aparecerá disponible** y obtendrás el error:
> `extension "postgis" is not available`”