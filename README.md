# Gym Control – Interfaz de consulta

Interfaz web sencilla (Python + Streamlit) para ver los datos de la base de datos `gym_control` en MySQL: todas las tablas, las vistas y las 10 consultas del proyecto.

## Archivos

| Archivo | Descripción |
|---|---|
| `gym_control.sql` | Script completo de la base de datos (esquema, datos, vistas, triggers, función y procedimientos), sin comentarios |
| `app.py` | Interfaz (Streamlit) |
| `requirements.txt` | Dependencias de Python |

## Requisitos

- MySQL 8.0.13 o superior (el script usa `DEFAULT (CURRENT_DATE)`)
- Python 3.9 o superior

## Pasos de ejecución

### 1. Crear la base de datos

Desde la terminal:

```bash
mysql -u root -p < gym_control.sql
```

O desde MySQL Workbench: *File → Open SQL Script → gym_control.sql* y ejecutar todo con el rayo.

> El script empieza con `DROP DATABASE IF EXISTS gym_control;`, así que cada vez que se ejecuta reinicia la base de datos con los datos de prueba originales.

### 2. Instalar dependencias

```bash
python -m venv venv
venv\Scripts\activate          # Windows
source venv/bin/activate       # Linux / macOS

pip install -r requirements.txt
```

### 3. Configurar la conexión

Abre `app.py` y edita el bloque `DB_CONFIG` al inicio:

```python
DB_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "TU_PASSWORD",
    "database": "gym_control",
}
```

### 4. Ejecutar

```bash
streamlit run app.py
```

Se abre en el navegador en <http://localhost:8501>.

## Uso

- **Tablas**: elige una tabla y se muestran todos sus registros.
- **Vistas**: muestra `vw_socios_estatus_acceso` y `vw_resumen_ventas_productos`.
- **Consultas**: las 10 consultas del proyecto, con opción de ver el SQL que se ejecuta.

Para detener la aplicación, presiona `Ctrl + C` en la terminal.

## Problemas comunes

| Mensaje | Solución |
|---|---|
| `Access denied for user` | Usuario o contraseña incorrectos en `DB_CONFIG` |
| `Can't connect to MySQL server` | El servicio de MySQL no está iniciado o el puerto es distinto de 3306 |
| `Unknown database 'gym_control'` | Falta importar `gym_control.sql` (paso 1) |
| `streamlit` no se reconoce como comando | Activa el entorno virtual o usa `python -m streamlit run app.py` |
| Algunas consultas salen vacías | Los datos de prueba dependen de la fecha actual (`CURDATE()`); por ejemplo, la consulta 4 queda vacía si todos los socios activos ya asistieron hoy |
