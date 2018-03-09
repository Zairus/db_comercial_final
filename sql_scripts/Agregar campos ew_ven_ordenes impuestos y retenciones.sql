USE db_comercial_final
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes') AND [name] = 'idimpuesto2_ret')
BEGIN
	ALTER TABLE ew_ven_ordenes ADD idimpuesto2_ret INT NOT NULL DEFAULT 0
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes') AND [name] = 'impuesto2_ret')
BEGIN
	ALTER TABLE ew_ven_ordenes ADD impuesto2_ret DECIMAL(18,6) NOT NULL DEFAULT 0
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes_mov') AND [name] = 'idimpuesto2_ret')
BEGIN
	ALTER TABLE ew_ven_ordenes_mov ADD idimpuesto2_ret INT NOT NULL DEFAULT 0
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes_mov') AND [name] = 'idimpuesto2_ret_valor')
BEGIN
	ALTER TABLE ew_ven_ordenes_mov ADD idimpuesto2_ret_valor DECIMAL(18,6) NOT NULL DEFAULT 0
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_ordenes_mov') AND [name] = 'impuesto2_ret')
BEGIN
	ALTER TABLE ew_ven_ordenes_mov ADD impuesto2_ret DECIMAL(18,6) NOT NULL DEFAULT 0
END
GO

ALTER TABLE ew_ven_ordenes_mov DROP COLUMN total
GO

ALTER TABLE ew_ven_ordenes_mov ADD total AS (importe + impuesto1 + impuesto2 + impuesto3 - (impuesto1_ret + impuesto2_ret))
GO

ALTER TABLE ew_ven_ordenes DROP COLUMN total
GO

ALTER TABLE ew_ven_ordenes ADD total AS (subtotal + impuesto1 + impuesto2 + impuesto3 + impuesto4 - (impuesto1_ret + impuesto2_ret))
GO
