USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ser_calendario') AND [name] = 'cancelado')
BEGIN
	ALTER TABLE ew_ser_calendario ADD cancelado BIT NOT NULL DEFAULT 0
END
