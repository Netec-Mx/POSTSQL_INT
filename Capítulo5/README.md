# Práctica 5. Replicación
## Objetivo
Al finalizar la práctica, serás capaz de:
-  Practicar lo que es la replicación lógica para una mejor disponibilidad de la aplicación.

## Duración aproximada
- 120 minutos.

## Objetivo visual
En la siguiente práctica, verás cómo realizar una replicación lógica de base de datos con PostgreSQL.

![diagrama5](../images/replicacion.png)

## Instrucciones

```
🔧 Requisitos
✔ PostgreSQL 14 instalado 
✔ Acceso a psql y permisos de administrador.
 
📌 Paso 1: Configurar dos instancias de PostgreSQL (Publisher y Subscriber)
Vamos a simular dos servidores en la misma máquina usando puertos diferentes:
•	Publisher (Primario): Puerto 5432 (default).
•	Subscriber (Réplica): Puerto 5433.

1.1 Crear un segundo cluster de PostgreSQL (Subscriber)
sudo pg_createcluster 14 replica --start --port=5433
Esto crea un nuevo cluster llamado replica en el puerto 5433.

1.2 Verificar que ambos clusters estén corriendo

sudo pg_lsclusters

Salida esperada:

Ver Cluster Port Status Owner    Data directory
14  main    5432 online postgres /var/lib/postgresql/14/main
14  replica 5433 online postgres /var/lib/postgresql/14/replica
 
📌 Paso 2: Configurar el Publisher (Primario, puerto 5432)

2.1 Editar postgresql.conf para habilitar replicación lógica

sudo nano /etc/postgresql/14/main/postgresql.conf

Asegúrate de que estas líneas estén configuradas:

wal_level = logical
max_replication_slots = 10
max_wal_senders = 10

2.2 Editar pg_hba.conf para permitir conexiones locales

sudo nano /var/lib/postgresql/14/main/pg_hba.conf

sino existe en la ruta anterior usa la siguiente:

sudo nano /etc/postgresql/14/main/pg_hba.conf

Agrega esta línea al final:
# Permite conexión local para replicación
host    localhost     replicator      127.0.0.1/32          md5

2.3 Reiniciar PostgreSQL

sudo systemctl restart postgresql@14-main  # nombre del cluster es @14-main

2.4 Crear un usuario replicador

sudo -u postgres psql -p 5432

CREATE ROLE replicador WITH REPLICATION LOGIN PASSWORD 'abc123';
GRANT USAGE ON SCHEMA public TO replicador;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replicador;

2.5 Crear una base de datos y tabla de prueba

CREATE DATABASE db_replica;
\c db_replica
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100)
);

2.6 Crear la publicación (Publication)

CREATE PUBLICATION pub_clientes FOR TABLE clientes; 
SELECT * FROM pg_publication;  # listar las publicaciones que ya existen
SELECT * FROM pg_stat_replication; # listar detalles de la replicacion
 
📌 Paso 3: Configurar el Subscriber (Réplica, puerto 5433)

3.1 Crear la misma estructura en el Subscriber

sudo -u postgres psql -p 5433 # conectarse con el servidor secundario

CREATE DATABASE db_replica;
\c db_replica
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100)
);
 
# Verificar la estructura de la tabla creada

\d clientes

3.2 Crear la suscripción (Subscription)

CREATE SUBSCRIPTION sub_clientes
CONNECTION 'host=127.0.0.1 port=5432 user=replicator password=password123 dbname=db_replica'  
PUBLICATION pub_clientes;

# Si todo está bien, PostgreSQL comenzará a sincronizar los datos.

CREATE SUBSCRIPTION sub_clientes
CONNECTION 'host=localhost port=5432 user=replicador password=abc123 dbname=db_replica'
PUBLICATION pub_clientes;
 
📌 Paso 4: Probar la replicación

4.1 Insertar datos en el Publisher (puerto 5432)

INSERT INTO clientes (nombre, email) VALUES 
    ('Juan Pérez', 'juan@example.com'),
    ('María López', 'maria@example.com');

4.2 Verificar datos en el Subscriber (puerto 5433)

SELECT * FROM clientes;

Salida esperada:
id |   nombre    |       email        
----+-------------+-------------------
  1 | Juan Pérez  | juan@example.com
  2 | María López | maria@example.com
 
📌 Paso 5: Monitorear el estado de la replicación

5.1 Ver slots de replicación (Publisher)

SELECT * FROM pg_replication_slots;

5.2 Ver estado de la suscripción (Subscriber)

SELECT * FROM pg_stat_subscription;
 
🔎 Posibles Errores y Soluciones

❌ Error: "No se pudo iniciar la replicación"
✔ Verifica que wal_level = logical en el Publisher.
✔ Confirma que el usuario replicator existe y tiene permisos.
❌ Datos no aparecen en el Subscriber
✔ Ejecuta en el Subscriber:
ALTER SUBSCRIPTION sub_clientes REFRESH PUBLICATION;
 
✅ Conclusión

¡Has configurado exitosamente replicación lógica en PostgreSQL 14!
🔹 Publisher (5432): Envía cambios.
🔹 Subscriber (5433): Recibe cambios en tiempo real.
🚀 Próximo paso: Prueba replicar múltiples tablas o configurar filtros (WHERE en publicaciones).

