USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 2010-07
-- Description:	
-- =============================================
ALTER TRIGGER [dbo].[tg_ct_poliza_mov_u]
	ON [dbo].[ew_ct_poliza_mov]
	FOR UPDATE
AS 

SET NOCOUNT ON

DECLARE 
	 @msg AS VARCHAR(200)
	,@miError AS VARCHAR(1000)
	,@id AS BIGINT
	,@cuenta AS VARCHAR(20)
	,@acuenta AS VARCHAR(20)
	,@idsucursal AS SMALLINT
	,@aidsucursal AS SMALLINT
	,@ejercicio AS SMALLINT
	,@aejercicio AS SMALLINT
	,@periodo AS TINYINT
	,@aperiodo AS TINYINT
	,@moneda AS TINYINT
	,@tipomov AS BIT
	,@atipomov AS BIT
	,@importe AS DECIMAL(15,2)
	,@cargos AS DECIMAL(15,4)
	,@acargos AS DECIMAL(15,4)
	,@abonos AS DECIMAL(15,4)
	,@aabonos AS DECIMAL(15,4)
	,@saldo AS DECIMAL(15,4)
	,@saldosuc AS DECIMAL(15,4)
	,@contabilidad AS TINYINT
	,@afectable AS BIT

-- Validamos que se hayan modificado alguno de los campos que afectan la condicion para acumular saldos
IF UPDATE(cuenta) OR UPDATE(idsucursal) OR UPDATE(tipomov) OR UPDATE(cargos) OR UPDATE(abonos) 
BEGIN
	-- iniciamos el cursor con todos los registros que se hayan modificado en la misma instruccion
	DECLARE cur_tg_ct_poliza_mov_u CURSOR FOR
		SELECT 
			m.idr
			, m.cuenta
			, p.ejercicio
			, p.periodo
			, m.idsucursal
			, m.tipomov
			, m.cargos
			, m.abonos 
			, p.contabilidad
		FROM 
			inserted m
			LEFT JOIN ew_ct_poliza p
				ON p.idtran = m.idtran
	
	OPEN cur_tg_ct_poliza_mov_u
	
	FETCH NEXT FROM cur_tg_ct_poliza_mov_u INTO 
		@id
		, @cuenta
		, @ejercicio
		, @periodo
		, @idsucursal
		, @tipomov
		, @cargos
		, @abonos
		, @contabilidad
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Obtenemos el valor del registro anterior (deleted)
		SELECT
			@acuenta = cuenta
			, @aejercicio = @ejercicio
			, @aperiodo = @periodo
			, @aidsucursal = idsucursal
			, @atipomov = tipomov
			, @acargos = cargos
			, @aabonos = abonos 
		FROM
			deleted 
		WHERE
			idr = @id

		-- Multiplicamos los cargos y los abonos por menos uno, para invertir su valor (desplicarlos)
		SELECT @acargos = @acargos * -1
		SELECT @aabonos = @aabonos * -1

		SELECT @miError = ''
		SELECT @importe = (CASE WHEN @tipomov = '0' THEN @acargos ELSE @aabonos END)

		-- Desaplicamos los saldos del periodo anterior
		EXEC _ct_prc_acumularSaldos @acuenta, @aidsucursal, @aejercicio, @aperiodo, @acargos, @aabonos, @importe, @miError, @contabilidad, 1

		IF (@@error != 0) OR (len(@miError) > 0)
		BEGIN
			-- Ocurrió un error al intentar desaplicar los saldos
			SELECT @msg = @miError

			CLOSE cur_tg_ct_poliza_mov_u
			DEALLOCATE cur_tg_ct_poliza_mov_u

			RAISERROR (@msg,16,1)
			RETURN
		END

		-- Acumulamos los saldos con el movimiento contable modificado
		SELECT @miError = '', @importe = (CASE WHEN @tipomov='0' THEN @cargos ELSE @abonos END)

		EXEC _ct_prc_acumularSaldos @cuenta, @idsucursal, @ejercicio, @periodo, @cargos, @abonos, @importe, @miError, @contabilidad

		IF (@@error != 0) OR (len(@miError) > 0)
		BEGIN
			-- Ocurrió un error al intentar aplicar los saldos
			SELECT @msg = @miError

			CLOSE cur_tg_ct_poliza_mov_u
			DEALLOCATE cur_tg_ct_poliza_mov_u

			RAISERROR (@msg,16,1)
			RETURN
		END
		
		FETCH NEXT FROM cur_tg_ct_poliza_mov_u INTO 
			@id
			, @cuenta
			, @ejercicio
			, @periodo
			, @idsucursal
			, @tipomov
			, @cargos
			, @abonos
			, @contabilidad
	END

	CLOSE cur_tg_ct_poliza_mov_u
	DEALLOCATE cur_tg_ct_poliza_mov_u
END
GO
