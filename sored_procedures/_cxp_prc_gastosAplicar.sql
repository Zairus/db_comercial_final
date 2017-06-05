USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100212
-- Description:	Aplicar gastos sobre compra.
-- =============================================
ALTER PROCEDURE [dbo].[_cxp_prc_gastosAplicar]
	@idtran AS INT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- APLICAR GASTOS A ORDEN DE COMPRA ############################################

DECLARE
	@idpedimento AS INT
	,@no_pedimento AS VARCHAR(50)

SELECT
	@no_pedimento = ct.importacion_pedimento
FROM
	ew_cxp_transacciones AS ct
WHERE
	ct.idtran = @idtran

IF @no_pedimento <> ''
BEGIN
	INSERT INTO ew_inv_pedimentos (
		idtran
		,idsucursal
		,folio
		,fecha
		,moneda
		,tipocambio
		,valor
		,valor_aduana
		,igi
		,dta
		,prv
		,importe
	)
	SELECT
		ct.idtran
		,ct.idsucursal
		,ct.importacion_pedimento
		,ct.fecha
		,ct.idmoneda
		,ct.tipocambio
		,ct.importacion_valor_aduana
		,ct.importacion_valor_aduana
		,ct.importacion_igi
		,ct.importacion_dta
		,ct.importacion_prv
		,ct.importacion_valor_aduana
	FROM
		ew_cxp_transacciones AS ct
	WHERE
		ct.idtran = @idtran

	SELECT
		@idpedimento = idpedimento
	FROM
		ew_inv_pedimentos
	WHERE idtran = @idtran
END

UPDATE co SET
	co.gastos = (co.gastos + ctr.importe)
	,co.idpedimento = ISNULL(@idpedimento, 0)
FROM
	ew_cxp_transacciones_rel AS ctr
	LEFT JOIN ew_com_ordenes AS co
		ON co.idtran = ctr.idtran2
WHERE
	ctr.idtran = @idtran

UPDATE com SET
	com.gastos = (
		com.gastos 
		+(
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

--------------------------------------------------------------------------------
-- APLICAR GASTOS A PEDIDO DE SUCURSAL #########################################

UPDATE id SET
	id.gasto = (id.gasto + ctr.importe)
	,id.gastos = (id.gastos + ctr.importe)
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
	,[idestado] = 38
	,[idu] = id.idu
FROM
	ew_cxp_transacciones_rel AS ctr
	LEFT JOIN ew_inv_documentos AS id
		ON id.idtran = ctr.idtran2
WHERE
	id.transaccion = 'GDT3'
	AND ctr.idtran = @idtran
GO
