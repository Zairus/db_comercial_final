USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091102
-- Description:	Agregar registros a ew_articulos_sucursales
-- =============================================
ALTER TRIGGER [dbo].[tg_sys_sucursales_i]
	ON [dbo].[ew_sys_sucursales]
	FOR INSERT
AS 

SET NOCOUNT ON

INSERT INTO ew_articulos_sucursales (
	idarticulo
	,idsucursal
)
SELECT
	a.idarticulo
	,s.idsucursal
FROM inserted AS s
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = a.idarticulo
WHERE
	a.idarticulo IS NOT NULL
GO
