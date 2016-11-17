USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160212
-- Description:	Llenar calculo de comisiones
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_calculoComisionesProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idvendedor AS INT
	,@fecha AS SMALLDATETIME

SELECT
	@idvendedor = vd.idvendedor
	,@fecha = vd.fecha
FROM
	ew_ven_documentos AS vd
WHERE
	vd.idtran = @idtran

INSERT INTO ew_ven_documentos_mov (
	[consecutivo]
	,[idarticulo]
	,[cantidad_surtida]
	,[precio_unitario]
	,[importe]
	,[importe_pagado]
	,[comision_porcentaje]
	,[comision_importe_prev]
	,[comision_pago_anterior]
	,[comision_importe]
	,[fecha_referencia]
	,[comentario]
	,[idmov2]
	,[idtran]
)

SELECT
	[consecutivo] = 0
	,[idarticulo] = vd1.idarticulo
	,[cantidad_surtida] = vd1.cantidad
	,[precio_unitario] = vd1.precio_unitario
	,[importe] = vd1.importe_base
	,[importe_pagado] = (vd1.importe_base * dbo._cxc_prc_facturaPagoProporcion(vd1.idtran, @fecha, 0))
	,[comision_porcentaje] = vd1.comision
	,[comision_importe_prev] = ((vd1.importe_base * dbo._cxc_prc_facturaPagoProporcion(vd1.idtran, @fecha, 0)) * vd1.comision)
	,[comision_pago_anterior] = ISNULL((
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
	,[comision_importe] = (
		(
			((vd1.importe_base * dbo._cxc_prc_facturaPagoProporcion(vd1.idtran, @fecha, 0)) * vd1.comision)
			*(
				ISNULL((
					SELECT vcl.porcentaje
					FROM 
						ew_ven_comisiones_limites AS vcl
					WHERE
						DATEDIFF(DAY, ct.fecha, vd1.fecha_ult_pago) BETWEEN vcl.limite_inferior AND vcl.limite_superior
				), 0.0)
			)
		)
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
	)
	,[fecha_referencia] = vd1.fecha_ult_pago
	,[comentario] = ''
	,[idmov2] = vd1.idmov
	,[idtran] = @idtran
FROM 
	ew_ven_comisiones_datos1 AS vd1
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vd1.idtran
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vd1.idarticulo
WHERE
	dbo._cxc_prc_facturaPagoProporcion(vd1.idtran, @fecha, 1) >= 1.0
	AND (
		SELECT COUNT(*) 
		FROM 
			ew_ven_documentos_mov AS vdm1 
			LEFT JOIN ew_ven_documentos AS vd_a
				ON vd_a.idtran = vdm1.idtran
		WHERE 
			vd_a.cancelado = 0
			AND vdm1.idmov2 = vd1.idmov
	) = 0
	AND (
		(
			((vd1.importe_base * dbo._cxc_prc_facturaPagoProporcion(vd1.idtran, @fecha, 0)) * vd1.comision)
			*(
				ISNULL((
					SELECT vcl.porcentaje
					FROM 
						ew_ven_comisiones_limites AS vcl
					WHERE
						DATEDIFF(DAY, ct.fecha, vd1.fecha_ult_pago) BETWEEN vcl.limite_inferior AND vcl.limite_superior
				), 0.0)
			)
		)
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
	) > 0.0
	AND vd1.idvendedor = @idvendedor

IF @@ROWCOUNT = 0
BEGIN
	RAISERROR('No existen comisiones que procesar.', 16, 1)
	RETURN
END

UPDATE vd SET
	subtotal = ISNULL((
		SELECT
			SUM(vdm.comision_importe)
		FROM
			ew_ven_documentos_mov AS vdm
		WHERE
			vdm.idtran = @idtran
	), 0)
FROM
	ew_ven_documentos AS vd
WHERE
	vd.idtran = @idtran
GO
