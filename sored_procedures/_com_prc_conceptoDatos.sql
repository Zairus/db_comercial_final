USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_conceptoDatos') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_conceptoDatos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190406
-- Description:	Obtener datos de concepto para compra, egreso o provision
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_conceptoDatos]
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
	, @idzona_fiscal_receptor AS INT
	, @extranjero AS BIT

SELECT 
	@idzona_fiscal_emisor = [dbo].[_ct_fnc_idzonaFiscalCP](p.codigo_postal)
	, @extranjero = p.extranjero
FROM
	ew_proveedores AS p
WHERE
	p.idproveedor = @idproveedor

SELECT @idzona_fiscal_receptor = [dbo].[_ct_fnc_idzonaFiscal](@idsucursal)

SELECT @idzona_fiscal_emisor = ISNULL(@idzona_fiscal_emisor, 1)
SELECT @extranjero = ISNULL(@extranjero, 0)

IF @idzona_fiscal_emisor <> @idzona_fiscal_receptor
BEGIN
	SELECT @idzona_fiscal_emisor = 1
END

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

	, [idimpuesto1] = ISNULL(cai.idimpuesto1, 0)
	, [idimpuesto1_valor] = ISNULL(cai.idimpuesto1_valor, 0)
	, [idimpuesto1_cuenta] = ISNULL(cai.idimpuesto1_c3, '')
	, [idimpuesto2] = ISNULL(cai.idimpuesto2, 0)
	, [idimpuesto2_valor] = ISNULL(cai.idimpuesto2_valor, 0)
	, [idimpuesto2_cuenta] = ISNULL(cai.idimpuesto2_c3, '')
	, [idimpuesto3] = ISNULL(cai.idimpuesto3, 0)
	, [idimpuesto3_valor] = ISNULL(cai.idimpuesto3_valor, 0)
	, [idimpuesto3_cuenta] = ISNULL(cai.idimpuesto3_c3, '')
	, [idimpuesto4] = ISNULL(cai.idimpuesto4, 0)
	, [idimpuesto4_valor] = ISNULL(cai.idimpuesto4_valor, 0)
	, [idimpuesto4_cuenta] = ISNULL(cai.idimpuesto4_c3, '')
	, [idimpuesto1_ret] = ISNULL(cai.idimpuesto1_ret, 0)
	, [idimpuesto1_ret_valor] = ISNULL(cai.idimpuesto1_ret_valor, 0)
	, [idimpuesto1_ret_cuenta] = ISNULL(cai.idimpuesto1_ret_c3, '')
	, [idimpuesto2_ret] = ISNULL(cai.idimpuesto2_ret, 0)
	, [idimpuesto2_ret_valor] = ISNULL(cai.idimpuesto2_ret_valor, 0)
	, [idimpuesto2_ret_cuenta] = ISNULL(cai.idimpuesto2_ret_c3, '')
FROM
	ew_articulos AS a
	LEFT JOIN ew_ct_articulos_impuestos AS cai
		ON cai.idarticulo = a.idarticulo
		AND (
			cai.idzona = @idzona_fiscal_emisor
			OR cai.idzona = 0
		)
		AND @extranjero = 0
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
