
# Comandos básicos de Linux y PostgreSQL (psql)

### Información del sistema

```bash
cat /etc/os-release     # Información del sistema operativo
uname -r                # Versión del kernel
uname -a                # Información completa del kernel
uname -d                # Nombre del dominio (si aplica)

lsb_release -a          # Información detallada de la distribución

pwd                     # Directorio actual

id                      # Información del usuario actual
whoamin                 # Usuario actual  

echo $PATH              # Variables de entorno PATH

whereis psql            # Ubicación del binario psql

sudo -i -u postgres psql  # Acceder a psql como usuario postgres

```

<br/><br/>

### Comandos básicos de psql

```sql
\l
-- Listar todas las bases de datos del servidor

\c nombre_bd
-- Conectarse a una base de datos específica

\conninfo
-- Mostrar información de la conexión actual

\q
-- Salir de psql

```

<br/><br/>

### Explorar objetos

```sql
\dt
-- Listar tablas del esquema actual

\dt *.*
-- Listar todas las tablas de todos los esquemas

\dv
-- Listar vistas

\di
-- Listar índices

\dn
-- Listar esquemas

\du
-- Listar roles / usuarios
```

<br/><br/>

### Describir objetos de la base de datos

```sql
\d tabla
-- Mostrar estructura de una tabla, un poco más de un describe de Oracle

\d+ tabla
-- Mostrar estructura con información adicional (tamaño, storage, etc.)

\d esquema.tabla
-- Describir tabla de un esquema específico

\df
-- Listar funciones

\df nombre_funcion
-- Ver información de una función específica

```

<br/><br/>

### Consultas útiles

```sql
\i archivo.sql
-- Ejecutar un script SQL desde archivo

\o archivo.txt
-- Guardar salida de consultas en un archivo

\t
-- Mostrar solo datos pero sin encabezados ni formato

\x
-- Activar modo expandido útil para filas con muchas columnas, similar a MySQL

\x auto
-- Activar modo expandido automático

```

<br/><br/>

### Historial y edición

```sql
\s
-- Mostrar historial de comandos

\e
-- Abrir editor para escribir o modificar una consulta

\r
-- Limpiar el buffer de consulta actual

```

<br/><br/>

### Información del servidor

```sql
\! comando_shell
-- Ejecutar comando del sistema operativo

\password usuario
-- Cambiar contraseña de un usuario

\h
-- Ayuda de comandos SQL

\h SELECT
-- Ayuda específica de un comando SQL
```

<br/><br/>

### Configuración de salida

```sql
\pset pager off
-- Desactivar paginación de resultados

\pset border 2
-- Cambiar formato de borde de tablas, este comando nunca me ha salido veo siempre el mismo tamaño del borde

\pset format aligned
-- Salida tabular alineada (default)

\pset format unaligned
-- Salida simple (útil para scripts)
```

<br/><br/>


### Autocommit

```sql
\echo :AUTOCOMMIT
-- ON  -> cada sentencia se confirma automáticamente, por default.
-- OFF -> debes usar COMMIT manualmente
-- IMPORTANTE va en mayúsculas

\set
-- Lista todas las variables de psql

\set AUTOCOMMIT off
-- Desactiva autocommit

\set AUTOCOMMIT on
-- Activa autocommit

```

<br/><br/>

### Notas

* Estos comandos son útiles tanto para administración como para laboratorio práctico del curso
* Ideal como **cheat sheet** para sesiones de entrenamiento.
* Espero que este material te sea de utilidad. Si encuentras algún error o tienes sugerencias de mejora, te agradeceré mucho que lo reportes a: **escamillablanca@gmail.com**