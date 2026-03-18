

# Demo: Transferencia con excepción (PL/pgSQL + psql)

<br/><br/>

## Objetivo

Simular una transferencia donde:

* Se intenta retirar dinero
* Si el saldo queda negativo → lanzar excepción
* Mostrar cómo ejecutar el script desde **línea de comandos (psql)**

<br/><br/>


### 1. Crear el archivo `transfiere.sql`

Guarda este archivo en tu máquina:

```sql
-- =========================================
-- Preparación del entorno
-- =========================================

DROP TABLE IF EXISTS cuentas;

CREATE TABLE cuentas (
    id_cuenta SERIAL PRIMARY KEY,
    nombre TEXT,
    saldo NUMERIC
);

INSERT INTO cuentas (nombre, saldo)
VALUES 
('Juan', 50),   -- saldo bajo para provocar error
('Ana', 500);

-- =========================================
-- Script de transferencia con validación
-- =========================================

DO $$
DECLARE
    temp_saldo_1 NUMERIC;
BEGIN

    -- Intento de retiro
    UPDATE cuentas
    SET saldo = saldo - 100
    WHERE id_cuenta = 1
    RETURNING saldo INTO temp_saldo_1;

    -- Validación de negocio
    IF temp_saldo_1 < 0 THEN
        RAISE EXCEPTION 'Saldo insuficiente en la cuenta 1';
    END IF;

    -- Depósito
    UPDATE cuentas
    SET saldo = saldo + 100
    WHERE id_cuenta = 2;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error detectado: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- Verificación final
-- =========================================

SELECT * FROM cuentas;
```

<br/><br/>


### 2. Ejecutar desde línea de comandos

Desde tu terminal:

```bash
psql -U postgres -d curso_db -f transfiere.sql 
```

Qué hace cada parámetro:

* `-U postgres` → usuario
* `-d curso_db` → base de datos
* `-f` → ejecuta archivo
* `-a` → muestra el script
* `-e` → muestra lo que ejecuta realmente

---

### 3. Flujo lógico (me comentaron en clase que la mayoría desarrolla, espero les sea claro el diagrama)

```
Inicio (DO block)
   |
   |-- UPDATE cuenta 1 (-100)
   |
   |-- Validación:
   |      saldo < 0 ?
   |         |
   |         ├── Sí → EXCEPTION
   |         └── No → continuar
   |
   |-- UPDATE cuenta 2 (+100)
   |
Fin
```

---

### 4. Resultado esperado (IMPORTANTE)

Como Juan tiene **50** y se le restan **100**:

saldo = **-50**

Entonces:

```text
NOTICE:  Error detectado: Saldo insuficiente en la cuenta 1
DO
```

---

### 5. Validación final

```sql
SELECT * FROM cuentas;
```

Resultado esperado:

| id_cuenta | nombre | saldo |
| --------- | ------ | ----- |
| 1         | Juan   | 50    |
| 2         | Ana    | 500   |

---

### PUNTO CLAVE PARA EXPLICAR (MUY IMPORTANTE)

Aunque hiciste el `UPDATE`, **NO se guardó el cambio**

¿Por qué?
Porque el bloque `DO` es **una transacción implícita**

Cuando ocurre:

```sql
RAISE EXCEPTION
```

PostgreSQL hace **ROLLBACK automático**

---

### 6. Diferencia clave 

| Comportamiento | Resultado                    |
| -------------- | ---------------------------- |
| Sin EXCEPTION  | Se completa la transferencia |
| Con EXCEPTION  | Se revierte TODO             |

---

> "PL/pgSQL convierte a PostgreSQL en un lenguaje con lógica de negocio (IF, excepciones), no solo consultas SQL."

---

### 8. Demo extra en vivo (recomendado)

Vuelve a ponerle saldo suficiente a la cuenta de `Juan` para que puedas ejecutar varias veces el script como lo hice en clase.

```sql
('Juan', 1000)
```

Ejecuta el script varias veces. Ahora **NO hay error**
La transferencia sí ocurre, hasta que nuevamente no hay saldo suficiente.




