USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110512
-- Description:	Datos de facturas para solicitud de reembolso
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_facturasReembolsoDatos]
	@idtran2 AS VARCHAR(MAX)
AS

SET NOCOUNT ON

SELECT
	 [idtran2] = ct.idtran
	,[referencia] = ct.folio
	,[idmov2] = ct.idmov
	,[movimiento] = o.nombre
	,[acreedor] = p.nombre
	,[importe] = ct.total
FROM
	ew_cxp_transacciones AS ct
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = ct.idproveedor
WHERE
	ct.idtran IN (
		SELECT CONVERT(INT, sm.valor) FROM dbo._sys_fnc_separarMultilinea(@idtran2, '	') AS sm
	)
GO