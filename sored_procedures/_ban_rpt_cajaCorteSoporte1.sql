USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151202
-- Description:	Soporte para corte de caja
-- =============================================
ALTER PROCEDURE [dbo].[_ban_rpt_cajaCorteSoporte1]
	@idsucursal AS INT
	,@fecha AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha, GETDATE()), 3) + ' 00:00')

SELECT
	[grupo] = 'Ventas'
	,[concepto] = ISNULL(an.nombre, '-Sin Asignar-')
	,[contado] = SUM(CASE WHEN ct.credito = 0 THEN vtm.total ELSE 0 END)
	,[credito] = SUM(CASE WHEN ct.credito = 1 THEN vtm.total ELSE 0 END)
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vt.idtran
	LEFT JOIN ew_ven_transacciones_mov AS vtm
		ON vtm.idtran = vt.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_articulos_niveles AS an
		ON an.codigo = a.nivel0
WHERE
	vt.cancelado = 0
	AND (
		vt.transaccion LIKE 'EFA%'
		AND vt.transaccion NOT IN ('EFA4')
	)
	AND vt.idsucursal = @idsucursal
	AND (CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), vt.fecha, 3) + ' 00:00')) = @fecha
GROUP BY
	an.nombre

UNION ALL

SELECT
	[grupo] = 'Pagos'
	,[concepto] = c.nombre
	,[contado] = (CASE WHEN f.credito = 0 THEN ctm.importe ELSE 0 END)
	,[credito] = (CASE WHEN f.credito = 1 THEN ctm.importe ELSE 0 END)
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
WHERE
	ct.cancelado = 0
	AND ct.transaccion = 'BDC2'
	AND ct.idsucursal = @idsucursal
	AND (CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ct.fecha, 3) + ' 00:00')) = @fecha

ORDER BY
	[grupo] DESC
GO
