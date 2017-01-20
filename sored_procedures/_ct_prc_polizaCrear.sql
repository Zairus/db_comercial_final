USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100426
-- Description:	Crear registro de póliza contable.
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_polizaCrear]
	 @idtran AS INT
	,@fecha AS SMALLDATETIME
	,@idtipo AS TINYINT
	,@idu AS SMALLINT
	,@poliza_idtran AS INT OUTPUT
	,@referencia AS VARCHAR(80) = ''
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACIÓN DE VARIABLES ####################################################

DECLARE
	  @idsucursal AS SMALLINT
	 ,@afecha AS VARCHAR(20)
	 ,@serie AS VARCHAR(5)
	 ,@folio AS VARCHAR(10)
	 ,@ejercicio AS SMALLINT
	 ,@periodo AS SMALLINT

DECLARE
	 @sql AS VARCHAR(MAX)
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	 @idsucursal = idsucursal
FROM 
	ew_sys_transacciones
WHERE
	idtran = @idtran

SELECT
	 @usuario = [usuario]
	,@password = [password]
FROM
	ew_usuarios
WHERE
	idu = @idu

SELECT @afecha = CONVERT(VARCHAR(8), @fecha, 3)
SELECT @ejercicio = YEAR(@fecha)
SELECT @periodo = MONTH(@fecha)

SELECT @serie = prefijo FROM ew_ct_tipos WHERE idtipo = @idtipo

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
	,[periodo] = ' + CONVERT(VARCHAR(2), MONTH(@fecha)) + '
	,[idtipo] = ' + CONVERT(VARCHAR(1), @idtipo) + '
	,[folio] = ''{folio}''
	,[transaccion] = ''APO1''
	,[referencia] = (
		CASE ''' + @referencia + '''
			WHEN '''' THEN (st.transaccion + '' - '' + st.folio)
			ELSE (''' + @referencia + ''')
		END
	)
	,[fecha] = ''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
	,[concepto] = o.nombre + '', folio: '' + st.folio
	,[origen] = 1
	,[prepol] = ''''
	,[usuario] = ' + CONVERT(VARCHAR(20), @idu) + '
FROM
	ew_sys_transacciones AS st
	LEFT JOIN objetos AS o
		ON o.codigo = st.transaccion
WHERE
	st.idtran = ' + CONVERT(VARCHAR(20), @idtran)

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('Error: No se pudo obtener información para póliza contable.', 16, 1)
	RETURN
END

EXEC _ct_prc_folioObtener
	@idtipo
	,@ejercicio
	,@periodo
	,@folio OUTPUT
	
EXEC _sys_prc_insertarTransaccion 
	 @usuario
	,@password
	,'APO1'
	,@idsucursal
	,@serie
	,@sql
	,6
	,@poliza_idtran OUTPUT
	,@folio
	,@afecha

IF @poliza_idtran IS NULL OR @poliza_idtran = 0
BEGIN
	RAISERROR('Error: No fue posible registrar la póliza contable.', 16, 1)
	RETURN
END

EXEC _ct_prc_folioEstablecer
	@idtipo
	,@ejercicio
	,@periodo
	,1
GO
