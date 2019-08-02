USE db_comercial_final
GO
IF OBJECT_ID('tg_ew_clientes_servicio_equipos_precios') IS NOT NULL
BEGIN
	DROP TRIGGER tg_ew_clientes_servicio_equipos_precios
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 210190402
-- Description:	Acutalizar precio de planes de cliente
-- =============================================
CREATE TRIGGER [dbo].[tg_ew_clientes_servicio_equipos_precios]
	ON [dbo].[ew_clientes_servicio_equipos]
	AFTER INSERT, UPDATE
AS 

SET NOCOUNT ON

DECLARE
	@idcliente AS INT
	, @plan_codigo AS VARCHAR(10)

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

DECLARE cur_planCosto CURSOR FOR
	SELECT DISTINCT
		i.idcliente
		, i.plan_codigo
	FROM
		inserted AS i

OPEN cur_planCosto

FETCH NEXT FROM cur_planCosto INTO
	@idcliente
	, @plan_codigo

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC [dbo].[_ser_prc_planCalcularCosto] @idcliente, @plan_codigo

	FETCH NEXT FROM cur_planCosto INTO
		@idcliente
		, @plan_codigo
END

CLOSE cur_planCosto
DEALLOCATE cur_planCosto
GO
