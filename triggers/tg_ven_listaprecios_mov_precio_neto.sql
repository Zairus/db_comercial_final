USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[tg_ven_listaprecios_mov_precio_neto]
   ON  [dbo].[ew_ven_listaprecios_mov]
   FOR INSERT,UPDATE
AS 

SET NOCOUNT ON

IF (
	UPDATE(precio_neto)
	OR UPDATE(precio_neto2)
	OR UPDATE(precio_neto3)
	OR UPDATE(precio_neto4)
	OR UPDATE(precio_neto5)
)
BEGIN
	UPDATE vlm SET
		vlm.precio_nuevo = (i.precio_neto / (1 + (s.iva / 100)))
		,vlm.precio1 = (i.precio_neto / (1 + (s.iva / 100)))
		,vlm.precio2 = (i.precio_neto2 / (1 + (s.iva / 100)))
		,vlm.precio3 = (i.precio_neto3 / (1 + (s.iva / 100)))
		,vlm.precio4 = (i.precio_neto4 / (1 + (s.iva / 100)))
		,vlm.precio5 = (i.precio_neto5 / (1 + (s.iva / 100)))
	FROM 
		inserted AS i
		LEFT JOIN ew_ven_listaprecios_mov AS vlm
			ON vlm.idr = i.idr
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idlista = vlm.idlista
	WHERE
		vlm.precio_neto > 0
END
GO
