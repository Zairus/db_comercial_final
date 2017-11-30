USE db_comercial_final
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_migracion') AND [name] = 'idsucursal')
BEGIN
	ALTER TABLE ew_cxc_migracion ADD idsucursal INT NOT NULL DEFAULT 0
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_migracion') AND [name] = 'idsucursal')
BEGIN
	ALTER TABLE ew_cxp_migracion ADD idsucursal INT NOT NULL DEFAULT 0
END
GO
