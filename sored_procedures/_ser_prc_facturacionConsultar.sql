USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180601
-- Description:	Presentar planes a facturar
-- =============================================
ALTER PROCEDURE [dbo].[_ser_prc_facturacionConsultar]
	@periodo AS INT = NULL
AS

SET NOCOUNT ON

SELECT @periodo = ISNULL(@periodo, MONTH(GETDATE()))

SELECT
	[cliente] = c.nombre
	, [idcliente] = vt.idcliente
	, [fecha] = vt.fecha
	, [plan] = csp.plan_descripcion
	, [plan_codigo] = vtms.plan_codigo
	, [costo] = vtm.importe
	, [facturar] = 1
	, [facturado] = 1
	, [no_orden] = vt.no_orden
	, [idtran2] = vt.idtran
	, [factura_folio] = vt.folio
	, [timbrada] = 1
	, [enviado] = (
		CASE
			WHEN (
				SELECT COUNT(*) 
				FROM 
					dbEVOLUWARE.dbo.ew_sys_email AS se 
				WHERE 
					[db] = DB_NAME() 
					AND se.idtran = vt.idtran
			) > 0 THEN 1
			ELSE 0
		END
	)
	, [uuid] = cct.cfdi_uuid
	, [periodo] = vtms.periodo
	, [objidtran] = vt.idtran
FROM
	ew_ven_transacciones_mov_servicio AS vtms
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtms.idtran
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_clientes_servicio_planes AS csp
		ON csp.idcliente = vt.idcliente
		AND csp.plan_codigo = vtms.plan_codigo
	LEFT JOIN ew_ven_transacciones_mov AS vtm
		ON vtm.idmov = vtms.idmov
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = vt.idtran
WHERE
	vtms.ejercicio = YEAR(GETDATE())
	AND vt.cancelado = 0
	AND vtms.periodo = @periodo
GO
