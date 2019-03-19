USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190301
-- Description:	Inicializar Ejercicio de Bancos
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_ejercicioInicializar]
	@ejercicio AS INT
AS

SET NOCOUNT ON

INSERT INTO ew_ban_saldos (
	idcuenta
	, ejercicio
	, tipo
)

SELECT
	bc.idcuenta
	, [ejercicio] = @ejercicio
	, [tipo] = t.valor
FROM
	ew_ban_cuentas AS bc
	LEFT JOIN dbo._sys_fnc_separarMultilinea('1,2,3', ',') AS t
		ON t.idr = t.idr
WHERE
	t.valor NOT IN (
		SELECT
			bs.tipo
		FROM
			ew_ban_saldos AS bs
		WHERE
			bs.idcuenta = bc.idcuenta
			AND bs.ejercicio = @ejercicio
	)
GO
