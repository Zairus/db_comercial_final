USE [db_comercial_final]
GO
ALTER TRIGGER [dbo].[tg_sys_transacciones2_idu] 
	ON [dbo].[ew_sys_transacciones2] 
	INSTEAD OF INSERT
AS

INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, fechahora
	, idu
	, host
	, comentario
)
SELECT
	[idtran] = i.idtran
	, [idestado] = i.idestado
	, [fechahora] = i.fechahora
	, [idu] = (
		CASE 
			WHEN i.idestado = 255 THEN ISNULL(i.idu, [dbo].[_sys_fnc_usuario]()) 
			ELSE i.idu 
		END
	)
	, [host] = i.host
	, [comentario] = i.comentario
FROM
	inserted AS i
GO
