USE db_comercial_final
GO
-- =============================================
-- Author:		Pul Monge
-- Create date: 20151027
-- Description:	Validar terminos de cobranza
-- =============================================
ALTER PROCEDURE _cxc_prc_clienteValidar
	@idcliente AS INT
AS

SET NOCOUNT ON

DECLARE
	@credito AS BIT
	,@credito_plazo AS SMALLINT
	,@credito_limite AS DECIMAL(15,2)
	,@saldo AS DECIMAL(15,2)
	,@documentos_vencidos AS INT
	,@mensaje AS VARCHAR(500) = ''

SELECT
	@credito = credito
	,@credito_plazo = credito_plazo
	,@credito_limite = credito_limite
	,@saldo = csa.saldo
FROM
	ew_clientes_terminos AS ctr
	LEFT JOIN ew_cxc_saldos_actual AS csa
		ON csa.idcliente = ctr.idcliente
WHERE
	ctr.idcliente = @idcliente

IF @credito = 0
BEGIN
	RETURN
END

SELECT @documentos_vencidos = COUNT(*)
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.cancelado = 0
	AND ct.tipo = 1
	AND ct.saldo > 0.01
	AND DATEDIFF(DAY, ct.fecha, GETDATE()) > @credito_plazo
	AND ct.idcliente = @idcliente

IF @documentos_vencidos > 0
BEGIN
	SELECT @mensaje = @mensaje + 'El cliente tiene ' + LTRIM(RTRIM(STR(@documentos_vencidos))) + ' documentos vencidos.' + CHAR(13)
END

IF @saldo > @credito_limite
BEGIN
	SELECT @mensaje = @mensaje + 'Cliente excede límite de crédito: Saldo=' + CONVERT(VARCHAR(20), @saldo) + ', Límite=' + CONVERT(VARCHAR(20), @credito_limite) + CHAR(13)
END

IF LEN(@mensaje) > 0
BEGIN
	RAISERROR (@mensaje, 16, 1)
END
GO
