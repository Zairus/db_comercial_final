USE db_comercial_final

IF NOT EXISTS (SELECT * FROM ew_sys_parametros WHERE codigo = 'COM_TRANSACCIONFACTURA')
BEGIN
	DECLARE
		@idparametro AS INT

	SELECT
		@idparametro = MAX(idparametro)
	FROM
		ew_sys_parametros

	SELECT @idparametro = ISNULL(@idparametro, 0) + 1

	INSERT INTO ew_sys_parametros 
		(idparametro, codigo, nombre, activo, valor)
	VALUES 
		(@idparametro, 'COM_TRANSACCIONFACTURA', 'CODIGO DE TRANSACCION PARA FACTURAR UNA ORDEN DE COMPRA', 0, 'CFA1')
END

SELECT [transaccion_factura] = [dbo].[_sys_fnc_parametroTexto]('COM_TRANSACCIONFACTURA')