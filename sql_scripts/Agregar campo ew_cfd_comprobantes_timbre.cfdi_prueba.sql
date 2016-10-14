USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cfd_comprobantes_timbre') AND name = 'cfdi_prueba')
BEGIN
	ALTER TABLE ew_cfd_comprobantes_timbre ADD cfdi_prueba BIT NOT NULL DEFAULT 0
END
