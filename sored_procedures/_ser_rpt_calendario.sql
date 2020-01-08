USE db_comercial_final
GO
IF OBJECT_ID('_ser_rpt_calendario') IS NOT NULL
BEGIN
	DROP PROCEDURE _ser_rpt_calendario
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20191217
-- Description:	Calendario de servicio
-- =============================================
CREATE PROCEDURE [dbo].[_ser_rpt_calendario]
	@idtecnico INT = 0 
	, @idtiposervicio AS INT = 0
	, @idcliente AS INT = 0
AS

SET NOCOUNT ON

SELECT
	[tecnico] = ISNULL((tecu.nombre + ' [' + tec.codigo + ']'), '-Sin Asignar-')
	, [servicio] = (st.nombre + ' [' + st.codigo + ']')
	, [idtiposervicio] = st.idtiposervicio
	
	, [servicio_ult_fecha] = ISNULL((
		SELECT TOP 1 
			so.fecha 
		FROM 
			ew_ser_ordenes AS so
		WHERE
			so.cancelado = 0
			AND so.idequipo = se.idequipo
			AND so.idtiposervicio = st.idtiposervicio
		ORDER BY
			so.fecha DESC
	), csp.fecha_inicial)
	, [servicio_periodo] = st.periodo
	, [servicio_prox_fecha] = GETDATE()

	, [equipo] = se.serie
	, [modelo] = a.codigo
	, [modelo_nombre] = a.nombre

	, [cliente_codigo] = c.codigo
	, [cliente_nombre] = c.nombre
INTO
	#_tmp_ser_calendario
FROM 
	ew_clientes_servicio_equipos AS cse
	LEFT JOIN ew_ser_equipos AS se
		ON se.idequipo = cse.idequipo
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = se.idarticulo
	LEFT JOIN ew_ser_tipos AS st
		ON st.programado = 1
	LEFT JOIN ew_clientes_servicio_planes AS csp
		ON csp.idcliente = cse.idcliente
		AND csp.plan_codigo = cse.plan_codigo
	LEFT JOIN ew_ser_tecnicos AS tec
		ON tec.idtecnico = cse.idtecnico
	LEFT JOIN evoluware_usuarios AS tecu
		ON tecu.idu = tec.idu
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = cse.idcliente
WHERE
	st.idtiposervicio IS NOT NULL
	AND cse.idtecnico = ISNULL(NULLIF(@idtecnico, 0), cse.idtecnico)
	AND st.idtiposervicio = ISNULL(NULLIF(@idtiposervicio, 0), st.idtiposervicio)
	AND cse.idcliente = ISNULL(NULLIF(@idcliente, 0), cse.idcliente)
ORDER BY
	ISNULL((tecu.nombre + ' [' + tec.codigo + ']'), '-Sin Asignar-')
	, (st.nombre + ' [' + st.codigo + ']')

UPDATE #_tmp_ser_calendario SET
	servicio_prox_fecha = ISNULL(DATEADD(MONTH, servicio_periodo, servicio_ult_fecha), GETDATE())

SELECT * 
FROM 
	#_tmp_ser_calendario
ORDER BY
	tecnico
	, servicio
	, servicio_prox_fecha

DROP TABLE #_tmp_ser_calendario
GO
