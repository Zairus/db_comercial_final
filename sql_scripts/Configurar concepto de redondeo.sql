USE db_comercial_final

DECLARE
	@idarticulo AS INT

SELECT @idarticulo = MAX(idarticulo) FROM ew_articulos

SELECT @idarticulo = ISNULL(@idarticulo, 0) + 1

IF NOT EXISTS(SELECT * FROM ew_articulos WHERE codigo = 'EWREDONDEO')
BEGIN
	INSERT INTO ew_articulos 
		(idarticulo, codigo, nombre, idum_venta, idum_compra, idum_almacen, idclasificacion_sat)
	VALUES
		(@idarticulo, 'EWREDONDEO', 'Redondeo', 31, 31, 31, 51542)
END

SELECT * FROM db_comercial.dbo.evoluware_cfd_sat_clasificaciones WHERE clave = '84111506'

SELECT * FROM ew_articulos WHERE codigo = 'EWREDONDEO'
