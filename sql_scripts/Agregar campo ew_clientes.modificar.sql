USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes') AND name = 'modificar')
BEGIN
	ALTER TABLE ew_clientes ADD modificar BIT NOT NULL DEFAULT 0
END
