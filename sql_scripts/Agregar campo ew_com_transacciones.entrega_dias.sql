USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_transacciones') AND [name] = 'entrega_dias')
BEGIN
	ALTER TABLE ew_com_transacciones ADD entrega_dias INT NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_com_transacciones') AND [name] = 'idpedimento')
BEGIN
	ALTER TABLE ew_com_transacciones ADD idpedimento INT NOT NULL DEFAULT 0
END