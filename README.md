# Gym Control – Interfaz en Node.js

Interfaz web sencilla (Node.js + Express + HTML) para ver las tablas, las vistas y las 10 consultas de la base de datos `gym_control` en MySQL.

## Archivos

| Archivo | Descripción |
|---|---|
| `db.sql` | Script completo de la base de datos. También crea el usuario `gym` que usa la interfaz |
| `server.js` | Servidor Express que consulta MySQL |
| `index.html` | Página que muestra los datos |
| `package.json` | Dependencias (`express`, `mysql2`) |

## Requisitos

- MySQL 8.0.13 o superior
- Node.js 18 o superior y npm

## Pasos de ejecución

### 1. Importar la base de datos (un solo comando)

Ubuntu / Linux:

```bash
sudo mysql < db.sql
```

Windows / macOS (o si tu `root` tiene contraseña):

```bash
mysql -u root -p < db.sql
```

El script crea la base `gym_control` con sus datos y el usuario `gym` (contraseña `gym1234`) con permisos solo sobre esa base. No hay que crear nada más.

> El script empieza con `DROP DATABASE IF EXISTS gym_control;`, así que cada vez que se ejecuta reinicia la base con los datos de prueba.

### 2. Instalar Node.js (si no lo tienes)

```bash
sudo apt install -y nodejs npm
node -v
```

Si `node -v` muestra una versión menor a 18:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### 3. Instalar dependencias y ejecutar

```bash
npm install
npm start
```

Abre <http://localhost:3000>. Para detener el servidor, `Ctrl + C`.

## Usar otro usuario o servidor (opcional)

Por defecto se conecta como `gym` / `gym1234` a `localhost`. Para otros datos, usa variables de entorno en lugar de editar código:

```bash
DB_USER=root DB_PASSWORD=mi_password npm start
```

Variables disponibles: `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`.

## Uso

- **Tablas**: elige una tabla y se muestran todos sus registros.
- **Vistas**: `vw_socios_estatus_acceso` y `vw_resumen_ventas_productos`.
- **Consultas**: las 10 consultas del proyecto, con el SQL que se ejecuta debajo de la tabla.

## Problemas comunes

| Mensaje | Solución |
|---|---|
| `Access denied for user 'gym'` | No se importó `db.sql` (paso 1) |
| `ECONNREFUSED` | MySQL no está iniciado: `sudo systemctl start mysql` |
| `Unknown database 'gym_control'` | Falta importar `db.sql` |
| `EADDRINUSE` (puerto 3000 ocupado) | Cambia `PUERTO` en `server.js` |
| Algunas consultas salen vacías | Los datos dependen de la fecha actual (`CURDATE()`); la consulta 4 queda vacía si todos los socios activos ya asistieron hoy |
