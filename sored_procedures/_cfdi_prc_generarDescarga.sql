USE db_comercial_final
GO
IF OBJECT_ID('_cfdi_prc_generarDescarga') IS NOT NULL
BEGIN
	DROP PROCEDURE _cfdi_prc_generarDescarga
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200101
-- Description:	Genera archivo para descarga de CFDi
-- =============================================
CREATE PROCEDURE [dbo].[_cfdi_prc_generarDescarga]
	@idsucursal SMALLINT = 0
	, @idcliente AS INT = 0
	, @tipo AS VARCHAR(1) = '-'
	, @fecha1 AS DATETIME = NULL
	, @fecha2 AS DATETIME = NULL
	, @condicion AS SMALLINT = -1
	, @cancelado AS SMALLINT = -1

	, @presentar AS BIT = 1
	, @zip AS VARCHAR(150) = NULL OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@idtran AS INT
	, @ruta AS VARCHAR(150)
	, @ruta_xml AS VARCHAR(150)
	, @archivos AS VARCHAR(MAX)

CREATE TABLE #_tmp_cfdi_dw (
	idr INT IDENTITY
	, idtran INT NOT NULL
	, ruta VARCHAR(150) NOT NULL

	, CONSTRAINT [PK__tmp_cfdi_dw] PRIMARY KEY CLUSTERED (
		idtran ASC
		, ruta ASC
	) ON [PRIMARY]
) ON [PRIMARY]

SELECT @fecha1 = CONVERT(
	 DATETIME
	, CONVERT(
		VARCHAR(10)
		,ISNULL(@fecha1, GETDATE()), 103
	) + ' 00:00'
)

SELECT @fecha2 = CONVERT(
	 DATETIME
	, CONVERT(
		VARCHAR(10)
		,ISNULL(@fecha2, GETDATE()), 103
	) + ' 23:59'
)

SELECT @archivos = ''

DECLARE cur_comprobantes CURSOR FOR
	SELECT
		cfdi.idtran
	FROM
		ew_cfd_comprobantes_timbre AS cfdi
		LEFT JOIN ew_cxc_transacciones AS cxc 
			ON cxc.idtran=cfdi.idtran
		LEFT JOIN ew_cfd_comprobantes AS cfd 
			ON cfd.idtran = cfdi.idtran
	WHERE
		cxc.idsucursal = ISNULL(NULLIF(@idsucursal, 0), cxc.idsucursal)
		AND cxc.idcliente = ISNULL(NULLIF(@idcliente, 0), cxc.idcliente)
		AND cxc.fecha BETWEEN @fecha1 AND @fecha2
		AND SUBSTRING(cfd.cfd_tipoDeComprobante, 1, 1) = (
			CASE 
				WHEN @tipo = '-' THEN SUBSTRING(cfd.cfd_tipoDeComprobante, 1, 1) 
				ELSE @tipo 
			END
		)
		AND cxc.credito = ISNULL(NULLIF(@condicion, -1), cxc.credito)
		AND cxc.cancelado = ISNULL(NULLIF(@cancelado, -1), cxc.cancelado)

OPEN cur_comprobantes

FETCH NEXT FROM cur_comprobantes INTO
	@idtran

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @ruta = ''
	EXEC [dbo].[_cfdi_prc_generarPDF] @idtran, @ruta OUTPUT
	
	SELECT @ruta_xml = ''
	EXEC [dbo].[_cfdi_prc_generarXML] @idtran, @ruta_xml OUTPUT
	
	INSERT INTO #_tmp_cfdi_dw (
		idtran
		, ruta
	)
	VALUES (
		@idtran
		, @ruta
	)

	IF @ruta IS NOT NULL
	BEGIN
		SELECT @archivos = @archivos + (CASE WHEN LEN(@archivos) > 0 THEN ';' ELSE '' END) + @ruta
	END
	
	IF @ruta_xml IS NOT NULL
	BEGIN
		SELECT @archivos = @archivos + (CASE WHEN LEN(@archivos) > 0 THEN ';' ELSE '' END) + @ruta_xml
	END

	FETCH NEXT FROM cur_comprobantes INTO
		@idtran
END

CLOSE cur_comprobantes
DEALLOCATE cur_comprobantes

SELECT @zip = ''

SELECT
	@zip = (
		cfa.rfc
		+ '-CFDI-'
		+ (
			CASE
				WHEN c.idcliente IS NULL THEN 'TODOS'
				ELSE (
					LEFT(REPLACE(c.nombre, ' ', ''), 15)
				)
			END
		)
		+ '-'
		+ (CASE WHEN @tipo = '-' THEN 'G' ELSE @tipo END)
		+ '-'
		+ [dbo].[fnRellenar](YEAR(@fecha1), 4, '0')
		+ [dbo].[fnRellenar](MONTH(@fecha1), 2, '0')
		+ [dbo].[fnRellenar](DAY(@fecha1), 2, '0')
		+ '-'
		+ [dbo].[fnRellenar](YEAR(@fecha2), 4, '0')
		+ [dbo].[fnRellenar](MONTH(@fecha2), 2, '0')
		+ [dbo].[fnRellenar](DAY(@fecha2), 2, '0')
		+ '.zip'
	)
FROM 
	ew_clientes_facturacion AS cfa 
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = @idcliente
		AND @idcliente > 0
WHERE 
	cfa.idcliente = 0 
	AND cfa.idfacturacion = 0

SELECT
	@zip = 'F:\Clientes\' + scs_dir.direccion + '\TEMP\' + @zip
FROM 
	dbEVOLUWARE.dbo.ew_sys_cuentas_servicios AS scs_db
	LEFT JOIN dbEVOLUWARE.dbo.ew_sys_cuentas_servicios AS scs_dir
		ON scs_dir.cuenta_id = scs_db.cuenta_id
		AND scs_dir.servicio_id = 3
WHERE
	scs_db.objeto_inicio = DB_NAME()

EXEC dbEVOLUWARE.dbo.zip_create @zip, @archivos

DROP TABLE #_tmp_cfdi_dw

IF @presentar = 1
BEGIN
	SELECT [ruta] = @zip
END
GO
