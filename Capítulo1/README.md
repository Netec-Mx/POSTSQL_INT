# Laboratorio 1. Manejo de Transacciones

## Ejercicio 1: Transferencia bancaria con rollback controlado
En el siguiente ejercicio practicarás diferentes escenarios de manejo de transacciones, comprobando su funcionamiento.

### Paso 1. Crear tabla y datos de prueba
psql -U postgres

sql
CREATE TABLE cuentas (
  id SERIAL PRIMARY KEY,
  nombre TEXT,
  saldo NUMERIC
);
```

```sql
INSERT INTO cuentas (nombre, saldo) VALUES ('Juan', 1000), ('Ana', 1000);
```

### Paso 2. Simular una transferencia exitosa
```sql
BEGIN;
UPDATE cuentas SET saldo = saldo - 200 WHERE nombre = 'Juan';
UPDATE cuentas SET saldo = saldo + 200 WHERE nombre = 'Ana';
COMMIT;
```

### Paso 3. Simular una falla y rollback
```sql
BEGIN;
UPDATE cuentas SET saldo = saldo - 500 WHERE nombre = 'Juan';
-- ERROR: en la siguiente sentencia, la cuenta de Carlos no existe
UPDATE cuentas SET saldo = saldo + 500 WHERE nombre = 'Carlos';
ROLLBACK;
```

### Paso 4. Verifica que nada cambió
```sql
SELECT * FROM cuentas;
```

## Ejercicio 2: Simulación de bloqueo concurrente.
El escenario será una transferencia de dinero, donde es crucial evitar inconsistencias si dos transacciones intentan modificar el saldo de la misma cuenta al mismo tiempo.
Usaremos dos sesiones de psql para simular esto: Sesión A y Sesión B.
Antes de iniciar el laboratorio lleve a cabo los pasos de preparación:

Preparación (En cualquier sesión, una sola vez):

### Paso 1. Primero, limpia la tabla cuentas y agrega los datos:

```sql
TRUNCATE TABLE cuentas;
INSERT INTO cuentas (nombre, saldo) VALUES ('Juan', 1000), ('Ana', 1000);
```

Puedes verificar los saldos iniciales con:

```sql
SELECT * FROM cuentas;
```

Salida Esperada:
- id | nombre | saldo
- ----+--------+-------
-  1 | Juan   |  1000
-  2 | Ana    |  1000
- (2 rows)

### Paso 2. Escenario de Bloqueo con SELECT ... FOR UPDATE
En este ejemplo, la Sesión A intentará retirar dinero de la cuenta de Juan, y la Sesión B intentará hacer lo mismo concurrentemente. Veremos cómo el bloqueo de fila evita un problema.

Sesión A (Terminal 1)
1.	Inicia una transacción y bloquea la cuenta de Juan para actualizarla:

```sql
BEGIN;
--Selecciona el saldo de Juan y bloquea la fila
SELECT saldo FROM cuentas WHERE nombre = 'Juan' FOR UPDATE;
```
Salida (Sesión A):
 saldo
-------
  1000
(1 row)

Explicación: La Sesión A ahora tiene un bloqueo exclusivo sobre la fila de 'Juan'. Esto significa que cualquier otra transacción que intente modificar o bloquear esta misma fila esperará hasta que Sesión A libere el bloqueo.

### Paso 3. Ahora, simula una operación de retiro en esta misma sesión:

```sql
UPDATE cuentas SET saldo = saldo - 200 WHERE nombre = 'Juan';
```

Explicación: Esta actualización se realiza dentro de la transacción de la Sesión A. El saldo de Juan ahora es 800 dentro de esta transacción, pero los cambios aún no son permanentes en la base de datos y la fila sigue bloqueada por Sesión A.
 
Sesión B (Terminal 2)
1.	Intenta leer la cuenta de Juan (sin bloqueo):

```sql
SELECT saldo FROM cuentas WHERE nombre = 'Juan';
```

Salida (Sesión B):
 saldo
-------
  1000
(1 row)

Explicación: La Sesión B puede leer la fila. Observa que ve el saldo como 1000, no 800, porque los cambios de la Sesión A todavía no han sido confirmados (COMMIT).

### Paso 4. Ahora, intenta realizar un retiro de la misma cuenta (lo que intentará adquirir un bloqueo FOR UPDATE):

```sql
UPDATE cuentas SET saldo = saldo - 150 WHERE nombre = 'Juan';
```

Salida (Sesión B): Verás que este comando se queda esperando (o "colgado") indefinidamente.
Explicación: La Sesión B está bloqueada porque la Sesión A tiene un bloqueo FOR UPDATE sobre esa fila. Sesión B esperará hasta que Sesión A libere su bloqueo.

Volver a Sesión A (Terminal 1)
1.	Confirma la transacción:

```sql
COMMIT;
```

Explicación: Al ejecutar COMMIT, la Sesión A guarda sus cambios permanentemente (el saldo de Juan ahora es 800) y, crucialmente, libera el bloqueo sobre la fila de 'Juan'.

Volver a Sesión B (Terminal 2)
Observa la salida: Tan pronto como Sesión A ejecutó COMMIT, el UPDATE de la Sesión B que estaba esperando finaliza su ejecución.

Salida (Sesión B):
UPDATE 1
Explicación: El UPDATE de la Sesión B ahora se ejecutó correctamente. El UPDATE aplicó el cambio de -150 al saldo actual que Sesión B vio después de que Sesión A hiciera commit (800). Por lo tanto, el saldo final de Juan será 800 - 150 = 650.


### Paso 5. Verificación Final (En cualquier sesión, después de que ambas transacciones hayan terminado):

```sql
SELECT * FROM cuentas WHERE nombre = 'Juan';
```
Salida Esperada:
- id | nombre | saldo
- ----+--------+-------
-  1 | Juan   |   650
- (1 row)
 

### Conclusión:
-	El comando SELECT ... FOR UPDATE adquirió un bloqueo exclusivo sobre la fila de la cuenta de Juan en la Sesión A.
-	Esto impidió que la UPDATE concurrente de la Sesión B se ejecutara inmediatamente; Sesión B tuvo que esperar.
-	Una vez que la Sesión A hizo COMMIT;, el bloqueo se liberó, permitiendo que la UPDATE de la Sesión B procediera y aplicara sus cambios.
-	Gracias al bloqueo, evitamos que ambas transacciones intentaran modificar el mismo saldo basándose en un valor inicial obsoleto, garantizando que todas las operaciones se aplicaran secuencialmente.

## Ejercicio 3: Comparación de niveles de aislamiento

### Paso 1. Abre dos terminales psql

Terminal A:
```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT COUNT(*) FROM cuentas;
```
 Mantén abierta la ventana

Terminal B:
```sql
INSERT INTO cuentas (nombre, saldo) VALUES ('Luis', 100);
```

De nuevo en Terminal A:
```sql
SELECT COUNT(*) FROM cuentas; -- verás el nuevo registro con READ COMMITTED
COMMIT;
```

Repite el mismo flujo usando REPEATABLE READ y compara resultados.

## Ejercicio 4: Simulación de Deadlock

### Paso 1. Crea tabla para el experimento.

```sql
CREATE TABLE recursos (
  id SERIAL PRIMARY KEY,
  nombre TEXT
);
INSERT INTO recursos (nombre) VALUES ('A'), ('B');
```

### Paso 2. Simula desde dos terminales

Terminal A:
```sql
BEGIN;
UPDATE recursos SET nombre = 'A1' WHERE id = 1;
--Espera aquí sin hacer COMMIT
```
Terminal B:
```sql
BEGIN;
UPDATE recursos SET nombre = 'B1' WHERE id = 2;
```
De nuevo en Terminal A:
```sql
UPDATE recursos SET nombre = 'A2' WHERE id = 2; -- queda esperando
```
Luego en Terminal B:
```sql
UPDATE recursos SET nombre = 'B2' WHERE id = 1; -- PostgreSQL detectará el deadlock
```
