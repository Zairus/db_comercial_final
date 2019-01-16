USE [db_comercial_final]
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: 20091122
-- Description:	Antiguedad de saldos de cuentas por cobrar
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_rpt_antiguedadSaldos]
	@idmoneda AS SMALLINT 
	, @idsucursal AS SMALLINT 
	, @idcliente AS SMALLINT
	, @idu AS SMALLINT
	, @idvendedor AS SMALLINT = 0
	, @detallado AS INT = 1
AS

SET NOCOUNT ON

DECLARE	
	@hoy AS SMALLDATETIME
	, @sucursales AS VARCHAR(20)

IF @detallado = 0
BEGIN
	EXEC [dbo].[_cxc_rpt_antiguedadSaldosResumido] @idmoneda, @idsucursal, @idcliente, @idu, @idvendedor
END
	ELSE
BEGIN
	SELECT @hoy = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), GETDATE(), 3))

	SELECT
		@sucursales = sucursales 
	FROM
		usuarios 
	WHERE 
		idu = @idu

	SELECT @sucursales = ISNULL(@sucursales, '')

	IF @sucursales = '0'
	BEGIN
		SELECT @sucursales = ''
	END

	SELECT 
		[sucursal] = s.nombre + ' (' + m.nombre + ')'
		, [cliente] = (p.nombre + ' ( ' + p.codigo + ' )')
		, [telefono1] = cf.telefono1
		, [transaccion] = o.nombre
		, [folio] = dp.folio
		, [concepto] = c.nombre
		, [fecha] = dp.fecha
		, [dias_emitido] = DATEDIFF(day,dp.fecha,GETDATE())
		, [tipo] = dp.tipo
		, [moneda] = m.nombre
		, [vencimiento] = DATEADD(day,pt.credito_plazo,dp.fecha)
		, [dias_vencido] = DATEDIFF(day,DATEADD(day,pt.credito_plazo,dp.fecha),GETDATE())
		, [saldo00] = (CASE WHEN dp.tipo = 1 THEN (CASE WHEN ((dp.fecha + pt.credito_plazo) >= CONVERT(SMALLDATETIME, @hoy)) THEN dp.saldo ELSE 0 END) ELSE dp.saldo * -1 END)
		, [saldo30] = (CASE WHEN dp.tipo = 1 THEN (CASE WHEN ((dp.fecha + pt.credito_plazo) < CONVERT(SMALLDATETIME, @hoy)) AND ((dp.fecha + pt.credito_plazo) >= CONVERT(SMALLDATETIME, @hoy) - 30) THEN dp.saldo ELSE 0 END) ELSE 0 END)
		, [saldo60] = (CASE WHEN dp.tipo = 1 THEN (CASE WHEN ((dp.fecha + pt.credito_plazo) < CONVERT(SMALLDATETIME, @hoy) - 30) AND ((dp.fecha + pt.credito_plazo) >= CONVERT(SMALLDATETIME, @hoy) - 60) THEN dp.saldo ELSE 0 END) ELSE 0 END)
		, [saldo90] = (CASE WHEN dp.tipo = 1 THEN (CASE WHEN ((dp.fecha + pt.credito_plazo) < CONVERT(SMALLDATETIME, @hoy) - 60) AND ((dp.fecha + pt.credito_plazo) >= CONVERT(SMALLDATETIME, @hoy) - 90) THEN dp.saldo ELSE 0 END) ELSE 0 END)
		, [saldo99] = (CASE WHEN dp.tipo = 1 THEN (CASE WHEN ((dp.fecha + pt.credito_plazo) < CONVERT(SMALLDATETIME, @hoy) - 90) THEN dp.saldo ELSE 0 END) ELSE 0 END)
		, [saldoxx] = (CASE WHEN dp.tipo = 1 THEN dp.saldo ELSE dp.saldo * -1 END)
		, [idtran] = dp.idtran

		, [tractor] = mt.mm_nombre
		, [remolque1] = mr.mm_nombre
		, [comentario] = dp.comentario

		, [vendedor] = ISNULL(v.nombre, '-Sin Asignar-')
		, [empresa] = dbo.fn_sys_empresa()

		, [idvendedor] = (CASE WHEN dp.idvendedor = 0 THEN ctr.idvendedor ELSE dp.idvendedor END)
		, [detallado] = @detallado

		, [titulo] = ro.nombre
		, [titulo_subtitulo] = UPPER(
			'MONEDA: '
			+ m.nombre
			+ '. AL '
			+ LTRIM(RTRIM(STR(DAY(@hoy))))
			+ ' DE '
			+ (SELECT spd.descripcion FROM ew_sys_periodos_datos AS spd WHERE spd.grupo = 'meses' AND spd.id = MONTH(@hoy))
			+ '-'
			+ LTRIM(RTRIM(STR(YEAR(@hoy))))
		)
		, [titulo_fecha] = 'Fecha: ' + CONVERT(VARCHAR(8), GETDATE(), 3)
		, [titulo_ruta] = [dbo].[_sys_fnc_objetoRuta](ro.objeto)

		INTO #temporal
	FROM 
		ew_cxc_transacciones AS dp
		LEFT JOIN ew_clientes AS p 
			ON p.idcliente = dp.idcliente
		LEFT JOIN ew_clientes_facturacion AS cf
			ON dp.idcliente = cf.idcliente 
			AND dp.idfacturacion = cf.idfacturacion
		LEFT JOIN ew_clientes_terminos AS ctr
			ON ctr.idcliente = p.idcliente
		LEFT JOIN sucursales AS s 
			ON s.idsucursal = dp.idsucursal
		LEFT JOIN ew_ban_monedas AS m 
			ON m.idmoneda = dp.idmoneda
		LEFT JOIN ew_clientes_terminos AS pt
			ON pt.idcliente = dp.idcliente
		LEFT JOIN conceptos AS c 
			ON c.idconcepto = dp.idconcepto
		LEFT JOIN ew_ven_vendedores AS v
			ON v.idvendedor = (CASE WHEN dp.idvendedor = 0 THEN ctr.idvendedor ELSE dp.idvendedor END)
		LEFT JOIN objetos AS o 
			ON o.codigo = dp.transaccion

		LEFT JOIN ew_ven_transacciones AS d 
			ON d.idtran = dp.idtran	
		LEFT JOIN mm_cat_vehiculos AS mt 
			ON mt.mm_idvehiculo = d.mm_idvehiculo
		LEFT JOIN mm_cat_vehiculos AS mr 
			ON mr.mm_idvehiculo = d.mm_idvehiculo_remolque1

		LEFT JOIN objetos AS ro
			ON ro.tipo = 'AUX'
			AND ro.codigo = 'AUX20'
	WHERE 
		dp.cancelado = 0
		AND ABS(dp.saldo) >= 0.01
		AND dp.tipo IN (1,2)
		AND dp.aplicado = 1

		AND (
			(
				@idsucursal = 0
				AND @idu > 0
				AND (
					dp.idsucursal IN (SELECT CONVERT(INT, ss.valor) FROM dbo.fn_sys_split(@sucursales, ',') AS ss)
					OR @sucursales = ''
				)
			)
			OR (
				@idsucursal > 0
				AND (
					dp.idsucursal = @idsucursal
				)
			)
			OR (
				@idsucursal = 0
				AND @idu = 0
			)
		)

		AND dp.idmoneda = (CASE WHEN @idmoneda = -1 THEN dp.idmoneda ELSE @idmoneda END)
		AND dp.idcliente = (CASE WHEN @idcliente > 0 THEN @idcliente ELSE dp.idcliente END)

		AND (
			CASE WHEN dp.idvendedor = 0 
				THEN ctr.idvendedor 
				ELSE dp.idvendedor 
			END
		) = (
			CASE WHEN @idvendedor = 0 
				THEN (
					CASE WHEN dp.idvendedor = 0 
						THEN ctr.idvendedor 
						ELSE dp.idvendedor 
					END
				) 
				ELSE @idvendedor 
			END
		)
	ORDER BY 
		dp.idsucursal
		,dp.idmoneda
		,(p.nombre + ' ( ' + p.codigo + ' )') ASC
		,(dp.fecha + pt.credito_plazo) ASC

	SELECT * 
	FROM 
		#temporal
END
GO
