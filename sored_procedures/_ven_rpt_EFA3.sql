USE db_comercial_final
GO
IF OBJECT_ID('_ven_rpt_EFA3') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_rpt_EFA3
END
GO
CREATE PROCEDURE [dbo].[_ven_rpt_EFA3]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[folio] = vt.folio
	, [emisor] = (
		SELECT razon_social 
		FROM 
			ew_clientes_facturacion 
		WHERE 
			idcliente = 0 
			AND idfacturacion = 0
	)
	, [fecha_hora] = vt.fecha_hora
	, [cliente] = (
		(
			c.codigo 
			+ ' - ' 
			+ c.nombre
		) 
		+ CHAR(13) 
		+ CHAR(10) 
		+ cf.calle 
		+ ' ' 
		+ cf.noExterior 
		+ ' C.P. ' 
		+ cf.codpostal 
		+ ' ' 
		+ scc.ciudad 
		+ ', ' 
		+ scc.estado
	)
	, [vendedor] = ISNULL(v.nombre, '')
	, [cajero] = ISNULL(u.nombre, '')
	, [medico_ordenante] = ISNULL(ISNULL(uto.nombre, sto.nombre), 'A quien corresponda')
	, [medico_receptor] = ISNULL(utr.nombre, [str].nombre)
	, [cantidad] = vtm.cantidad_facturada
	, [descripcion] = a.nombre
	, [importe] = vtm.total
	, [precio_unitario_o] = vtm.precio_venta
	, [descuento1] = (vtm.descuento1 / 100.00)
	, [precio_unitario] = (
		CASE 
			WHEN vtm.cantidad_facturada > 0 THEN vtm.total / vtm.cantidad_facturada 
			ELSE 0 
		END
	)
	, [total_o] = ISNULL((
		SELECT
			SUM(vtm1.cantidad_facturada * vtm1.precio_venta)
		FROM
			ew_ven_transacciones_mov AS vtm1
		WHERE
			vtm1.idtran = vt.idtran
	), 0)
	, [total] = vt.total
	, [pago_total] = (vtp.total + vtp.total2)
	, [pago_cambio] = ((vtp.total + vtp.total2) - vt.total)
	, [pendiente] = (
		CASE 
			WHEN ((vtp.total + vtp.total2) - vt.total) < 0 THEN ((vtp.total + vtp.total2) - vt.total) * -1 
			ELSE 0 
		END
	)
	, [folio_ticket] = (
		dbo._sys_fnc_rellenar(vt.idsucursal, 3, '0')
		+ vt.folio
		+ RIGHT(CONVERT(VARCHAR(MAX), CONVERT(BIGINT, vt.idr) * CONVERT(BIGINT, vt.idtran)), 2)
	)
	, [descuento] = (vtm.cantidad_facturada * vtm.precio_venta) - vtm.importe
	, [sucursal_datos] = (
		s.nombre 
		+ CHAR(10) 
		+ CHAR(13) 
		+ s.direccion 
		+ CHAR(10) 
		+ CHAR(13) 
		+ 'C.P. ' 
		+ s.codpostal 
		+ CHAR(10) 
		+ CHAR(13) 
		+ sc.ciudad 
		+ ', ' 
		+ sc.estado 
		+ CHAR(10) 
		+ CHAR(13) 
		+ 'R.F.C. ' 
		+ s.rfc
	)
	, [url_facturacion] = (
		LOWER(dbo.fn_sys_obtenerDato('GLOBAL', 'EVOLUWARE_CUENTA')) 
		+ '.evoluware.net'
	)
	, [formaPago] = (
		ISNULL(bf.nombre,'') 
		+ (
			CASE 
				WHEN vtp.idforma2 > 0 THEN ('/' + bf2.nombre) 
				ELSE '' 
			END
		)
	)
	, [moneda] = bm.nombre
	, [tipocambio] = vt.tipocambio
	, [condicionVenta] = (
		CASE 
			WHEN vt.credito=1 THEN 'CREDITO' 
			ELSE 'CONTADO' 
		END
	)
	, [comentario] = (
		CASE 
			WHEN vt.transaccion IN('EFA1','EFA3','EFA6') THEN (
				CONVERT(VARCHAR(MAX), vt.comentario) 
				+ CHAR(10) 
				+ CHAR(13) 
				+ ISNULL(dbo.fn_sys_parametro('VEN_MENSAJE_COMENTARIO'), '')
			)
			ELSE vt.comentario 
		END
	)
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_ven_transacciones_mov AS vtm 
		ON vtm.idtran = vt.idtran
	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_clientes_facturacion cf
		ON cf.idcliente = c.idcliente and cf.idfacturacion = 0
	LEFT JOIN ew_ven_vendedores AS v 
		ON v.idvendedor = vt.idvendedor
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_ven_transacciones_pagos AS vtp 
		ON vtp.idtran = vt.idtran
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = vt.idsucursal
	LEFT JOIN ew_sys_ciudades AS sc
		ON sc.idciudad = s.idciudad
	LEFT JOIN ew_sys_ciudades AS scc
		ON scc.idciudad = cf.idciudad

	LEFT JOIN ew_cat_usuarios AS u
		ON u.idu = vt.idu
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = vt.idforma

	LEFT JOIN ew_ban_formas AS bf2
		ON bf2.idforma = vtp.idforma2

	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = vt.idmoneda

	LEFT JOIN ew_ven_transacciones_medico_ordenante AS vtmo
		ON vtmo.idtran = vt.idtran
	LEFT JOIN ew_ser_tecnicos AS sto
		ON sto.idtecnico = vtmo.idtecnico_ordenante
	LEFT JOIN evoluware_usuarios AS uto
		ON uto.idu = sto.idu
	LEFT JOIN ew_ven_transacciones_medico_receptor As vtmr
		ON vtmr.idtran = vt.idtran
	LEFT JOIN ew_ser_tecnicos AS [str]
		ON [str].idtecnico = vtmr.idtecnico_receptor
	LEFT JOIN evoluware_usuarios AS utr
		ON utr.idu = [str].idu
WHERE
	vt.idtran = @idtran
GO
