USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20111222
-- Description:	Crear registro de póliza contable sin referencia de transacción.
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_polizaCrearSinReferencia]
	 @fecha AS SMALLDATETIME
	,@idtipo AS TINYINT
	,@idu AS SMALLINT
	,@idsucursal AS SMALLINT
	,@referencia AS VARCHAR(80)
	,@poliza_idtran AS INT OUTPUT

	,@periodo AS INT = NULL
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACIÓN DE VARIABLES ####################################################

DECLARE
	@afecha AS VARCHAR(20)

DECLARE
	 @sql AS VARCHAR(MAX)
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	 @usuario = usuario
	,@password = password
FROM
	ew_usuarios
WHERE
	idu = @idu

SELECT @afecha = CONVERT(VARCHAR(8), @fecha, 3)

--------------------------------------------------------------------------------
-- REGISTRAR PÓLIZA ############################################################

IF @fecha IS NULL
BEGIN
	RAISERROR('Fecha Inválida.', 16, 1)
	RETURN
END

SELECT @sql = 'INSERT INTO ew_ct_poliza (
	 idtran
	,ejercicio
	,periodo
	,idtipo
	,folio
	,transaccion
	,referencia
	,fecha
	,concepto
	,origen
	,prepol
	,usuario
)
SELECT
	 [idtran] = {idtran}
	,[ejercicio] = ' + CONVERT(VARCHAR(4), YEAR(@fecha)) + '
	,[periodo] = ' + CONVERT(VARCHAR(20), ISNULL(@periodo, MONTH(@fecha))) + '
	,[idtipo] = ' + CONVERT(VARCHAR(1), @idtipo) + '
	,[folio] = ''{folio}''
	,[transaccion] = ''APO1''
	,[referencia] = ''' + @referencia + '''
	,[fecha] = ''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
	,[concepto] = ''' + @referencia + '''
	,[origen] = 0
	,[prepol] = ''''
	,[usuario] = ' + CONVERT(VARCHAR(20), @idu) + '
'

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('Error: No se pudo obtener información para póliza contable.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion 
	 @usuario
	,@password
	,'APO1'
	,@idsucursal
	,'A'
	,@sql
	,6
	,@poliza_idtran OUTPUT
	,''
	,@afecha

IF @poliza_idtran IS NULL OR @poliza_idtran = 0
BEGIN
	RAISERROR('Error: No fue posible registrar la póliza contable.', 16, 1)
	RETURN
END
GO
