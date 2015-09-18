USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150916
-- Description:	Lista de idtran de documentos relacionados a una transacción de compras
-- =============================================
ALTER FUNCTION [dbo].[fn_com_relaciones]
(
	@idtran AS INT
)
RETURNS @tbRelaciones TABLE (idr INT IDENTITY, idtran INT)
AS
BEGIN
	INSERT @tbRelaciones
		(idtran)

	SELECT DISTINCT r.idtran 
	FROM (
		--Ordenes
		SELECT cor.idtran FROM ew_com_ordenes AS cor WHERE cor.idtran IN (SELECT ctm.idtran2 FROM ew_com_transacciones_mov AS ctm WHERE ctm.idtran = @idtran)
		UNION ALL
		--Recepciones
		SELECT ctmr.idtran FROM ew_com_transacciones_mov AS ctmr WHERE ctmr.idtran2 IN (SELECT cor.idtran FROM ew_com_ordenes AS cor WHERE cor.idtran IN (SELECT ctm.idtran2 FROM ew_com_transacciones_mov AS ctm WHERE ctm.idtran = @idtran))
		UNION ALL
		--Entradas por compra
		SELECT it.idtran FROM ew_inv_transacciones AS it WHERE it.idtran2 IN (SELECT ctmr.idtran FROM ew_com_transacciones_mov AS ctmr WHERE ctmr.idtran2 IN (SELECT cor.idtran FROM ew_com_ordenes AS cor WHERE cor.idtran IN (SELECT ctm.idtran2 FROM ew_com_transacciones_mov AS ctm WHERE ctm.idtran = @idtran)))
		UNION ALL
		--Devoluciones
		SELECT ctm.idtran FROM ew_com_transacciones_mov AS ctm WHERE CONVERT(INT, FLOOR(ctm.idmov2)) = @idtran
		UNION ALL
		--Salidas por devolucion
		SELECT it.idtran FROM ew_inv_transacciones AS it WHERE it.idtran2 IN (SELECT ctm.idtran FROM ew_com_transacciones_mov AS ctm WHERE CONVERT(INT, FLOOR(ctm.idmov2)) = @idtran)
	) AS r

	RETURN
END
GO
