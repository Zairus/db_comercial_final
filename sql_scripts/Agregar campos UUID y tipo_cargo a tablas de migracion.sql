USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_migracion') AND name = 'UUID')
BEGIN
	ALTER TABLE ew_cxc_migracion ADD UUID VARCHAR(36) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_migracion') AND name = 'UUID')
BEGIN
	ALTER TABLE ew_cxp_migracion ADD UUID VARCHAR(36) NOT NULL DEFAULT ''
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_migracion') AND name = 'tipo_cargo')
BEGIN
	ALTER TABLE ew_cxp_migracion ADD tipo_cargo SMALLINT NOT NULL DEFAULT 0
END
