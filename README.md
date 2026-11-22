# Interfaz de consulta

Interfaz web sencilla hecha con Python + Streamlit para ver los datos de la base de datos en MySQL: todas las tablas, las vistas y las 10 consultas del proyecto.

## Requisitos

- MySQL 8.0.13 o superior (el script usa `DEFAULT (CURRENT_DATE)`)
- Python 3.9 o superior

## Pasos de ejecución

### 1. Crear la base de datos

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

Para detener la aplicación se usa `Ctrl + C` en la terminal.
