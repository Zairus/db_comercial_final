USE db_comercial_final
GO
-- =================================================================
-- Programador:		Laurence Saavedra
-- Descripcion:		Acumular los saldos contables por cada partida de la poliza
-- Fecha Creacion:	200910
-- Fecha Cambio:	201007
-- 
-- =================================================================
ALTER TRIGGER [dbo].[tg_ct_poliza_mov_i] ON [dbo].[ew_ct_poliza_mov] 
FOR INSERT
AS

SET NOCOUNT ON

DECLARE 
	@msg AS VARCHAR(200)
	,@idr AS BIGINT
	,@cuenta AS VARCHAR(20)
	,@idsucursal AS SMALLINT
	,@ejercicio AS SMALLINT
	,@periodo AS TINYINT
	,@moneda AS TINYINT
	,@tipocambio AS DECIMAL(15,2)
	,@tipomov AS BIT
	,@importe AS DECIMAL(15,2)
	,@cargos AS DECIMAL(15,4)
	,@abonos AS DECIMAL(15,4)
	,@saldo AS DECIMAL(15,4)
	,@iddiario AS SMALLINT
	,@contabilidad AS TINYINT
	,@operacion AS BIT
	,@cont AS INT
	,@miError AS VARCHAR(100)

SELECT @msg = ''

DECLARE tg_ct_poliza_mov_i CURSOR FOR
	SELECT
		m.idr
		, m.cuenta
		, m.idsucursal
		, p.ejercicio
		, p.periodo
		, m.moneda
		, m.tipocambio
		, m.tipomov
		, m.cargos
		, m.abonos
		, m.iddiario
		, p.contabilidad
	FROM 
		inserted AS m
		LEFT JOIN ew_ct_poliza AS p 
	ON 
		p.idtran = m.idtran

OPEN tg_ct_poliza_mov_i

FETCH NEXT FROM tg_ct_poliza_mov_i INTO 
	@idr
	, @cuenta
	, @idsucursal
	, @ejercicio
	, @periodo
	, @moneda
	, @tipocambio
	, @tipomov
	, @cargos
	, @abonos
	, @iddiario
	, @contabilidad

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @miError = ''
	SELECT @importe = (CASE WHEN @tipomov = '0' THEN @cargos ELSE @abonos END)

	IF @contabilidad!= 0 
	BEGIN
		SELECT @contabilidad = 100
	END

	IF @idsucursal = 0
	BEGIN
		CLOSE tg_ct_poliza_mov_i
		DEALLOCATE tg_ct_poliza_mov_i

		RAISERROR('Error: Sucursal 0 invalida en contabilidad.', 16, 1)
		RETURN
	END
	
	-- Actualizamos los saldos de la cuenta
	EXEC _ct_prc_acumularSaldos 
		@cuenta
		, @idsucursal
		, @ejercicio
		, @periodo
		, @cargos
		, @abonos
		, @importe
		, @miError
		, @contabilidad

	IF (@@ERROR != 0) OR (LEN(@miError) > 0)
	BEGIN
		SELECT @msg = @miError
		
		CLOSE tg_ct_poliza_mov_i
		DEALLOCATE tg_ct_poliza_mov_i

		RAISERROR (@msg, 16, 1)
		RETURN
	END

	-- Acumulamos al Diario Especial
	IF @iddiario > 0
	BEGIN
		SELECT @miError = ''
		SELECT @importe = (
			CASE 
				WHEN @tipomov = 0 THEN @cargos 
				ELSE @abonos 
			END
		) * (
			CASE 
				WHEN @tipomov = 0 THEN 1 
				ELSE -1
			END
		)

		INSERT INTO ew_ct_diarios_saldos (
			iddiario
			, ejercicio
			, periodo
			, idsucursal
			, importe
		)
		VALUES (
			@iddiario
			, @ejercicio
			, @periodo
			, @idsucursal
			, @importe
		)
	END
	
	-- Obtenemos el saldo actual para la cuenta en la sucursal
	SELECT @saldo = dbo.xls_ct_cuentaSaldo(@cuenta, @idsucursal, @ejercicio, @periodo, @contabilidad)
	
	-- Confirmamos que ya acumulamos los saldos
	UPDATE ew_ct_poliza_mov SET
		acumulado = 1
		, saldo = @saldo
	WHERE
		idr = @idr

	FETCH NEXT FROM tg_ct_poliza_mov_i INTO 
		@idr
		, @cuenta
		, @idsucursal
		, @ejercicio
		, @periodo
		, @moneda
		, @tipocambio
		, @tipomov
		, @cargos
		, @abonos
		, @iddiario
		, @contabilidad
END

CLOSE tg_ct_poliza_mov_i
DEALLOCATE tg_ct_poliza_mov_i
GO
