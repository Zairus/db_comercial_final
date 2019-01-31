USE [db_comercial_final]
GO
ALTER VIEW [dbo].[ew_cfd_sat_clasificaciones]
AS
SELECT
	idr
	, idclasificacion
	, clave
	, descripcion
	, fecha_inicio_vigencia
	, fecha_fin_vigencia
	, iva_trasladado
	, ieps_trasladado
	, complemento
	, estimulo_frontera
	, palabras_clave
FROM
	db_comercial.dbo.evoluware_cfd_sat_clasificaciones
GO
