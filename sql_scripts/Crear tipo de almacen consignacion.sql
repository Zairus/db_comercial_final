USE db_comercial_final

IF NOT EXISTS (SELECT * FROM ew_inv_almacenes_tipos WHERE nombre = 'Consignación')
BEGIN
	DECLARE @idtipo AS INT

	SELECT @idtipo = MAX(idtipo) FROM ew_inv_almacenes_tipos 
	SELECT @idtipo = ISNULL(@idtipo, 0) + 1

	INSERT INTO ew_inv_almacenes_tipos (idtipo, nombre, propio)
	VALUES (@idtipo, 'Consignación', 0)
END

SELECT * FROM ew_inv_almacenes_tipos
