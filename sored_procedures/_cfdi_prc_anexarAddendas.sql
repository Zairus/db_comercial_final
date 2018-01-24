USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180124
-- Description:	Aplicar adendas a comprobantes
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_anexarAddendas]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@archivoXML AS VARCHAR(200)
	,@archivoXML_o AS VARCHAR(200)
	,@existe AS INT
	,@idcliente AS INT
	,@procedimiento AS NVARCHAR(500)
	,@comando AS NVARCHAR(MAX)
	,@addenda AS VARCHAR(MAX)
	,@xmlBase64 AS VARCHAR(MAX)
	,@bin_xml AS VARBINARY(MAX)
	,@msg AS VARCHAR(400)

SELECT
	@idcliente = ct.idcliente
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT 
	@archivoXML = archivoXML 
	,@archivoXML_o = archivoXML 
FROM 
	ew_cfd_comprobantes_sello 
WHERE 
	idtran = @idtran

SELECT @existe = dbEVOLUWARE.dbo._sys_fnc_fileExists(REPLACE(@archivoXML, '.xml', '_original.xml'))

IF @existe = 1
BEGIN
	SELECT @archivoXML = REPLACE(@archivoXML, '.xml', '_original.xml')
END
	ELSE
BEGIN
	SELECT @bin_xml = [dbEVOLUWARE].[dbo].[BIN_ReadFile](@archivoXML)
	SELECT @msg = [dbEVOLUWARE].[dbo].[BIN_WriteFile](@bin_xml, REPLACE(@archivoXML, '.xml', '_original.xml'))
END

SELECT @existe = dbEVOLUWARE.dbo._sys_fnc_fileExists(@archivoXML)

DECLARE cur_addendas CURSOR FOR
	SELECT
		procedimiento
	FROM 
		[dbo].[ew_clientes_addendas]
	WHERE
		idcliente = @idcliente

OPEN cur_addendas

FETCH NEXT FROM cur_addendas INTO
	@procedimiento

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @comando = N'EXEC ' + @procedimiento + ' @idtranIn, @addendaIn OUTPUT'

	EXEC sp_executesql @comando, N'@idtranIn AS INT, @addendaIn VARCHAR(MAX) OUTPUT', @idtranIn = @idtran, @addendaIn = @addenda OUTPUT

	SELECT @xmlBase64 = [dbEVOLUWARE].[dbo].[ADDENDA_AnexarLibre](@archivoXML, @addenda)
	SELECT @bin_xml = [dbEVOLUWARE].[dbo].[CONV_Base64ToBin](@xmlBase64)
	SELECT @msg = [dbEVOLUWARE].[dbo].[BIN_WriteFile](@bin_xml, @archivoXML_o)

	FETCH NEXT FROM cur_addendas INTO
		@procedimiento
END

CLOSE cur_addendas
DEALLOCATE cur_addendas
GO
