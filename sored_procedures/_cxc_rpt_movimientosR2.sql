USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150922
-- Description:	Movimientos de cobranza
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_rpt_movimientosR2]
	@idsucursal AS INT = 0
	, @objeto AS INT = -1
	, @idcliente AS INT = 0
	, @idvendedor AS INT = 0
	, @idestado AS INT = -1
	, @fecha1 AS SMALLDATETIME = NULL
	, @fecha2 AS SMALLDATETIME = NULL
	, @idmoneda SMALLINT = -1
	, @opcion TINYINT = 1
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	[sucursal] = s.nombre
	, [moneda] = bm.nombre
	, [movimiento] = o.nombre
	, [fecha] = ct.fecha
	, [fecha_banco] = ct.fecha_operacion
	, [folio] = ct.folio
	, [codigo] = c.codigo
	, [cliente] = c.nombre + ' [' + c.codigo + ']'
	, [vendedor] = ISNULL(v.nombre, '-Sin Especificar-')
	, [subtotal] = (CASE WHEN ct.cancelado = 1 THEN 0 ELSE ct.subtotal END)
	, [impuesto1] = (CASE WHEN ct.cancelado = 1 THEN 0 ELSE ct.impuesto1 END)
	, [total] = (CASE WHEN ct.cancelado = 1 THEN 0 ELSE ct.total END)
	, [estado] = ISNULL(e.nombre, '-NA-')
	, [usuario] = u.nombre
	, [comentario] = ct.comentario
	
	, [idtran] = ct.idtran
	, [objidtran] = ct.idtran

	, [concepto] = ec.nombre
	, [cuenta] = bc.no_cuenta

	, [forma_pago] = bf.nombre

	, [cfdi_UUID] = ISNULL(UPPER(cct.cfdi_UUID), '')

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
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = ct.idsucursal
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = ct.idtran
	LEFT JOIN estados AS e
		ON e.idestado = st.idestado
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = ct.idu
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = c.idcliente
	LEFT JOIN ew_ven_vendedores AS v
		ON v.idvendedor = (CASE WHEN ct.idvendedor = 0 THEN ctr.idvendedor ELSE ct.idvendedor END)

	LEFT JOIN evoluware_conceptos ec ON ec.idconcepto = ct.idconcepto
	LEFT JOIN ew_cxc_transacciones vt ON vt.idtran=ct.idtran2
	LEFT JOIN ew_ban_cuentas bc ON bc.idcuenta = ct.idcuenta

	LEFT JOIN ew_ban_formas bf ON bf.idforma = ct.idforma

	LEFT JOIN ew_ban_monedas bm ON
		bm.idmoneda = ct.idmoneda

	LEFT JOIN ew_cfd_comprobantes AS ccc
		ON ccc.idtran = ct.idtran AND ct.transaccion IN(SELECT transaccion FROM ew_cxc_transacciones)
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = ccc.idtran

	LEFT JOIN objetos AS ro
		ON ro.tipo = 'AUX'
		AND ro.codigo = 'AUX28'
WHERE
	ct.idsucursal = (CASE WHEN @idsucursal = 0 THEN ct.idsucursal ELSE @idsucursal END)
	AND o.objeto = (CASE WHEN @objeto = -1 THEN o.objeto ELSE @objeto END)
	AND ct.idcliente = (CASE WHEN @idcliente = 0 THEN ct.idcliente ELSE @idcliente END)
	AND ISNULL(v.idvendedor, 0) = (CASE WHEN @idvendedor = 0 THEN ISNULL(v.idvendedor, 0) ELSE @idvendedor END)
	AND st.idestado = (CASE WHEN @idestado = -1 THEN st.idestado ELSE @idestado END)
	AND ct.idmoneda = (CASE WHEN @idmoneda = -1 THEN ct.idmoneda ELSE @idmoneda END)
	AND ct.fecha BETWEEN @fecha1 AND @fecha2
ORDER BY
	ct.idsucursal
	, ct.idmoneda
	, o.nombre
	, CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ct.fecha, 3))
	, ct.folio
	, c.nombre
GO
