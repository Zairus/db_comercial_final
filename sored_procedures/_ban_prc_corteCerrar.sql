USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100911
-- Description:	Cerrar corte de caja.
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_corteCerrar]
	 @idtran AS INT
	,@fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	 @sql AS VARCHAR(MAX)
	,@egreso_idtran AS INT
	,@ingreso_idtran AS INT
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@idsucursal AS SMALLINT
	,@idcuenta1 AS INT
	,@idcuenta2 AS INT

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idu = idu
	,@idsucursal = idsucursal
	,@idcuenta1 = idcuenta1
	,@idcuenta2 = idcuenta2
FROM
	ew_ban_documentos
WHERE
	idtran = @idtran

SELECT
	 @usuario = usuario
	,@password = [password]
FROM
	ew_usuarios
WHERE
	idu = @idu

IF @idcuenta1 = 0
BEGIN
	RAISERROR('Error: No se ha indicado cuenta de origen.', 16, 1)
	RETURN
END

IF @idcuenta2 = 0
BEGIN
	RAISERROR('Error: No se ha indicado cuenta de destino.', 16, 1)
	RETURN
END

IF EXISTS(
	SELECT *
	FROM
		ew_sys_turnos
	WHERE
		idcuenta = @idcuenta2
		AND fecha_fin IS NULL
		AND idu <> @idu
)
BEGIN
	RAISERROR('Error: La caja se debe cerrar por em mismo usuario que abrio turno.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- EGRESO DE CUENTA DE ORIGEN ##################################################

SELECT
	@sql = 'INSERT INTO ew_ban_transacciones (
	 idtran
	,idtran2
	,idcuenta
	,tipo
	,idconcepto
	,idsucursal
	,transaccion
	,folio
	,referencia
	,fecha
	,importe
	,subtotal
	,idforma
	,automatico
	,programado
	,idu
)
SELECT
	 [idtran] = {idtran}
	,[idtran2] = idtran
	,[idcuenta] = idcuenta1
	,[tipo] = 2
	,[idconcepto] = 0
	,[idsucursal] = idsucursal
	,[transaccion] = ''BDA1''
	,[folio] = ''{folio}''
	,[referencia] = transaccion + '' - '' + folio
	,[fecha] = ''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
	,[importe] = importe
	,[subtotal] = importe
	,[idforma] = 0
	,[automatico] = 1
	,[programado] = 0
	,[idu] = idu
FROM
	ew_ban_documentos
WHERE
	idtran = ' + LTRIM(RTRIM(STR(@idtran))) + '
	
INSERT INTO ew_ban_transacciones_mov (
	idtran
	,consecutivo
	,idmov2
	,idconcepto
	,importe
	,comentario
)
SELECT
	[idtran] = {idtran}
	,[consecutivo] = 1
	,[idmov2] = idmov
	,[idconcepto] = 41
	,[importe] = importe
	,[comentario] = comentario
FROM
	ew_ban_documentos
WHERE
	idtran = ' + LTRIM(RTRIM(STR(@idtran)))

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('Error: No se pudo obtener información para egreso bancario.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion 
	 @usuario
	,@password
	,'BDA1' --@transaccion
	,@idsucursal
	,'A' --@serie
	,@sql
	,6 --@foliolen
	,@egreso_idtran OUTPUT
	,'' -- @afolio
	,'' -- @afecha

IF @egreso_idtran IS NULL OR @egreso_idtran = 0
BEGIN
	RAISERROR('Error: No se pudo generar egreso bancario.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- INGRESO A CUENTA DESTINO ####################################################

SELECT
	@sql = 'INSERT INTO ew_ban_transacciones (
	 idtran
	,idtran2
	,idcuenta
	,tipo
	,idconcepto
	,idsucursal
	,transaccion
	,folio
	,referencia
	,fecha
	,importe
	,subtotal
	,idforma
	,automatico
	,programado
	,idu
)
SELECT
	 [idtran] = {idtran}
	,[idtran2] = idtran
	,[idcuenta] = idcuenta2
	,[tipo] = 1
	,[idconcepto] = 0
	,[idsucursal] = idsucursal
	,[transaccion] = ''BDC1''
	,[folio] = ''{folio}''
	,[referencia] = transaccion + '' - '' + folio
	,[fecha] = ''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
	,[importe] = importe
	,[subtotal] = importe
	,[idforma] = 0
	,[automatico] = 1
	,[programado] = 0
	,[idu] = idu
FROM
	ew_ban_documentos
WHERE
	idtran = ' + LTRIM(RTRIM(STR(@idtran))) + '

INSERT INTO ew_ban_transacciones_mov (
	idtran
	,consecutivo
	,idmov2
	,idconcepto
	,importe
	,comentario
)
SELECT
	[idtran] = {idtran}
	,[consecutivo] = 1
	,[idmov2] = idmov
	,[idconcepto] = 41
	,[importe] = importe
	,[comentario] = comentario
FROM
	ew_ban_documentos
WHERE
	idtran = ' + LTRIM(RTRIM(STR(@idtran)))

IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('Error: No se pudo obtener información para ingreso bancario.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion 
	 @usuario
	,@password
	,'BDC1' --@transaccion
	,@idsucursal
	,'A' --@serie
	,@sql
	,6 --@foliolen
	,@ingreso_idtran OUTPUT
	,'' -- @afolio
	,'' -- @afecha

IF @ingreso_idtran IS NULL OR @ingreso_idtran = 0
BEGIN
	RAISERROR('Error: No se pudo generar ingreso bancario.', 16, 1)
	RETURN
END

EXEC _ct_prc_contabilizarBPR2 @idtran

--------------------------------------------------------------------------------
-- CAMBIAR ESTADO DE CORTE #####################################################

EXEC _sys_prc_finalizarTurno @idu, @fecha

INSERT INTO ew_sys_transacciones2
	(idtran, idestado, idu)
VALUES
	(@idtran, 251, @idu)
GO
