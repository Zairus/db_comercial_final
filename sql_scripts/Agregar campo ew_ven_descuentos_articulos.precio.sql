USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_descuentos_articulos') AND name = 'precio')
BEGIN
	ALTER TABLE ew_ven_descuentos_articulos ADD precio DECIMAL(18,6) NOT NULL DEFAULT 0
END