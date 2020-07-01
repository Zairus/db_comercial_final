USE [db_imaginn_datos]
GO
IF OBJECT_ID('_ven_rpt_resumenVentasServiciosMedicosFP') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_rpt_resumenVentasServiciosMedicosFP
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200311
-- Description:	Detallado de ventas para servicios medicos
-- =============================================
CREATE PROCEDURE [dbo].[_ven_rpt_resumenVentasServiciosMedicosFP]
	@idsucursal AS INT = 0
	, @familia_codigo AS VARCHAR(30) = ''
	, @idtecnico_ordenante AS INT = 0
	, @idtecnico_receptor AS INT = 0
	, @idclasifica AS INT = 0
	, @fecha1 AS DATETIME = NULL
	, @fecha2 AS DATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(DATETIME, CONVERT(VARCHAR, ISNULL(@fecha1, DATEADD(MONTH, -1, GETDATE())), 103) + ' 00:00')
SELECT @fecha2 = CONVERT(DATETIME, CONVERT(VARCHAR, ISNULL(@fecha2, GETDATE()), 103) + ' 23:59')

SELECT
	[forma_pago] = ISNULL(bf.nombre, 'Crédito')
	, [importe] = SUM(ISNULL(pm.importe2, vt.total))
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = vt.idcliente

	LEFT JOIN ew_ven_transacciones_medico_ordenante AS vtmo
		ON vtmo.idtran = vt.idtran
	LEFT JOIN ew_ven_transacciones_medico_receptor AS vtmr
		ON vtmr.idtran = vt.idtran

	LEFT JOIN ew_ven_transacciones_mov AS vtm
		ON vtm.idtran = vt.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_articulos_niveles AS af
		ON af.nivel = 1
		AND af.codigo = a.nivel1
		
	LEFT JOIN ew_cxc_transacciones_mov AS pm
		ON pm.idtran2 = vt.idtran
	LEFT JOIN ew_cxc_transacciones AS p
		ON p.idtran = pm.idtran
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = p.idforma
WHERE
	vt.cancelado = 0
	AND vt.transaccion = 'EFA3'

	AND vt.idsucursal = ISNULL(NULLIF(@idsucursal, 0), vt.idsucursal)
	AND af.codigo = ISNULL(NULLIF(@familia_codigo, ''), af.codigo)
	AND ISNULL(vtmo.idtecnico_ordenante, 0) = ISNULL(NULLIF(@idtecnico_ordenante, 0), ISNULL(vtmo.idtecnico_ordenante, 0))
	AND ISNULL(vtmr.idtecnico_receptor, 0) = ISNULL(NULLIF(@idtecnico_receptor, 0), ISNULL(vtmr.idtecnico_receptor, 0))
	AND c.idclasifica = ISNULL(NULLIF(@idclasifica, 0), c.idclasifica)
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
GROUP BY 
	ISNULL(bf.nombre, 'Crédito')
GO
