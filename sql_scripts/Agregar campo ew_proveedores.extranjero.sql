USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_proveedores') AND name = 'extranjero')
BEGIN
	ALTER TABLE ew_proveedores ADD extranjero BIT NOT NULL DEFAULT 0
END
