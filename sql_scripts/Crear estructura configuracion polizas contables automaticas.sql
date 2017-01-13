USE db_comercial_final
GO
IF OBJECT_ID ('ew_ct_polizas_configuracion') IS NOT NULL
BEGIN
	DROP TABLE ew_ct_polizas_configuracion
END
GO
IF OBJECT_ID ('ew_ct_polizas_configuracion_mov') IS NOT NULL
BEGIN
	DROP TABLE ew_ct_polizas_configuracion_mov
END
GO
CREATE TABLE ew_ct_polizas_configuracion (
	idr INT IDENTITY
	,objeto_codigo VARCHAR(10) NOT NULL DEFAULT ''
	,idtipo SMALLINT NOT NULL DEFAULT 3

	CONSTRAINT [PK_ew_ct_polizas_configuracion] PRIMARY KEY CLUSTERED ([objeto_codigo]) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE ew_ct_polizas_configuracion_mov (
	idr INT IDENTITY
	,objeto_codigo VARCHAR(10) NOT NULL DEFAULT ''
	,orden INT NOT NULL DEFAULT 0
	,cuenta VARCHAR(1000) NOT NULL DEFAULT ''
	,tipomov INT NOT NULL DEFAULT 0
	,tabla VARCHAR(2000) NOT NULL DEFAULT ''
	,campo_llave VARCHAR(100) NOT NULL DEFAULT ''
	,importe VARCHAR(2000) NOT NULL DEFAULT ''
	,agrupacion VARCHAR(2000) NOT NULL DEFAULT ''
	,ordenamiento VARCHAR(2000) NOT NULL DEFAULT ''
	
	CONSTRAINT [PK_ew_ct_polizas_configuracion_mov] PRIMARY KEY CLUSTERED ([objeto_codigo], [orden]) ON [PRIMARY]
) ON [PRIMARY]

GO

INSERT INTO ew_ct_polizas_configuracion
	(objeto_codigo, idtipo)
VALUES
	('CFA2', 3)
	,('EFA6', 3)

INSERT INTO ew_ct_polizas_configuracion_mov
	(objeto_codigo, orden, cuenta, tipomov, tabla, campo_llave, importe)
VALUES
	('CFA2', 1, '1160001000', 0, 'ew_com_transacciones AS ct', 'ct.idtran', 'ct.subtotal')
	,('CFA2', 2, '1150004001', 0, 'ew_com_transacciones AS ct', 'ct.idtran', 'ct.impuesto1 + ct.impuesto2 + ct.impuesto3 + ct.impuesto4')
	,('CFA2', 3, '2100001000', 1, 'ew_com_transacciones AS ct', 'ct.idtran', 'ct.total')

	,('EFA6', 1, '1130001000', 0, 'ew_ven_transacciones AS vt', 'vt.idtran', 'vt.total')
	,('EFA6', 2, '4100001000', 1, 'ew_ven_transacciones AS vt', 'vt.idtran', 'vt.subtotal')
	,('EFA6', 3, '2130001002', 1, 'ew_ven_transacciones AS vt', 'vt.idtran', 'vt.impuesto1')
	,('EFA6', 4, '5100000001', 0, 'ew_ven_transacciones AS vt', 'vt.idtran', 'vt.costo')
	,('EFA6', 5, '1160001000', 1, 'ew_ven_transacciones AS vt', 'vt.idtran', 'vt.costo')
	
	--,('', 1, '', 1, '', '')

GO

SELECT * FROM ew_ct_polizas_configuracion
SELECT * FROM ew_ct_polizas_configuracion_mov