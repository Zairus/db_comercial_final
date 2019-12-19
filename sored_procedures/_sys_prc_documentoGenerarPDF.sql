USE db_comercial_final
GO
IF OBJECT_ID('_sys_prc_documentoGenerarPDF') IS NOT NULL
BEGIN
	DROP PROCEDURE _sys_prc_documentoGenerarPDF
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190810
-- Description:	Generar Archivo PDF a documento
-- =============================================
CREATE PROCEDURE [dbo].[_sys_prc_documentoGenerarPDF]
	@idtran AS INT
	, @ruta_local AS VARCHAR(MAX) OUTPUT
	, @presentar AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@RUTA_BASE AS VARCHAR(500) = 'F:\Clientes\'

DECLARE
	@rs_url AS NVARCHAR(4000)
	, @ruta AS NVARCHAR(4000)
	, @file_name AS NVARCHAR(4000)
	, @success AS BIT

SELECT
	@rs_url = ISNULL((
		dbo.fn_sys_obtenerDato('DEFAULT', '?50')
		+ 'Pages/ReportViewer.aspx?/'
		+ ISNULL(od.valor, '')
		+ '&rs:Command=Render'
		+ '&rc:Toolbar=true'
		+ '&rc:parameters=false'
		+ '&dsu:Conexion_servidor=' + dbo.fn_sys_obtenerDato('DEFAULT', '?52')
		+ '&dsp:Conexion_servidor=' + dbo.fn_sys_obtenerDato('DEFAULT', '?53')
		+ '&rs:format=PDF'
		+ '&ServidorSQL=Data Source=erp.evoluware.com,1093;Initial Catalog=' + DB_NAME()
		+ '&idtran='
		+ LTRIM(RTRIM(STR(st.idtran)))
	), '')
	, @ruta = (
		@RUTA_BASE
		+ scs_dir.direccion
	)
	, @file_name = (
		st.transaccion
		+ '_'
		+ REPLACE(s.nombre, ' ', '-')
		+ '_'
		+ st.folio
		+ ''
	)
FROM
	ew_sys_transacciones AS st
	LEFT JOIN objetos AS o
		ON o.codigo = st.transaccion
	LEFT JOIN objetos_datos AS od
		ON od.objeto = o.objeto
		AND od.codigo = 'REPORTERS'
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = st.idsucursal

	LEFT JOIN dbEVOLUWARE.dbo.ew_sys_cuentas_servicios AS scs_db
		ON scs_db.servicio_id = 1
		AND scs_db.objeto_inicio = DB_NAME()
	LEFT JOIN dbEVOLUWARE.dbo.ew_sys_cuentas_servicios AS scs_dir
		ON scs_dir.servicio_id = 3
		AND scs_dir.cuenta_id = scs_db.cuenta_id
WHERE
	st.idtran = @idtran

CREATE TABLE #_tmp_dircheck (
	subdirectory VARCHAR(MAX)
)

INSERT INTO #_tmp_dircheck EXEC xp_subdirs @ruta

SELECT @ruta = @ruta + '\Documentos'

IF NOT EXISTS (SELECT * FROM #_tmp_dircheck WHERE subdirectory = 'Documentos')
BEGIN
	EXEC xp_create_subdir @ruta
END

DROP TABLE #_tmp_dircheck

SELECT @ruta_local = @ruta + '\' + @file_name + '.pdf'

IF NOT [dbEVOLUWARE].[dbo].[_sys_fnc_fileExists](@ruta_local) = 1
BEGIN
	SELECT @success = [dbEVOLUWARE].[dbo].[web_download_v2](@rs_url, @ruta_local, '', '')
END

IF @presentar = 1
BEGIN
	SELECT [ruta_local] = @ruta_local
END
GO
