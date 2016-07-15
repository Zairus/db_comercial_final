USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cfd_comprobantes_impuesto') AND name = 'cfd_ambito')
BEGIN
	ALTER TABLE ew_cfd_comprobantes_impuesto ADD cfd_ambito SMALLINT NOT NULL DEFAULT 0
END
