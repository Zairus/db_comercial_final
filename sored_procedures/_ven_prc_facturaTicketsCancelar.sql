USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150915
-- Description:	Cancelar factura de tickets
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaTicketsCancelar]
	@idtran AS INT
	,@fecha AS SMALLDATETIME
	,@idu AS INT
AS

SET NOCOUNT ON

UPDATE ew_cxc_transacciones SET
	cancelado = 1
	,cancelado_fecha = @fecha
WHERE
	idtran = @idtran

UPDATE ew_ven_transacciones SET
	cancelado = 1
	,cancelado_fecha = @fecha
WHERE
	idtran = @idtran

INSERT INTO ew_sys_transacciones2 (
	 idtran
	,idestado
	,idu
)
SELECT
	 [idtran] = ctr.idtran2
	,[idestado] = (CASE WHEN ct.saldo = 0 THEN 50 ELSE 0 END)
	,[idu] = ft.idu
FROM
	ew_cxc_transacciones_rel AS ctr
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = ctr.idtran2
	LEFT JOIN ew_cxc_transacciones AS ft
		ON ft.idtran = ctr.idtran
WHERE
	ctr.idtran = @idtran
GO
