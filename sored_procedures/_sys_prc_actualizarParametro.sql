USE db_comercial_final
GO
IF OBJECT_ID('_sys_prc_actualizarParametro') IS NOT NULL
BEGIN
	DROP PROCEDURE _sys_prc_actualizarParametro
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200519
-- Description:	Actualizar valor de parametro
-- =============================================
CREATE PROCEDURE [dbo].[_sys_prc_actualizarParametro]
	@codigo AS VARCHAR(100)
	, @valor AS VARCHAR(MAX)
AS

SET NOCOUNT ON

DECLARE
	@tipo AS VARCHAR(100)

SELECT
	@tipo = p.tipo
FROM
	db_comercial.dbo.evoluware_parametros AS p
WHERE
	p.codigo = @codigo

IF @tipo = 'booleano'
BEGIN
	UPDATE sp SET
		sp.valor = @valor
		, sp.activo = CONVERT(BIT, @valor)
	FROM
		ew_sys_parametros AS sp
	WHERE
		sp.codigo = @codigo
END

UPDATE sp SET
	sp.valor = @valor
	, sp.activo = 1
FROM
	ew_sys_parametros AS sp
WHERE
	@tipo != 'booleano'
	AND sp.codigo = @codigo
GO
