USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171121
-- Description:	Datos de cliente para pago de cliente
-- =============================================
ALTER PROCEDURE _cxc_prc_clientePagoDatos
	@codcliente AS VARCHAR(30)
AS

SET NOCOUNT ON

SELECT 
	[idcliente] = c.idcliente
	,[codcliente] = c.codigo
	,[cliente_rfc] = c.rfc
	,[cliente_nombre_corto] = c.nombre_corto
	,[cliente_nombre] = c.nombre
	,[cliente_cuenta] = c.contabilidad 
	,[clabe_origen] = (
		CASE
			WHEN (SELECT COUNT(*) FROM ew_clientes_cuentas_bancarias AS ccb WHERE ccb.idcliente = c.idcliente) = 1 THEN
				(
					SELECT TOP 1 ccb.clabe 
					FROM ew_clientes_cuentas_bancarias AS ccb 
					WHERE ccb.idcliente = c.idcliente
				)
			ELSE ''
		END
	)
FROM 
	vew_clientes AS c
WHERE 
	c.codigo = @codcliente
GO
