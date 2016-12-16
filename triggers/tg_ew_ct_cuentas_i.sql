USE [db_comercial_final]
GO
ALTER TRIGGER [dbo].[tg_ew_ct_cuentas_i] ON [dbo].[ew_ct_cuentas] 
	INSTEAD OF INSERT
AS

SET NOCOUNT ON

DECLARE 
	@msg AS VARCHAR(100)
	,@idcuenta AS INT
	,@cont AS INT
	,@cuenta AS VARCHAR(20)
	,@cuentasup AS VARCHAR(20)
	,@llave AS VARCHAR(50)
	,@ejercicio AS SMALLINT
	,@afectable AS BIT

DECLARE cur_ew_ct_cuentas_i CURSOR FOR
	SELECT 
		idcuenta
		, cuenta
		, cuentasup
		, YEAR(fecha_alta) 
	FROM 
		inserted 

OPEN cur_ew_ct_cuentas_i

FETCH NEXT FROM cur_ew_ct_cuentas_i INTO 
	@idcuenta
	, @cuenta
	, @cuentasup
	, @ejercicio

WHILE @@fetch_status = 0
BEGIN
	SELECT @cont = 0
	
	-- validamos que exista la cuenta superior
	IF NOT EXISTS(SELECT cuenta from ew_ct_cuentas where cuenta = @cuentasup)
	BEGIN
		SELECT @msg = 'La cuenta '  + @cuentasup + ' no existe...'
		
		CLOSE cur_ew_ct_cuentas_i 
		DEALLOCATE cur_ew_ct_cuentas_i 
		
		RAISERROR (@msg,16,1)
		RETURN
	END

	-- la cuenta superior es afectable en el ejercicio?
	SELECT @afectable = dbo._ct_fnc_cuentaAfectable(@cuentasup, @ejercicio)
	
	-- insertamos definitivamente la cuenta el catalogo
	INSERT INTO ew_ct_cuentas (
		cuenta
		, cuentasup
		, activo
		, nombre
		, tipo
		, naturaleza
		, ctaefectivo
		, llave
		, comentario
		, fecha_alta
		, ctamayor
		, idcuenta_sat
	)
	SELECT
		cuenta
		, cuentasup
		, activo
		, nombre
		, tipo
		, naturaleza
		, ctaefectivo
		, llave
		, comentario
		, fecha_alta
		, ctamayor
		, idcuenta_sat
	FROM 
		inserted
	WHERE 
		cuenta = @cuenta
		
	-- regeneramos la llave partiendo de la cuenta superior
	EXEC _ct_prc_generarLlave @cuentasup
	
	-- heredamos los movimientos de la cuenta superior en las polizas del ejercicio
	IF @afectable = 1
	BEGIN
		UPDATE ew_ct_poliza_mov SET
			cuenta = @cuenta
		FROM 
			ew_ct_poliza_mov
		WHERE 
			cuenta = @cuentasup
	END
	
	FETCH NEXT FROM cur_ew_ct_cuentas_i INTO 
		@idcuenta
		, @cuenta
		, @cuentasup
		, @ejercicio
END

CLOSE cur_ew_ct_cuentas_i
DEALLOCATE cur_ew_ct_cuentas_i
GO
