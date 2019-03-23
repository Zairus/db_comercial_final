USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20110401
-- Description:	Procesar nota de crédito por devolucion de cliente.
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_devolucionProcesar]
	@idtran AS BIGINT
AS

SET NOCOUNT ON

DECLARE
	@surtir AS BIT
	, @error_mensaje AS VARCHAR(250)

-- Parametro que indica si las facturas surten.
SELECT @surtir = dbo.fn_sys_parametro('VEN_SURFAC')

-- Valida si los documentos aplicados son timbrados o no
-- no puede haber mezcla de documentos timbrados y no timbrados
EXEC _cxc_prc_validarTimbreAplicacion @idtran

-- Si la factura surtio, se devuelve lo surtido
IF @surtir = 1
BEGIN
	EXEC [dbo].[_ven_prc_facturaSurtir] @idtran, 0
END

--Actualizar cantidad devuelta en facturas
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
