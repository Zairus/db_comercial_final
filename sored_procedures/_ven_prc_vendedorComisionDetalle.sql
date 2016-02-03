USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150922
-- Description:	Datos para calculo de comision
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_vendedorComisionDetalle]
	@idvendedor AS INT
AS

SET NOCOUNT ON

SELECT
	ct.fecha
	,ct.folio
	,[cliente] = c.nombre + ' [' + c.codigo + ']'
	,[idarticulo] = vd1.idarticulo
	,[codarticulo] = a.codigo
	,[articulo] = a.nombre

	,[cantidad_surtida] = vd1.cantidad
	,[precio_unitario] = vd1.precio_unitario
	,[importe] = vd1.importe_base
	
	,[importe_pagado] = (vd1.importe_base * (CASE WHEN vd1.pago_proporcion > 1.0 THEN 1.0 ELSE vd1.pago_proporcion END))
	,[comision_porcentaje] = vd1.comision
	
	,[comision_importe_prev] = ((vd1.importe_base * (CASE WHEN vd1.pago_proporcion > 1.0 THEN 1.0 ELSE vd1.pago_proporcion END)) * vd1.comision)
	,[comision_pago_anterior] = ISNULL((
		SELECT
			SUM(vdm.comision_importe)
		FROM
			ew_ven_documentos_mov AS vdm
			LEFT JOIN ew_ven_documentos AS vd
				ON vd.idtran = vdm.idtran
		WHERE
			vdm.idmov2 = vd1.idmov
	), 0)
	,[comision_importe] = (
		((vd1.importe_base * (CASE WHEN vd1.pago_proporcion > 1.0 THEN 1.0 ELSE vd1.pago_proporcion END)) * vd1.comision)
		-ISNULL((
			SELECT
				SUM(vdm.comision_importe)
			FROM
				ew_ven_documentos_mov AS vdm
				LEFT JOIN ew_ven_documentos AS vd
					ON vd.idtran = vdm.idtran
			WHERE
				vd.cancelado = 0
				AND vdm.idmov2 = vd1.idmov
		), 0)
	)*(
		ISNULL((
			SELECT vcl.porcentaje
			FROM 
				ew_ven_comisiones_limites AS vcl
			WHERE
				DATEDIFF(DAY, ct.fecha, vd1.fecha_ult_pago) BETWEEN vcl.limite_inferior AND vcl.limite_superior
		), 0.0)
	)

	,[fecha_referencia] = vd1.fecha_ult_pago
	,[dias_vigente] = DATEDIFF(DAY, ct.fecha, vd1.fecha_ult_pago)

	,[idtran2] = vd1.idtran
	,[idmov2] = vd1.idmov
FROM 
	ew_ven_comisiones_datos1 AS vd1
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vd1.idtran
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vd1.idarticulo
WHERE
	vd1.pago_proporcion > 0
	AND (
		((vd1.importe_base * (CASE WHEN vd1.pago_proporcion > 1.0 THEN 1.0 ELSE vd1.pago_proporcion END)) * vd1.comision)
		-ISNULL((
			SELECT
				SUM(vdm.comision_importe)
			FROM
				ew_ven_documentos_mov AS vdm
				LEFT JOIN ew_ven_documentos AS vd
					ON vd.idtran = vdm.idtran
			WHERE
				vd.cancelado = 0
				AND vdm.idmov2 = vd1.idmov
		), 0)
	)*(
		ISNULL((
			SELECT vcl.porcentaje
			FROM 
				ew_ven_comisiones_limites AS vcl
			WHERE
				DATEDIFF(DAY, ct.fecha, vd1.fecha_ult_pago) BETWEEN vcl.limite_inferior AND vcl.limite_superior
		), 0.0)
	) > 0.0
	AND vd1.idvendedor = @idvendedor
GO
