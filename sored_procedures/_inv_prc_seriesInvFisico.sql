USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20181228
-- Description:	Presentar series para ajuste en inventario fisico
-- =============================================
ALTER PROCEDURE _inv_prc_seriesInvFisico
	@idarticulo AS INT
	, @idalmacen AS INT
	, @diferencia AS DECIMAL(18, 6)
AS

SET NOCOUNT ON

SELECT 
	a.serie
	, a.idarticulo
	, a.fecha 
FROM  
	ew_inv_capas_existencia AS b 
	LEFT JOIN ew_inv_capas AS a 
		ON a.idcapa = b.idcapa 
WHERE 
	a.idarticulo = @idarticulo
	AND (
		(
			@diferencia < 0
			AND b.idalmacen = @idalmacen AND b.existencia > 0
		)
		OR (
			@diferencia >= 0
			AND a.existencia = 0
		)
	)
GO
