USE db_comercial_final

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_listaprecios_mov') AND name = 'precio_neto')
BEGIN
	ALTER TABLE ew_ven_listaprecios_mov ADD precio_neto DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_listaprecios_mov') AND name = 'precio_neto2')
BEGIN
	ALTER TABLE ew_ven_listaprecios_mov ADD precio_neto2 DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_listaprecios_mov') AND name = 'precio_neto3')
BEGIN
	ALTER TABLE ew_ven_listaprecios_mov ADD precio_neto3 DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_listaprecios_mov') AND name = 'precio_neto4')
BEGIN
	ALTER TABLE ew_ven_listaprecios_mov ADD precio_neto4 DECIMAL(18,6) NOT NULL DEFAULT 0
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_ven_listaprecios_mov') AND name = 'precio_neto5')
BEGIN
	ALTER TABLE ew_ven_listaprecios_mov ADD precio_neto5 DECIMAL(18,6) NOT NULL DEFAULT 0
END
