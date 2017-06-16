USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 201104
-- Modificacion: 

-- Description:	Procesar nota de crédito por devolucion de cliente.
-- EXEC _ven_prc_devolucionProcesar 0

-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_devolucionProcesar]
	@idtran AS BIGINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- VALIDAR DATOS 

DECLARE
	@surtir AS BIT
	,@msg AS VARCHAR(250)

SELECT @surtir = dbo.fn_sys_parametro('VEN_SURFAC')

--------------------------------------------------------------------------------
-- SURTIR MERCANCIA 

IF @surtir = 1
BEGIN
	EXEC _inv_prc_ventaSurtir @idtran, 1, 20
END

--------------------------------------------------------------------
-- Devolvemos la mercancia en la orden de Venta
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	[idmov1] = m.idmov
	,[idmov2] = m2.idmov2
	,[campo] = 'cantidad_devuelta'
	,[valor] = m.cantidad
FROM	
	ew_ven_transacciones_mov AS m
	LEFT JOIN ew_ven_transacciones_mov AS m2 
		ON m2.idmov = m.idmov2
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = m.idarticulo
WHERE 
	m.cantidad != 0
	AND m.idtran = @idtran

--------------------------------------------------------------------
-- Indicamos la mercancia en la factura
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	[idmov1] = idmov
	,[idmov2] = idmov2
	,[campo] = 'cantidad_devuelta'
	,[valor] = cantidad
FROM	
	ew_ven_transacciones_mov
WHERE 
	idtran = @idtran
	AND cantidad != 0
GO
