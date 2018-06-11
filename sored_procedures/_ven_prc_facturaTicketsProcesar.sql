USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20121112
-- Description:	Procesar factura de tickets
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaTicketsProcesar]
	@idtran AS INT
	,@idu SMALLINT
AS

SET NOCOUNT ON

DECLARE
	 @total_detalle AS DECIMAL(18,6)
	,@total_documento AS DECIMAL(18,6)
	,@error_mensaje AS VARCHAR(1000)
	,@fecha AS DATETIME

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
	,idimpuesto1
	,idimpuesto2
	,idimpuesto1_ret
	,idimpuesto2_ret
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
	,[idimpuesto1] = (CASE WHEN vtm.idimpuesto1 = 0 THEN 1 ELSE vtm.idimpuesto1 END)
	,[idimpuesto2] = (CASE WHEN vtm.idimpuesto2 = 0 THEN 11 ELSE vtm.idimpuesto2 END)
	,[idimpuesto1_ret] = 0
	,[idimpuesto2_ret] = 0
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
	@fecha = ct.fecha
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

EXEC _cxc_prc_desaplicarTransaccion @idtran, @idu

EXEC [dbo].[_ven_prc_facturaProcesarImpuestos] @idtran

UPDATE vt SET
	vt.impuesto1 = ISNULL((SELECT SUM(vtm.impuesto1) FROM ew_ven_transacciones_mov AS vtm WHERE vtm.idtran = vt.idtran), 0)
	,vt.impuesto2 = ISNULL((SELECT SUM(vtm.impuesto2) FROM ew_ven_transacciones_mov AS vtm WHERE vtm.idtran = vt.idtran), 0)
FROM
	ew_ven_transacciones AS vt
WHERE
	vt.idtran = @idtran

UPDATE ct SET
	ct.impuesto1 = vt.impuesto1
	,ct.impuesto2 = vt.impuesto2
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = ct.idtran
WHERE
	ct.idtran = @idtran

UPDATE ct SET
	ct.saldo = (
		ct.total 
		- ISNULL((
			SELECT SUM(t.total) 
			FROM 
				ew_cxc_transacciones_rel AS ctr 
				LEFT JOIN ew_cxc_transacciones AS t
					ON t.idtran = ctr.idtran2
			WHERE 
				ctr.idtran = ct.idtran
		), 0)
		+ ISNULL((
			SELECT SUM(ctr.saldo) 
			FROM 
				ew_cxc_transacciones_rel AS ctr 
			WHERE 
				ctr.idtran = ct.idtran
		), 0)
	)
FROM
	ew_cxc_transacciones As ct
WHERE
	ct.idtran = @idtran

EXEC _cxc_prc_aplicarTransaccion @idtran, @fecha, @idu

SELECT
	@total_documento = ct.total - ct.redondeo
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT
	@total_detalle = SUM(vt.total)
FROM
	ew_ven_transacciones_mov AS vt
WHERE
	vt.idtran = @idtran

SELECT @total_detalle = ISNULL(@total_detalle, 0)

IF ABS(@total_documento - @total_detalle) > 0.10
BEGIN
	SELECT @error_mensaje = (
		'Error: El total del detalle [' 
		+ CONVERT(VARCHAR(20), @total_detalle) 
		+ '] no coincide con el total del documento [' 
		+ CONVERT(VARCHAR(20), @total_documento) 
		+ '].'
	)

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

EXEC _ven_prc_existenciaComprometer

INSERT INTO ew_sys_transacciones2 (
	 idtran
	,idestado
	,idu
)
SELECT
	 [idtran] = idtran2
	,[idestado] = 51
	,@idu
FROM
	ew_cxc_transacciones_rel
WHERE
	idtran = @idtran

EXEC _cxc_prc_ticketSaldoTrasladarFactura @idtran
GO
