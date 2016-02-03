USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160129
-- Description:	Calculo de precios desde recepcion de compra
-- =============================================
ALTER PROCEDURE _com_prc_recepcionPreciosVenta
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idsucursal AS SMALLINT
	,@idlista AS INT

SELECT
	@idsucursal = idsucursal
FROM
	ew_com_transacciones
WHERE
	idtran = @idtran

SELECT
	@idlista = s.idlista
FROM
	ew_sys_sucursales AS s
WHERE
	s.idsucursal = @idsucursal

IF @idlista IS NULL
BEGIN
	SELECT @idlista = 0
END

UPDATE vlm SET
	vlm.costo_base = ctm.costo_unitario
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idarticulo = ctm.idarticulo
		AND vlm.idlista = @idlista
WHERE
	ctm.precio_neto > 0
	AND ctm.idtran = @idtran

UPDATE vlm SET
	vlm.precio_neto = ctm.precio_neto
	,vlm.precio_neto2 = ctm.precio_neto2
	,vlm.precio_neto3 = ctm.precio_neto3
	,vlm.precio_neto4 = ctm.precio_neto4
	,vlm.precio_neto5 = ctm.precio_neto5
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idarticulo = ctm.idarticulo
		AND vlm.idlista = @idlista
WHERE
	ctm.precio_neto > 0
	AND ctm.idtran = @idtran

UPDATE [as] SET
	[as].utilidad1 = [dbo].[fn_sys_calcularMargen]((ctm.precio_neto / [dbo].[fn_ct_articuloCargaFactor](ctm.idarticulo, ct.idsucursal)), ctm.costo_unitario)
	,[as].utilidad2 = [dbo].[fn_sys_calcularMargen]((ctm.precio_neto2 / [dbo].[fn_ct_articuloCargaFactor](ctm.idarticulo, ct.idsucursal)), ctm.costo_unitario)
	,[as].utilidad3 = [dbo].[fn_sys_calcularMargen]((ctm.precio_neto3 / [dbo].[fn_ct_articuloCargaFactor](ctm.idarticulo, ct.idsucursal)), ctm.costo_unitario)
	,[as].utilidad4 = [dbo].[fn_sys_calcularMargen]((ctm.precio_neto4 / [dbo].[fn_ct_articuloCargaFactor](ctm.idarticulo, ct.idsucursal)), ctm.costo_unitario)
	,[as].utilidad5 = [dbo].[fn_sys_calcularMargen]((ctm.precio_neto5 / [dbo].[fn_ct_articuloCargaFactor](ctm.idarticulo, ct.idsucursal)), ctm.costo_unitario)
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_com_transacciones AS ct
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idarticulo = ctm.idarticulo
		AND [as].idsucursal = ct.idsucursal
WHERE
	ctm.precio_neto > 0
	AND ctm.cantidad_recibida > 0
	AND ctm.idtran = @idtran
GO
