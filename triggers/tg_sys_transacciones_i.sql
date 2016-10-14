USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091026
-- Description:	Registro de transacciones.
-- =============================================
ALTER TRIGGER [dbo].[tg_sys_transacciones_i]
	ON [dbo].[ew_sys_transacciones]
	FOR INSERT
AS 

SET NOCOUNT ON

INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, idu
)
SELECT TOP 1
	[idtran] = i.idtran
	,[idestado] = ISNULL((
		SELECT TOP 1 
			idestado 
		FROM 
			objetos_estados 
		WHERE 
			objeto = dbo.fn_sys_objeto(i.transaccion)
		ORDER BY 
			orden
			,idestado
	), 0)
	,[idu] = dbo._sys_fnc_usuario()
FROM 
	inserted AS i
GO
