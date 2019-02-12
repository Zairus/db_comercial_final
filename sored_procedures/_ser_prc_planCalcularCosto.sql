USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190206
-- Description:	Calculo de costo de planes
-- =============================================
ALTER PROCEDURE _ser_prc_planCalcularCosto
	@idcliente AS INT
	, @plan_codigo AS VARCHAR(10)
AS

SET NOCOUNT ON

UPDATE csp SET
	csp.costo = (
		(
			SELECT SUM(ISNULL(vlm.precio1, 0))
			FROM 
				ew_clientes_servicio_equipos AS cse
				LEFT JOIN ew_ser_equipos AS e
					ON e.idequipo = cse.idequipo
				LEFT JOIN ew_ven_listaprecios_mov AS vlm
					ON vlm.idlista = CONVERT(INT, dbo._sys_fnc_parametroTexto('SER_LISTA_PRECIOS_RENTA'))
					AND vlm.idarticulo = e.idarticulo
			WHERE
				cse.idcliente = csp.idcliente
				AND cse.plan_codigo = csp.plan_codigo
		)
		* csp.periodo
	)
FROM
	ew_clientes_servicio_planes AS csp
WHERE
	csp.idcliente = @idcliente
	AND csp.plan_codigo = @plan_codigo
GO
