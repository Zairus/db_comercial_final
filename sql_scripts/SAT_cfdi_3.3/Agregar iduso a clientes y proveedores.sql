USE db_comercial_final
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes') AND [name] = 'cfd_iduso')
BEGIN
	ALTER TABLE ew_clientes ADD cfd_iduso INT NOT NULL DEFAULT 0
END
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_transacciones') AND [name] = 'cfd_iduso')
BEGIN
	ALTER TABLE ew_cxc_transacciones ADD cfd_iduso INT NOT NULL DEFAULT 0
END
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_proveedores') AND [name] = 'cfd_iduso')
BEGIN
	ALTER TABLE ew_proveedores ADD cfd_iduso INT NOT NULL DEFAULT 0
END
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_transacciones') AND [name] = 'cfd_iduso')
BEGIN
	ALTER TABLE ew_cxp_transacciones ADD cfd_iduso INT NOT NULL DEFAULT 0
END
GO
SELECT cfd_iduso FROM ew_clientes
SELECT cfd_iduso FROM ew_cxc_transacciones
SELECT cfd_iduso FROM ew_proveedores
SELECT cfd_iduso FROM ew_cxp_transacciones