USE db_comercial_final
GO
IF OBJECT_ID('tg_ew_ban_estado_cuenta_periodo_mov_d') IS NOT NULL
BEGIN
	DROP TRIGGER tg_ew_ban_estado_cuenta_periodo_mov_d
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190408
-- Description:	Administrar borrado de registros de estado de cuenta
-- =============================================
CREATE TRIGGER tg_ew_ban_estado_cuenta_periodo_mov_d
	ON ew_ban_estado_cuenta_periodo_mov
	INSTEAD OF DELETE
AS 

SET NOCOUNT ON

UPDATE bt SET
	bt.conciliado_id = 0
FROM
	ew_ban_transacciones AS bt
WHERE
	bt.conciliado_id IN (SELECT idr FROM deleted)

DELETE FROM ew_ban_estado_cuenta 
WHERE idr IN (SELECT idr FROM deleted)
GO
