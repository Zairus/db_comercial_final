USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091113
-- Description:	Procesar factura de cliente.
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaProcesar]
	@idtran AS BIGINT
AS

SET NOCOUNT ON

DECLARE
	@surtir AS BIT

DECLARE
	@idu AS SMALLINT
	,@idtran2 AS INT

SELECT @surtir = dbo.fn_sys_parametro('VEN_SURFAC')

SELECT
	@idtran2 = idtran2
	,@idu = idu
FROM 
	ew_ven_transacciones
WHERE
	idtran = @idtran

IF @surtir = 1
BEGIN
	EXEC [dbo].[_ven_prc_facturaSurtir] @idtran, 0
END

IF EXISTS(SELECT * FROM ew_cxc_transacciones WHERE cfd_iduso = 0 AND idtran = @idtran)
BEGIN
	RAISERROR('Error: No se ha indicado uso para comprobante fiscal.', 16, 1)
	RETURN
END

--------------------------------------------------------------------
-- Surtimos la mercancia en la orden 
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	[idmov] = m.idmov
	,[idmov2] = m.idmov2
	,[campo] = 'cantidad_surtida'
	,[valor] = m.cantidad_surtida
FROM	
	ew_ven_transacciones_mov AS m
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = m.idarticulo
WHERE 
	m.cantidad_surtida > 0
	AND a.inventariable = 1
	AND idtran = @idtran

--------------------------------------------------------------------
-- Indicamos la mercancia facturada en la orden 
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT 
	[idmov] = idmov
	,[idmov2] = idmov2
	,[campo] = 'cantidad_facturada'
	,[valor] = cantidad_facturada 
FROM	
	ew_ven_transacciones_mov
WHERE 
	cantidad_facturada > 0
	AND idtran = @idtran

EXEC _ven_prc_facturaPagos @idtran

--------------------------------------------------------------------
-- Cambiamos el estado de la orden
--------------------------------------------------------------------
DECLARE cur_detalle CURSOR FOR
	SELECT DISTINCT 
		[idtran] = FLOOR(fm.idmov2)
	FROM
		ew_ven_transacciones_mov AS fm 
	WHERE
		fm.idtran = @idtran
		AND fm.cantidad_facturada > 0

OPEN cur_detalle

FETCH NEXT FROM cur_detalle INTO
	@idtran2

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC _ven_prc_ordenEstado @idtran2, @idu
	
	FETCH NEXT FROM cur_detalle INTO 
		@idtran2
END

CLOSE cur_detalle
DEALLOCATE cur_detalle

IF @surtir = 1
BEGIN
	UPDATE vtm SET
		vtm.costo = ISNULL(itm.costo, 0)
	FROM
		ew_ven_transacciones_mov As vtm
		LEFT JOIN ew_inv_transacciones_mov AS itm
			ON itm.idmov2 = vtm.idmov
			AND itm.tipo = 2
	WHERE
		vtm.idtran = @idtran

	UPDATE vt SET
		vt.costo = ISNULL((
			SELECT SUM(vtm.costo) 
			FROM ew_ven_transacciones_mov AS vtm 
			WHERE vtm.idtran = vt.idtran
		), 0)
	FROM
		ew_ven_transacciones AS vt
	WHERE
		vt.idtran = @idtran

	SELECT 
		costo = ISNULL(SUM(costo), 0) 
	FROM 
		ew_ven_transacciones_mov 
	WHERE 
		idtran = @idtran
END

EXEC _ct_prc_polizaAplicarDeconfiguracion @idtran, 'EFA6', @idtran
GO
