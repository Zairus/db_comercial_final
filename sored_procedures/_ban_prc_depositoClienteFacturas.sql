USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110502
-- Description:	Datos de facturas para deposito por pago
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_depositoClienteFacturas]
	@idtran2 AS VARCHAR(1000)
AS

SET NOCOUNT ON

SELECT
	 [idtran2] = ct.idtran
	,[codigo] = c.codigo
	,[idconcepto] = ct.idcliente
	,[cliente] = c.nombre
	,[ref_folio] = ct.folio
	,[ref_fecha] = ct.fecha
	,[ref_sucursal] = ct.idsucursal
	,[ref_subtotal] = ct.subtotal
	,[ref_impuesto1] = ct.impuesto1
	,[ref_total] = ct.total
	,[ref_saldo] = ct.saldo
	,[importe] = ct.saldo 
FROM 
	ew_cxc_transacciones AS ct 
	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = ct.idcliente 
WHERE 
	ct.cancelado = 0 
	AND ct.tipo = 1 
	AND ct.saldo > 0 
	AND ct.idtran IN (
		SELECT
			CONVERT(INT, sm.valor)
		FROM
			dbo._sys_fnc_separarMultilinea(@idtran2, '	') AS sm
	)
GO