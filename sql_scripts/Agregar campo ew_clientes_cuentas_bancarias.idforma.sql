USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_clientes_cuentas_bancarias') AND [name] = 'idforma')
BEGIN
	ALTER TABLE ew_clientes_cuentas_bancarias ADD idforma INT NOT NULL DEFAULT 0
END
