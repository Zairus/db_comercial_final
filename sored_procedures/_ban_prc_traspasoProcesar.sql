USE db_comercial_final
GO
-- =============================================
-- Author:		Arvin Valenzuela
-- Create date: 20100224
-- Description:	Procesar traspaso de bancos
--- EXEC _ban_prc_traspasoProcesar 1215, '03/05/10', 1;
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_traspasoProcesar]
	@idtran AS INT
	, @aplicado_fecha AS SMALLDATETIME
	, @idu AS SMALLINT
AS

SET NOCOUNT ON

DECLARE	
	@id AS BIGINT
	, @idtran2 AS BIGINT
	, @aplicado AS BIT
	, @idcuenta1 AS SMALLINT
	, @idcuenta2 As SMALLINT
	, @tipo AS TINYINT
	, @idconcepto AS SMALLINT
	, @importe AS DECIMAL(15,2)
	, @fecha AS SMALLDATETIME
	, @cont AS SMALLINT
	, @msg AS VARCHAR(250)
	, @SQL AS VARCHAR(8000)
	, @salida_idtran AS INT
	, @entrada_idtran AS INT
	, @usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @idsucursal AS SMALLINT

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################
SELECT
	@usuario = usuario
	, @password = [password]
FROM 
	ew_usuarios
WHERE
	idu = @idu
	
-- Obtenemos los datos de la transaccion y se exige que no se encuentre cancelada ó inactiva
SELECT 
	@aplicado = aplicado
	, @idcuenta1 = idcuenta1
	, @idcuenta2 = idcuenta2
	, @idtran2 = idtran2
	, @idconcepto = idconcepto
	, @importe = importe
	, @idsucursal = idsucursal
FROM 
	ew_ban_documentos
WHERE
	idtran = @idtran 
	AND cancelado = 0

IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Error 1: ban_documentos, no se permitió aplicar la transaccion.'
		
	RAISERROR (@msg, 16, 1)
	RETURN
END	

-----------------------------------------------------------
-- EGRESO ################################################

SELECT
	@sql = '
SET DATEFORMAT DMY

INSERT INTO ew_ban_transacciones (
	idtran
	, idtran2
	, transaccion 
	, idsucursal
	, fecha
	, idcuenta
	, tipocambio
	, folio
	, referencia
	, idu
	, tipo
	, idrelacion
	, identidad
	, idforma
	, forma_referencia
	, forma_moneda
	, programado
	, programado_fecha
	, importe
	, subtotal
	, impuesto
	, comentario
)

SELECT
	[idtran] = {idtran}
	, [idtran2] = idtran
	, [transaccion] = ''BDA1''
	, [idsucursal] = ew_ban_documentos.idsucursal
	, [fecha] = ''' + CONVERT(VARCHAR(10), @aplicado_fecha, 103)+ '''
	, [idcuenta] = idcuenta1
	, tipocambio
	, ''{folio}''
	, ''TRAS-''+ folio
	, ' + CONVERT(VARCHAR(20), @idu) + '
	, 2
	, 5
	, b.idbanco
	, idforma
	, folio
	, forma_moneda
	, 0
	, ''' + CONVERT(VARCHAR(20), @aplicado_fecha) + '''
	, importe
	, importe
	, impuesto
	, ew_ban_documentos.comentario 
FROM 
	ew_ban_documentos
    LEFT JOIN ew_ban_cuentas AS b 
		ON b.idcuenta = ew_ban_documentos.idcuenta1
WHERE 
	idtran = ' + CONVERT(VARCHAR(20), @idtran) + '

INSERT INTO ew_ban_transacciones_mov (
	idtran
	, idmov2
	, consecutivo
	, idconcepto
	, importe
	, idimpuesto
	, impuesto_tasa
)
SELECT 
	[idtran] = {idtran}
	, [idmov2] = idmov
	, [consecutivo] = ROW_NUMBER() OVER (ORDER BY ew_ban_documentos.idr)
	, [idconcepto] = 13
	, [importe] = importe
	, [idimpuesto] = 0
	, [impuesto_tasa] = 0
FROM 
	ew_ban_documentos
WHERE 
	idtran = ' + CONVERT(VARCHAR(20), @idtran) + '
'

IF @sql IS NULL OR @sql = ''
BEGIN	
	RAISERROR('No se pudo obtener información para registrar salida del origen.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	@usuario
	, @password
	, 'BDA1' --Transacción
	, @idsucursal
	, 'A' --Serie
	, @sql
	, 6 --Longitod del folio
	, @salida_idtran OUTPUT
	, '' --Afolio
	, @aplicado_fecha --Afecha

IF @salida_idtran IS NULL OR @salida_idtran = 0
BEGIN
	RAISERROR('No se pudo crear el egreso bancario.', 16, 1)
	RETURN
END

SELECT @sql = ''

-----------------------------------------------------------
-- INGRESO ################################################

SELECT
	@sql = '
SET DATEFORMAT DMY

INSERT INTO ew_ban_transacciones (
	idtran
	, idtran2
	, transaccion 
	, idsucursal
	, fecha
	, idcuenta
	, tipocambio
	, folio
	, referencia
	, idu
	, tipo
	, idrelacion
	, identidad
	, idforma
	, forma_referencia
	, forma_moneda
	, programado
	, programado_fecha
	, importe
	, subtotal
	, impuesto
	, comentario
)

SELECT 
	[idtran] = {idtran}
	, [idtran2] = idtran
	, [transaccion] = ''BDC1''
	, [idsucursal] = ew_ban_documentos.idsucursal
	, [fecha] = ''' + CONVERT(VARCHAR(10), @aplicado_fecha, 103)+ '''
	, [idcuenta] = idcuenta2
	, tipocambio2
	, ''{folio}''
	, ''TRAS-''+ folio
	, ' + CONVERT(VARCHAR(20),@idu)+'
	, 1
	, 5
	, b.idbanco
	, idforma
	, folio
	, forma_moneda
	, 0
	, ''' + CONVERT(VARCHAR(20),@aplicado_fecha)+'''
	, ((importe * tipocambio) / (tipocambio2))
	, ((importe * tipocambio) / (tipocambio2))
	, impuesto
	, ew_ban_documentos.comentario 
FROM 
	ew_ban_documentos
    LEFT JOIN ew_ban_cuentas AS b 
		ON b.idcuenta = ew_ban_documentos.idcuenta2
WHERE 
	idtran = ' + CONVERT(VARCHAR(20), @idtran) + '

INSERT INTO ew_ban_transacciones_mov (
	idtran
	, idmov2
	, consecutivo
	, idconcepto
	, importe
	, idimpuesto
	, impuesto_tasa
)
SELECT 
	[idtran] = {idtran}
	, [idmov2] = idmov
	, [consecutivo] = ROW_NUMBER() OVER (ORDER BY ew_ban_documentos.idr)
	, [idconcepto] = 13
	, [importe] = ((importe * tipocambio)/(tipocambio2))
	, [idimpuesto] = 0
	, [impuesto_tasa] = 0
FROM 
	ew_ban_documentos
WHERE
	idtran = ' + CONVERT(VARCHAR(20), @idtran) + '
'
	
IF @sql IS NULL OR @sql = ''
BEGIN
	RAISERROR('No se pudo obtener información para registrar el ingreso a la cuenta destino.', 16, 1)
	RETURN
END

EXEC _sys_prc_insertarTransaccion
	@usuario
	, @password
	, 'BDC1' --Transacción
	, @idsucursal
	, 'A' --Serie
	, @sql
	, 6 --Longitod del folio
	, @entrada_idtran OUTPUT
	, '' --Afolio
	, @aplicado_fecha --Afecha

IF @entrada_idtran IS NULL OR @entrada_idtran = 0
BEGIN
	RAISERROR('No se pudo crear el ingreso bancario.', 16, 1)
	RETURN
END

-- Modificando el Estatus a APL
IF NOT EXISTS(SELECT a = 'No' WHERE dbo.fn_sys_estadoActual(@idtran) = dbo.fn_sys_estadoID('APL'))
BEGIN		
	INSERT INTO ew_sys_transacciones2
		(idtran, idestado, idu)
	VALUES 
		(@idtran, dbo.fn_sys_estadoID('APL'), @idu)
END

-- Modificando la bandera de aplicado
UPDATE ew_ban_documentos SET 
	aplicado = 1
	, aplicado_fecha = @aplicado_fecha
WHERE 
	idtran = @idtran
GO
