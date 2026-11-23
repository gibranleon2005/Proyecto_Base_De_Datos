DROP DATABASE IF EXISTS gym_control;
CREATE DATABASE gym_control CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gym_control;

CREATE USER IF NOT EXISTS 'gym'@'localhost' IDENTIFIED BY 'gym1234';
GRANT ALL PRIVILEGES ON gym_control.* TO 'gym'@'localhost';

CREATE TABLE usuario_sistema (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('Administrador', 'Recepcionista') NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE socio (
    id_socio INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL,
    apellidos VARCHAR(80) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    tel_emergencia VARCHAR(15) NOT NULL,
    fecha_registro DATE NOT NULL DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB;

CREATE TABLE plan_membresia (
    id_plan INT AUTO_INCREMENT PRIMARY KEY,
    nombre_plan VARCHAR(50) NOT NULL UNIQUE,
    duracion_dias INT NOT NULL,
    precio_actual DECIMAL(8,2) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_plan_duracion CHECK (duracion_dias > 0),
    CONSTRAINT chk_plan_precio CHECK (precio_actual > 0)
) ENGINE=InnoDB;

CREATE TABLE suscripcion (
    id_suscripcion INT AUTO_INCREMENT PRIMARY KEY,
    id_socio INT NOT NULL,
    id_plan INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado ENUM('Activa', 'Vencida', 'Cancelada') NOT NULL DEFAULT 'Activa',
    CONSTRAINT fk_suscripcion_socio FOREIGN KEY (id_socio)
        REFERENCES socio(id_socio) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_suscripcion_plan FOREIGN KEY (id_plan)
        REFERENCES plan_membresia(id_plan) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_suscripcion_fechas CHECK (fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE TABLE auditoria_suscripcion (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_suscripcion INT NOT NULL,
    id_socio INT NOT NULL,
    estado_anterior VARCHAR(20) NOT NULL,
    estado_nuevo VARCHAR(20) NOT NULL,
    fecha_fin_anterior DATE NOT NULL,
    fecha_fin_nueva DATE NOT NULL,
    usuario_bd VARCHAR(100) NOT NULL,
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auditoria_suscripcion FOREIGN KEY (id_suscripcion)
        REFERENCES suscripcion(id_suscripcion) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pago (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_suscripcion INT NOT NULL,
    monto_pagado DECIMAL(8,2) NOT NULL,
    fecha_pago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metodo_pago ENUM('Efectivo', 'Tarjeta', 'Transferencia') NOT NULL,
    CONSTRAINT fk_pago_suscripcion FOREIGN KEY (id_suscripcion)
        REFERENCES suscripcion(id_suscripcion) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_pago_monto CHECK (monto_pagado > 0)
) ENGINE=InnoDB;

CREATE TABLE asistencia (
    id_asistencia INT AUTO_INCREMENT PRIMARY KEY,
    id_socio INT NOT NULL,
    fecha_hora_entrada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_asistencia_socio FOREIGN KEY (id_socio)
        REFERENCES socio(id_socio) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE entrenador (
    id_entrenador INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(120) NOT NULL,
    especialidad VARCHAR(60) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE clase_grupal (
    id_clase INT AUTO_INCREMENT PRIMARY KEY,
    id_entrenador INT NOT NULL,
    nombre_clase VARCHAR(50) NOT NULL,
    dia_semana ENUM('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo') NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    cupo_maximo INT NOT NULL,
    CONSTRAINT fk_clase_entrenador FOREIGN KEY (id_entrenador)
        REFERENCES entrenador(id_entrenador) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_clase_cupo CHECK (cupo_maximo > 0),
    CONSTRAINT chk_clase_horario CHECK (hora_fin > hora_inicio)
) ENGINE=InnoDB;

CREATE TABLE inscripcion_clase (
    id_inscripcion INT AUTO_INCREMENT PRIMARY KEY,
    id_socio INT NOT NULL,
    id_clase INT NOT NULL,
    fecha_inscripcion DATE NOT NULL DEFAULT (CURRENT_DATE),
    estatus ENUM('Confirmada', 'Cancelada') NOT NULL DEFAULT 'Confirmada',
    CONSTRAINT fk_inscripcion_socio FOREIGN KEY (id_socio)
        REFERENCES socio(id_socio) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_inscripcion_clase FOREIGN KEY (id_clase)
        REFERENCES clase_grupal(id_clase) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_socio_clase_fecha UNIQUE (id_socio, id_clase, fecha_inscripcion)
) ENGINE=InnoDB;

CREATE TABLE evaluacion_fisica (
    id_evaluacion INT AUTO_INCREMENT PRIMARY KEY,
    id_socio INT NOT NULL,
    id_entrenador INT NOT NULL,
    fecha_evaluacion DATE NOT NULL DEFAULT (CURRENT_DATE),
    peso_kg DECIMAL(5,2) NOT NULL,
    estatura_cm DECIMAL(5,2) NOT NULL,
    porcentaje_grasa DECIMAL(4,2) NULL,
    notas VARCHAR(255) NULL,
    CONSTRAINT fk_eval_socio FOREIGN KEY (id_socio)
        REFERENCES socio(id_socio) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_eval_entrenador FOREIGN KEY (id_entrenador)
        REFERENCES entrenador(id_entrenador) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_eval_peso CHECK (peso_kg > 20 AND peso_kg < 350),
    CONSTRAINT chk_eval_estatura CHECK (estatura_cm > 80 AND estatura_cm < 250)
) ENGINE=InnoDB;

CREATE TABLE rutina (
    id_rutina INT AUTO_INCREMENT PRIMARY KEY,
    id_socio INT NOT NULL,
    id_entrenador INT NOT NULL,
    nombre_rutina VARCHAR(80) NOT NULL,
    objetivo VARCHAR(60) NOT NULL,
    fecha_asignacion DATE NOT NULL DEFAULT (CURRENT_DATE),
    descripcion TEXT NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_rutina_socio FOREIGN KEY (id_socio)
        REFERENCES socio(id_socio) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rutina_entrenador FOREIGN KEY (id_entrenador)
        REFERENCES entrenador(id_entrenador) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE categoria_producto (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NULL
) ENGINE=InnoDB;

CREATE TABLE producto (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,
    nombre_producto VARCHAR(80) NOT NULL UNIQUE,
    precio_venta DECIMAL(8,2) NOT NULL,
    stock_actual INT NOT NULL DEFAULT 0,
    stock_minimo INT NOT NULL DEFAULT 5,
    CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria)
        REFERENCES categoria_producto(id_categoria) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_producto_precio CHECK (precio_venta > 0),
    CONSTRAINT chk_producto_stock CHECK (stock_actual >= 0 AND stock_minimo >= 0)
) ENGINE=InnoDB;

CREATE TABLE venta (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_socio INT NULL,
    fecha_venta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_venta DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    metodo_pago ENUM('Efectivo', 'Tarjeta', 'Transferencia') NOT NULL,
    CONSTRAINT fk_venta_socio FOREIGN KEY (id_socio)
        REFERENCES socio(id_socio) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_venta_total CHECK (total_venta >= 0)
) ENGINE=InnoDB;

CREATE TABLE detalle_venta (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario_venta DECIMAL(8,2) NOT NULL,
    subtotal DECIMAL(8,2) NOT NULL,
    CONSTRAINT fk_detalle_venta FOREIGN KEY (id_venta)
        REFERENCES venta(id_venta) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detalle_precio CHECK (precio_unitario_venta > 0)
) ENGINE=InnoDB;

INSERT INTO usuario_sistema (nombre_usuario, password_hash, rol, activo) VALUES
('admin_gibran', 'admin1234', 'Administrador', TRUE),
('recep_jorge', 'recep1234', 'Recepcionista', TRUE),
('recep_laura', 'laura2026', 'Recepcionista', TRUE);

INSERT INTO socio (nombre, apellidos, fecha_nacimiento, telefono, correo, tel_emergencia, fecha_registro) VALUES
('Carlos', 'Mendoza Ruiz', '1998-05-14', '6461122334', 'carlos.mendoza@email.com', '6469988776', '2026-01-10'),
('Ana Sofía', 'López Estrada', '2001-09-22', '6462233445', 'anasofia.lopez@email.com', '6468877665', '2026-02-15'),
('Roberto', 'Gómez Pineda', '1992-11-03', '6463344556', 'roberto.gp@email.com', '6467766554', '2026-03-01'),
('Valeria', 'Torres Castillo', '2003-04-18', '6464455667', 'valeria.tc@email.com', '6466655443', '2026-05-20'),
('Diego', 'Ramírez Soto', '1995-08-30', '6465566778', 'diego.ramirez@email.com', '6465544332', '2026-08-12'),
('Fernanda', 'Núñez Vega', '1999-12-11', '6466677889', 'fer.nunez@email.com', '6464433221', '2026-10-01');

INSERT INTO plan_membresia (nombre_plan, duracion_dias, precio_actual, activo) VALUES
('Visita Diaria', 1, 80.00, TRUE),
('Plan Mensual', 30, 650.00, TRUE),
('Plan Estudiante Mensual', 30, 500.00, TRUE),
('Plan Trimestral', 90, 1750.00, TRUE),
('Plan Anual VIP', 365, 6200.00, TRUE);

INSERT INTO suscripcion (id_socio, id_plan, fecha_inicio, fecha_fin, estado) VALUES
(1, 5, DATE_SUB(CURDATE(), INTERVAL 60 DAY), DATE_ADD(CURDATE(), INTERVAL 305 DAY), 'Activa'),
(2, 3, DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 20 DAY), 'Activa'),
(3, 2, DATE_SUB(CURDATE(), INTERVAL 45 DAY), DATE_SUB(CURDATE(), INTERVAL 15 DAY), 'Vencida'),
(4, 4, DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_ADD(CURDATE(), INTERVAL 70 DAY), 'Activa'),
(5, 2, DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 25 DAY), 'Activa'),
(6, 2, DATE_SUB(CURDATE(), INTERVAL 40 DAY), DATE_SUB(CURDATE(), INTERVAL 10 DAY), 'Vencida');

INSERT INTO pago (id_suscripcion, monto_pagado, fecha_pago, metodo_pago) VALUES
(1, 6200.00, DATE_SUB(NOW(), INTERVAL 60 DAY), 'Tarjeta'),
(2, 500.00, DATE_SUB(NOW(), INTERVAL 10 DAY), 'Efectivo'),
(3, 650.00, DATE_SUB(NOW(), INTERVAL 45 DAY), 'Transferencia'),
(4, 1750.00, DATE_SUB(NOW(), INTERVAL 20 DAY), 'Tarjeta'),
(5, 650.00, DATE_SUB(NOW(), INTERVAL 5 DAY), 'Efectivo'),
(6, 650.00, DATE_SUB(NOW(), INTERVAL 40 DAY), 'Efectivo');

INSERT INTO asistencia (id_socio, fecha_hora_entrada) VALUES
(1, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(4, NOW()),
(5, NOW());

INSERT INTO entrenador (nombre_completo, especialidad, telefono, activo) VALUES
('Héctor Morales Díaz', 'Pesas e Hipertrofia', '6461010101', TRUE),
('Mariana Salazar Cruz', 'Spinning y Cardio', '6462020202', TRUE),
('Luis Fernando Ortega', 'CrossFit y Funcional', '6463030303', TRUE),
('Sofía Méndez Ríos', 'Yoga y Movilidad', '6464040404', FALSE);

INSERT INTO clase_grupal (id_entrenador, nombre_clase, dia_semana, hora_inicio, hora_fin, cupo_maximo) VALUES
(2, 'Spinning Extremo', 'Lunes', '07:00:00', '08:00:00', 15),
(3, 'Funcional HIIT', 'Martes', '18:00:00', '19:00:00', 12),
(1, 'Taller de Fuerza', 'Miércoles', '17:00:00', '18:30:00', 10),
(2, 'Spinning Nocturno VIP', 'Jueves', '20:00:00', '21:00:00', 2);

INSERT INTO inscripcion_clase (id_socio, id_clase, fecha_inscripcion, estatus) VALUES
(1, 1, CURDATE(), 'Confirmada'),
(2, 1, CURDATE(), 'Confirmada'),
(4, 2, CURDATE(), 'Confirmada'),
(1, 4, CURDATE(), 'Confirmada'),
(5, 4, CURDATE(), 'Confirmada');

INSERT INTO evaluacion_fisica (id_socio, id_entrenador, fecha_evaluacion, peso_kg, estatura_cm, porcentaje_grasa, notas) VALUES
(1, 1, DATE_SUB(CURDATE(), INTERVAL 60 DAY), 84.50, 178.00, 21.50, 'Inicio de etapa de recomposición corporal'),
(1, 1, DATE_SUB(CURDATE(), INTERVAL 15 DAY), 81.20, 178.00, 18.20, 'Excelente progreso, aumento de fuerza en básicos'),
(2, 3, DATE_SUB(CURDATE(), INTERVAL 10 DAY), 58.00, 163.00, 24.00, 'Enfoque en resistencia cardiovascular y tonificación'),
(4, 1, DATE_SUB(CURDATE(), INTERVAL 20 DAY), 62.40, 168.00, 22.80, 'Sin lesiones previas, buena movilidad');

INSERT INTO rutina (id_socio, id_entrenador, nombre_rutina, objetivo, fecha_asignacion, descripcion, activa) VALUES
(1, 1, 'Adaptación Full Body', 'Acondicionamiento', DATE_SUB(CURDATE(), INTERVAL 60 DAY), 'Circuito 3 días: Sentadilla 3x12, Press banca 3x12, Remo 3x12', FALSE),
(1, 1, 'Torso / Pierna Hipertrofia', 'Hipertrofia', DATE_SUB(CURDATE(), INTERVAL 15 DAY), '4 días: Lunes/Jueves Torso pesado, Martes/Viernes Pierna enfoque cuádriceps', TRUE),
(2, 3, 'Quema Calórica y Core', 'Resistencia', DATE_SUB(CURDATE(), INTERVAL 10 DAY), 'HIIT 20 min + Planchas 4x45s + Zancadas 3x15', TRUE),
(4, 1, 'Fuerza Tren Inferior', 'Fuerza', DATE_SUB(CURDATE(), INTERVAL 20 DAY), 'Hip Thrust 4x10, Peso Muerto Rumano 4x10, Prensa 3x12', TRUE);

INSERT INTO categoria_producto (nombre_categoria, descripcion) VALUES
('Bebidas Hidratantes', 'Agua natural, electrolitos y bebidas energéticas'),
('Suplementos', 'Proteínas en polvo, creatina y pre-entrenos individuales'),
('Barras y Snacks', 'Barras proteicas y colaciones saludables'),
('Accesorios', 'Candados, guantes, straps y botellas reutilizables');

INSERT INTO producto (id_categoria, nombre_producto, precio_venta, stock_actual, stock_minimo) VALUES
(1, 'Agua Natural 1L', 20.00, 45, 10),
(1, 'Electrolit Mora Azul 625ml', 32.00, 24, 8),
(2, 'Scoop Proteína Whey Chocolate', 45.00, 30, 5),
(2, 'Shot Pre-Entreno C4', 40.00, 4, 5),
(3, 'Barra Proteína Quest Cookies', 55.00, 18, 6),
(4, 'Candado de Combinación Gym', 120.00, 10, 3);

INSERT INTO venta (id_socio, fecha_venta, total_venta, metodo_pago) VALUES
(1, DATE_SUB(NOW(), INTERVAL 1 DAY), 65.00, 'Efectivo'),
(NULL, NOW(), 52.00, 'Efectivo'),
(2, NOW(), 95.00, 'Tarjeta');

INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario_venta, subtotal) VALUES
(1, 1, 1, 20.00, 20.00),
(1, 3, 1, 45.00, 45.00),
(2, 1, 1, 20.00, 20.00),
(2, 2, 1, 32.00, 32.00),
(3, 4, 1, 40.00, 40.00),
(3, 5, 1, 55.00, 55.00);

CREATE OR REPLACE VIEW vw_socios_estatus_acceso AS
SELECT s.id_socio,
       CONCAT(s.nombre, ' ', s.apellidos) AS nombre_completo,
       s.telefono,
       p.nombre_plan,
       sub.fecha_fin,
       CASE
           WHEN sub.estado = 'Activa' AND sub.fecha_fin >= CURDATE() THEN 'PERMITIDO'
           ELSE 'DENEGADO - VENCIDA'
       END AS acceso_recepcion
FROM socio s
LEFT JOIN suscripcion sub ON s.id_socio = sub.id_socio
    AND sub.id_suscripcion = (SELECT MAX(id_suscripcion) FROM suscripcion WHERE id_socio = s.id_socio)
LEFT JOIN plan_membresia p ON sub.id_plan = p.id_plan;

CREATE OR REPLACE VIEW vw_resumen_ventas_productos AS
SELECT p.id_producto, p.nombre_producto, c.nombre_categoria,
       p.precio_venta, p.stock_actual,
       COALESCE(SUM(dv.cantidad), 0) AS total_vendidos,
       COALESCE(SUM(dv.subtotal), 0.00) AS monto_recaudado
FROM producto p
INNER JOIN categoria_producto c ON p.id_categoria = c.id_categoria
LEFT JOIN detalle_venta dv ON p.id_producto = dv.id_producto
GROUP BY p.id_producto, p.nombre_producto, c.nombre_categoria, p.precio_venta, p.stock_actual;

DELIMITER //

DROP TRIGGER IF EXISTS trg_validar_acceso_socio //
CREATE TRIGGER trg_validar_acceso_socio
BEFORE INSERT ON asistencia
FOR EACH ROW
BEGIN
    DECLARE v_vigente INT DEFAULT 0;
    SELECT COUNT(*) INTO v_vigente
    FROM suscripcion
    WHERE id_socio = NEW.id_socio
      AND estado = 'Activa'
      AND fecha_fin >= CURDATE();

    IF v_vigente = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ACCESO DENEGADO: El socio no cuenta con una suscripcion activa y vigente.';
    END IF;
END //

DROP TRIGGER IF EXISTS trg_validar_cupo_clase //
CREATE TRIGGER trg_validar_cupo_clase
BEFORE INSERT ON inscripcion_clase
FOR EACH ROW
BEGIN
    DECLARE v_cupo_max INT DEFAULT 0;
    DECLARE v_inscritos INT DEFAULT 0;

    IF NEW.estatus = 'Confirmada' THEN
        SELECT cupo_maximo INTO v_cupo_max
        FROM clase_grupal WHERE id_clase = NEW.id_clase;

        SELECT COUNT(*) INTO v_inscritos
        FROM inscripcion_clase
        WHERE id_clase = NEW.id_clase
          AND fecha_inscripcion = NEW.fecha_inscripcion
          AND estatus = 'Confirmada';

        IF v_inscritos >= v_cupo_max THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'CUPO LLENO: La clase grupal ya alcanzo su capacidad maxima.';
        END IF;
    END IF;
END //

DROP TRIGGER IF EXISTS trg_descontar_stock_venta //
CREATE TRIGGER trg_descontar_stock_venta
BEFORE INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    DECLARE v_stock INT DEFAULT 0;
    SELECT stock_actual INTO v_stock
    FROM producto WHERE id_producto = NEW.id_producto;

    IF v_stock < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'STOCK INSUFICIENTE: No hay unidades disponibles para completar la venta.';
    ELSE
        UPDATE producto
        SET stock_actual = stock_actual - NEW.cantidad
        WHERE id_producto = NEW.id_producto;
    END IF;
END //

DROP TRIGGER IF EXISTS trg_auditoria_cambio_suscripcion //
CREATE TRIGGER trg_auditoria_cambio_suscripcion
AFTER UPDATE ON suscripcion
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado OR OLD.fecha_fin <> NEW.fecha_fin THEN
        INSERT INTO auditoria_suscripcion (
            id_suscripcion, id_socio, estado_anterior, estado_nuevo,
            fecha_fin_anterior, fecha_fin_nueva, usuario_bd
        ) VALUES (
            NEW.id_suscripcion, NEW.id_socio, OLD.estado, NEW.estado,
            OLD.fecha_fin, NEW.fecha_fin, USER()
        );
    END IF;
END //

DROP TRIGGER IF EXISTS trg_proteger_pagos_update //
CREATE TRIGGER trg_proteger_pagos_update
BEFORE UPDATE ON pago
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'OPERACION PROHIBIDA: Un pago registrado no puede ser modificado.';
END //

DROP TRIGGER IF EXISTS trg_proteger_pagos_delete //
CREATE TRIGGER trg_proteger_pagos_delete
BEFORE DELETE ON pago
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'OPERACION PROHIBIDA: Un pago registrado no puede ser eliminado.';
END //

DROP FUNCTION IF EXISTS fn_calcular_imc //
CREATE FUNCTION fn_calcular_imc(p_peso_kg DECIMAL(5,2), p_estatura_cm DECIMAL(5,2))
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_estatura_m DECIMAL(5,2);
    SET v_estatura_m = p_estatura_cm / 100;
    RETURN ROUND(p_peso_kg / (v_estatura_m * v_estatura_m), 2);
END //

DROP PROCEDURE IF EXISTS sp_registrar_suscripcion //
CREATE PROCEDURE sp_registrar_suscripcion(
    IN p_id_socio INT,
    IN p_id_plan INT,
    IN p_metodo_pago ENUM('Efectivo', 'Tarjeta', 'Transferencia')
)
BEGIN
    DECLARE v_duracion INT;
    DECLARE v_precio DECIMAL(8,2);
    DECLARE v_nueva_suscripcion INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        SELECT duracion_dias, precio_actual INTO v_duracion, v_precio
        FROM plan_membresia WHERE id_plan = p_id_plan AND activo = TRUE;

        IF v_duracion IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El plan seleccionado no existe o esta inactivo.';
        END IF;

        UPDATE suscripcion SET estado = 'Vencida'
        WHERE id_socio = p_id_socio AND estado = 'Activa';

        INSERT INTO suscripcion (id_socio, id_plan, fecha_inicio, fecha_fin, estado)
        VALUES (p_id_socio, p_id_plan, CURDATE(), DATE_ADD(CURDATE(), INTERVAL v_duracion DAY), 'Activa');

        SET v_nueva_suscripcion = LAST_INSERT_ID();

        INSERT INTO pago (id_suscripcion, monto_pagado, metodo_pago)
        VALUES (v_nueva_suscripcion, v_precio, p_metodo_pago);
    COMMIT;
END //

DROP PROCEDURE IF EXISTS sp_asignar_rutina //
CREATE PROCEDURE sp_asignar_rutina(
    IN p_id_socio INT,
    IN p_id_entrenador INT,
    IN p_nombre_rutina VARCHAR(80),
    IN p_objetivo VARCHAR(60),
    IN p_descripcion TEXT
)
BEGIN
    DECLARE v_entrenador_activo BOOLEAN DEFAULT FALSE;

    SELECT activo INTO v_entrenador_activo
    FROM entrenador WHERE id_entrenador = p_id_entrenador;

    IF v_entrenador_activo IS NULL OR v_entrenador_activo = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'OPERACION INVALIDA: El entrenador no existe o esta inactivo.';
    END IF;

    UPDATE rutina SET activa = FALSE WHERE id_socio = p_id_socio AND activa = TRUE;

    INSERT INTO rutina (id_socio, id_entrenador, nombre_rutina, objetivo, descripcion, activa)
    VALUES (p_id_socio, p_id_entrenador, p_nombre_rutina, p_objetivo, p_descripcion, TRUE);
END //

DELIMITER ;

SELECT s.id_socio, CONCAT(s.nombre, ' ', s.apellidos) AS socio, p.nombre_plan,
       sub.fecha_inicio, sub.fecha_fin, sub.estado,
       DATEDIFF(sub.fecha_fin, CURDATE()) AS dias_restantes
FROM socio s
INNER JOIN suscripcion sub ON s.id_socio = sub.id_socio
INNER JOIN plan_membresia p ON sub.id_plan = p.id_plan
ORDER BY sub.fecha_fin ASC;

SELECT c.id_clase, c.nombre_clase, c.dia_semana, c.hora_inicio, c.hora_fin,
       e.nombre_completo AS entrenador, c.cupo_maximo,
       COUNT(ic.id_inscripcion) AS inscritos_confirmados
FROM clase_grupal c
INNER JOIN entrenador e ON c.id_entrenador = e.id_entrenador
LEFT JOIN inscripcion_clase ic ON c.id_clase = ic.id_clase AND ic.estatus = 'Confirmada'
GROUP BY c.id_clase, c.nombre_clase, c.dia_semana, c.hora_inicio, c.hora_fin, e.nombre_completo, c.cupo_maximo;

SELECT v.id_venta, v.fecha_venta,
       COALESCE(CONCAT(s.nombre, ' ', s.apellidos), 'Visitante Externo') AS cliente,
       pr.nombre_producto, dv.cantidad, dv.precio_unitario_venta, dv.subtotal, v.metodo_pago
FROM venta v
LEFT JOIN socio s ON v.id_socio = s.id_socio
INNER JOIN detalle_venta dv ON v.id_venta = dv.id_venta
INNER JOIN producto pr ON dv.id_producto = pr.id_producto
ORDER BY v.id_venta;

SELECT s.id_socio, s.nombre, s.apellidos, s.telefono
FROM socio s
WHERE EXISTS (
    SELECT 1 FROM suscripcion sub
    WHERE sub.id_socio = s.id_socio AND sub.estado = 'Activa' AND sub.fecha_fin >= CURDATE()
)
AND NOT EXISTS (
    SELECT 1 FROM asistencia a
    WHERE a.id_socio = s.id_socio AND DATE(a.fecha_hora_entrada) = CURDATE()
);

SELECT p.id_producto, p.nombre_producto, p.precio_venta, p.stock_actual
FROM producto p
WHERE NOT EXISTS (
    SELECT 1 FROM detalle_venta dv WHERE dv.id_producto = p.id_producto
);

SELECT metodo_pago, COUNT(id_pago) AS total_transacciones, SUM(monto_pagado) AS ingresos_totales
FROM pago
GROUP BY metodo_pago
HAVING SUM(monto_pagado) > 1000.00
ORDER BY ingresos_totales DESC;

SELECT cat.nombre_categoria, SUM(dv.cantidad) AS unidades_vendidas, SUM(dv.subtotal) AS total_ingresos
FROM categoria_producto cat
INNER JOIN producto p ON cat.id_categoria = p.id_categoria
INNER JOIN detalle_venta dv ON p.id_producto = dv.id_producto
GROUP BY cat.nombre_categoria
ORDER BY total_ingresos DESC;

SELECT s.id_socio, CONCAT(s.nombre, ' ', s.apellidos) AS socio,
       COUNT(ef.id_evaluacion) AS num_evaluaciones,
       MAX(ef.peso_kg) - MIN(ef.peso_kg) AS variacion_peso_kg
FROM socio s
INNER JOIN evaluacion_fisica ef ON s.id_socio = ef.id_socio
GROUP BY s.id_socio, s.nombre, s.apellidos
HAVING COUNT(ef.id_evaluacion) > 1;

SELECT p.id_producto, c.nombre_categoria, p.nombre_producto, p.stock_actual, p.stock_minimo,
       (p.stock_minimo - p.stock_actual) AS deficit
FROM producto p
INNER JOIN categoria_producto c ON p.id_categoria = c.id_categoria
WHERE p.stock_actual <= p.stock_minimo;

SELECT s.id_socio, CONCAT(s.nombre, ' ', s.apellidos) AS socio,
       r.nombre_rutina, r.objetivo, e.nombre_completo AS entrenador_asignado
FROM socio s
INNER JOIN rutina r ON s.id_socio = r.id_socio AND r.activa = TRUE
INNER JOIN entrenador e ON r.id_entrenador = e.id_entrenador;

START TRANSACTION;
INSERT INTO venta (id_socio, total_venta, metodo_pago) VALUES (4, 40.00, 'Efectivo');
SET @ultima_venta = LAST_INSERT_ID();
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario_venta, subtotal)
VALUES (@ultima_venta, 1, 2, 20.00, 40.00);
COMMIT;

START TRANSACTION;
INSERT INTO venta (id_socio, total_venta, metodo_pago) VALUES (5, 120.00, 'Tarjeta');
ROLLBACK;
