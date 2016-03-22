USE db_comercial_final
GO
-- =============================================
-- Author:		Vladimir Barreras P.
-- Create date: Marzo 3, 2016
-- Description:	Reporte WEB para el ticket de venta.
-- Ejemplo : EXEC _ven_rpt_EFA3 102826
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_EFA3]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	vt.folio
	,[emisor] = (SELECT nombre FROM ew_clientes WHERE idcliente=0)
	,vt.fecha_hora
	,[cliente]=c.codigo + ' - ' + c.nombre
	,[cajero]=v.nombre
	,[cantidad]=vtm.cantidad_facturada
	,[descripcion]=a.nombre
	,[importe]=vtm.total
	,[precio_unitario]=(CASE WHEN vtm.cantidad_facturada >0 THEN vtm.total/vtm.cantidad_facturada ELSE 0 END)
	,[total] = vt.total
	,[pago_total]=vtp.total+vtp.total2
	,[pago_cambio]=(vtp.total+vtp.total2)-vt.total
	,[pendiente]=(CASE WHEN ((vtp.total+vtp.total2)-vt.total) < 0 THEN ((vtp.total+vtp.total2)-vt.total)*-1 ELSE 0 END)
	,[folio_ticket] = (
		dbo._sys_fnc_rellenar(vt.idsucursal, 3, '0')
		+vt.folio
		+RIGHT(LTRIM(RTRIM(STR(vt.idr * vt.idtran))), 2)
	)
FROM
	ew_ven_transacciones vt
	LEFT JOIN ew_ven_transacciones_mov vtm ON vtm.idtran=vt.idtran
	LEFT JOIN ew_clientes c ON c.idcliente=vt.idcliente
	LEFT JOIN ew_ven_vendedores v ON v.idvendedor=vt.idvendedor
	LEFT JOIN ew_articulos a ON a.idarticulo=vtm.idarticulo
	LEFT JOIN ew_ven_transacciones_pagos vtp ON vtp.idtran=vt.idtran
WHERE
	vt.idtran=@idtran
GO
