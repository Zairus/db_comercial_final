USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_ticketVentaArticuloExistencia') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_ticketVentaArticuloExistencia
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150630
-- Description:	Obtiene la existencia de un articulo en ticket
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_ticketVentaArticuloExistencia]
	@codarticulo AS VARCHAR(30)
	, @idalmacen AS INT
	, @cantidad_ordenada AS DECIMAL(18,6) = 0
AS

SET NOCOUNT ON

SELECT
	[existencia] = (
		ISNULL(ea.existencia, 0)
		-dbo.fn_inv_existenciaComprometida(a.idarticulo, @idalmacen)
	) * a.inventariable
	, [cantidad_facturada] = (
		CASE 
			WHEN (ISNULL(ea.existencia, 0) >= @cantidad_ordenada) OR (a.inventariable = 0) THEN @cantidad_ordenada 
			ELSE 0 
		END
	)
FROM
	ew_articulos AS a
	LEFT JOIN ew_articulos_almacenes AS ea
		ON ea.idarticulo = a.idarticulo
		AND ea.idalmacen = @idalmacen
WHERE
	a.codigo = @codarticulo
GO
