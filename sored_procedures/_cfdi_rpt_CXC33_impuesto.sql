USE db_refriequipos_datos
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171212
-- Description:	Formato de impreison CFDi 33 para CXC
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_rpt_CXC33_impuesto]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT 
	[orden] = 0
	,[concepto] = 'Sub total'
	,[importe] = cc.cfd_subTotal
FROM 
	ew_cfd_comprobantes AS cc
WHERE
	cc.idtran = @idtran

UNION ALL

SELECT
	[orden] = 20
	,[concepto] = cci.cfd_impuesto + ' ' + LTRIM(RTRIM(STR(cci.cfd_tasa, 2))) + '%'
	,[importe] = cci.cfd_importe * (CASE WHEN cci.idtipo = 1 THEN 1 ELSE -1 END)
FROM 
	ew_cfd_comprobantes_impuesto AS cci
WHERE 
	cci.idtran = @idtran

UNION ALL

SELECT 
	[orden] = 90
	,[concepto] = 'Total'
	,[importe] = cc.cfd_total
FROM 
	ew_cfd_comprobantes AS cc
WHERE
	cc.idtran = @idtran

ORDER BY
	[orden]
GO
