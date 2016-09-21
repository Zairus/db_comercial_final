USE [db_comercial_final]
GO
ALTER VIEW [dbo].[ew_cfd_certificados]
AS
SELECT
	c.idr
	, c.idcertificado
	, c.noCertificado
	, c.certificado
	, c.firma
	, c.contraseña
	, c.[hash]
	, c.cadenaOriginal
	, c.directorio
	, c.sucursales
	, c.activo
	, c.idpac
	, c.prueba
	, c.pac_usr
	, c.pac_pwd
	, c.comentario
FROM
	dbo.evoluware_certificados AS c
GO
