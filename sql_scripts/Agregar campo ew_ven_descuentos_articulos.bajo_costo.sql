USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_descuentos_articulos') AND name = 'bajo_costo')
BEGIN
	ALTER TABLE ew_ven_descuentos_articulos ADD bajo_costo BIT NOT NULL DEFAULT 0
END

SELECT * FROM ew_ven_descuentos_articulos
