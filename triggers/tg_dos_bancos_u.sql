USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170628
-- Description:	Actualizar vista docs_bancos
-- =============================================
ALTER TRIGGER [dbo].[tg_dos_bancos_u]
	ON  [dbo].[docs_bancos]
	INSTEAD OF UPDATE
AS 

SET NOCOUNT ON

UPDATE bt SET
	bt.conciliado_id = i.conciliado
	,bt.aplicado_fecha = i.Fechabanco
	,bt.comentario = i.comentario
FROM
	inserted AS i
	LEFT JOIN ew_ban_transacciones AS bt
		ON bt.idmov = i.id
WHERE
	i.r_tipo = 0

UPDATE btm SET
	btm.conciliado_id = i.conciliado
	,btm.comentario = i.comentario
FROM
	inserted AS i
	LEFT JOIN ew_ban_transacciones_mov AS btm
		ON btm.idmov = i.id
	LEFT JOIN ew_ban_transacciones As bt
		ON bt.idtran = btm.idtran
WHERE
	i.r_tipo = 1
GO
