USE db_comercial_final
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cfd_comprobantes') AND [name] = 'cfd_uso')
BEGIN
	ALTER TABLE ew_cfd_comprobantes ADD cfd_uso VARCHAR(10) NOT NULL DEFAULT ''
END
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cfd_comprobantes_mov') AND [name] = 'idmov2')
BEGIN
	ALTER TABLE ew_cfd_comprobantes_mov ADD idmov2 MONEY
END
GO
