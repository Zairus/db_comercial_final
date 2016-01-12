USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_documentos_mov') AND name = 'idimpuesto1')
BEGIN
	ALTER TABLE ew_com_documentos_mov ADD idimpuesto1 INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_documentos_mov') AND name = 'idimpuesto2')
BEGIN
	ALTER TABLE ew_com_documentos_mov ADD idimpuesto2 INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_documentos_mov') AND name = 'idimpuesto1_ret')
BEGIN
	ALTER TABLE ew_com_documentos_mov ADD idimpuesto1_ret INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_documentos_mov') AND name = 'idimpuesto2_ret')
BEGIN
	ALTER TABLE ew_com_documentos_mov ADD idimpuesto2_ret INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_documentos_mov') AND name = 'idimpuesto1_valor')
BEGIN
	ALTER TABLE ew_com_documentos_mov ADD idimpuesto1_valor DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_documentos_mov') AND name = 'idimpuesto2_valor')
BEGIN
	ALTER TABLE ew_com_documentos_mov ADD idimpuesto2_valor DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_documentos_mov') AND name = 'idimpuesto1_ret_valor')
BEGIN
	ALTER TABLE ew_com_documentos_mov ADD idimpuesto1_ret_valor DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_documentos_mov') AND name = 'idimpuesto2_ret_valor')
BEGIN
	ALTER TABLE ew_com_documentos_mov ADD idimpuesto2_ret_valor DECIMAL(18,6) NOT NULL DEFAULT 0
END
