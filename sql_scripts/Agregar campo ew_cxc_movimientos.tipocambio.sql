USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_movimientos') AND [name] = 'tipocambio')
BEGIN
	ALTER TABLE ew_cxc_movimientos ADD tipocambio DECIMAL(18,6) NOT NULL DEFAULT 0
END
