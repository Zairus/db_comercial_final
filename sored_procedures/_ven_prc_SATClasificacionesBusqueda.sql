USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190130
-- Description:	Busqueda de Clasificaciones SAT
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_SATClasificacionesBusqueda]
	@busqueda AS VARCHAR(MAX)
AS

SET NOCOUNT ON

SELECT @busqueda = REPLACE(@busqueda, ' ', '%')
SELECT @busqueda = ('%' + @busqueda + '%')

SELECT
	[idclasificacion_sat] = csc.idclasificacion
	, [sat_clave] = csc.clave
	, [sat_nombre] = csc.descripcion 
	, [estimulo_frontera] = (CASE WHEN csc.estimulo_frontera = 1 THEN 'Si' ELSE 'No' END)
FROM 
	ew_cfd_sat_clasificaciones AS csc
WHERE
	csc.descripcion LIKE @busqueda
GO
