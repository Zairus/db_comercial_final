USE db_comercial_final
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER VIEW [dbo].[ew_ban_formas]
AS
SELECT
	bfl.idr
	,bfl.idforma
	,bfl.codigo
	,bfl.nombre
	,bfl.activo
	,bfl.maneja_cheques
	,bfl.idmoneda
	,bfl.comentario
	,bfl.[version]
FROM 
	ew_ban_formas_local AS bfl
	
UNION ALL

SELECT
	csf.idr
	,[idforma]  = csf.idr + 1000
	,[codigo] = csf.c_formapago
	,[nombre] = csf.descripcion
	,[activo] = 1
	,[maneja_cheques] = 0
	,[idmoneda] = 0
	,[comentario] = ''
	,[version] = '3.3'
FROM 
	db_comercial.dbo.evoluware_cfd_sat_formapago AS csf
WHERE
	(SELECT COUNT(*) FROM ew_ban_formas_local AS bfl WHERE bfl.codigo = csf.c_formapago) = 0
GO
