
# Demo: Control de accesos de red (CIDR + INET + MACADDR)

## Objetivo

Simular un sistema que:

* Define redes permitidas (`CIDR`)
* Registra dispositivos (`INET`, `MACADDR`)
* Valida si un dispositivo puede acceder

<br/><br/>

### 1. Crear estructura

```sql
DROP TABLE IF EXISTS accesos;
DROP TABLE IF EXISTS redes_permitidas;

-- Redes permitidas (bloques de red)
CREATE TABLE redes_permitidas (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    red CIDR
);

-- Dispositivos / accesos
CREATE TABLE accesos (
    id SERIAL PRIMARY KEY,
    ip INET,
    mac MACADDR,
    fecha TIMESTAMP DEFAULT NOW()
);
```

<br/><br/>

###  2. Insertar datos

```sql
-- Redes permitidas
INSERT INTO redes_permitidas (nombre, red) VALUES
('Oficina CDMX', '192.168.1.0/24'),
('Sucursal MTY', '10.0.0.0/8');

-- Dispositivos que intentan acceder
INSERT INTO accesos (ip, mac) VALUES
('192.168.1.10', '08:00:2b:01:02:03'),
('192.168.1.200', '08:00:2b:AA:BB:CC'),
('10.1.5.20', '08:00:2b:11:22:33'),
('172.16.0.5', '08:00:2b:FF:EE:DD'); -- fuera de red
```

<br/><br/>

### 3. Algunas consultas POC

### 3.1 ¿Qué IP pertenece a qué red? (operador `<<`)

```sql
SELECT 
    a.ip,
    r.nombre AS red_pertenece
FROM accesos a
JOIN redes_permitidas r
ON a.ip << r.red;
```

> **Nota:** 

> `<<` significa: “esta IP está contenida dentro de esta red CIDR”

<br/><br/>

### 3.2 Detectar accesos fuera de redes permitidas

```sql
SELECT *
FROM accesos a
WHERE NOT EXISTS (
    SELECT 1
    FROM redes_permitidas r
    WHERE a.ip << r.red
);
```

> **Nota:** Esto simula, detección de intrusos o accesos no autorizados

<br/><br/>

### 3.3 Ver rango de cada IP

```sql
SELECT 
    ip,
    network(ip) AS red,
    host(ip) AS host
FROM accesos;
```

>**Nota:**

* `network(ip)`: obtiene la red
* `host(ip)`: solo la IP sin máscara

<br/><br/>

### 3.4 Ordenar IPs correctamente (no como texto)

```sql
SELECT ip
FROM accesos
ORDER BY ip;
```

>**Nota**:
> Aquí PostgreSQL ordena **numéricamente**, no como string
> ventaja clave del tipo `INET`

<br/><br/>

### 3.5 Buscar dispositivos por MAC

```sql
SELECT *
FROM accesos
WHERE mac = '08:00:2b:01:02:03';
```

>**Nota:** Caso real: auditoría / inventario de hardware

<br/><br/>

### 3.6 Validar si una IP pertenece a una red específica

```sql
SELECT 
    '192.168.1.50'::inet << '192.168.1.0/24'::cidr AS pertenece;
-- true

SELECT 
    '192.168.1.50'::inet << '192.169.1.0/24'::cidr AS pertenece;
-- false

```


<br/><br/>

## 4. Consulta PRO  

```sql
SELECT 
    a.ip,
    a.mac,
    r.nombre,
    CASE 
        WHEN a.ip << r.red THEN 'PERMITIDO'
        ELSE 'DENEGADO'
    END AS estado
FROM accesos a
LEFT JOIN redes_permitidas r
ON a.ip << r.red;
```

<br/><br/>

### Guía rápida

> * `CIDR` → representa **redes completas**
> * `INET` → representa **hosts (dispositivos)**
> * `MACADDR` → representa **hardware físico**
>
> PostgreSQL permite cruzarlos con operadores como `<<`
> que hacen validaciones de red **sin lógica adicional**


<br/><br/>


## Tabla de ayuda – Tipos de red en PostgreSQL (`INET`, `CIDR`, `MACADDR`)


### 1. Operadores principales (`INET` / `CIDR`)

| Operador | ¿Para qué sirve?             | Ejemplo                                              | Resultado |
| -------- | ---------------------------- | ---------------------------------------------------- | --------- |
| `<<`     | IP está contenida en una red | `'192.168.1.10'::inet << '192.168.1.0/24'::cidr`     | `true`    |
| `<<=`    | Contenido o igual            | `'192.168.1.0/24'::cidr <<= '192.168.1.0/24'::cidr`  | `true`    |
| `>>`     | Red contiene IP/red          | `'192.168.1.0/24'::cidr >> '192.168.1.10'::inet`     | `true`    |
| `>>=`    | Contiene o igual             | `'192.168.1.0/24'::cidr >>= '192.168.1.0/24'::cidr`  | `true`    |
| `&&`     | Redes se traslapan           | `'192.168.1.0/24'::cidr && '192.168.1.128/25'::cidr` | `true`    |
| `=`      | Igualdad exacta              | `'192.168.1.1'::inet = '192.168.1.1'::inet`          | `true`    |
| `<>`     | Diferente                    | `'192.168.1.1'::inet <> '192.168.1.2'::inet`         | `true`    |
| `<`      | Menor (orden numérico IP)    | `'192.168.1.1'::inet < '192.168.1.2'::inet`          | `true`    |
| `>`      | Mayor (orden numérico IP)    | `'192.168.1.10'::inet > '192.168.1.2'::inet`         | `true`    |

<br/><br/>

### 2. Funciones clave (`INET` / `CIDR`)

| Función              | ¿Para qué sirve?            | Ejemplo                                 | Resultado         |
| -------------------- | --------------------------- | --------------------------------------- | ----------------- |
| `network()`          | Obtiene la red base         | `network('192.168.1.10/24')`            | `192.168.1.0/24`  |
| `host()`             | Obtiene solo la IP          | `host('192.168.1.10/24')`               | `192.168.1.10`    |
| `masklen()`          | Longitud del prefijo        | `masklen('192.168.1.0/24')`             | `24`              |
| `broadcast()`        | Dirección broadcast         | `broadcast('192.168.1.0/24')`           | `192.168.1.255`   |
| `set_masklen()`      | Cambia la máscara           | `set_masklen('192.168.1.10/24', 16)`    | `192.168.1.10/16` |
| `family()`           | Tipo de IP (IPv4=4, IPv6=6) | `family('192.168.1.1')`                 | `4`               |
| `inet_same_family()` | Verifica misma familia IP   | `inet_same_family('192.168.1.1','::1')` | `false`           |

<br/><br/>

### 3. Operadores (`MACADDR`)

| Operador | ¿Para qué sirve?      | Ejemplo                                                        | Resultado |
| -------- | --------------------- | -------------------------------------------------------------- | --------- |
| `=`      | Igualdad              | `'08:00:2b:01:02:03'::macaddr = '08:00:2b:01:02:03'::macaddr`  | `true`    |
| `<>`     | Diferente             | `'08:00:2b:01:02:03'::macaddr <> '08:00:2b:AA:BB:CC'::macaddr` | `true`    |
| `<`      | Menor (orden binario) | `'08:00:2b:01:02:03'::macaddr < '08:00:2b:FF:FF:FF'`           | `true`    |
| `>`      | Mayor (orden binario) | `'08:00:2b:FF:FF:FF'::macaddr > '08:00:2b:01:02:03'`           | `true`    |

<br/><br/>

### 4. Funciones útiles (`MACADDR`)

| Función      | ¿Para qué sirve?                   | Ejemplo                                | Resultado                 |
| ------------ | ---------------------------------- | -------------------------------------- | ------------------------- |
| `macaddr8()` | Convierte MAC de 6 bytes a 8 bytes | `macaddr8('08:00:2b:01:02:03')`        | `08:00:2b:ff:fe:01:02:03` |
| `trunc()`    | Trunca MACADDR8 a MACADDR          | `trunc(macaddr8('08:00:2b:01:02:03'))` | `08:00:2b:01:02:03`       |

