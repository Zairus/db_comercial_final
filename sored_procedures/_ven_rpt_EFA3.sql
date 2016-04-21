USE db_comercial_final
GO
-- =============================================
-- Author:		Vladimir Barreras P.
-- Create date: Marzo 3, 2016
-- Description:	Reporte WEB para el ticket de venta.
-- Ejemplo : EXEC _ven_rpt_EFA3 100517
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_EFA3]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	vt.folio
	,[emisor] = (SELECT nombre FROM ew_clientes WHERE idcliente = 0)
	,[fecha_hora] = vt.fecha_hora
	,[cliente] = (c.codigo + ' - ' + c.nombre)
	,[cajero] = v.nombre
	,[cantidad] = vtm.cantidad_facturada
	,[descripcion] = a.nombre
	,[importe] = vtm.total
	,[precio_unitario] = (CASE WHEN vtm.cantidad_facturada > 0 THEN vtm.total / vtm.cantidad_facturada ELSE 0 END)
	,[total] = vt.total
	,[pago_total] = (vtp.total + vtp.total2)
	,[pago_cambio] = ((vtp.total + vtp.total2) - vt.total)
	,[pendiente] = (CASE WHEN ((vtp.total + vtp.total2) - vt.total) < 0 THEN ((vtp.total + vtp.total2) - vt.total) * -1 ELSE 0 END)
	,[folio_ticket] = (
		dbo._sys_fnc_rellenar(vt.idsucursal, 3, '0')
		+vt.folio
		+RIGHT(LTRIM(RTRIM(STR(vt.idr * vt.idtran))), 2)
	)
	,[descuento]=(cantidad_facturada * precio_venta) - importe
	,[sucursal_datos] = (s.nombre + char(10) + char(13) + s.direccion + char(10) + char(13) + 'C.P. ' + s.codpostal + char(10) + char(13) + sc.ciudad + ', ' + sc.estado + char(10) + char(13) + 'R.F.C. ' + s.rfc)
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_ven_transacciones_mov AS vtm 
		ON vtm.idtran = vt.idtran
	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_ven_vendedores AS v 
		ON v.idvendedor = vt.idvendedor
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_ven_transacciones_pagos AS vtp 
		ON vtp.idtran = vt.idtran
	LEFT JOIN ew_sys_sucursales s
		ON s.idsucursal = vt.idsucursal
	LEFT JOIN ew_sys_ciudades sc
		ON sc.idciudad = s.idciudad
WHERE
	vt.idtran = @idtran
GO
