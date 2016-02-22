USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160202
-- Description:	Reporte de calculo de comisiones
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_EPR1]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	vd.fecha
	,vd.folio
	,[vendedor] = v.nombre
	,[usuario] = u.nombre
	,vd.total

	,[fecha_ref] = vcd1.fecha
	,[folio_ref] = vcd1.folio
	,[movimiento] = o.nombre
	,[cliente] = c.nombre

	,[comision_importe] = SUM(vdm.comision_importe)
FROM
	ew_ven_documentos AS vd
	LEFT JOIN ew_ven_vendedores AS v
		ON v.idvendedor = vd.idvendedor
	LEFT JOIN evoluware_usuarios As u
		ON u.idu = vd.idu
	LEFT JOIN ew_ven_documentos_mov AS vdm
		ON vdm.idtran = vd.idtran
	LEFT JOIN ew_articulos As a
		ON a.idarticulo = vdm.idarticulo

	LEFT JOIN ew_ven_comisiones_datos1 AS vcd1
		ON vcd1.idmov = vdm.idmov2
	LEFT JOIN ew_cxc_transacciones As ct
		ON ct.idtran = vcd1.idtran
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	vd.idtran = @idtran
GROUP BY
	vd.fecha
	,vd.folio
	,v.nombre
	,u.nombre
	,vd.total
	,vcd1.fecha
	,vcd1.folio
	,o.nombre
	,c.nombre
GO
