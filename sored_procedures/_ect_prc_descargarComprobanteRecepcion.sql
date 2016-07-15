USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160616
-- Description:	Generar documento PDF de comprobante recibido
-- =============================================
ALTER PROCEDURE _ect_prc_descargarComprobanteRecepcion
	@uuid AS VARCHAR(50)
AS

SET NOCOUNT ON

DECLARE
	@success AS BIT
	,@archivoPDF AS VARCHAR(4000)

DECLARE
	@rs_command AS VARCHAR(4000)

SELECT
	@rs_command = (
		'http://68.233.240.102:8008/ReportServer_R2/Pages/ReportViewer.aspx?'
		+'/Modelo/Compras/ComprobanteCFDi'
		+'&rs:Command=Render'
		+'&uuid=' + @uuid
		+'&rc:Toolbar=true'
		+'&rc:parameters=false'
		+'&dsu:Conexion_servidor=ewadmin'
		+'&dsp:Conexion_servidor=pwevoluware2008'
		+'&ServidorSQL=Data Source=68.233.240.102,1093;Initial Catalog=db_comercial_final'
		+'&rs:format=PDF'
	)

SELECT
	@archivoPDF = REPLACE(ruta_archivo, '.xml', '.pdf')
FROM 
	ew_cfd_comprobantes_recepcion AS ccr
WHERE
	ccr.Timbre_UUID = @uuid

SELECT @success = db_comercial.dbo.WEB_download(@rs_command, @archivoPDF, '', '')

SELECT [codigo] = @success, [ruta] = @archivoPDF
GO
