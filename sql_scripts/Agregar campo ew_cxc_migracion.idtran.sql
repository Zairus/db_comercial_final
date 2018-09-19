USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_migracion') AND [name] = 'idtran')
BEGIN
	ALTER TABLE ew_cxc_migracion ADD idtran INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_migracion') AND [name] = 'cfdi_xml')
BEGIN
	ALTER TABLE ew_cxc_migracion ADD cfdi_xml XML
END
