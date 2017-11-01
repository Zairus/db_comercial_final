USE db_comercial_final
GO
IF EXISTS (SELECT * FROM sys.objects WHERE [name] = 'ew_cfd_sat_clasificaciones' AND [type] = 'U')
BEGIN
	DROP TABLE ew_cfd_sat_clasificaciones
END
GO
IF EXISTS (SELECT * FROM sys.objects WHERE [name] = 'ew_cfd_sat_clasificaciones' AND [type] = 'V')
BEGIN
	DROP VIEW ew_cfd_sat_clasificaciones
END
GO
CREATE VIEW ew_cfd_sat_clasificaciones
AS
SELECT
	idr
	,idclasificacion
	,clave
	,descripcion
	,fecha_inicio_vigencia
	,fecha_fin_vigencia
	,iva_trasladado
	,ieps_trasladado
	,complemento
FROM
	db_comercial.dbo.evoluware_cfd_sat_clasificaciones
GO
SELECT * FROM ew_cfd_sat_clasificaciones
