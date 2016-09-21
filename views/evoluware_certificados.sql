USE [db_comercial_final]
GO
ALTER VIEW [dbo].[evoluware_certificados]
AS
SELECT
	ec.idr
	, ec.idcertificado
	, ec.noCertificado
	, ec.certificado
	, ec.firma
	, ec.[contraseña]
	, ec.[hash]
	, ec.cadenaOriginal
	, ec.directorio
	, ec.sucursales
	, ec.activo
	, ec.idpac
	, ec.prueba
	, ec.pac_usr
	, ec.pac_pwd
	, ec.comentario
FROM
	db_comercial.dbo.evoluware_certificados AS ec
WHERE
	ec.idcertificado IN (999,998)
GO
