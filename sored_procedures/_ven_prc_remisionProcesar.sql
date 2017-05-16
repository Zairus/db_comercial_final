USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100106
-- Description:	Procesar remisión de venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_remisionProcesar]
	@idtran AS INT
	,@idu SMALLINT
AS

SET NOCOUNT ON

DECLARE
	@idtran2 AS INT

--------------------------------------------------------------------------------
-- Actualizar la cantidad surtida en la orden
--------------------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	idmov
	,idmov2
	,'cantidad_surtida'
	,cantidad
FROM
	ew_inv_transacciones_mov
WHERE
	idtran = @idtran
	AND cantidad != 0
	AND idmov2 != 0

--------------------------------------------------------------------------------
-- Actualizar el estado de las ordenes de venta surtidas
--------------------------------------------------------------------------------
DECLARE cur_detalle CURSOR FOR
	SELECT DISTINCT 
		[idtran] = FLOOR(fm.idmov2)
	FROM
		ew_inv_transacciones_mov AS fm
	WHERE
		fm.idtran = @idtran
		AND fm.cantidad != 0
		AND fm.idmov2 != 0

OPEN cur_detalle		

FETCH NEXT FROM cur_detalle INTO 
	@idtran2

WHILE @@fetch_status = 0
BEGIN
	EXEC _ven_prc_ordenEstado @idtran2, @idu

	FETCH NEXT FROM cur_detalle INTO 
		@idtran2
END

CLOSE cur_detalle
DEALLOCATE cur_detalle
GO
