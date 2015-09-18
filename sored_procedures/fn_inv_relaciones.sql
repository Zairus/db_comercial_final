USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150916
-- Description:	Lista de idtran de documentos relacionados a una transacción de inventario
-- =============================================
ALTER FUNCTION [dbo].[fn_inv_relaciones]
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
		--Recepciones
		SELECT ctm.idtran FROM ew_com_transacciones_mov AS ctm WHERE ctm.idtran IN (SELECT DISTINCT itm.idtran2 FROM ew_inv_transacciones_mov AS itm WHERE itm.idtran = @idtran)
		UNION ALL
		--Compras Ordenes
		SELECT com.idtran FROM ew_com_ordenes_mov AS com WHERE com.idtran IN (SELECT DISTINCT ctm.idtran2 FROM ew_com_transacciones_mov AS ctm WHERE ctm.idtran IN (SELECT DISTINCT itm.idtran2 FROM ew_inv_transacciones_mov AS itm WHERE itm.idtran = @idtran))
		UNION ALL
		--Facturas
		SELECT ctm.idtran FROM ew_com_transacciones_mov AS ctm WHERE ctm.idtran2 IN (SELECT com.idtran FROM ew_com_ordenes_mov AS com WHERE com.idtran IN (SELECT DISTINCT ctm.idtran2 FROM ew_com_transacciones_mov AS ctm WHERE ctm.idtran IN (SELECT DISTINCT itm.idtran2 FROM ew_inv_transacciones_mov AS itm WHERE itm.idtran = @idtran)))
		UNION ALL
		--Ventas Dev
		SELECT vtm.idtran FROM ew_ven_transacciones_mov AS vtm WHERE vtm.idtran IN (SELECT DISTINCT itm.idtran2 FROM ew_inv_transacciones_mov AS itm WHERE itm.idtran = @idtran)
		UNION ALL
		--Ventas Ordenes
		SELECT vom.idtran FROM ew_ven_ordenes_mov AS vom WHERE vom.idtran IN (SELECT vtm.idtran2 FROM ew_ven_transacciones_mov AS vtm WHERE vtm.idtran IN (SELECT DISTINCT itm.idtran2 FROM ew_inv_transacciones_mov AS itm WHERE itm.idtran = @idtran))
		UNION ALL
		--Ventas Facturas
		SELECT vtm1.idtran FROM ew_ven_transacciones_mov AS vtm1 WHERE vtm1.idtran2 IN (SELECT vom.idtran FROM ew_ven_ordenes_mov AS vom WHERE vom.idtran IN (SELECT vtm.idtran2 FROM ew_ven_transacciones_mov AS vtm WHERE vtm.idtran IN (SELECT DISTINCT itm.idtran2 FROM ew_inv_transacciones_mov AS itm WHERE itm.idtran = @idtran)))
	) AS r

	RETURN
END
GO
