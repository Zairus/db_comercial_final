USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[tg_ven_listaprecios_mov_precio_neto]
   ON  [dbo].[ew_ven_listaprecios_mov]
   FOR UPDATE
AS 

SET NOCOUNT ON

IF (
	UPDATE(precio_neto)
	AND TRIGGER_NESTLEVEL() <= 1
)
BEGIN
	UPDATE vlm SET
		vlm.precio1 = (i.precio_neto / [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))
	FROM 
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		ABS(vlm.precio1 - (vlm.precio_neto / [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))) > 0.10
END

IF (
	UPDATE(precio_neto2)
	AND TRIGGER_NESTLEVEL() <= 1
)
BEGIN
	UPDATE vlm SET
		vlm.precio2 = (i.precio_neto2 / [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))
	FROM 
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		ABS(vlm.precio2 - (vlm.precio_neto2 / [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))) > 0.10
END

IF (
	UPDATE(precio_neto3)
	AND TRIGGER_NESTLEVEL() <= 1
)
BEGIN
	UPDATE vlm SET
		vlm.precio3 = (i.precio_neto3 / [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))
	FROM 
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		ABS(vlm.precio3 - (vlm.precio_neto3 / [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))) > 0.10
END

IF (
	UPDATE(precio_neto4)
	AND TRIGGER_NESTLEVEL() <= 1
)
BEGIN
	UPDATE vlm SET
		vlm.precio4 = (i.precio_neto4 / [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))
	FROM 
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		ABS(vlm.precio4 - (vlm.precio_neto4 / [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))) > 0.10
END

IF (
	UPDATE(precio_neto5)
	AND TRIGGER_NESTLEVEL() <= 1
)
BEGIN
	UPDATE vlm SET
		vlm.precio5 = (i.precio_neto5 / [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))
	FROM 
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		ABS(vlm.precio5 - (vlm.precio_neto5 / [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))) > 0.10
END

IF (
	UPDATE(precio1)
	AND TRIGGER_NESTLEVEL() <= 1
)
BEGIN
	UPDATE vlm SET
		vlm.precio_neto = (i.precio1 * [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))
	FROM
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		ABS(vlm.precio_neto - (vlm.precio1 * [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))) > 0.10
END

IF (
	UPDATE(precio2)
	AND TRIGGER_NESTLEVEL() <= 1
)
BEGIN
	UPDATE vlm SET
		vlm.precio_neto2 = (i.precio2 * [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))
	FROM
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		ABS(vlm.precio_neto2 - (vlm.precio2 * [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))) > 0.10
END

IF (
	UPDATE(precio3)
	AND TRIGGER_NESTLEVEL() <= 1
)
BEGIN
	UPDATE vlm SET
		vlm.precio_neto3 = (i.precio3 * [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))
	FROM
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		ABS(vlm.precio_neto3 - (vlm.precio3 * [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))) > 0.10
END

IF (
	UPDATE(precio4)
	AND TRIGGER_NESTLEVEL() <= 1
)
BEGIN
	UPDATE vlm SET
		vlm.precio_neto4 = (i.precio4 * [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))
	FROM
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		ABS(vlm.precio_neto4 - (vlm.precio4 * [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))) > 0.10
END

IF (
	UPDATE(precio5)
	AND TRIGGER_NESTLEVEL() <= 1
)
BEGIN
	UPDATE vlm SET
		vlm.precio_neto5 = (i.precio5 * [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))
	FROM
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		ABS(vlm.precio_neto5 - (vlm.precio5 * [dbo].[fn_ct_articuloCargaFactor](vlm.idarticulo, s.idsucursal))) > 0.10
END
GO
