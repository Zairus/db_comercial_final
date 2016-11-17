USE db_comercial_final
GO
-- =============================================
-- Author:		Arvin Valenzuela
-- Create date: 200811
-- Description:	Cancelar una poliza operativa
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_cancelarPoliza2]
	 @idtran2 AS BIGINT
	,@idusuario AS SMALLINT
	,@password AS VARCHAR(20)
	,@fecha AS SMALLDATETIME
AS

SET NOCOUNT ON

DECLARE
	@estado AS SMALLINT
	,@ejercicio2 AS SMALLINT
	,@referencia AS VARCHAR(100)
	,@error AS VARCHAR(500)
	,@ejercicio AS SMALLINT
	,@idsucursal AS SMALLINT
	,@periodo AS TINYINT
	,@origen AS TINYINT
	,@idtran AS BIGINT 
	,@usuario AS VARCHAR(20)
	,@idtranct AS BIGINT

-- inicializo variables   
SELECT 
	@usuario = usuario 
FROM 
	ew_usuarios 
WHERE 
	idu = @idusuario

SELECT  @ejercicio = DATEPART(YEAR, @fecha)
SELECT  @periodo = DATEPART(MONTH, @fecha)

SELECT 
	@estado = idestado
	, @idsucursal = codsuc
FROM 
	c_transacciones 
WHERE
	idtran = @idtran2

SELECT TOP 1
	@idtranct = c.idtran
	, @origen = c.origen
	, @ejercicio2 = c.ejercicio
	, @referencia = c.folio 
FROM
	ew_ct_poliza AS c
	LEFT JOIN ew_ct_poliza_mov As m 
		ON m.idtran = c.idtran
WHERE 
	m.idtran2 = @idtran2

--- verificamos que la transaccion tenga una poliza existente.
IF EXISTS (
	SELECT top 1 idtran 
	FROM ew_ct_poliza_mov 
	WHERE idtran2 = @idtran2
)
BEGIN
	IF @ejercicio != @ejercicio2
	BEGIN
		SELECT @error = 'El ejercicio en el que fue generada la poliza es diferente al de la fecha de cancelacion'
		RAISERROR (@error, 16, 1)
		RETURN
	END

	-- Generamos la transaccion
	EXEC _sys_prc_insertarTransaccion @usuario, @password, 'APO1', @idsucursal, 'A', '', 5, @idtran OUTPUT

	IF @idtran IS NULL OR @idtran < 1 
	BEGIN
		SELECT @error = 'Ocurrio un error al intentar crear la transaccion...' 
		RAISERROR (@error, 16, 1)
		RETURN
	END

	-- inserto en ct_polizas
	INSERT INTO ct_poliza (
		idtran
		,transaccion
		,referencia
		,fecha
		,ejercicio
		,periodo
		,idtipo
		,origen
		,usuario
		,concepto
	)
	SELECT
		@idtran
		,transaccion
		,referencia
		,@fecha
		,@ejercicio
		,@periodo
		,idtipo
		,1
		,usuario = @idusuario
		,concepto = 'Canc. ' + RTRIM(concepto)
	FROM
		ct_poliza 
	WHERE
		idtran = @idtranct
		
	--  Insertar los moviemientos
	INSERT INTO ew_ct_poliza_mov (
		idtran
		, idtran2
		,consecutivo
		,cuenta
		,concepto
		,referencia
		,cargos,abonos
		,tipomov
		,moneda
		,tipocambio
		,importe
		,idsucursal
	)
	SELECT
		@idtran
		, @idtran2
		, ct.consecutivo
		, ct.cuenta
		, concepto =  'Canc. ' + ct.concepto
		, @referencia
		, cargo = (ct.cargos * (-1))
		, abonos = ( ct.abonos * (-1))
		, ct.tipomov
		, ct.moneda
		, ct.tipocambio
		, importe = ct.importe * (-1)
		, ct.idsucursal
	FROM 
		ew_ct_poliza_mov AS ct 
		LEFT JOIN ew_ct_cuentas AS c
			ON c.cuenta = ct.cuenta
	WHERE 
		ct.idtran2 = @idtran2
END
GO
