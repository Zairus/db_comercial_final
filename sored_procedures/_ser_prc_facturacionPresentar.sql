USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180601
-- Description:	Presentar planes a facturar
-- =============================================
ALTER PROCEDURE [dbo].[_ser_prc_facturacionPresentar]
AS

SET NOCOUNT ON

SELECT
	[cliente] = c.nombre
	,[idcliente] = c.idcliente
	,[fecha] = GETDATE()
	,[plan] = (
		CASE
			WHEN csp.tipo_facturacion = 3 THen csp.plan_descripcion
			ELSE (
				SELECT
					csp1.plan_descripcion + CHAR(9) AS [text()]
				FROM
					ew_clientes_servicio_planes AS csp1
				WHERE
					csp1.idcliente = csp.idcliente
					AND csp1.tipo_facturacion IN (1,2)
				FOR XML PATH ('')
			) --csp.plan_codigo
		END
	) --csp.plan_descripcion
	,[plan_codigo] = (
		CASE
			WHEN csp.tipo_facturacion = 3 THen csp.plan_codigo
			ELSE (
				SELECT
					csp1.plan_codigo + CHAR(9) AS [text()]
				FROM
					ew_clientes_servicio_planes AS csp1
				WHERE
					csp1.idcliente = csp.idcliente
					AND csp1.tipo_facturacion IN (1,2)
				FOR XML PATH ('')
			) --csp.plan_codigo
		END
	)
	,[costo] = (csp.costo)
	,[facturar] = 1
	,[no_orden] = ''
INTO
	#_tmp_planesf
FROM
	ew_clientes_servicio_planes AS csp
	LEFT JOIN ew_ser_planes_tipos AS spt
		ON spt.idtipoplan = csp.tipo
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = csp.idcliente
WHERE
	spt.facturar = 1
	AND (MONTH(GETDATE()) - MONTH(csp.fecha_inicial)) % csp.periodo = 0

SELECT
	tf.cliente
	, tf.idcliente
	, tf.fecha
	, tf.[plan]
	, tf.plan_codigo
	, [costo] = SUM(tf.costo)
	, tf.facturar
	, tf.no_orden
FROM
	#_tmp_planesf AS tf
GROUP BY
	tf.cliente
	, tf.idcliente
	, tf.fecha
	, tf.[plan]
	, tf.plan_codigo
	, tf.facturar
	, tf.no_orden
ORDER BY
	tf.idcliente

DROP TABLE #_tmp_planesf
GO
