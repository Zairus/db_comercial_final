USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110505
-- Description:	Consulta de pedidos de sucursal
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_pedidos]
	 @idsucursal_origen AS SMALLINT = 0
	,@idsucursal_destino AS SMALLINT = 0
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
	,@idestado AS SMALLINT = -1
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3))

SELECT
	 [sucursal_destino] = sd.nombre
	,[sucursal_origen] = so.nombre
	,id.fecha
	,id.folio
	,id.total
	,[estado] = oe.nombre
	,id.idtran
FROM
	ew_inv_documentos AS id
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = id.idtran
	LEFT JOIN ew_sys_sucursales AS so
		ON so.idsucursal = id.idsucursal
	LEFT JOIN ew_sys_sucursales AS sd
		ON sd.idsucursal = id.idsucursal_destino
	LEFT JOIN objetos AS o
		ON o.codigo = id.transaccion
	LEFT JOIN objetos_estados AS oe
		ON oe.idestado = st.idestado
		AND oe.objeto = o.objeto
WHERE
	id.transaccion = 'GDT3'
	AND id.idsucursal = (CASE @idsucursal_origen WHEN 0 THEN id.idsucursal ELSE @idsucursal_origen END)
	AND id.idsucursal_destino = (CASE @idsucursal_destino WHEN 0 THEN id.idsucursal_destino ELSE @idsucursal_destino END)
	AND id.fecha BETWEEN @fecha1 AND @fecha2
	AND st.idestado = (CASE @idestado WHEN -1 THEN st.idestado ELSE @idestado END)
ORDER BY
	 id.idsucursal_destino
	,id.idsucursal
	,id.fecha
GO
