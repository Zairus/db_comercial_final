USE db_comercial_final
GO

-- =============================================
-- Author:		Paul Monge
-- Create date: 20091029
-- MODI:		Arvin 20100416 - modifique cantidades de las ordenes consolidadas
-- Description:	Procesar Orden de Compra
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_ordenValidar]
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@registros AS INT
	,@campo VARCHAR(50)

SELECT
	@registros = COUNT(idr)
FROM 
	ew_com_ordenes_mov
WHERE
	idtran = @idtran
	AND costo_unitario = 0

IF @registros > 0
BEGIN
	RAISERROR('Error: No es posible guardar registros con costo cero.', 16, 1)
	RETURN
END

-- Determinamos si el detalle referncia a una orden de compra o a una cotizacion.
SELECT @campo = 'cantidad_ordenada'

IF EXISTS (
	SELECT * 
	FROM 
		ew_com_ordenes_mov AS ref
		LEFT JOIN ew_com_ordenes_mov AS doc 
			ON doc.idmov2 = ref.idmov
	WHERE 
		doc.idtran = @idtran
	)
BEGIN
	SELECT @campo = 'cantidad_surtida'
END


-- Insertamos en las cotizaciones que los campos modificados.
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
	ew_com_ordenes_mov
WHERE
	idtran = @idtran

-- Cambiamos el estado a la cotizacion si todos los articulos fueron ordenados.
INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, idu
)
SELECT 
	[idtran] = idtran2
	,[idestado] = 35 
	,[idu] = @idu
FROM 
	ew_com_ordenes
WHERE 
	idtran <> 0
	AND idtran2 <> 0 
	AND idtran = @idtran
	AND idtran2 NOT IN
	(
		SELECT 
			o.idtran2	
		FROM 
			ew_com_ordenes AS o
			LEFT JOIN ew_com_documentos AS d 
				ON o.idtran2 = d.idtran
			LEFT JOIN ew_com_documentos_mov AS dm 
				ON dm.idtran = d.idtran
		WHERE
			(dm.cantidad_solicitada - dm.cantidad_ordenada) <> 0 
			AND o.idtran <> 0 
			AND o.idtran = @idtran
	)
GO
