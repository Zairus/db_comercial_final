USE [db_comercial_final]
GO
-- ==========================================================================================
-- Autor:		Laurence Saavedra
-- Fecha:		2010-02
-- Descripcion: Trigger que se encarga de modificar los saldos pendientes de aplicar
-- ==========================================================================================
ALTER TRIGGER [dbo].[tg_cxp_transacciones_mov_u] ON [dbo].[ew_cxp_transacciones_mov]
FOR UPDATE
AS

SET NOCOUNT ON

RETURN

--------------------------------------------------------------------------------
-- Afectando el saldo pendiente de aplicar en la transaccion principal IDTRAN
--------------------------------------------------------------------------------
UPDATE t SET
	t.saldo=t.saldo - m.importe
FROM
	(
	SELECT
		i.idtran
		,[importe]=SUM((d.importe*(-1)) + i.importe)
	FROM
		inserted i
		LEFT JOIN deleted d ON d.idr=i.idr
	WHERE
		i.importe!=d.importe
	GROUP BY
		i.idtran
	) AS m 
	LEFT JOIN ew_cxp_transacciones t ON t.idtran=m.idtran

--------------------------------------------------------------------------------
-- Afectando el saldo pendiente de aplicar en las transacciones referenciadas IDTRAN2
--------------------------------------------------------------------------------
UPDATE t SET
	t.saldo=t.saldo - m.importe2
FROM
	(
	SELECT
		i.idtran2
		,[importe2]=SUM((d.importe2*(-1)) + i.importe2)
	FROM
		inserted i
		LEFT JOIN deleted d ON d.idr=i.idr
	WHERE
		i.importe2!=d.importe2
	GROUP BY
		i.idtran2
	) AS m 
	LEFT JOIN ew_cxp_transacciones t ON t.idtran=m.idtran2
GO
