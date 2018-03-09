USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091029
-- Description:	Procesar Orden de Venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_ordenValidar]
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@registros AS INT
	,@campo VARCHAR(50)

SELECT @campo = 'cantidad_ordenada'

IF EXISTS (
	SELECT * 
	FROM 
		ew_ven_ordenes_mov ref
		LEFT JOIN ew_ven_ordenes_mov doc
			ON doc.idmov2 = ref.idmov
	WHERE 
		doc.idtran = @idtran
	)
BEGIN
	SELECT @campo = 'cantidad_surtida'
END

INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	,idmov2
	,campo
	,valor
)
SELECT
	[idmov1] = vom.idmov
	,[idmov2] = vom.idmov2
	,[campo] = @campo
	,[valor] = vom.cantidad_ordenada 
FROM
	ew_ven_ordenes_mov AS vom
WHERE
	(
		SELECT COUNT(*)
		FROM
			ew_sys_movimientos_acumula AS sma
		WHERE
			sma.idmov1 = vom.idmov
	) = 0
	AND idtran = @idtran
GO
