USE db_comercial_final
GO
IF OBJECT_ID('fn_ct_cuentaSaldo') IS NOT NULL
BEGIN
	DROP FUNCTION fn_ct_cuentaSaldo
END
GO
CREATE FUNCTION [dbo].[fn_ct_cuentaSaldo] (
	@cuenta VARCHAR(20)
	, @ejercicio SMALLINT
	, @periodo SMALLINT
	, @idsucursal SMALLINT
)
RETURNS DECIMAL(15,2) AS  
BEGIN
	DECLARE 
		@saldo AS DECIMAL(15,2)

	SELECT 
		@saldo = (
			CASE @periodo
				WHEN 1 THEN periodo1
				WHEN 2 THEN periodo2
				WHEN 3 THEN periodo3
				WHEN 4 THEN periodo4
				WHEN 5 THEN periodo5
				WHEN 6 THEN periodo6
				WHEN 7 THEN periodo7
				WHEN 8 THEN periodo8
				WHEN 9 THEN periodo9
				WHEN 10 THEN periodo10
				WHEN 11 THEN periodo11
				WHEN 12 THEN periodo12
				WHEN 13 THEN periodo13
				ELSE periodo14
			END
		)
	FROM 
		ew_ct_saldos 
	WHERE 
		tipo = 1 
		AND cuenta = @cuenta 
		AND ejercicio = @ejercicio
		AND idsucursal = @idsucursal

	IF @saldo IS NULL
	BEGIN
		SELECT @saldo = 0
	END

	SELECT @saldo = @saldo + [dbo].[fn_ct_cuentaSaldoInicialEx](@cuenta, @ejercicio, @idsucursal, 1)

	RETURN (@saldo)
END
GO
