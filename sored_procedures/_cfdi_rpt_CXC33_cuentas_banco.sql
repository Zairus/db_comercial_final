USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171212
-- Description:	Cuentas bancarias para pago Formato de impreison CFDi 33 para CXC
-- =============================================
ALTER PROCEDURE _cfdi_rpt_CXC33_cuentas_banco
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT TOP 3
	[Banco] = bb.nombre
	,[Cuenta] = (
		bc.no_cuenta
		+ (
			CASE
				WHEN LEN(bc.sucursal) > 0 THEN ' Suc: ' + bc.sucursal
				ELSe ''
			END
		)
	)
	,[CLABE] = bc.clabe
FROM 
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.imprimir = 1
		AND (
			bc.idsucursal = ct.idsucursal
			OR bc.idsucursal = 0
		)
	LEFT JOIN ew_ban_bancos AS bb
		ON bb.idbanco = bc.idbanco
WHERE
	ct.tipo = 1
	AND ct.idtran = @idtran
GO
