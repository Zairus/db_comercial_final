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

DECLARE
	@modificar AS BIT

SELECT
	@modificar = modificar
FROM
	ew_clientes
WHERE
	idcliente = @idcliente

IF @idcliente = 0 OR @modificar = 0
BEGIN
	RETURN
END

DECLARE
	@idciudad AS INT
	
IF @dato = 'nombre'
BEGIN
	UPDATE ew_clientes SET 
		nombre = @valor 
	WHERE 
		idcliente = @idcliente

	UPDATE ew_clientes_facturacion SET
		razon_social = @valor
	WHERE
		idcliente = @idcliente
END

IF @dato = 'direccion'
BEGIN
	UPDATE ew_clientes_facturacion SET 
		direccion1 = @valor 
		,calle = @valor
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

IF @dato = 'ciudad'
BEGIN
	SELECT 
		@idciudad = idciudad 
	FROM 
		ew_sys_ciudades AS cd 
	WHERE 
		cd.codciudad = @valor
	
	IF @idciudad IS NULL
	BEGIN
		RAISERROR('Error: No se ha indicado codigo de ciudad correctamente.', 16, 1)
		RETURN
	END

	UPDATE ew_clientes_facturacion SET 
		idciudad = @idciudad
	WHERE 
		idcliente = @idcliente
		AND idfacturacion = @idfacturacion
END

IF @dato = 'codigo_postal'
BEGIN
	UPDATE ew_clientes_facturacion SET 
		codpostal = @valor
	WHERE 
		idcliente = @idcliente
		AND idfacturacion = @idfacturacion
END

IF @dato = 'email'
BEGIN
	UPDATE ew_clientes_facturacion SET 
		email = @valor
	WHERE 
		idcliente = @idcliente
		AND idfacturacion = @idfacturacion
END
GO
