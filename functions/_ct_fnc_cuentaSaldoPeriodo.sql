USE db_comercial_final
GO
IF OBJECT_ID('_ct_fnc_cuentaSaldoPeriodo') IS NOT NULL
BEGIN
	DROP FUNCTION _ct_fnc_cuentaSaldoPeriodo
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091013
-- Description:	Saldo de una cuenta contable
-- select dbo._ct_fnc_cuentaSaldo ('2',2010,1,1)
-- =============================================
CREATE FUNCTION [dbo].[_ct_fnc_cuentaSaldoPeriodo]
(
	@cuenta AS VARCHAR(20)
	, @ejercicio AS SMALLINT
	, @periodo AS TINYINT
	, @idsucursal AS SMALLINT
)
RETURNS DECIMAL(15,2)
AS
BEGIN
	DECLARE 
		@saldo AS DECIMAL(15,2)
		, @saldo_cargos AS DECIMAL(15,2)
		, @saldo_abonos AS DECIMAL(15,2)

	SELECT 
		@saldo_cargos = (
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
		tipo = 2
		AND cuenta = @cuenta 
		AND ejercicio = @ejercicio
		AND idsucursal = @idsucursal

	SELECT 
		@saldo_abonos = (
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
		tipo = 3
		AND cuenta = @cuenta 
		AND ejercicio = @ejercicio
		AND idsucursal = @idsucursal

	SELECT
		@saldo = (
			CASE
				WHEN cc.naturaleza = 0 THEN @saldo_cargos - @saldo_abonos
				ELSE @saldo_abonos - @saldo_cargos
			END
		)
	FROM
		ew_ct_cuentas AS cc
	WHERE
		cc.cuenta = @cuenta
	
	SELECT @saldo = ISNULL(@saldo, 0)
	
	RETURN @saldo
END
GO
