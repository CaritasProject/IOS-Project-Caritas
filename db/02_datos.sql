/* =============================================================================
   Sistema de Ingresos — Cáritas de Monterrey, A.B.P.
   02_datos.sql · Catálogos y datos de prueba
   Ejecutar después de 01_esquema.sql.

   Origen de los datos
   - Catálogos: valores del Diccionario de Conceptos (sección 1). Se corrigen
     acentos para que la interfaz no muestre faltas de ortografía.
   - Donantes 1 a 8, sus pagos, llamadas, metas, usuarios e historial de
     reportes: prototipo aprobado (Sistema de Ingresos · iPad Pro v2).
     Los cobros se completan hacia atrás hasta cubrir 12 meses, y hasta
     septiembre de 2026 siguiendo el mismo patrón de cada donante.
   - Donantes 9 y 10: datos de prueba para los niveles amarillo y rojo del
     semáforo, que ningún donante del prototipo cubre.
   - Contraseña de todos los usuarios de prueba: se entrega aparte; aquí solo
     se guarda el hash (werkzeug.security.generate_password_hash).
============================================================================= */

USE SistemaIngresos;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

/* ---------- Limpieza de datos previos ---------- */
DELETE FROM dbo.REPORTE_CAMPANA_FINANCIERA;
DELETE FROM dbo.REPORTE_LINEA_ESTRATEGICA;
DELETE FROM dbo.HISTORIAL_REPORTE;
DELETE FROM dbo.CAT_FORMATO_REPORTE;
DELETE FROM dbo.CAT_TIPO_REPORTE;
DELETE FROM dbo.META;
DELETE FROM dbo.REGISTRO_LLAMADA;
DELETE FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS;
DELETE FROM dbo.OPE_DONATIVOS_DONANTE;
DELETE FROM dbo.OPE_DONANTES;
DELETE FROM dbo.USUARIO;
DELETE FROM dbo.RECOLECTOR;
DELETE FROM dbo.CAT_ROL;
DELETE FROM dbo.CAT_ESTATUS_PAGO;
DELETE FROM dbo.CAT_ESTATUS_DONATIVO;
DELETE FROM dbo.CAT_CAMPANA_FINANCIERA;
DELETE FROM dbo.CAT_ASIGNACION;
DELETE FROM dbo.CAT_LINEA_ESTRATEGICA;
DELETE FROM dbo.CAT_TIPO_FRECUENCIA;
DELETE FROM dbo.CAT_FRECUENCIA;
DELETE FROM dbo.CAT_FORMA_PAGO;
DELETE FROM dbo.CAT_CLASIFICACION;
DELETE FROM dbo.CAT_TIPO_DONANTE;

/* =============================================================================
   CATÁLOGOS
============================================================================= */

-- 1.21
INSERT INTO dbo.CAT_TIPO_DONANTE (ID_TIPO_DONANTE, NOMBRE) VALUES
    (1, N'FÍSICO'),
    (2, N'FUNDACIONES'),
    (3, N'GOB'),
    (4, N'MORAL'),
    (5, N'ONG');

-- 1.22 (ejemplos del Diccionario; la mayoría de los donantes son ORDINARIO)
INSERT INTO dbo.CAT_CLASIFICACION (ID_CLASIFICACION, NOMBRE) VALUES
    (1, N'ASAMBLEÍSTA'),
    (2, N'PATRONO'),
    (3, N'ORDINARIO'),
    (4, N'VIP');

-- 1.15
INSERT INTO dbo.CAT_FORMA_PAGO (ID_FORMA_PAGO, NOMBRE) VALUES
    (1, N'CHEQUE'),
    (2, N'CHEQUE/DEPOSITADO'),
    (3, N'DEPÓSITO'),
    (4, N'EFECTIVO'),
    (5, N'EFECTIVO/DEPOSITADO'),
    (6, N'NO ESPECIFICADO'),
    (7, N'TARJETA DE CRÉDITO'),
    (8, N'TARJETA DE DÉBITO'),
    (9, N'TRANSFERENCIA');

-- 1.16
INSERT INTO dbo.CAT_FRECUENCIA (ID_FRECUENCIA, NOMBRE) VALUES
    (1, N'PERMANENTE'),
    (2, N'TEMPORAL');

-- 1.17
INSERT INTO dbo.CAT_TIPO_FRECUENCIA (ID_TIPO_FRECUENCIA, NOMBRE) VALUES
    (1, N'SEMANAL'),
    (2, N'QUINCENAL'),
    (3, N'MENSUAL'),
    (4, N'BIMESTRAL'),
    (5, N'TRIMESTRAL'),
    (6, N'SEMESTRAL');

-- 1.5
INSERT INTO dbo.CAT_LINEA_ESTRATEGICA (ID_LINEA_ESTRATEGICA, NOMBRE) VALUES
    (1, N'TELEMARKETING'),
    (2, N'EVENTOS'),
    (3, N'FUNDACIONES'),
    (4, N'MEDIOS DE COMUNICACIÓN'),
    (5, N'COLECTA ÁNFORAS'),
    (6, N'DONATIVOS POR ÁREA');

-- 1.7 (OBRA = donativo libre) y asignaciones que usa el prototipo en Metas
INSERT INTO dbo.CAT_ASIGNACION (ID_ASIGNACION, NOMBRE) VALUES
    (1, N'OBRA'),
    (2, N'CASOS'),
    (3, N'BANCO DE ALIMENTOS'),
    (4, N'BRIGADAS DE SALUD'),
    (5, N'DAMNIFICADOS'),
    (6, N'DISPENSARIOS MÉDICOS'),
    (7, N'POSADA DEL PEREGRINO'),
    (8, N'PROMOCIÓN HUMANA'),
    (9, N'BANCO DE MEDICAMENTOS');

-- 1.6 (CORREO DIRECTO equivale a Telemarketing)
INSERT INTO dbo.CAT_CAMPANA_FINANCIERA (ID_CAMPANA_FINANCIERA, NOMBRE) VALUES
    (1, N'CORREO DIRECTO'),
    (2, N'TU AYUDA MI ÚNICA ESPERANZA'),
    (3, N'ESTÍMULOS PÚBLICOS');

-- Valores no documentados por Cáritas
INSERT INTO dbo.CAT_ESTATUS_DONATIVO (ID_ESTATUS, NOMBRE) VALUES
    (1, N'ACTIVO'),
    (2, N'CANCELADO'),
    (3, N'CONCLUIDO');

INSERT INTO dbo.CAT_ESTATUS_PAGO (ID_ESTATUS_PAGO, NOMBRE) VALUES
    (1, N'COBRADO'),
    (2, N'RECHAZADO'),
    (3, N'PENDIENTE');

INSERT INTO dbo.CAT_TIPO_REPORTE (ID_TIPO_REPORTE, NOMBRE) VALUES
    (1, N'INGRESOS'),
    (2, N'COBRANZA'),
    (3, N'TELEMARKETING'),
    (4, N'METAS');

INSERT INTO dbo.CAT_FORMATO_REPORTE (ID_FORMATO, NOMBRE) VALUES
    (1, N'PDF'),
    (2, N'EXCEL'),
    (3, N'CSV');

INSERT INTO dbo.CAT_ROL (ID_ROL, NOMBRE) VALUES
    (1, N'ADMINISTRADOR'),
    (2, N'TELEFONISTA'),
    (3, N'RECOLECTOR');

-- 1.19 Zonas de recolección (el Diccionario no da los nombres de los recolectores)
INSERT INTO dbo.RECOLECTOR (NOMBRE, ZONA) VALUES
    (NULL, N'CENTRO Y SUR DE MONTERREY'),
    (NULL, N'ESPECIAL'),
    (NULL, N'FORÁNEA'),
    (NULL, N'GUADALUPE, JUÁREZ Y CARRETERA NACIONAL'),
    (NULL, N'MONTERREY PONIENTE, ESCOBEDO Y GARCÍA-LINCOLN'),
    (NULL, N'OTROS (ZUAZUA, EL CARMEN, CIÉNEGA DE FLORES, SALINAS VICTORIA, SANTIAGO)'),
    (NULL, N'SAN NICOLÁS Y APODACA'),
    (NULL, N'SAN PEDRO, SANTA CATARINA Y GARCÍA-CENTRO');

/* =============================================================================
   USUARIOS (perfil del prototipo y agentes que aparecen en la bitácora)
============================================================================= */
SET IDENTITY_INSERT dbo.USUARIO ON;
INSERT INTO dbo.USUARIO (ID_USUARIO, NOMBRE, CORREO, CONTRASENA_HASH, ID_ROL, AREA, ULTIMO_ACCESO) VALUES
    (1, N'Mariana Guerra', N'mariana.guerra@caritas.org.mx',
     N'scrypt:32768:8:1$qYznI421Xt8ez0bx$da20728a36b74fd504210956613858d3b595fd047ed9b88797fc088ba5fa66fbb181c840da9c0ef40cde9b096d9fdad5028fc1ecc5aff390618a83c52cb64eb5',
     1, N'Dirección General', '2026-08-27 08:42:00'),
    (2, N'L. Cantú', N'l.cantu@caritas.org.mx',
     N'scrypt:32768:8:1$0f49i5iYTF2t1Lw3$240f5f00dc59cf815f8f1fa5df913827657ae48b7aa7ee2bd5cd148c0a72fd18991e64882bec5578cb37b1fb4fd9f8ab8da2ffdf8915d391560dc6a78b15c7dd',
     2, N'Procuración de Fondos', NULL),
    (3, N'R. Salas', N'r.salas@caritas.org.mx',
     N'scrypt:32768:8:1$FtV4eYUjln1N8f0n$392247762af282caf1c031eb6902af99550c6bea25dbc22b4bcbce906a23e0b45847ddf811d810f6040bd5641b490210784337c7741d710fa854ff0f875ba2b2',
     2, N'Procuración de Fondos', NULL),
    (4, N'D. Ochoa', N'd.ochoa@caritas.org.mx',
     N'scrypt:32768:8:1$JxAtCyW8WRGgQuDY$d7191bb12325b6469e19c9912f89026483304cc3879618cb3d7c67b7593d2fea3d5cbcaef4cf2af1ca3e620ff5587554afc1ae548b76966333068c7d224e15fc',
     2, N'Procuración de Fondos', NULL),
    (5, N'M. Reyna', N'm.reyna@caritas.org.mx',
     N'scrypt:32768:8:1$s5j9EA9FhFAjdz15$0231656cb13ebaf7fe7b756817b136aacd284cecdc5ac99e020e916bcd701edcbbdaec1cd9c7da544fa44bd16a95a296801c2e5c99aaa76cf5326209a13b1180',
     2, N'Procuración de Fondos', NULL);
SET IDENTITY_INSERT dbo.USUARIO OFF;

/* =============================================================================
   DONANTES
   1 a 8: prototipo aprobado · 9 y 10: prueba de los niveles amarillo y rojo
============================================================================= */
SET IDENTITY_INSERT dbo.OPE_DONANTES ON;
INSERT INTO dbo.OPE_DONANTES (ID_DONANTE, NOMBRE, A_PATERNO, A_MATERNO, RAZON_SOCIAL, ID_TIPO_DONANTE, ID_CLASIFICACION, FECHA_ALTA, ESTATUS_DONANTE) VALUES
    (1, N'María Elena', N'Treviño', NULL, NULL, 1, 3, '2018-03-01', N'ACTIVO'),
    (2, NULL, NULL, NULL, N'Grupo Industrial Ánimas', 4, 3, '2015-01-01', N'ACTIVO'),
    (3, N'Jorge Alberto', N'Sandoval', NULL, NULL, 1, 3, '2021-09-01', N'ACTIVO'),
    (4, NULL, NULL, NULL, N'Fundación Sierra Madre', 2, 3, '2012-05-01', N'ACTIVO'),
    (5, N'Ana Sofía', N'Villarreal', NULL, NULL, 1, 3, '2023-02-01', N'ACTIVO'),
    (6, N'Roberto', N'Cárdenas', N'Lozano', NULL, 1, 3, '2019-08-01', N'ACTIVO'),
    (7, NULL, NULL, NULL, N'Comercializadora del Norte', 4, 3, '2017-10-01', N'ACTIVO'),
    (8, N'Guadalupe', N'Ramírez', NULL, NULL, 1, 3, '2020-07-01', N'INACTIVO'),
    (9, N'Patricia', N'Garza', N'Leal', NULL, 1, 3, '2026-01-10', N'INACTIVO'),
    (10, N'Luis Fernando', N'Medina', NULL, NULL, 1, 3, '2025-06-10', N'INACTIVO');
SET IDENTITY_INSERT dbo.OPE_DONANTES OFF;

/* =============================================================================
   COMPROMISOS (OPE_DONATIVOS_DONANTE)
   Frecuencia y forma de pago del prototipo: "domiciliado" = TARJETA DE CRÉDITO
============================================================================= */
SET IDENTITY_INSERT dbo.OPE_DONATIVOS_DONANTE ON;
INSERT INTO dbo.OPE_DONATIVOS_DONANTE (ID_DONATIVO, ID_DONANTE, IMPORTE, ID_FORMA_PAGO, ID_FRECUENCIA, ID_TIPO_FRECUENCIA, PAGO_UNICO, ID_LINEA_ESTRATEGICA, ID_ASIGNACION, ID_CAMPANA_FINANCIERA, ID_ESTATUS, FECHA_ALTA) VALUES
    (1, 1, 4000.00, 7, 1, 3, 0, 1, 3, 1, 1, '2018-03-01'),
    (2, 2, 30000.00, 9, 1, 3, 0, 1, 9, 1, 1, '2015-01-01'),
    (3, 3, 1200.00, 7, 1, 3, 0, 1, 6, 1, 1, '2021-09-01'),
    (4, 4, 135000.00, 9, 1, 5, 0, 3, 7, NULL, 1, '2012-05-01'),
    (5, 5, 800.00, 7, 1, 3, 0, 1, 8, 1, 1, '2023-02-01'),
    (6, 6, 1800.00, 7, 1, 3, 0, 1, 3, 1, 1, '2019-08-01'),
    (7, 7, 22000.00, 9, 1, 3, 0, 1, 6, 1, 1, '2017-10-01'),
    (8, 8, 600.00, 7, 1, 3, 0, 1, 8, 1, 2, '2020-07-01'),
    (9, 9, 500.00, 7, 2, 3, 0, 1, 1, 1, 3, '2026-01-10'),
    (10, 10, 2500.00, 4, NULL, NULL, 1, 2, 1, NULL, 3, '2025-06-10');
SET IDENTITY_INSERT dbo.OPE_DONATIVOS_DONANTE OFF;

/* =============================================================================
   COBROS (OPE_BITACORA_PAGOS_DONATIVOS)
   Vencimiento: 10 días después de la fecha programada.
============================================================================= */
INSERT INTO dbo.OPE_BITACORA_PAGOS_DONATIVOS (ID_DONATIVO, ID_RECOLECTOR, FECHA_COBRO, FECHA_VENCIMIENTO, FECHA_PAGO, IMPORTE, IMPORTE_COBRADO, ESTATUS_PAGO) VALUES
    (1, NULL, '2025-08-10', '2025-08-20', '2025-08-10', 4000.00, 4000.00, 1),
    (1, NULL, '2025-09-10', '2025-09-20', '2025-09-10', 4000.00, 4000.00, 1),
    (1, NULL, '2025-10-10', '2025-10-20', '2025-10-10', 4000.00, 4000.00, 1),
    (1, NULL, '2025-11-10', '2025-11-20', '2025-11-10', 4000.00, 4000.00, 1),
    (1, NULL, '2025-12-10', '2025-12-20', '2025-12-10', 4000.00, 4000.00, 1),
    (1, NULL, '2026-01-10', '2026-01-20', '2026-01-10', 4000.00, 4000.00, 1),
    (1, NULL, '2026-02-10', '2026-02-20', '2026-02-10', 4000.00, 4000.00, 1),
    (1, NULL, '2026-03-10', '2026-03-20', '2026-03-10', 4000.00, 4000.00, 1),
    (1, NULL, '2026-04-10', '2026-04-20', '2026-04-10', 4000.00, 4000.00, 1),
    (1, NULL, '2026-05-11', '2026-05-21', '2026-05-11', 4000.00, 4000.00, 1),
    (1, NULL, '2026-06-12', '2026-06-22', '2026-06-12', 4000.00, 4000.00, 1),
    (1, NULL, '2026-07-10', '2026-07-20', NULL, 4000.00, 0.00, 2),
    (1, NULL, '2026-08-10', '2026-08-20', NULL, 4000.00, 0.00, 2),
    (1, NULL, '2026-09-10', '2026-09-20', NULL, 4000.00, 0.00, 2),
    (2, NULL, '2025-08-05', '2025-08-15', '2025-08-05', 30000.00, 30000.00, 1),
    (2, NULL, '2025-09-05', '2025-09-15', '2025-09-05', 30000.00, 30000.00, 1),
    (2, NULL, '2025-10-05', '2025-10-15', '2025-10-05', 30000.00, 30000.00, 1),
    (2, NULL, '2025-11-05', '2025-11-15', '2025-11-05', 30000.00, 30000.00, 1),
    (2, NULL, '2025-12-05', '2025-12-15', '2025-12-05', 30000.00, 30000.00, 1),
    (2, NULL, '2026-01-05', '2026-01-15', '2026-01-05', 30000.00, 30000.00, 1),
    (2, NULL, '2026-02-05', '2026-02-15', '2026-02-05', 30000.00, 30000.00, 1),
    (2, NULL, '2026-03-05', '2026-03-15', '2026-03-05', 30000.00, 30000.00, 1),
    (2, NULL, '2026-04-05', '2026-04-15', '2026-04-05', 30000.00, 30000.00, 1),
    (2, NULL, '2026-05-05', '2026-05-15', '2026-05-05', 30000.00, 30000.00, 1),
    (2, NULL, '2026-06-05', '2026-06-15', '2026-06-05', 30000.00, 30000.00, 1),
    (2, NULL, '2026-07-05', '2026-07-15', '2026-07-05', 30000.00, 30000.00, 1),
    (2, NULL, '2026-08-05', '2026-08-15', '2026-08-05', 30000.00, 30000.00, 1),
    (2, NULL, '2026-09-05', '2026-09-15', '2026-09-05', 30000.00, 30000.00, 1),
    (3, NULL, '2025-08-16', '2025-08-26', '2025-08-16', 1200.00, 1200.00, 1),
    (3, NULL, '2025-09-16', '2025-09-26', '2025-09-16', 1200.00, 1200.00, 1),
    (3, NULL, '2025-10-16', '2025-10-26', '2025-10-16', 1200.00, 1200.00, 1),
    (3, NULL, '2025-11-16', '2025-11-26', '2025-11-16', 1200.00, 1200.00, 1),
    (3, NULL, '2025-12-16', '2025-12-26', '2025-12-16', 1200.00, 1200.00, 1),
    (3, NULL, '2026-01-16', '2026-01-26', '2026-01-16', 1200.00, 1200.00, 1),
    (3, NULL, '2026-02-16', '2026-02-26', '2026-02-16', 1200.00, 1200.00, 1),
    (3, NULL, '2026-03-16', '2026-03-26', '2026-03-16', 1200.00, 1200.00, 1),
    (3, NULL, '2026-04-16', '2026-04-26', '2026-04-16', 1200.00, 1200.00, 1),
    (3, NULL, '2026-05-16', '2026-05-26', '2026-05-16', 1200.00, 1200.00, 1),
    (3, NULL, '2026-06-16', '2026-06-26', '2026-06-16', 1200.00, 1200.00, 1),
    (3, NULL, '2026-07-18', '2026-07-28', '2026-07-18', 1200.00, 1200.00, 1),
    (3, NULL, '2026-08-15', '2026-08-25', NULL, 1200.00, 0.00, 3),
    (3, NULL, '2026-09-15', '2026-09-25', NULL, 1200.00, 0.00, 3),
    (4, NULL, '2025-08-01', '2025-08-11', '2025-08-01', 135000.00, 135000.00, 1),
    (4, NULL, '2025-11-01', '2025-11-11', '2025-11-01', 135000.00, 135000.00, 1),
    (4, NULL, '2026-02-01', '2026-02-11', '2026-02-01', 135000.00, 135000.00, 1),
    (4, NULL, '2026-05-01', '2026-05-11', '2026-05-01', 135000.00, 135000.00, 1),
    (4, NULL, '2026-08-01', '2026-08-11', '2026-08-01', 135000.00, 135000.00, 1),
    (5, NULL, '2025-08-08', '2025-08-18', '2025-08-08', 800.00, 800.00, 1),
    (5, NULL, '2025-09-08', '2025-09-18', '2025-09-08', 800.00, 800.00, 1),
    (5, NULL, '2025-10-08', '2025-10-18', '2025-10-08', 800.00, 800.00, 1),
    (5, NULL, '2025-11-08', '2025-11-18', '2025-11-08', 800.00, 800.00, 1),
    (5, NULL, '2025-12-08', '2025-12-18', '2025-12-08', 800.00, 800.00, 1),
    (5, NULL, '2026-01-08', '2026-01-18', '2026-01-08', 800.00, 800.00, 1),
    (5, NULL, '2026-02-08', '2026-02-18', '2026-02-08', 800.00, 800.00, 1),
    (5, NULL, '2026-03-08', '2026-03-18', '2026-03-08', 800.00, 800.00, 1),
    (5, NULL, '2026-04-08', '2026-04-18', '2026-04-08', 800.00, 800.00, 1),
    (5, NULL, '2026-05-08', '2026-05-18', '2026-05-08', 800.00, 800.00, 1),
    (5, NULL, '2026-06-08', '2026-06-18', '2026-06-08', 800.00, 800.00, 1),
    (5, NULL, '2026-07-08', '2026-07-18', '2026-07-08', 800.00, 800.00, 1),
    (5, NULL, '2026-08-08', '2026-08-18', '2026-08-08', 800.00, 800.00, 1),
    (5, NULL, '2026-09-08', '2026-09-18', '2026-09-08', 800.00, 800.00, 1),
    (6, NULL, '2025-08-14', '2025-08-24', '2025-08-14', 1800.00, 1800.00, 1),
    (6, NULL, '2025-09-14', '2025-09-24', '2025-09-14', 1800.00, 1800.00, 1),
    (6, NULL, '2025-10-14', '2025-10-24', '2025-10-14', 1800.00, 1800.00, 1),
    (6, NULL, '2025-11-14', '2025-11-24', '2025-11-14', 1800.00, 1800.00, 1),
    (6, NULL, '2025-12-14', '2025-12-24', '2025-12-14', 1800.00, 1800.00, 1),
    (6, NULL, '2026-01-14', '2026-01-24', '2026-01-14', 1800.00, 1800.00, 1),
    (6, NULL, '2026-02-14', '2026-02-24', '2026-02-14', 1800.00, 1800.00, 1),
    (6, NULL, '2026-03-14', '2026-03-24', '2026-03-14', 1800.00, 1800.00, 1),
    (6, NULL, '2026-04-14', '2026-04-24', '2026-04-14', 1800.00, 1800.00, 1),
    (6, NULL, '2026-05-14', '2026-05-24', '2026-05-14', 1800.00, 1800.00, 1),
    (6, NULL, '2026-06-14', '2026-06-24', NULL, 1800.00, 0.00, 2),
    (6, NULL, '2026-07-14', '2026-07-24', NULL, 1800.00, 0.00, 2),
    (6, NULL, '2026-08-14', '2026-08-24', NULL, 1800.00, 0.00, 2),
    (6, NULL, '2026-09-14', '2026-09-24', NULL, 1800.00, 0.00, 2),
    (7, NULL, '2025-08-02', '2025-08-12', '2025-08-02', 22000.00, 22000.00, 1),
    (7, NULL, '2025-09-02', '2025-09-12', '2025-09-02', 22000.00, 22000.00, 1),
    (7, NULL, '2025-10-02', '2025-10-12', '2025-10-02', 22000.00, 22000.00, 1),
    (7, NULL, '2025-11-02', '2025-11-12', '2025-11-02', 22000.00, 22000.00, 1),
    (7, NULL, '2025-12-02', '2025-12-12', '2025-12-02', 22000.00, 22000.00, 1),
    (7, NULL, '2026-01-02', '2026-01-12', '2026-01-02', 22000.00, 22000.00, 1),
    (7, NULL, '2026-02-02', '2026-02-12', '2026-02-02', 22000.00, 22000.00, 1),
    (7, NULL, '2026-03-02', '2026-03-12', '2026-03-02', 22000.00, 22000.00, 1),
    (7, NULL, '2026-04-02', '2026-04-12', '2026-04-02', 22000.00, 22000.00, 1),
    (7, NULL, '2026-05-02', '2026-05-12', '2026-05-02', 22000.00, 22000.00, 1),
    (7, NULL, '2026-06-02', '2026-06-12', '2026-06-02', 22000.00, 22000.00, 1),
    (7, NULL, '2026-07-02', '2026-07-12', '2026-07-02', 22000.00, 22000.00, 1),
    (7, NULL, '2026-08-02', '2026-08-12', NULL, 22000.00, 0.00, 3),
    (7, NULL, '2026-09-02', '2026-09-12', '2026-09-02', 22000.00, 22000.00, 1),
    (8, NULL, '2025-08-10', '2025-08-20', '2025-08-10', 600.00, 600.00, 1),
    (8, NULL, '2025-09-10', '2025-09-20', '2025-09-10', 600.00, 600.00, 1),
    (8, NULL, '2025-10-10', '2025-10-20', '2025-10-10', 600.00, 600.00, 1),
    (8, NULL, '2025-11-10', '2025-11-20', '2025-11-10', 600.00, 600.00, 1),
    (8, NULL, '2025-12-10', '2025-12-20', '2025-12-10', 600.00, 600.00, 1),
    (8, NULL, '2026-01-10', '2026-01-20', '2026-01-10', 600.00, 600.00, 1),
    (8, NULL, '2026-02-10', '2026-02-20', '2026-02-10', 600.00, 600.00, 1),
    (8, NULL, '2026-03-10', '2026-03-20', '2026-03-10', 600.00, 600.00, 1),
    (9, NULL, '2026-01-20', '2026-01-30', '2026-01-20', 500.00, 500.00, 1),
    (9, NULL, '2026-02-20', '2026-03-02', '2026-02-20', 500.00, 500.00, 1),
    (9, NULL, '2026-03-20', '2026-03-30', '2026-03-20', 500.00, 500.00, 1),
    (9, NULL, '2026-04-20', '2026-04-30', '2026-04-20', 500.00, 500.00, 1),
    (9, NULL, '2026-05-20', '2026-05-30', '2026-05-20', 500.00, 500.00, 1),
    (9, NULL, '2026-06-20', '2026-06-30', '2026-06-20', 500.00, 500.00, 1),
    (10, NULL, '2025-06-15', '2025-06-25', '2025-06-15', 2500.00, 2500.00, 1);

/* =============================================================================
   BITÁCORA DE LLAMADAS (prototipo)
============================================================================= */
INSERT INTO dbo.REGISTRO_LLAMADA (ID_DONANTE, ID_USUARIO, FECHA_LLAMADA, RESULTADO, COMENTARIOS) VALUES
    (1, 2, '2026-08-14 10:00:00', N'Sin respuesta', N'Segundo intento'),
    (1, 2, '2026-08-02 10:00:00', N'Acordó actualizar tarjeta', NULL),
    (1, 3, '2026-07-18 10:00:00', N'Aviso de cobro rechazado', NULL),
    (2, 4, '2026-08-01 10:00:00', N'Confirmó donativo anual 2027', NULL),
    (2, 4, '2026-06-12 10:00:00', N'Envío de informe de impacto', NULL),
    (3, 5, '2026-08-20 10:00:00', N'Solicitó cambio de fecha de cargo', NULL),
    (3, 5, '2026-07-03 10:00:00', N'Agradecimiento de campaña', NULL),
    (4, 4, '2026-07-28 10:00:00', N'Reunión de seguimiento anual', NULL),
    (5, 5, '2026-06-10 10:00:00', N'Invitación a evento de voluntariado', NULL),
    (6, 2, '2026-08-22 10:00:00', N'Número fuera de servicio', NULL),
    (6, 2, '2026-08-05 10:00:00', N'Sin respuesta', N'Primer intento'),
    (7, 4, '2026-08-19 10:00:00', N'Contabilidad reprograma pago', NULL),
    (8, 5, '2026-04-15 10:00:00', N'Solicitó pausar su donativo', NULL);

/* =============================================================================
   METAS del trimestre julio–septiembre 2026 (montos del prototipo)
============================================================================= */
INSERT INTO dbo.META (ID_ASIGNACION, FECHA_INICIO, FECHA_FIN, MONTO_META) VALUES
    (3, '2026-07-01', '2026-09-30', 820000.00),
    (6, '2026-07-01', '2026-09-30', 420000.00),
    (7, '2026-07-01', '2026-09-30', 260000.00),
    (8, '2026-07-01', '2026-09-30', 310000.00),
    (9, '2026-07-01', '2026-09-30', 590000.00);

/* =============================================================================
   HISTORIAL DE REPORTES (biblioteca del prototipo, solo parámetros)
============================================================================= */
-- Generados por la administradora (usuario 1). Alcance: todas las líneas y
-- campañas, así que no llevan filas en REPORTE_LINEA_ESTRATEGICA ni en REPORTE_CAMPANA_FINANCIERA.
INSERT INTO dbo.HISTORIAL_REPORTE (ID_TIPO_REPORTE, ID_FORMATO, ID_USUARIO, FECHA_DESDE, FECHA_HASTA, FECHA_GENERACION) VALUES
    (2, 1, 1, '2026-08-17', '2026-08-23', '2026-08-24 08:00:00'),
    (2, 1, 1, '2026-08-10', '2026-08-16', '2026-08-17 08:00:00'),
    (3, 2, 1, '2026-08-10', '2026-08-16', '2026-08-17 08:05:00'),
    (1, 1, 1, '2026-07-01', '2026-07-31', '2026-08-01 08:00:00'),
    (1, 1, 1, '2026-06-01', '2026-06-30', '2026-07-01 08:00:00'),
    (4, 2, 1, '2026-04-01', '2026-06-30', '2026-07-02 08:00:00');

COMMIT TRANSACTION;
GO
