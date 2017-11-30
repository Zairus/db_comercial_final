USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171121
-- Description:	Datos de cliente para pago de cliente
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_clientePagoDatos]
	@codcliente AS VARCHAR(30)
AS

SET NOCOUNT ON

SELECT 
	[codcliente] = c.codigo
	,[idforma] = c.idforma
	,[referencia] = c.cfd_NumCtaPago
	,[cliente_nombre] = c.nombre
	,[cliente_rfc] = c.rfc
	,[cliente_cuenta] = c.contabilidad 
	,[cliente_email] = cfa.email
	,[cliente_notif] = dbo._sys_fnc_parametroActivo('CFDI_NOTIFICAR_AUTOMATICO')
	,[idcliente] = c.idcliente
	,[identidad] = c.idcliente
	
	,[clabe_origen] = ISNULL(ccb.clabe, '')
	,[cliente_banco] = ISNULL(ccb.nombre, '')
	,[cliente_banco_rfc] = ISNULL(ccb.rfc, '')
FROM 
	vew_clientes AS c
	LEFT JOIN ew_clientes_facturacion AS cfa
		ON cfa.idfacturacion = 0
		AND cfa.idcliente = c.idcliente

	LEFT JOIN (
		SELECT 
			ccb.clabe
			, cbb.nombre
			, cbb.rfc 
		FROM 
			ew_clientes_cuentas_bancarias AS ccb 
			LEFT JOIN ew_ban_bancos AS cbb 
				ON cbb.idbanco = ccb.idbanco

	) AS ccb
		ON ccb.clabe = (
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
WHERE 
	c.codigo = @codcliente
GO
