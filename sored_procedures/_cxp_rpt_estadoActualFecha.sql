USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110228
-- Description:	Estado actual de cartera
-- =============================================
ALTER PROCEDURE [dbo].[_cxp_rpt_estadoActualFecha]
	 @idsucursal AS SMALLINT = 0
	,@codproveedor AS VARCHAR(30) = ''
	,@fecha AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

DECLARE
	@fecha_inicial AS SMALLDATETIME

SELECT
	@fecha_inicial = MIN(ct.fecha)
FROM
	ew_cxp_transacciones AS ct
WHERE
	ct.cancelado = 0
	AND ct.tipo IN (1,2)
	AND ct.saldo <> 0
	
SELECT @fecha = ISNULL(@fecha, CONVERT(VARCHAR(8), GETDATE(), 3) + ' 23:59')

SELECT
	[proveedor_tipo] = (
		CASE p.tipo 
			WHEN 0 THEN 'Proveedor' 
			WHEN 1 THEN 'Acreedor' 
			ELSE
				CASE
					WHEN ct.transaccion = 'CFA1' THEN 'Proveedor'
					ELSE 'Acreedor'
				END
		END
	)
	,[proveedor] = p.nombre + ' (' + p.codigo + ')'
	,[codigo] = p.codigo
	,[sucursal] = s.nombre
	,[idsucursal] = ct.idsucursal
	,[fecha] = ct.fecha
	,[vencimiento] = DATEADD(DAY, ct.credito_dias, ct.fecha)
	,[movimiento] = o.nombre
	,[folio] = ct.folio
	,[tipo] = ct.tipo
	,[saldo_actual] = [dbo].[_cxp_fnc_documentoSaldoR2] (ct.idtran, @fecha) * (CASE WHEN ct.idmoneda = 0 THEN 1 ELSE ct.tipocambio END) 
	,[cargos] = 0
	,[abonos] = 0
	,[saldo] = 0
	,[comentario] = ct.comentario
	,[idtran] = ct.idtran
INTO
	#_tmp_estadoActual
FROM
	ew_cxp_transacciones AS ct
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = ct.idsucursal
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = ct.idproveedor
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = ct.idmoneda
WHERE
	ct.cancelado = 0
	AND ct.tipo IN (1,2)
	AND ct.fecha >= @fecha_inicial
	AND ABS([dbo].[_cxp_fnc_documentoSaldoR2] (ct.idtran, @fecha)) > 0
	AND ct.idsucursal = (CASE WHEN @idsucursal = 0 THEN ct.idsucursal ELSE @idsucursal END)
	AND p.codigo = (CASE WHEN @codproveedor = '' THEN p.codigo ELSE @codproveedor END)
	AND ct.caja_chica = 0
ORDER BY
	 ct.idsucursal
	,p.nombre
	,ct.fecha
	,ct.folio

SELECT
	[proveedor_tipo]
	,[proveedor]
	,[sucursal]
	,[fecha]
	,[vencimiento]
	,[movimiento]
	,[folio]
	,[cargos] = (CASE WHEN tea.tipo = 1 THEN tea.saldo_actual ELSE 0 END)
	,[abonos] = (CASE WHEN tea.tipo = 2 THEN tea.saldo_actual ELSE 0 END)
	,[saldo] = (CASE WHEN tea.tipo = 1 THEN tea.saldo_actual ELSE (tea.saldo_actual * -1) END)
	,[saldo2] = (CASE WHEN tea.tipo = 1 THEN tea.saldo_actual ELSE (tea.saldo_actual * -1) END)
	,tea.comentario
	,tea.idtran
FROM
	#_tmp_estadoActual AS tea
	WHERE
		tea.[saldo_actual] <> 0
ORDER BY
	tea.proveedor_tipo
	,tea.codigo
	,tea.fecha

DROP TABLE #_tmp_estadoActual
GO
