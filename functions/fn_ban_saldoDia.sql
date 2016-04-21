USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100925
-- Description:	Saldo al Día de una cuenta
-- =============================================
ALTER FUNCTION [dbo].[fn_ban_saldoDia]
(
	 @idcuenta AS INT
	,@fecha AS SMALLDATETIME
)
RETURNS DECIMAL(15,2)
AS
BEGIN
	DECLARE
		 @saldo AS DECIMAL(15,2)
		,@saldo_periodo AS DECIMAL(15,2)
	
	DECLARE
		 @dia AS SMALLINT
		,@periodo AS SMALLINT
		,@ejercicio AS SMALLINT
		,@fecha_inicial AS SMALLDATETIME
		,@fecha_final AS SMALLDATETIME
	
	SELECT @dia = DAY(@fecha)
	SELECT @periodo = MONTH(@fecha)
	SELECT @ejercicio = YEAR(@fecha)
	
	SELECT
		@saldo = (
			CASE @periodo
				WHEN 1 THEN periodo0
				WHEN 2 THEN periodo1 + periodo0
				WHEN 3 THEN periodo2 + periodo0
				WHEN 4 THEN periodo3 + periodo0
				WHEN 5 THEN periodo4 + periodo0
				WHEN 6 THEN periodo5 + periodo0
				WHEN 7 THEN periodo6 + periodo0
				WHEN 8 THEN periodo7 + periodo0
				WHEN 9 THEN periodo8 + periodo0
				WHEN 10 THEN periodo9 + periodo0
				WHEN 11 THEN periodo10 + periodo0
				WHEN 12 THEN periodo11 + periodo0
			END
		)
	FROM
		ew_ban_saldos AS bs
	WHERE
		tipo = 1
		AND idcuenta = @idcuenta
		AND ejercicio = @ejercicio
	
	SELECT @saldo = ISNULL(@saldo, 0)
	
	SELECT @fecha_inicial = CONVERT(SMALLDATETIME, '01/' + CONVERT(VARCHAR(2), @periodo) + '/' + CONVERT(VARCHAR(4), @ejercicio) + ' 00:00')
	SELECT @fecha_final = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(2), @dia) + '/' + CONVERT(VARCHAR(2), @periodo) + '/' + CONVERT(VARCHAR(4), @ejercicio) + ' 23:59')
	
	SELECT
		@saldo_periodo = SUM(
			CASE bm.tipo
				WHEN 1 THEN bm.total
				ELSE (bm.total * -1)
			END
		)
	FROM
		ew_ban_transacciones AS bm
	WHERE
		bm.tipo IN (1,2)
		AND bm.cancelado = 0
		AND bm.idcuenta = @idcuenta
		AND bm.fecha BETWEEN @fecha_inicial AND @fecha_final
	
	SELECT @saldo_periodo = ISNULL(@saldo_periodo, 0)
	
	SELECT @saldo = @saldo + @saldo_periodo
	
	RETURN @saldo
END
GO
