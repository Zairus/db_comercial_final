USE db_comercial_final

DECLARE
	@ejecutar AS BIT = 0 --### CAMBIAR A 1 PARA EJECUTAR

BEGIN TRAN

/*
###################################

IMPORTANTE:
Ejecutar procedimiento despues de haber creado todos
los campos, tablas y procedimientos.

###################################
*/

UPDATE ew_cat_impuestos SET nombre = 'IVA', activo = 1 WHERE idimpuesto = 1
UPDATE ew_cat_impuestos SET nombre = 'IVA', activo = 0 WHERE idimpuesto = 2
UPDATE ew_cat_impuestos SET nombre = 'IVA', activo = 0 WHERE idimpuesto = 3
UPDATE ew_cat_impuestos SET nombre = 'IVA', activo = 0 WHERE idimpuesto = 4
UPDATE ew_cat_impuestos SET nombre = 'IVA', activo = 0 WHERE idimpuesto = 5
UPDATE ew_cat_impuestos SET nombre = 'ISR', activo = 1 WHERE idimpuesto = 6
UPDATE ew_cat_impuestos SET nombre = 'IVA', activo = 0 WHERE idimpuesto = 7
UPDATE ew_cat_impuestos SET nombre = 'IVA', activo = 0 WHERE idimpuesto = 8
UPDATE ew_cat_impuestos SET nombre = 'IEPS', activo = 1 WHERE idimpuesto = 11
UPDATE ew_cat_impuestos SET nombre = 'ISH', activo = 1 WHERE idimpuesto = 12
UPDATE ew_cat_impuestos SET nombre = 'ISH', activo = 0 WHERE idimpuesto = 13

-- ## INI: AGREGAR CUENTAS CONTABLES ########################################

IF NOT EXISTS(SELECT idcuenta FROM ew_ct_cuentas WHERE cuenta = '1150008000')
BEGIN
	INSERT INTO ew_ct_cuentas
		(cuenta, cuentasup, nombre, activo, tipo, naturaleza)
	VALUES
		('1150008000', '1150000000', 'IVA RETENIDO A LA VENTA', 1, 1, 0)
		,('1150008001', '1150008000', 'IVA RET. PEND. COBRO', 1, 1, 0)
		,('1150008002', '1150008000', 'IVA RET. COBRADO', 1, 1, 0)
END

IF NOT EXISTS(SELECT idcuenta FROM ew_ct_cuentas WHERE cuenta = '1150009000')
BEGIN
	INSERT INTO ew_ct_cuentas
		(cuenta, cuentasup, nombre, activo, tipo, naturaleza)
	VALUES
		('1150009000', '1150000000', 'ISR RETENIDO A LA VENTA', 1, 1, 0)
		,('1150009001', '1150009000', 'ISR RET. PEND. COBRO', 1, 1, 0)
		,('1150009002', '1150009000', 'ISR RET. COBRADO', 1, 1, 0)
END

IF NOT EXISTS(SELECT idcuenta FROM ew_ct_cuentas WHERE cuenta = '1150007001')
BEGIN
	INSERT INTO ew_ct_cuentas
		(cuenta, cuentasup, nombre, activo, tipo, naturaleza)
	VALUES
		('1150007001', '1150007000', 'IEPS PAGADO', 1, 1, 0)
END

IF NOT EXISTS(SELECT idcuenta FROM ew_ct_cuentas WHERE cuenta = '1150007002')
BEGIN
	INSERT INTO ew_ct_cuentas
		(cuenta, cuentasup, nombre, activo, tipo, naturaleza)
	VALUES
		('1150007002', '1150007000', 'IEPS PEND. PAGADO', 1, 1, 0)
END

IF NOT EXISTS(SELECT idcuenta FROM ew_ct_cuentas WHERE cuenta = '2130002009')
BEGIN
	INSERT INTO ew_ct_cuentas
		(cuenta, cuentasup, nombre, activo, tipo, naturaleza)
	VALUES
		('2130002009', '2130002000', 'RET. IVA PEND. PAGO', 1, 2, 1)
END

IF NOT EXISTS(SELECT idcuenta FROM ew_ct_cuentas WHERE cuenta = '2130002010')
BEGIN
	INSERT INTO ew_ct_cuentas
		(cuenta, cuentasup, nombre, activo, tipo, naturaleza)
	VALUES
		('2130002010', '2130002000', 'RET. ISR 10% HONORARIOS PEND. PAGO', 1, 2, 1)
END

IF NOT EXISTS(SELECT idcuenta FROM ew_ct_cuentas WHERE cuenta = '2130002011')
BEGIN
	INSERT INTO ew_ct_cuentas
		(cuenta, cuentasup, nombre, activo, tipo, naturaleza)
	VALUES
		('2130002011', '2130002000', 'RET. ISR 10% ARRENDAMIENTO PEND. PAGO', 1, 2, 1)
END

IF NOT EXISTS(SELECT idcuenta FROM ew_ct_cuentas WHERE cuenta = '2130001004')
BEGIN
	INSERT INTO ew_ct_cuentas
		(cuenta, cuentasup, nombre, activo, tipo, naturaleza)
	VALUES
		('2130001004', '2130001000', 'IEPS PEND. PAGO', 1, 2, 1)
END

-- ## FIN: AGREGAR CUENTAS CONTABLES ########################################

-- ## INI: TEMPORAL TASA DE IMPUESTOS #######################################

CREATE TABLE _tmp_impuestosTasas (
	idr INT IDENTITY
	,codimpuesto VARCHAR(10)
	,tasa DECIMAL(12,6)
	,descripcion VARCHAR(100)
	,tipo TINYINT
	,contabilidad1 VARCHAR(20)
	,contabilidad2 VARCHAR(20)
	,contabilidad3 VARCHAR(20)
	,contabilidad4 VARCHAR(20)
)

INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('IVA', 0, 'Tasa Cero', 1, '', '', '', '')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('IVA', 0, 'Excento', 1, '', '', '', '')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('IVA', 0.16, 'Tasa 16%', 1, '2130001002', '2130001001', '1150004001', '1150003001')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('IVA', 0.106666666666667, 'Retenc. 2/3', 2, '1150008001', '1150008002', '2130002009', '2130002005')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('IVA', 0.04, 'Retenc. Fletes', 2, '1150008001', '1150008002', '2130002009', '2130002005')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('IVA', 0.16, 'Retenido', 2, '2130001002', '2130001001', '1150004001', '1150003001')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('ISR', 0.1, 'Retenc. Honorarios', 2, '1150009001', '1150009002', '2130002010', '2130002002')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('ISR', 0.1, 'Retenc. Arrendamiento', 2, '1150009001', '1150009002', '2130002011', '2130002003')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('ISH', 0.02, 'Tasa 2%', 1, '2130001004', '2130001003', '1150007002', '1150007001')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('ISH', 0.03, 'Tasa 3%', 1, '2130001004', '2130001003', '1150007002', '1150007001')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('IEPS', 0.06, 'IEPS al 6%', 1, '2130001004', '2130001003', '1150007002', '1150007001')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('IEPS', 0.07, 'IEPS al 7%', 1, '2130001004', '2130001003', '1150007002', '1150007001')
INSERT INTO _tmp_impuestosTasas (codimpuesto, tasa, descripcion, tipo, contabilidad1, contabilidad2, contabilidad3, contabilidad4) VALUES ('IEPS', 0.09, 'IEPS al 9%', 1, '2130001004', '2130001003', '1150007002', '1150007001')

TRUNCATE TABLE ew_cat_impuestos_tasas

ALTER TABLE ew_cat_impuestos_tasas DROP CONSTRAINT PK_ew_cat_impuestos_tasas

ALTER TABLE ew_cat_impuestos_tasas ADD CONSTRAINT PK_ew_cat_impuestos_tasas PRIMARY KEY CLUSTERED (idimpuesto, tasa, descripcion)

INSERT INTO ew_cat_impuestos_tasas (
	idimpuesto
	,tasa
	,descripcion
	,tipo
	,contabilidad1
	,contabilidad2
	,contabilidad3
	,contabilidad4
)
SELECT
	ci.idimpuesto
	,tit.tasa
	,tit.descripcion
	,tit.tipo
	,tit.contabilidad1
	,tit.contabilidad2
	,tit.contabilidad3
	,tit.contabilidad4
FROM 
	_tmp_impuestosTasas AS tit
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.nombre = tit.codimpuesto

DROP TABLE _tmp_impuestosTasas

-- ## FIN: TEMPORAL TASA DE IMPUESTOS #######################################

SELECT * FROM ew_cat_impuestos
SELECT * FROM ew_cat_impuestos_tasas

IF @ejecutar = 1
BEGIN
	SELECT [ejecutado] = 'SI'
	COMMIT TRAN
END
	ELSE
BEGIN
	SELECT [ejecutado] = 'No **prueba'
	ROLLBACK TRAN
END
