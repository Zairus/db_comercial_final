USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_transacciones') AND name = 'idfirma')
BEGIN
	ALTER TABLE ew_ven_transacciones ADD idfirma INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_transacciones') AND name = 'iddepartamento')
BEGIN
	ALTER TABLE ew_ven_transacciones ADD iddepartamento INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_transacciones') AND name = 'referencia')
BEGIN
	ALTER TABLE ew_ven_transacciones ADD referencia VARCHAR(50) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_transacciones') AND name = 'fecha_impresion')
BEGIN
	ALTER TABLE ew_ven_transacciones ADD fecha_impresion SMALLDATETIME
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_transacciones') AND name = 'idviaembarque')
BEGIN
	ALTER TABLE ew_ven_transacciones ADD idviaembarque INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_transacciones') AND name = 'no_guia')
BEGIN
	ALTER TABLE ew_ven_transacciones ADD no_guia VARCHAR(50) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_transacciones') AND name = 'ubicacion_instalacion')
BEGIN
	ALTER TABLE ew_ven_transacciones ADD ubicacion_instalacion VARCHAR(500) NOT NULL DEFAULT ''
END
