USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_cuentas') AND [name] = 'activo')
BEGIN
	ALTER TABLE ew_ban_cuentas ADD activo BIT NOT NULL DEFAULT 1
END
