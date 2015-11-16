USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150630
-- Description:	Obtiene la existencia de un articulo en ticket
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_ticketVentaArticuloExistencia]
	@codarticulo AS VARCHAR(30)
	,@idalmacen AS INT
	,@cantidad_ordenada AS DECIMAL(18,6) = 0
AS

SET NOCOUNT ON

SELECT
	[existencia] = (
		ISNULL(ea.existencia, 0)
		-dbo.fn_inv_existenciaComprometida(a.idarticulo, @idalmacen)
	)
	,[cantidad_facturada] = (CASE WHEN ISNULL(ea.existencia, 0) >= @cantidad_ordenada THEN @cantidad_ordenada ELSE 0 END)
FROM
	ew_articulos AS a
	LEFT JOIN ew_articulos_almacenes AS ea
		ON ea.idarticulo = a.idarticulo
		AND ea.idalmacen = @idalmacen
WHERE
	a.codigo = @codarticulo
GO
