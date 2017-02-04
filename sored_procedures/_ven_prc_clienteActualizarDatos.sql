USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110428
-- Description:	Actualizar datos de cliente
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_clienteActualizarDatos]
	 @idcliente AS INT
	,@idfacturacion AS INT
	,@idubicacion AS INT
	,@dato AS VARCHAR(20)
	,@valor AS VARCHAR(2000)
AS

SET NOCOUNT ON

RETURN

IF @dato = 'nombre'
BEGIN
	UPDATE ew_clientes SET 
		nombre = @valor 
	WHERE 
		idcliente = @idcliente
END

IF @dato = 'direccion'
BEGIN
	UPDATE ew_clientes_facturacion SET 
		direccion1 = @valor 
	WHERE 
		idcliente = @idcliente
		AND idfacturacion = @idfacturacion
END

IF @dato = 'rfc'
BEGIN
	UPDATE ew_clientes_facturacion SET 
		rfc = @valor 
	WHERE 
		idcliente = @idcliente
		AND idfacturacion = @idfacturacion
END

IF @dato = 'colonia'
BEGIN
	UPDATE ew_clientes_facturacion SET 
		colonia = @valor 
	WHERE 
		idcliente = @idcliente
		AND idfacturacion = @idfacturacion
END

/*
IF @dato = 'ciudad'
BEGIN
	UPDATE ew_clientes_facturacion SET 
		codciudad = @valor
	WHERE 
		idcliente = @idcliente
		AND idfacturacion = @idfacturacion
END
*/

IF @dato = 'codigo_postal'
BEGIN
	UPDATE ew_clientes_facturacion SET 
		codpostal = @valor
	WHERE 
		idcliente = @idcliente
		AND idfacturacion = @idfacturacion
END
GO
