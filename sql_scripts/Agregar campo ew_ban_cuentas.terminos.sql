USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ban_cuentas') AND [name] = 'terminos')
BEGIN
	ALTER TABLE ew_ban_cuentas ADD terminos SMALLINT NOT NULL DEFAULT -1
END
