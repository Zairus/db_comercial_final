USE db_comercial_final

IF NOT EXISTS(SELECT * FROM objetos_datos WHERE grupo = 'GLOBAL' AND codigo = 'VENTA_FACT_AUT')
BEGIN
	INSERT INTO objetos_datos
		(objeto, grupo, codigo, valor, orden)
	VALUES
		(0, 'GLOBAL', 'VENTA_FACT_AUT', 0, 0)
END
