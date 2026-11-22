import mysql.connector
import pandas as pd
import streamlit as st

DB_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "TU_PASSWORD",
    "database": "gym_control",
}

CONSULTAS = {
    "1. Socios con su suscripción y días restantes": """
        SELECT s.id_socio, CONCAT(s.nombre, ' ', s.apellidos) AS socio, p.nombre_plan,
               sub.fecha_inicio, sub.fecha_fin, sub.estado,
               DATEDIFF(sub.fecha_fin, CURDATE()) AS dias_restantes
        FROM socio s
        INNER JOIN suscripcion sub ON s.id_socio = sub.id_socio
        INNER JOIN plan_membresia p ON sub.id_plan = p.id_plan
        ORDER BY sub.fecha_fin ASC""",
    "2. Clases grupales con entrenador y cupos": """
        SELECT c.id_clase, c.nombre_clase, c.dia_semana, c.hora_inicio, c.hora_fin,
               e.nombre_completo AS entrenador, c.cupo_maximo,
               COUNT(ic.id_inscripcion) AS inscritos_confirmados
        FROM clase_grupal c
        INNER JOIN entrenador e ON c.id_entrenador = e.id_entrenador
        LEFT JOIN inscripcion_clase ic ON c.id_clase = ic.id_clase AND ic.estatus = 'Confirmada'
        GROUP BY c.id_clase, c.nombre_clase, c.dia_semana, c.hora_inicio, c.hora_fin,
                 e.nombre_completo, c.cupo_maximo""",
    "3. Detalle de tickets de venta": """
        SELECT v.id_venta, v.fecha_venta,
               COALESCE(CONCAT(s.nombre, ' ', s.apellidos), 'Visitante Externo') AS cliente,
               pr.nombre_producto, dv.cantidad, dv.precio_unitario_venta, dv.subtotal, v.metodo_pago
        FROM venta v
        LEFT JOIN socio s ON v.id_socio = s.id_socio
        INNER JOIN detalle_venta dv ON v.id_venta = dv.id_venta
        INNER JOIN producto pr ON dv.id_producto = pr.id_producto
        ORDER BY v.id_venta""",
    "4. Socios activos que no han asistido hoy": """
        SELECT s.id_socio, s.nombre, s.apellidos, s.telefono
        FROM socio s
        WHERE EXISTS (
            SELECT 1 FROM suscripcion sub
            WHERE sub.id_socio = s.id_socio AND sub.estado = 'Activa' AND sub.fecha_fin >= CURDATE()
        )
        AND NOT EXISTS (
            SELECT 1 FROM asistencia a
            WHERE a.id_socio = s.id_socio AND DATE(a.fecha_hora_entrada) = CURDATE()
        )""",
    "5. Productos que nunca se han vendido": """
        SELECT p.id_producto, p.nombre_producto, p.precio_venta, p.stock_actual
        FROM producto p
        WHERE NOT EXISTS (
            SELECT 1 FROM detalle_venta dv WHERE dv.id_producto = p.id_producto
        )""",
    "6. Ingresos por método de pago (> $1,000)": """
        SELECT metodo_pago, COUNT(id_pago) AS total_transacciones, SUM(monto_pagado) AS ingresos_totales
        FROM pago
        GROUP BY metodo_pago
        HAVING SUM(monto_pagado) > 1000.00
        ORDER BY ingresos_totales DESC""",
    "7. Total vendido por categoría de producto": """
        SELECT cat.nombre_categoria, SUM(dv.cantidad) AS unidades_vendidas, SUM(dv.subtotal) AS total_ingresos
        FROM categoria_producto cat
        INNER JOIN producto p ON cat.id_categoria = p.id_categoria
        INNER JOIN detalle_venta dv ON p.id_producto = dv.id_producto
        GROUP BY cat.nombre_categoria
        ORDER BY total_ingresos DESC""",
    "8. Socios con más de 1 evaluación física": """
        SELECT s.id_socio, CONCAT(s.nombre, ' ', s.apellidos) AS socio,
               COUNT(ef.id_evaluacion) AS num_evaluaciones,
               MAX(ef.peso_kg) - MIN(ef.peso_kg) AS variacion_peso_kg
        FROM socio s
        INNER JOIN evaluacion_fisica ef ON s.id_socio = ef.id_socio
        GROUP BY s.id_socio, s.nombre, s.apellidos
        HAVING COUNT(ef.id_evaluacion) > 1""",
    "9. Alerta de inventario bajo": """
        SELECT p.id_producto, c.nombre_categoria, p.nombre_producto, p.stock_actual, p.stock_minimo,
               (p.stock_minimo - p.stock_actual) AS deficit
        FROM producto p
        INNER JOIN categoria_producto c ON p.id_categoria = c.id_categoria
        WHERE p.stock_actual <= p.stock_minimo""",
    "10. Rutina vigente de cada socio": """
        SELECT s.id_socio, CONCAT(s.nombre, ' ', s.apellidos) AS socio,
               r.nombre_rutina, r.objetivo, e.nombre_completo AS entrenador_asignado
        FROM socio s
        INNER JOIN rutina r ON s.id_socio = r.id_socio AND r.activa = TRUE
        INNER JOIN entrenador e ON r.id_entrenador = e.id_entrenador""",
}


def ejecutar(sql):
    conexion = mysql.connector.connect(**DB_CONFIG)
    cursor = conexion.cursor()
    cursor.execute(sql)
    columnas = [c[0] for c in cursor.description]
    filas = cursor.fetchall()
    cursor.close()
    conexion.close()
    return pd.DataFrame(filas, columns=columnas)


def mostrar(sql):
    try:
        df = ejecutar(sql)
        st.caption(f"{len(df)} registro(s)")
        st.dataframe(df, hide_index=True)
    except mysql.connector.Error as error:
        st.error(f"Error de base de datos: {error}")


st.set_page_config(page_title="Gym Control", layout="wide")
st.title("Gym Control")

try:
    objetos = ejecutar("SHOW FULL TABLES")
    nombres = objetos.iloc[:, 0].tolist()
    tipos = objetos.iloc[:, 1].tolist()
except mysql.connector.Error as error:
    st.error(f"No se pudo conectar a MySQL: {error}")
    st.info("Revisa usuario y contraseña en DB_CONFIG dentro de app.py y que el script SQL ya esté importado.")
    st.stop()

tablas = [n for n, t in zip(nombres, tipos) if t == "BASE TABLE"]
vistas = [n for n, t in zip(nombres, tipos) if t == "VIEW"]

tab_tablas, tab_vistas, tab_consultas = st.tabs(["Tablas", "Vistas", "Consultas"])

with tab_tablas:
    tabla = st.selectbox("Tabla", tablas)
    mostrar(f"SELECT * FROM `{tabla}`")

with tab_vistas:
    vista = st.selectbox("Vista", vistas)
    mostrar(f"SELECT * FROM `{vista}`")

with tab_consultas:
    consulta = st.selectbox("Consulta", list(CONSULTAS.keys()))
    mostrar(CONSULTAS[consulta])
    with st.expander("Ver SQL"):
        st.code(CONSULTAS[consulta].strip(), language="sql")
