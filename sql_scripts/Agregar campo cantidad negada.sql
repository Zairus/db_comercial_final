USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes_mov') AND name = 'cantidad_negada')
BEGIN
	ALTER TABLE ew_ven_ordenes_mov ADD cantidad_negada DECIMAL(18,6) NOT NULL DEFAULT 0
END
