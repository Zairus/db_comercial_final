USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20111011
-- Description:	Procesar inicio de caja
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_inicioProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idu AS INT
	,@fecha AS SMALLDATETIME
	,@idturno AS INT
	,@idcuenta AS INT
	,@idcuenta_origen AS INT

DECLARE
	@sql AS VARCHAR(MAX)
	,@egreso_idtran AS INT
	,@ingreso_idtran AS INT
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@idsucursal AS SMALLINT

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idu = idu
	,@fecha = fecha
	,@idcuenta = idcuenta1
	,@idcuenta_origen = idcuenta2
	,@idsucursal = idsucursal
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

EXEC [dbo].[_sys_prc_iniciarTurno] @idu, @fecha

SELECT @idturno = dbo.fn_sys_turnoActual(@idu)

IF @idcuenta = 0
BEGIN
	RAISERROR('Error: No se ha indicado cuenta bancaria.', 16, 1)
	RETURN
END

IF @idturno IS NULL
bEGIN
	RAISERROR('Error: No se pudo iniciar turno, verifique que haya cerrado turno anterior.', 16, 1)
	RETURN
END

IF EXISTS(SELECT * FROM ew_sys_turnos WHERE idcuenta = @idcuenta AND fecha_fin IS NULL)
BEGIN
	RAISERROR('Error: Existe turno abierto en esta caja, favor de cerrar turno o seleccionar otra caja.', 16, 1)
	RETURN
END

UPDATE ew_sys_turnos SET
	idcuenta = @idcuenta
WHERE
	idturno = @idturno

--Egreso
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
	,[idconcepto] = 47
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

SELECT @sql = ''

--Ingreso
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
	,[idconcepto] = 47
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
	RAISERROR('Error: No se pudo generar egreso bancario.', 16, 1)
	RETURN
END
GO
