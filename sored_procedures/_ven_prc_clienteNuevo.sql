USE db_comercial_final
GO

-- =============================================
-- Author:		Arvin Valenzuela
-- Create date: 2010 Enero
-- Description:	Procedimiento que da alta de cliente para facturar
-- Ejemplo: EXEC _ven_prc_clienteNuevo 'PR01','Prueba X','Paterno','Materno','xxx','asda454545-454','calle x','Xolonia','83290',732,'2325445','54545454'
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_clienteNuevo]
	@codcliente AS VARCHAR(10) = ''
	,@nombre AS VARCHAR(200)
	,@rfc AS VARCHAR(15)
	,@calle AS VARCHAR(100)
	,@numExterior AS VARCHAR(10)
	,@numInterior AS VARCHAR(10)
	,@codpostal AS VARCHAR(10)
	,@idciudad AS SMALLINT
	,@telefono1 AS VARCHAR(20)
 AS

SET NOCOUNT ON

DECLARE
	@mensaje AS VARCHAR(50)
	,@idcliente AS SMALLINT

SELECT @mensaje = ''

IF @codcliente = ''
BEGIN
	SELECT @codcliente = ISNULL(MAX(idcliente),0) + 1 FROM ew_clientes WHERE codigo <> 'PUBLICO'
END

SELECT 
	@idcliente = ISNULL(MAX(idcliente), 0) + 1 
FROM
	ew_clientes

IF NOT EXISTS(
	SELECT * 
	FROM ew_clientes 
	WHERE codigo = @codcliente
) AND NOT EXISTS (
	SELECT * 
	FROM ew_clientes 
	WHERE nombre = @nombre
)
BEGIN
	INSERT INTO ew_clientes (
		idcliente
		,codigo
		,nombre
		,activo
	)
	VALUES (
		@idcliente
		,@codcliente
		,@nombre
		,1
	)
		
	INSERT INTO ew_clientes_facturacion (
		idcliente
		, idfacturacion
		, razon_social
		, rfc
		, calle
		, noExterior
		, noInterior
		, telefono1
		, codpostal
		, idciudad
	)
	VALUES (
		@idcliente
		, 0
		, @nombre
		, @rfc
		, @calle
		, @numExterior
		, @numInterior
		, @telefono1
		, @codpostal
		, @idciudad
	)
		
	SELECT @mensaje = 'Alta se dio correctamente...'
	
	SELECT 
		[mensaje] = @mensaje
		, c.idcliente
		, c.codigo
		, c.nombre
		, c.fecha_alta
	FROM 
		ew_clientes AS c
		LEFT JOIN 
			ew_clientes_facturacion AS cf 
				ON cf.idcliente = c.idcliente
	WHERE 
		c.idcliente = @idcliente
END
	ELSE
BEGIN
	SELECT @mensaje = 'ERROR. CLIENTE ya existe...'
	
	SELECT 
		[mensaje] = @mensaje
		, c.idcliente
		, codigo
		, c.nombre
		, c.fecha_alta
	FROM
		ew_clientes c
		LEFT JOIN ew_clientes_facturacion AS cf 
			ON cf.idcliente = c.idcliente
	WHERE 
		c.codigo = @codcliente
		OR c.nombre = @nombre
END
GO
