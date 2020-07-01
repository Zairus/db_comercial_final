USE db_comercial_final
GO
IF OBJECT_ID('_cxc_prc_ejercicioInicializar') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_prc_ejercicioInicializar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100709
-- Description:	Inicializar saldos de CXC
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_prc_ejercicioInicializar]
	@ejercicio AS SMALLINT
	, @debug AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@registros_agregados AS INT

INSERT INTO ew_cxc_saldos (
	idcliente
	, idmoneda
	, ejercicio
	, tipo
)
SELECT
	[idcliente] = c.idcliente
	, [idmoneda] = bm.idmoneda
	, [ejerciio] = @ejercicio
	, [tipo] = t.valor
FROM
	ew_clientes AS c
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.activo = 1
		AND bm.idmoneda = bm.idmoneda
	LEFT JOIN dbo._sys_fnc_separarMultilinea('1,2,3', ',') AS t
		ON t.valor = t.valor
WHERE
	c.idcliente NOT IN (
		SELECT
			cs.idcliente
		FROM
			ew_cxc_saldos AS cs
		WHERE 
			cs.idmoneda = bm.idmoneda
			AND cs.tipo = t.valor
			AND cs.ejercicio = @ejercicio
	)

SELECT @registros_agregados = @@ROWCOUNT

IF @debug = 1
BEGIN
	SELECT [registros_agregados] = @registros_agregados
END
GO