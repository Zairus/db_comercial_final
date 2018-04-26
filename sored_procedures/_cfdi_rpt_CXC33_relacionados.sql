USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171212
-- Description:	Formato de impreison CFDi 33 para CXC
-- ==============================================
ALTER PROCEDURE [dbo].[_cfdi_rpt_CXC33_relacionados]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	f.transaccion
	,[movimiento] = o.nombre
	,f.idconcepto
	,f.fecha
	,f.folio
	,f.subtotal
	,f.impuesto1
	,f.impuesto2
	,f.impuesto1_ret
	,f.impuesto2_ret
	,f.total
	,[aplicado] = ctm.importe
	,ctm.comentario
FROM 
	ew_cxc_transacciones_mov AS ctm
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN objetos AS o
		ON o.codigo = f.transaccion
WHERE 
	ctm.idtran = @idtran
GO
