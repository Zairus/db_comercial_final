USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190131
-- Description:	Obtiene un registro para tabla temporal de datos de articulo
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_articuloDatosRegistro]
	@codarticulo AS VARCHAR(30)
	, @idlista AS INT
	, @idcliente AS INT
	, @idsucursal AS INT
	, @idalmacen AS INT

	, @precio_factor AS DECIMAL(18,6) = 1
	, @objlevel AS INT = 0
	, @reg_clave AS VARCHAR(20) = ''
AS

SET NOCOUNT ON

SELECT
	[codarticulo] = a.codigo
	, [idlista] = vl.idlista
	, [idarticulo] = a.idarticulo
	, [idtipo] = a.idtipo
	, [nombre] = a.nombre
	, [descripcion] = a.nombre
	, [nombre_corto] = a.nombre_corto
	, [marca] = a.nombre
	, [clasif_SAT] = ISNULL(csc.clave, '-Sin Clasif.-')
	, [idum] = a.idum_venta
	, [maneja_lote] = a.lotes
	, [autorizable] = a.autorizable
	, [factor] = um.factor
	, [unidad] = um.codigo
	, [idmoneda_m] = vlm.idmoneda
	, [tipocambio_m] = ISNULL(bm.tipocambio, 1)
	, [kit] = 0
	, [inventariable] = a.inventariable
	, [serie] = a.series

	, [cantidad_facturada] = (CASE WHEN a.idtipo = 1 THEN 1 ELSE 0 END)
	, [precio_unitario] = (
		(
			(
				CASE ISNULL(vp.codprecio, 1)
					WHEN 2 THEN vlm.precio2
					WHEN 3 THEN vlm.precio3
					WHEN 4 THEN vlm.precio4
					WHEN 5 THEN vlm.precio5
					ELSE vlm.precio1
				END
			)
			* um.factor
		)
		* @precio_factor
	)
	, [precio_unitario_m] = (
		(
			(
				CASE ISNULL(vp.codprecio, 1)
					WHEN 2 THEN vlm.precio2
					WHEN 3 THEN vlm.precio3
					WHEN 4 THEN vlm.precio4
					WHEN 5 THEN vlm.precio5
					ELSE vlm.precio1
				END
			)
			* um.factor
		)
		* @precio_factor
	)
	, [precio_unitario_m2] = (
		(
			(
				CASE ISNULL(vp.codprecio, 1)
					WHEN 2 THEN vlm.precio2
					WHEN 3 THEN vlm.precio3
					WHEN 4 THEN vlm.precio4
					WHEN 5 THEN vlm.precio5
					ELSE vlm.precio1
				END
			)
			* um.factor
		)
		* @precio_factor
	)
	, [precio_minimo] = (
		[dbo].[_ven_fnc_articuloPrecioMinimoPorSucursal]([as].idarticulo, [as].idsucursal, [as].costo_base)
		* @precio_factor
	)

	, [existencia] = ISNULL(aa.existencia, 0)
	, [comprometida] = (
		CASE
			WHEN a.inventariable = 1 THEN dbo.fn_inv_existenciaComprometida(a.idarticulo, @idalmacen)
			ELSE 0
		END
	)

	, [idimpuesto1] = 0
	, [idimpuesto1_valor] = 0
	, [idimpuesto1_cuenta] = ''
	, [idimpuesto2] = 0
	, [idimpuesto2_valor] = 0
	, [idimpuesto2_cuenta] = ''
	, [idimpuesto1_ret] = 0
	, [idimpuesto1_ret_valor] = 0
	, [idimpuesto1_ret_cuenta] = ''
	, [idimpuesto2_ret] = 0
	, [idimpuesto2_ret_valor] = 0
	, [idimpuesto2_ret_cuenta] = ''
	, [ingresos_cuenta] = ''

	, [cambiar_precio] = [as].cambiar_precio
	, [precio_congelado] = CONVERT(BIT, (CASE WHEN [as].cambiar_precio = 1 THEN 0 ELSE 1 END))
	, [cantidad_mayoreo] = [as].mayoreo

	, [max_descuento1] = ISNULL(vp.descuento_limite, 0)
	, [max_descuento2] = ISNULL(vp.descuento_linea, 0)
	, [cuenta_sublinea] = ISNULL(subl.contabilidad,'')
	, [descuento1] = 0
	, [descuento2] = 0
	, [descuento3] = 0

	, [costo] = ISNULL([as].costo_ultimo, 0)
	, [costo_promedio] = ISNULL([as].costo_promedio, 0)
	, [costo_ultimo] = ISNULL([as].costo_ultimo, 0)
	, [costo_bajo] = [as].bajo_costo
	
	, [objerrmsg] = (
		(
			CASE
				WHEN a.activo = 0 THEN 'No seencuentra activo||'
				ELSE ''
			END
		)
		+ (
			CASE
				WHEN csc.clave IS NULL THEN 'No tiene clasificación SAT asignada||'
				ELSE ''
			END
		)
		+ (
			CASE
				WHEN LEN(ISNULL(um.sat_unidad_clave, '')) = 0 THEN 'Tiene unidad de medida sin clave del SAT||'
				ELSE ''
			END
		)
	)
	, [mensaje] = 'Ok'
	, [objlevel] = @objlevel
	, [reg_clave] = @reg_clave
FROM
	ew_articulos AS a
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = @idcliente
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = @idsucursal
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idarticulo = a.idarticulo
		AND [as].idsucursal = s.idsucursal
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = a.idarticulo
		AND aa.idalmacen = @idalmacen
	LEFT JOIN ew_cat_marcas AS m 
			ON a.idmarca = m.idmarca
	LEFT JOIN ew_cfd_sat_clasificaciones AS csc
		ON csc.idclasificacion = a.idclasificacion_sat
	LEFT JOIN ew_cat_unidadesMedida AS um 
			ON um.idum = a.idum_venta
	LEFT JOIN ew_ven_listaprecios AS vl
		ON vl.idlista = (
			CASE
				WHEN ctr.idlista > 0 THEN ctr.idlista
				WHEN @idlista = 0 THEN s.idlista
				ELSE @idlista
			END
		)
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idlista = vl.idlista
		AND vlm.idarticulo = a.idarticulo
	LEFT JOIN ew_ban_monedas AS bm
			ON bm.idmoneda = vlm.idmoneda
	LEFT JOIN ew_ven_politicas AS vp
		ON vp.idpolitica = ctr.idpolitica
	LEFT JOIN ew_articulos_niveles AS subl 
			ON subl.codigo = a.nivel3
WHERE
	a.codigo = @codarticulo
GO
