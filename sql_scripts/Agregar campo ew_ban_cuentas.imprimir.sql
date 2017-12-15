USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_cuentas') AND [name] = 'imprimir')
BEGIN
	ALTER TABLE ew_ban_cuentas ADD imprimir BIT NOT NULL DEFAULT 0
END
