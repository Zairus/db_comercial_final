USE db_comercial_final
GO
IF OBJECT_ID('_cxc_rpt_antiguedadSaldos') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_rpt_antiguedadSaldos
END
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: 20091122
-- Description:	Antiguedad de saldos de cuentas por cobrar
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_rpt_antiguedadSaldos]
	@idmoneda AS SMALLINT 
	, @idsucursal AS SMALLINT 
	, @idcliente AS SMALLINT
	, @idu AS SMALLINT
	, @idvendedor AS SMALLINT = 0
	, @detallado AS INT = 1
	, @fecha AS DATETIME = NULL
AS

SET NOCOUNT ON

DECLARE	
	@hoy AS SMALLDATETIME
	, @sucursales AS VARCHAR(20)

IF @detallado = 0
BEGIN
	EXEC [dbo].[_cxc_rpt_antiguedadSaldosResumido] @idmoneda, @idsucursal, @idcliente, @idu, @idvendedor
	RETURN
END

SELECT @fecha = ISNULL(@fecha, GETDATE())
SELECT @fecha = CONVERT(DATETIME, (CONVERT(VARCHAR(10), @fecha, 103) + ' 23:59'))

SELECT @hoy = CONVERT(DATETIME, CONVERT(VARCHAR(8), GETDATE(), 3))

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
	[idr] = ROW_NUMBER() OVER (ORDER BY ct.idmoneda, ct.idsucursal, c.nombre, DATEADD(DAY, ctr.credito_plazo, ct.fecha))
	, [sucursal] = s.nombre + ' (' + m.nombre + ')'
	, [cliente] = (c.nombre + ' ( ' + c.codigo + ' )')
	, [telefono1] = c.telefono1
	, [transaccion] = o.nombre
	, [folio] = ct.folio
	, [concepto] = o.nombre
	, [fecha] = ct.fecha
	, [vencimiento] = DATEADD(DAY, ctr.credito_plazo, ct.fecha)
	, [dias_emitido] = DATEDIFF(DAY, ct.fecha, @fecha)
	, [dias_vencido] = DATEDIFF(DAY, DATEADD(DAY, ctr.credito_plazo, ct.fecha), @fecha)
	, [tipo] = ct.tipo
	, [saldo00] = CONVERT(DECIMAL(18,6), 0)
	, [saldo30] = CONVERT(DECIMAL(18,6), 0)
	, [saldo60] = CONVERT(DECIMAL(18,6), 0)
	, [saldo90] = CONVERT(DECIMAL(18,6), 0)
	, [saldo99] = CONVERT(DECIMAL(18,6), 0)
	, [saldoxx] = [dbo].[_cxc_fnc_documentoSaldoR2] (ct.idtran, @fecha) * (CASE WHEN ct.tipo = 1 THEN 1 ELSE -1 END)
	, [idtran] = ct.idtran

	, [tractor] = mt.mm_nombre
	, [remolque1] = mr.mm_nombre
	, [comentario] = ct.comentario

	, [vendedor] = ISNULL(v.nombre, '-Sin Asignar-')
	, [empresa] = dbo.fn_sys_empresa()

	, [idvendedor] = ISNULL(v.idvendedor, 0)
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
INTO
	#_tmp_ant_saldos
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = ct.idcliente
	LEFT JOIN sucursales AS s 
		ON s.idsucursal = ct.idsucursal
	LEFT JOIN ew_ban_monedas AS m 
		ON m.idmoneda = ct.idmoneda
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN objetos AS o 
		ON o.codigo = ct.transaccion
	LEFT JOIN ew_ven_vendedores AS v
		ON v.idvendedor = ISNULL(NULLIF(ct.idvendedor, 0), ctr.idvendedor)

	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = ct.idtran	
	LEFT JOIN mm_cat_vehiculos AS mt 
		ON mt.mm_idvehiculo = vt.mm_idvehiculo
	LEFT JOIN mm_cat_vehiculos AS mr 
		ON mr.mm_idvehiculo = vt.mm_idvehiculo_remolque1

	LEFT JOIN objetos AS ro
		ON ro.tipo = 'AUX'
		AND ro.codigo = 'AUX20'
WHERE
	ct.cancelado = 0
	AND ct.aplicado = 1
	AND ct.tipo IN (1,2)
	AND ABS([dbo].[_cxc_fnc_documentoSaldoR2] (ct.idtran, @fecha)) > 0.01

	AND (
		(
			@idsucursal = 0
			AND @idu > 0
			AND (
				ct.idsucursal IN (SELECT CONVERT(INT, ss.valor) FROM dbo.fn_sys_split(@sucursales, ',') AS ss)
				OR @sucursales = ''
			)
		)
		OR (
			@idsucursal > 0
			AND (
				ct.idsucursal = @idsucursal
			)
		)
		OR (
			@idsucursal = 0
			AND @idu = 0
		)
	)
	AND ct.idmoneda = ISNULL(NULLIF(@idmoneda, -1), ct.idmoneda)
	AND ct.idcliente = ISNULL(NULLIF(@idcliente, -1), ct.idcliente)
	AND ISNULL(v.idvendedor, 0) = ISNULL(NULLIF(@idvendedor, 0), ISNULL(v.idvendedor, 0))

ORDER BY
	ct.fecha DESC

UPDATE #_tmp_ant_saldos SET 
	dias_vencido = 0 
WHERE 
	dias_vencido < 0
	OR tipo = 2

UPDATE #_tmp_ant_saldos SET 
	saldo00 = saldoxx
WHERE 
	dias_vencido = 0

UPDATE tas SET
	tas.saldo00 = (CASE WHEN tas.vencimiento >= @fecha THEN tas.saldoxx ELSE tas.saldo00 END)
	, tas.saldo30 = (CASE WHEN tas.vencimiento < @fecha AND tas.dias_vencido BETWEEN 1 AND 30 THEN tas.saldoxx ELSE tas.saldo30 END)
	, tas.saldo60 = (CASE WHEN tas.vencimiento < @fecha AND tas.dias_vencido BETWEEN 31 AND 60 THEN tas.saldoxx ELSE tas.saldo60 END)
	, tas.saldo90 = (CASE WHEN tas.vencimiento < @fecha AND tas.dias_vencido BETWEEN 61 AND 90 THEN tas.saldoxx ELSE tas.saldo90 END)
	, tas.saldo99 = (CASE WHEN tas.vencimiento < @fecha AND tas.dias_vencido > 90 THEN tas.saldoxx ELSE tas.saldo99 END)
FROM
	#_tmp_ant_saldos AS tas

SELECT * 
FROM 
	#_tmp_ant_saldos 
ORDER BY
	idr ASC

DROP TABLE #_tmp_ant_saldos
GO
