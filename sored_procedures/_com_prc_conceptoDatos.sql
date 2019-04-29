USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190406
-- Description:	Obtener datos de concepto para compra, egreso o provision
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_conceptoDatos]
	@idarticulo AS VARCHAR(MAX)
	, @idsucursal AS INT
	, @idalmacen AS INT
	, @idproveedor AS INT = 0
	, @idmoneda AS INT = 0
	, @tipocambio AS DECIMAL(18, 6) = 1
AS

SET NOCOUNT ON

DECLARE
	@idzona_fiscal_emisor AS INT

SELECT 
	@idzona_fiscal_emisor = [dbo].[_ct_fnc_idzonaFiscalCP](p.codigo_postal)
FROM
	ew_proveedores AS p
WHERE
	p.idproveedor = @idproveedor

SELECT
	[idarticulo] = a.idarticulo
	, [codigo] = a.codigo
	, [codarticulo] = a.codigo
	, [descripcion] = a.nombre
	, [nombre] = a.nombre
	, [nombre_corto] = a.nombre_corto
	, [idtipo] = a.idtipo

	, [codigo_proveedor] = ISNULL(ap.codigo_proveedor, '')
	, [clave_proveedor] = ISNULL(ap.codigo_proveedor, '')

	, [marca] = ISNULL(m.nombre, '')
	, [idum] = a.idum_compra
	, [maneja_lote] = a.lotes
	, [maneja_series] = a.series
	, [costo_unitario] = ISNULL((
		SELECT TOP 1 ISNULL(ctm.costo_unitario, 0)
		FROM
			ew_com_transacciones_mov ctm
			LEFT JOIN ew_com_transacciones ct
				ON ct.idtran = ctm.idtran
		WHERE
			ct.cancelado = 0
			AND ctm.idarticulo = a.idarticulo
			AND ct.idmoneda = @idmoneda
		ORDER BY
			ct.fecha DESC
	), 0)
	, [precio_lista] = ISNULL(((vlm.precio1 * bm.tipocambio) - ((vlm.precio1 * bm.tipocambio) * 0.10)), 0)
	, [existencia] = ISNULL(aa.existencia, 0)
	, [idsucursal] = ISNULL(s.idsucursal, @idsucursal)
	, [idalmacen] = ISNULL(aa.idalmacen, @idalmacen)

	, [cuenta] = a.contabilidad1
	, [contabilidad1] = a.contabilidad1

	, [idimpuesto1] = cai.idimpuesto1
	, [idimpuesto1_valor] = cai.idimpuesto1_valor
	, [idimpuesto1_cuenta] = cai.idimpuesto1_c3
	, [idimpuesto2] = cai.idimpuesto2
	, [idimpuesto2_valor] = cai.idimpuesto2_valor
	, [idimpuesto2_cuenta] = cai.idimpuesto2_c3
	, [idimpuesto3] = cai.idimpuesto3
	, [idimpuesto3_valor] = cai.idimpuesto3_valor
	, [idimpuesto3_cuenta] = cai.idimpuesto3_c3
	, [idimpuesto4] = cai.idimpuesto4
	, [idimpuesto4_valor] = cai.idimpuesto4_valor
	, [idimpuesto4_cuenta] = cai.idimpuesto4_c3
	, [idimpuesto1_ret] = cai.idimpuesto1_ret
	, [idimpuesto1_ret_valor] = cai.idimpuesto1_ret_valor
	, [idimpuesto1_ret_cuenta] = cai.idimpuesto1_ret_c3
	, [idimpuesto2_ret] = cai.idimpuesto2_ret
	, [idimpuesto2_ret_valor] = cai.idimpuesto2_ret_valor
	, [idimpuesto2_ret_cuenta] = cai.idimpuesto2_ret_c3
FROM
	ew_articulos AS a
	LEFT JOIN ew_ct_articulos_impuestos AS cai
		ON cai.idarticulo = a.idarticulo
		AND cai.idzona = @idzona_fiscal_emisor
	LEFT JOIN ew_articulos_proveedores AS ap
		ON ap.idarticulo = a.idarticulo
		AND ap.idproveedor = @idproveedor
	LEFT JOIN ew_cat_marcas m
		ON a.idmarca = m.idmarca
	LEFT JOIN ew_articulos_sucursales AS ss
		ON ss.idarticulo = a.idarticulo
		AND ss.idsucursal = @idsucursal
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = a.idarticulo
		AND aa.idalmacen = @idalmacen
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = @idsucursal
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idarticulo = a.idarticulo
		AND vlm.idlista = s.idlista
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = vlm.idmoneda
WHERE
	a.idarticulo IN (
		SELECT CONVERT(INT, al.valor)
		FROM
			[dbo].[_sys_fnc_separarMultilinea](@idarticulo, '	') AS al
	)
GO
