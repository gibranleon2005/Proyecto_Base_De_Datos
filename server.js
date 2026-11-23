const path = require("path");
const express = require("express");
const mysql = require("mysql2/promise");

const DB_CONFIG = {
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || "gym",
  password: process.env.DB_PASSWORD || "gym1234",
  database: process.env.DB_NAME || "gym_control",
  dateStrings: true,
};

const PUERTO = 3000;

const CONSULTAS = [
  {
    titulo: "1. Socios con su suscripción y días restantes",
    sql: `SELECT s.id_socio, CONCAT(s.nombre, ' ', s.apellidos) AS socio, p.nombre_plan,
       sub.fecha_inicio, sub.fecha_fin, sub.estado,
       DATEDIFF(sub.fecha_fin, CURDATE()) AS dias_restantes
FROM socio s
INNER JOIN suscripcion sub ON s.id_socio = sub.id_socio
INNER JOIN plan_membresia p ON sub.id_plan = p.id_plan
ORDER BY sub.fecha_fin ASC`,
  },
  {
    titulo: "2. Clases grupales con entrenador y cupos",
    sql: `SELECT c.id_clase, c.nombre_clase, c.dia_semana, c.hora_inicio, c.hora_fin,
       e.nombre_completo AS entrenador, c.cupo_maximo,
       COUNT(ic.id_inscripcion) AS inscritos_confirmados
FROM clase_grupal c
INNER JOIN entrenador e ON c.id_entrenador = e.id_entrenador
LEFT JOIN inscripcion_clase ic ON c.id_clase = ic.id_clase AND ic.estatus = 'Confirmada'
GROUP BY c.id_clase, c.nombre_clase, c.dia_semana, c.hora_inicio, c.hora_fin,
         e.nombre_completo, c.cupo_maximo`,
  },
  {
    titulo: "3. Detalle de tickets de venta",
    sql: `SELECT v.id_venta, v.fecha_venta,
       COALESCE(CONCAT(s.nombre, ' ', s.apellidos), 'Visitante Externo') AS cliente,
       pr.nombre_producto, dv.cantidad, dv.precio_unitario_venta, dv.subtotal, v.metodo_pago
FROM venta v
LEFT JOIN socio s ON v.id_socio = s.id_socio
INNER JOIN detalle_venta dv ON v.id_venta = dv.id_venta
INNER JOIN producto pr ON dv.id_producto = pr.id_producto
ORDER BY v.id_venta`,
  },
  {
    titulo: "4. Socios activos que no han asistido hoy",
    sql: `SELECT s.id_socio, s.nombre, s.apellidos, s.telefono
FROM socio s
WHERE EXISTS (
    SELECT 1 FROM suscripcion sub
    WHERE sub.id_socio = s.id_socio AND sub.estado = 'Activa' AND sub.fecha_fin >= CURDATE()
)
AND NOT EXISTS (
    SELECT 1 FROM asistencia a
    WHERE a.id_socio = s.id_socio AND DATE(a.fecha_hora_entrada) = CURDATE()
)`,
  },
  {
    titulo: "5. Productos que nunca se han vendido",
    sql: `SELECT p.id_producto, p.nombre_producto, p.precio_venta, p.stock_actual
FROM producto p
WHERE NOT EXISTS (
    SELECT 1 FROM detalle_venta dv WHERE dv.id_producto = p.id_producto
)`,
  },
  {
    titulo: "6. Ingresos por método de pago (> $1,000)",
    sql: `SELECT metodo_pago, COUNT(id_pago) AS total_transacciones, SUM(monto_pagado) AS ingresos_totales
FROM pago
GROUP BY metodo_pago
HAVING SUM(monto_pagado) > 1000.00
ORDER BY ingresos_totales DESC`,
  },
  {
    titulo: "7. Total vendido por categoría de producto",
    sql: `SELECT cat.nombre_categoria, SUM(dv.cantidad) AS unidades_vendidas, SUM(dv.subtotal) AS total_ingresos
FROM categoria_producto cat
INNER JOIN producto p ON cat.id_categoria = p.id_categoria
INNER JOIN detalle_venta dv ON p.id_producto = dv.id_producto
GROUP BY cat.nombre_categoria
ORDER BY total_ingresos DESC`,
  },
  {
    titulo: "8. Socios con más de 1 evaluación física",
    sql: `SELECT s.id_socio, CONCAT(s.nombre, ' ', s.apellidos) AS socio,
       COUNT(ef.id_evaluacion) AS num_evaluaciones,
       MAX(ef.peso_kg) - MIN(ef.peso_kg) AS variacion_peso_kg
FROM socio s
INNER JOIN evaluacion_fisica ef ON s.id_socio = ef.id_socio
GROUP BY s.id_socio, s.nombre, s.apellidos
HAVING COUNT(ef.id_evaluacion) > 1`,
  },
  {
    titulo: "9. Alerta de inventario bajo",
    sql: `SELECT p.id_producto, c.nombre_categoria, p.nombre_producto, p.stock_actual, p.stock_minimo,
       (p.stock_minimo - p.stock_actual) AS deficit
FROM producto p
INNER JOIN categoria_producto c ON p.id_categoria = c.id_categoria
WHERE p.stock_actual <= p.stock_minimo`,
  },
  {
    titulo: "10. Rutina vigente de cada socio",
    sql: `SELECT s.id_socio, CONCAT(s.nombre, ' ', s.apellidos) AS socio,
       r.nombre_rutina, r.objetivo, e.nombre_completo AS entrenador_asignado
FROM socio s
INNER JOIN rutina r ON s.id_socio = r.id_socio AND r.activa = TRUE
INNER JOIN entrenador e ON r.id_entrenador = e.id_entrenador`,
  },
];

const app = express();
const pool = mysql.createPool(DB_CONFIG);

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

async function listarObjetos() {
  const [filas] = await pool.query("SHOW FULL TABLES");
  const tablas = [];
  const vistas = [];
  for (const fila of filas) {
    const [nombre, tipo] = Object.values(fila);
    if (tipo === "VIEW") vistas.push(nombre);
    else tablas.push(nombre);
  }
  return { tablas, vistas };
}

function manejarError(res, error) {
  res.status(500).json({ error: error.message });
}

app.get("/api/objetos", async (req, res) => {
  try {
    const objetos = await listarObjetos();
    res.json({
      tablas: objetos.tablas,
      vistas: objetos.vistas,
      consultas: CONSULTAS.map((c, i) => ({ id: i, titulo: c.titulo })),
    });
  } catch (error) {
    manejarError(res, error);
  }
});

app.get("/api/objeto/:nombre", async (req, res) => {
  try {
    const { tablas, vistas } = await listarObjetos();
    const nombre = req.params.nombre;
    if (![...tablas, ...vistas].includes(nombre)) {
      return res.status(404).json({ error: "Tabla o vista no encontrada" });
    }
    const [filas] = await pool.query("SELECT * FROM ??", [nombre]);
    res.json({ filas });
  } catch (error) {
    manejarError(res, error);
  }
});

app.get("/api/consulta/:id", async (req, res) => {
  try {
    const consulta = CONSULTAS[Number(req.params.id)];
    if (!consulta) {
      return res.status(404).json({ error: "Consulta no encontrada" });
    }
    const [filas] = await pool.query(consulta.sql);
    res.json({ filas, sql: consulta.sql });
  } catch (error) {
    manejarError(res, error);
  }
});

app.listen(PUERTO, () => {
  console.log(`Gym Control disponible en http://localhost:${PUERTO}`);
});
