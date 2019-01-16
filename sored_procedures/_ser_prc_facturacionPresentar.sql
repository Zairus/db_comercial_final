USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180601
-- Description:	Presentar planes a facturar
-- =============================================
ALTER PROCEDURE [dbo].[_ser_prc_facturacionPresentar]
	@periodo AS INT = NULL
	, @idcliente AS INT = 0
AS

SET NOCOUNT ON

SELECT @periodo = ISNULL(@periodo, MONTH(GETDATE()))

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
	,[facturar] = 0
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
	AND (
		csp.idcliente = @idcliente
		OR @idcliente = 0
	)
	AND (
		SELECT COUNT(*) 
		FROM 
			ew_clientes_servicio_equipos AS cse 
		WHERE 
			cse.idcliente = csp.idcliente 
			AND cse.plan_codigo = csp.plan_codigo
	) > 0
	AND csp.plan_codigo NOT IN (
		SELECT DISTINCT
			vtms.plan_codigo
		FROM
			ew_ven_transacciones_mov_servicio AS vtms
			LEFT JOIN ew_ven_transacciones AS vt
				ON vt.idtran = vtms.idtran
		WHERE
			vtms.ejercicio = YEAR(GETDATE())
			AND vtms.periodo = @periodo
			AND vt.idcliente = csp.idcliente
			AND vt.cancelado = 0
	)

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
	tf.cliente

DROP TABLE #_tmp_planesf
GO
