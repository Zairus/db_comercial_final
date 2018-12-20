USE db_comercial_final
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[tg_ew_clientes_servicio_equipos_precios]
	ON [dbo].[ew_clientes_servicio_equipos]
	AFTER INSERT, UPDATE
AS 

SET NOCOUNT ON

IF EXISTS (
	SELECT
		*
	FROM
		ew_clientes_servicio_equipos AS cse
	WHERE
		(SELECT COUNT(*) FROM ew_clientes_servicio_equipos AS cse1 WHERE cse1.idequipo = cse.idequipo) > 1
)
BEGIN
	RAISERROR('Error: No sepuede insertar un equipo en dos planes de manera simultanea.', 16, 1)
	RETURN
END

UPDATE csp SET
	csp.costo = (
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
FROM
	ew_clientes_servicio_planes AS csp
WHERE
	csp.plan_codigo IN (
		SELECT
			i.plan_codigo
		FROM
			inserted AS i
	)
	AND csp.idcliente IN (
		SELECT
			i.idcliente
		FROM
			inserted AS i
	)
GO
