USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110228
-- Description:	Estado actual de cartera
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_rpt_estadoActualFecha]
	 @idsucursal AS SMALLINT = 0
	,@codcliente AS VARCHAR(30) = ''
	,@idvendedor AS INT = 0
	,@fecha AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

DECLARE
	@fecha_inicial AS SMALLDATETIME

SELECT
	@fecha_inicial = MIN(ct.fecha)
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.cancelado = 0
	AND ct.tipo IN (1,2)
	AND ct.saldo <> 0

SELECT @fecha = ISNULL(@fecha, CONVERT(VARCHAR(8), GETDATE(), 3) + ' 23:59')

SELECT
	 [sucursal] = s.nombre
	,ct.idsucursal
	,[cliente] = c.nombre + ' (' + c.codigo + ')'
	,c.codigo
	,ct.fecha
	,[vencimiento] = DATEADD(DAY, ctr.credito_plazo, ct.fecha)
	,[folio] = (
		CASE 
			WHEN ct.transaccion = 'EFA1' THEN 
				(CASE ct.idsucursal WHEN 1 THEN 'HMO' WHEN 2 THEN 'OBR' WHEN 4 THEN '' ELSE '' END) + dbo._sys_fnc_rellenar(ct.folio, 6, '0')
			ELSE ct.folio
		END
	)
	,ct.tipo
	,[saldo_actual] = [dbo].[_cxc_fnc_documentoSaldoR2](ct.idtran, @fecha)
	,[cargos] = (CASE WHEN ct.tipo = 1 THEN [dbo].[_cxc_fnc_documentoSaldoR2](ct.idtran, @fecha) ELSE 0 END)
	,[abonos] = (CASE WHEN ct.tipo = 2 THEN [dbo].[_cxc_fnc_documentoSaldoR2](ct.idtran, @fecha) ELSE 0 END)
	,[saldo] = (CASE WHEN ct.tipo = 1 THEN [dbo].[_cxc_fnc_documentoSaldoR2](ct.idtran, @fecha) ELSE ([dbo].[_cxc_fnc_documentoSaldoR2](ct.idtran, @fecha) * -1) END)
	,ct.comentario
	,ct.idtran
INTO
	#_tmp_estadoActual
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = ct.idsucursal
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = ct.idcliente
WHERE
	ct.cancelado = 0
	AND ct.tipo IN (1,2)
	AND ct.fecha >= @fecha_inicial
	AND [dbo].[_cxc_fnc_documentoSaldoR2] (ct.idtran, @fecha) <> 0
	AND ct.idsucursal = (CASE WHEN @idsucursal = 0 THEN ct.idsucursal ELSE @idsucursal END)
	AND c.codigo = (CASE WHEN @codcliente = '' THEN c.codigo ELSE @codcliente END)
	AND ctr.idvendedor = (CASE WHEN @idvendedor = 0 THEN ctr.idvendedor ELSE @idvendedor END)
ORDER BY
	 ct.idsucursal
	,c.nombre
	,ct.fecha
	,ct.folio

SELECT
	[sucursal]
	,[cliente]
	,[fecha]
	,[vencimiento]
	,[folio]
	,[cargos] = (CASE WHEN tea.tipo = 1 THEN tea.saldo_actual ELSE 0 END)
	,[abonos] = (CASE WHEN tea.tipo = 2 THEN tea.saldo_actual ELSE 0 END)
	,[saldo] = (CASE WHEN tea.tipo = 1 THEN tea.saldo_actual ELSE (tea.saldo_actual * -1) END)
	,[saldo2] = [dbo].[_cxc_fnc_documentoSaldoR2] (tea.idtran, @fecha)
	,tea.comentario
	,tea.idtran
FROM
	#_tmp_estadoActual AS tea
	WHERE
		tea.[saldo_actual] <> 0
ORDER BY
	tea.idsucursal
	,tea.codigo
	,tea.fecha

DROP TABLE #_tmp_estadoActual
GO
