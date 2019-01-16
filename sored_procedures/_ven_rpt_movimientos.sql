USE db_comercial_final
GO
-- ================================================================================
-- Author:		Paul Monge
-- Create date: 200910
-- Description:	Auxiliar de Movimientos de Ventas
-- =================================================================================
ALTER PROCEDURE [dbo].[_ven_rpt_movimientos]
	@idsucursal AS INT
	, @idalmacen AS INT
	, @objeto AS INT
	, @idestado AS INT = -1	
	, @fecha1 AS SMALLDATETIME = NULL
	, @fecha2 AS SMALLDATETIME = NULL
	, @idcliente  INT = 0
	, @idvendedor AS INT = 0
	, @idmoneda AS TINYINT = 0
	, @opcion AS TINYINT = 1
AS

SET NOCOUNT ON

DECLARE 
	@objetocodigo AS VARCHAR(5) = ''

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT 
	@objetocodigo = codigo 
FROM 
	objetos 
WHERE 
	objeto = @objeto

SELECT @objetocodigo = ISNULL(@objetocodigo, '')

SELECT 
	[sucursal] = s.nombre
	, [almacen] = a.nombre	
	, [movimiento] = o.nombre
	, [estado] = ISNULL(oe.nombre, '') 
	, [codigo] = ISNULL(ec.codigo + ' - ', ' - ')+ ISNULL(ec.nombre, '')
	, [idtran] = ct.idtran
	, [idsucursal] = ct.idsucursal
	, [transaccion] = ct.transaccion
	, [concepto] = cc.nombre
	, [fecha] = ct.fecha
	, [folio] = ct.folio
	, [idcliente] = ct.idcliente
	, [nombre] = ec.nombre
	, [idvendedor] = ct.idvendedor
	, [vendedor] = vv.nombre
	, [idmoneda] = ct.idmoneda

	, [subtotal] = (CASE WHEN ct.cancelado = 0 THEN ISNULL(ct.subtotal, 0) ELSE 0 END)
	, [impuesto1] = (CASE WHEN ct.cancelado = 0 THEN ISNULL(ct.impuesto1, 0) ELSE 0 END)
	, [total] = (CASE WHEN ct.cancelado = 0 THEN ISNULL(ct.total, 0) ELSE 0 END)

	, [cancelado] = ct.cancelado
	, [cancelado_fecha] = (CASE WHEN t.cancelado = 1 THEN ct.cancelado_fecha ELSE NULL END)
	, [empresa] = dbo.fn_sys_empresa()
	, [medio_venta] = vm.medio
	, [comentario] = ct.comentario

	, [cfdi_UUID] = ISNULL(UPPER(cct.cfdi_UUID), '')
	, [cliente_orden] = ct.cliente_orden

	, [titulo] = ro.nombre
	, [titulo_subtitulo] = UPPER(
		'DEL '
		+ LTRIM(RTRIM(STR(DAY(@fecha1))))
		+ ' DE '
		+ (SELECT spd.descripcion FROM ew_sys_periodos_datos AS spd WHERE spd.grupo = 'meses' AND spd.id = MONTH(@fecha1))
		+ '-'
		+ LTRIM(RTRIM(STR(YEAR(@fecha1))))
		+ ' AL '
		+ LTRIM(RTRIM(STR(DAY(@fecha2))))
		+ ' DE '
		+ (SELECT spd.descripcion FROM ew_sys_periodos_datos AS spd WHERE spd.grupo = 'meses' AND spd.id = MONTH(@fecha2))
		+ '-'
		+ LTRIM(RTRIM(STR(YEAR(@fecha2))))
	)
	, [titulo_fecha] = 'Fecha: ' + CONVERT(VARCHAR(8), GETDATE(), 3)
	, [titulo_ruta] = [dbo].[_sys_fnc_objetoRuta](ro.objeto)
FROM
	ven_transacciones ct
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = ct.idsucursal
	LEFT JOIN objetos AS o 
		ON o.codigo = ct.transaccion
	LEFT JOIN ew_inv_almacenes AS a 
		ON a.idalmacen = ct.idalmacen
	LEFT JOIN ew_clientes AS ec 
		ON ec.idcliente = ct.idcliente
	LEFT JOIN ew_ven_vendedores AS vv 
		ON vv.idvendedor = ct.idvendedor
	LEFT JOIN c_transacciones AS t 
		ON t.idtran = ct.idtran 
	LEFT JOIN objetos_estados AS oe 
		ON oe.idestado = t.idestado 
		AND oe.objeto=o.objeto
	LEFT JOIN conceptos AS cc 
		ON cc.idconcepto = ct.idconcepto

	LEFT JOIN ew_ven_medios AS vm
		ON vm.idmedioventa = ct.idmedioventa

	LEFT JOIN ew_cfd_comprobantes AS ccc
		ON ccc.idtran = ct.idtran 
		AND ct.transaccion IN (SELECT transaccion FROM ew_ven_transacciones)
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = ccc.idtran

	LEFT JOIN objetos AS ro
		ON ro.tipo = 'AUX'
		AND ro.codigo = 'AUX20'
WHERE
	ct.idsucursal = (CASE @idsucursal WHEN 0 THEN ct.idsucursal ELSE @idsucursal END)
	AND ct.idalmacen = (CASE @idalmacen WHEN 0 THEN ct.idalmacen ELSE @idalmacen END)	
	AND o.codigo IN (
		SELECT ov.codigo 
		FROM 
			objetos AS ov 
		WHERE 
			ov.codigo LIKE (
				CASE 
					WHEN @objeto = -1 THEN ov.codigo 
					WHEN @objeto = -2 THEN 
						CASE 
							WHEN ct.transaccion = 'EFA1' THEN 'EFA1' 
							ELSE 
								CASE 
									WHEN ct.transaccion = 'EFA4' THEN 'EFA4' 
									ELSE	
										CASE 
											WHEN ct.transaccion = 'EFA6' THEN 'EFA6' 
										END 
								END 
							END 
						ELSE @objetocodigo 
				END
			)
	)
	AND t.idestado = (CASE @idestado WHEN -1 THEN t.idestado ELSE @idestado END)		
	AND ct.idcliente = (CASE @idcliente WHEN 0 THEN ct.idcliente ELSE @idcliente END)
	AND ct.idvendedor = (CASE @idvendedor WHEN 0 THEN ct.idvendedor ELSE @idvendedor END)
	AND ct.fecha BETWEEN @fecha1 AND @fecha2
	AND ct.idmoneda = @idmoneda
ORDER BY
	ct.idsucursal
	, CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ct.fecha, 3))
	, ct.folio
	, ec.codigo
GO
