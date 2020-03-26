USE db_comercial_final
GO
IF OBJECT_ID('_ser_rpt_reportesPorTipoDeServicio') IS NOT NULL
BEGIN
	DROP PROCEDURE _ser_rpt_reportesPorTipoDeServicio
END
GO
-- =============================================
-- Author:		Vladimir Barreras
-- Create date: 20200128
-- Description:	Movimientos de servicio
-- =============================================
CREATE PROCEDURE [dbo].[_ser_rpt_reportesPorTipoDeServicio]
	@idsucursal AS INT = 0
	, @idcliente AS INT = 0
	, @idequipo AS INT = 0
	, @idtiposervicio AS SMALLINT = 0
	, @fecha1 AS DATETIME = NULL
	, @fecha2 AS DATETIME = NULL
	, @idtecnico AS INT = 0
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(VARCHAR(10), ISNULL(@fecha1, DATEADD(MONTH, -1, GETDATE())), 103) + ' 00:00'
SELECT @fecha2 = CONVERT(VARCHAR(10), ISNULL(@fecha2, GETDATE()), 103) + ' 23:59'

SELECT
	[sucursal] = s.nombre
	, [equipo] = se.serie
	, [tipo_servicio] = st.nombre
	, [falla] = ISNULL(f.descripcion, '-NA-')
	, [num_reportes] = (
		SELECT COUNT(*)
		FROM
			ew_ser_ordenes AS so
			LEFT JOIN ew_sys_transacciones AS st1
				ON st1.idtran = so.idtran
		WHERE
			so.cancelado = 0
			AND so.transaccion = 'SOR1'
			AND st1.idestado IN (51,251)
			AND so.idequipo = cse.idequipo
			AND so.idtiposervicio = st.idtiposervicio
			--AND so.idfalla = ISNULL(NULLIF(ISNULL(f.idfalla, 0), 0), so.idfalla)
			AND (
				so.idfalla = ISNULL(f.idfalla, so.idfalla)
				OR (
					so.idfalla NOT IN (
						SELECT stf1.idfalla 
						FROM 
							ew_ser_tipos_fallas AS stf1 
						WHERE 
							stf1.idtiposervicio = st.idtiposervicio
					)
					AND f.idfalla = 0
				)
			)
			AND so.fecha BETWEEN @fecha1 AND @fecha2
	)
	, [cliente] = '[' + c.codigo + '] ' + c.nombre
	, [tecnico] = u.nombre
INTO
	#_tmp_reportes_por_servicio
FROM 
	ew_clientes_servicio_equipos AS cse
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = cse.idcliente
	LEFT JOIN ew_ser_tecnicos AS tec
		ON tec.idtecnico = cse.idtecnico
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = tec.idu
	LEFT JOIN ew_ser_equipos AS se
		ON se.idequipo = cse.idequipo
	LEFT JOIN ew_ser_tipos AS st
		ON st.idtiposervicio = ISNULL(NULLIF(@idtiposervicio, 0), st.idtiposervicio)
	LEFT JOIN (
		SELECT
			[idtiposervicio] = st0.idtiposervicio
			, [idfalla]= 0
		FROM
			ew_ser_tipos AS st0

		UNION ALL

		SELECT
			[idtiposervicio] = stf0.idtiposervicio
			, [idfalla] = stf0.idfalla
		FROM
			ew_ser_tipos_fallas AS stf0
	) AS stf
		ON stf.idtiposervicio = st.idtiposervicio
	LEFT JOIN (
		SELECT [idfalla] = 0, [descripcion] = '-NA-' 
		UNION ALL 
		SELECT sf.idfalla, sf.descripcion FROM ew_ser_fallas AS sf
	) AS f
		ON f.idfalla = stf.idfalla
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = ISNULL(NULLIF(@idsucursal, 0), s.idsucursal)
WHERE
	cse.idcliente = ISNULL(NULLIF(@idcliente, 0), cse.idcliente)
	AND cse.idequipo = ISNULL(NULLIF(@idequipo, 0), cse.idequipo)
	AND cse.idtecnico = ISNULL(NULLIF(@idtecnico, 0), cse.idtecnico)

SELECT * 
FROM 
	#_tmp_reportes_por_servicio 
WHERE 
	num_reportes > 0
ORDER BY
	sucursal
	, equipo
	, tipo_servicio
GO
