USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20121112
-- Description:	Datos de tickets a facturar
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaTicketDatos]
	@idtran AS VARCHAR(MAX)
AS

SET NOCOUNT ON

SELECT
	[referencia] = ct.idtran
	,[idtran2] = ct.idtran
	,[objidtran] = ct.idtran
	,[r_fecha] = ct.fecha
	,[r_folio] = ct.folio
	,[r_cliente] = c.nombre
	,[r_importe] = ct.subtotal
	,[r_impuesto1] = ct.impuesto1
	,[r_total] = ct.total
	,[saldo] = ct.saldo
FROM 
	ew_cxc_transacciones AS ct 
	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = ct.idcliente 
WHERE 
	ct.idtran IN (SELECT sm.valor FROM dbo._sys_fnc_separarMultilinea(@idtran, '	') AS sm)
GO
