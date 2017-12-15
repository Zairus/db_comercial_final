USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_migracion') AND name = 'impuesto1_ret')
BEGIN
	ALTER TABLE ew_cxc_migracion ADD impuesto1_ret DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_migracion') AND name = 'impuesto2_ret')
BEGIN
	ALTER TABLE ew_cxc_migracion ADD impuesto2_ret DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_migracion') AND name = 'impuesto1_ret')
BEGIN
	ALTER TABLE ew_cxp_migracion ADD impuesto1_ret DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxp_migracion') AND name = 'impuesto2_ret')
BEGIN
	ALTER TABLE ew_cxp_migracion ADD impuesto2_ret DECIMAL(18,6) NOT NULL DEFAULT 0
END

SELECT * FROM ew_cxc_migracion

SELECT * FROM ew_cxp_migracion
