USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20131118
-- Description:	Desaplicar gasto sobre compra
-- =============================================
ALTER PROCEDURE [dbo].[_cxp_prc_gastosDesaplicar] 
	 @idtran AS INT
	,@fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

IF EXISTS (
	SELECT *
	FROM
		ew_cxp_transacciones_rel AS ctr
		LEFT JOIN ew_inv_documentos AS id
			ON id.idtran = ctr.idtran2
		LEFT JOIN ew_sys_transacciones AS st
			ON st.idtran = ctr.idtran2
	WHERE
		id.transaccion = 'GDT3'
		AND st.idestado = 43
		AND ctr.idtran = @idtran
)
BEGIN
	RAISERROR('Error: Existen pedidos de sucursal recibidos por la aplicacion de este gasto.', 16, 1)
	RETURN
END

IF EXISTS (
	SELECT *
	FROM
		ew_cxp_transacciones_rel AS ctr
		LEFT JOIN ew_com_ordenes AS orden
			ON orden.idtran = ctr.idtran2
		LEFT JOIN ew_com_transacciones AS factura
			ON factura.idtran2 = orden.idtran
	WHERE
		factura.idr IS NOT NULL
		AND ctr.idtran = @idtran
)
BEGIN
	RAISERROR('Error: No se puede cancelar aplicación de gastos para mercancía recibida.', 16, 1)
	RETURN
END

UPDATE co SET
	 co.gastos = (co.gastos - ctr.importe)
	,co.idpedimento = 0
FROM
	ew_cxp_transacciones_rel AS ctr
	LEFT JOIN ew_com_ordenes AS co
		ON co.idtran = ctr.idtran2
WHERE
	ctr.idtran = @idtran

UPDATE com SET
	com.gastos = (
		com.gastos 
		-(
			(
				com.importe
				/(
					SELECT
						co.subtotal
					FROM 
						ew_com_ordenes AS co
					WHERE
						co.idtran = com.idtran
				)
			)
			*ctr.importe
		)
	)
FROM
	ew_cxp_transacciones_rel AS ctr
	LEFT JOIN ew_com_ordenes_mov AS com
		ON com.idtran = ctr.idtran2
WHERE
	ctr.idtran = @idtran

DECLARE
	@idestado AS INT

UPDATE id SET
	id.gasto = (id.gasto - ctr.importe)
	,id.gastos = (id.gastos - ctr.importe)
FROM
	ew_cxp_transacciones_rel AS ctr
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = ctr.idtran2
WHERE
	ctr.idtran = @idtran

INSERT INTO ew_sys_transacciones2 (
	 idtran
	,idestado
	,idu
)
SELECT
	 [idtran] = ctr.idtran2
	,[idestado] = 44
	,[idu] = id.idu
FROM
	ew_cxp_transacciones_rel AS ctr
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = ctr.idtran2
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = ctr.idtran2
WHERE
	id.transaccion = 'GDT3'
	AND st.idestado = 38
	AND ctr.idtran = @idtran

EXEC _cxp_prc_cancelarTransaccion @idtran, @fecha, @idu

EXEC _ct_prc_transaccionAnularCT @idtran
GO
