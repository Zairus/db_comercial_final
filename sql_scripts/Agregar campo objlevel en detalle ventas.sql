USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes_mov') AND name = 'objlevel')
BEGIN
	ALTER TABLE ew_ven_ordenes_mov ADD objlevel INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_documentos_mov') AND name = 'objlevel')
BEGIN
	ALTER TABLE ew_ven_documentos_mov ADD objlevel INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_transacciones_mov') AND name = 'objlevel')
BEGIN
	ALTER TABLE ew_ven_transacciones_mov ADD objlevel INT NOT NULL DEFAULT 0
END
