USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20121112
-- Description:	Procesar factura de tickets
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaTicketsProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	 @total_detalle AS DECIMAL(18,6)
	,@total_documento AS DECIMAL(18,6)

SELECT
	@total_documento = ct.total
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

INSERT INTO ew_ven_transacciones_mov (
	idtran
	,consecutivo
	,idmov2
	,idarticulo
	,idum
	,idalmacen
	,tipo
	,cantidad_ordenada
	,cantidad_autorizada
	,cantidad_surtida
	,cantidad_facturada
	,cantidad_devuelta
	,series
	,precio_unitario
	,descuento1
	,descuento2
	,descuento3
	,descuento_pp1
	,descuento_pp2
	,descuento_pp3
	,importe
	,impuesto1
	,impuesto2
	,impuesto3
	,impuesto4
	,costo
	,gastos
	,comentario
)
SELECT
	[idtran] = @idtran
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY @idtran)
	,[idmov2] = vtm.idmov
	,vtm.idarticulo
	,vtm.idum
	,vtm.idalmacen
	,vtm.tipo
	,vtm.cantidad_ordenada
	,vtm.cantidad_autorizada
	,vtm.cantidad_surtida
	,vtm.cantidad_facturada
	,vtm.cantidad_devuelta
	,vtm.series
	,vtm.precio_unitario
	,vtm.descuento1
	,vtm.descuento2
	,vtm.descuento3
	,vtm.descuento_pp1
	,vtm.descuento_pp2
	,vtm.descuento_pp3
	,vtm.importe
	,vtm.impuesto1
	,vtm.impuesto2
	,vtm.impuesto3
	,vtm.impuesto4
	,vtm.costo
	,vtm.gastos
	,vtm.comentario
FROM 
	ew_ven_transacciones_mov AS vtm 
WHERE 
	vtm.idtran IN (
		SELECT ctr.idtran2
		FROM ew_cxc_transacciones_rel AS ctr 
		WHERE ctr.idtran = @idtran
	)

SELECT
	@total_detalle = SUM(vt.total)
FROM
	ew_ven_transacciones_mov AS vt
WHERE
	vt.idtran = @idtran

SELECT @total_detalle = ISNULL(@total_detalle, 0)

IF ABS(@total_documento - @total_detalle) > 0.10
BEGIN
	RAISERROR('Error: El total del detalle no coincide con el total del documento.', 16, 1)
	RETURN
END

INSERT INTO ew_sys_transacciones2 (
	 idtran
	,idestado
)
SELECT
	 [idtran] = idtran2
	,[idestado] = 251
FROM
	ew_cxc_transacciones_rel
WHERE
	idtran = @idtran
GO
