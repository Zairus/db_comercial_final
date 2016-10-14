USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091029
-- MODI:		Arvin 20100416 - modifique cantidades de las ordenes consolidadas
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
	[idmov1] = idmov
	,[idmov2] = idmov2
	,[campo] = @campo
	,[valor] = cantidad_ordenada 
FROM
	ew_ven_ordenes_mov
WHERE
	idtran = @idtran

INSERT INTO ew_sys_transacciones2 (
	idtran
	,idestado
	,idu
)
SELECT 
	[idtrab] = idtran2
	,[idestado] = 251 
	,[idu] = @idu
FROM 
	ew_ven_ordenes
WHERE
	idtran = @idtran
GO
