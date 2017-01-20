USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes_terminos') AND [name] = 'autorizacion')
BEGIN
	ALTER TABLE ew_clientes_terminos ADD autorizacion BIT NOT NULL DEFAULT 0
END
