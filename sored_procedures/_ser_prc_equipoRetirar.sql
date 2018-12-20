USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20181211
-- Description:	Retira un equipo del cliente
-- =============================================
ALTER PROCEDURE [dbo].[_ser_prc_equipoRetirar]
	@idequipo AS INT
AS

SET NOCOUNT ON

DECLARE
	@msg AS VARCHAR(500)

SELECT
	@msg = (
		'Se ha retirado el equipo [' 
		+ se.serie 
		+ '] del cliente: '
		+ c.nombre
		+ ', en plan '
		+ csp.plan_descripcion
	)
FROM
	ew_clientes_servicio_equipos AS cse
	LEFT JOIN ew_clientes_servicio_planes AS csp
		ON csp.idcliente = cse.idcliente
		AND csp.plan_codigo = cse.plan_codigo
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = cse.idcliente
	LEFT JOIN ew_ser_equipos AS se
		ON se.idequipo = cse.idequipo
WHERE
	cse.idequipo = @idequipo

INSERT INTO ew_ser_equipos_bitacora (
	idequipo
	, idestado
	, idaccion
)
SELECT
	[idequipo] = @idequipo
	, [idestado] = 0
	, [idaccion] = 0

DELETE FROM ew_clientes_servicio_equipos WHERE idequipo = @idequipo

SELECT [resultado] = @msg
GO
