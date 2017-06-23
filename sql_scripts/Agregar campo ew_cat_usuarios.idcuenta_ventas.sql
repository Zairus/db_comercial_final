USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cat_usuarios') AND [name] = 'idcuenta_ventas')
BEGIN
	ALTER TABLE ew_cat_usuarios ADD idcuenta_ventas INT NOT NULL DEFAULT 0
END
