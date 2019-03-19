USE db_comercial_final
GO
DECLARE 
	@ConstraintName AS NVARCHAR(200)

SELECT 
	@ConstraintName = [name]
FROM 
	sys.default_constraints
WHERE
	parent_object_id = OBJECT_ID('ew_ban_saldos')
	AND parent_column_id = (
		SELECT column_id 
		FROM sys.columns 
		WHERE 
			[name] = N'periodo0' 
			AND [object_id] = OBJECT_ID(N'ew_ban_saldos')
	)

IF @ConstraintName IS NOT NULL
BEGIN
	EXEC('ALTER TABLE ew_ban_saldos DROP CONSTRAINT ' + @ConstraintName)
END

IF EXISTS (SELECT * FROM syscolumns WHERE id = OBJECT_ID('ew_ban_saldos') AND [name] = 'periodo0')
BEGIN
	EXEC('ALTER TABLE ew_ban_saldos DROP COLUMN periodo0')
END

GO
IF OBJECT_ID('fn_ban_cuentaSaldoInicialEX') IS NOT NULL
BEGIN
	DROP FUNCTION fn_ban_cuentaSaldoInicialEX
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190309
-- Description:	Regresa el saldo inicial de una cuenta bancaria para un ejercicio
-- =============================================
CREATE FUNCTION [dbo].[fn_ban_cuentaSaldoInicialEX] (
	@idcuenta AS INT
	, @ejercicio AS INT
	, @tipo AS SMALLINT
)
RETURNS DECIMAL(18, 6) AS  
BEGIN
	DECLARE
		@saldo AS DECIMAL(18, 6)
		, @saldo_inicial AS DECIMAL(18, 6)

	SELECT
		@saldo = SUM(periodo12)
	FROM
		ew_ban_saldos
	WHERE
		idcuenta = @idcuenta
		AND tipo = @tipo
		AND ejercicio < @ejercicio

	SELECT
		@saldo_inicial = bc.saldo_inicial
	FROM
		ew_ban_cuentas AS bc
	WHERE
		bc.idcuenta = @idcuenta

	SELECT @saldo_inicial = ISNULL(@saldo_inicial, 0)
	SELECT @saldo = ISNULL(@saldo, 0) + @saldo_inicial

	RETURN @saldo
END
GO
ALTER TABLE ew_ban_saldos ADD periodo0 AS ([dbo].[fn_ban_cuentaSaldoInicialEX](idcuenta, ejercicio, tipo))
GO
