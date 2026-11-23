# Interfaz en Node.js

Interfaz web sencilla (Node.js + Express + HTML) para ver las tablas, las vistas y las 10 consultas de la base de datos en MySQL.

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

### 1. Importar la base de datos

Windows / macOS:

```bash
mysql -u root -p < db.sql
```

Linux:

```bash
sudo mysql < db.sql
```

### 2. Instalar Node.js

### 3. Instalar dependencias y ejecutar

```bash
npm install
npm start
```

Abre <http://localhost:3000>. 
Para detener el servidor, `Ctrl + C`.


## Uso

- **Tablas**: elige una tabla y se muestran todos sus registros.
- **Vistas**: `vw_socios_estatus_acceso` y `vw_resumen_ventas_productos`.
- **Consultas**: las 10 consultas del proyecto, con el SQL que se ejecuta debajo de la tabla.
El script crea la base `gym_control` con sus datos y el usuario `gym` con contraseña `gym1234`
