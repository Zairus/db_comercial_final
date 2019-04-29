USE db_comercial_final
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

DECLARE
	@cmd AS NVARCHAR(4000) = ''

IF NOT EXISTS(SELECT * FROM objetos WHERE codigo IN (SELECT transaccion FROM inserted))
BEGIN
	RAISERROR('Error: Transaccion inexistente.', 16, 1)
	RETURN
END

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

SELECT 
	@cmd = (
		SELECT DISTINCT 
			'EXEC _sys_prc_ejercicioInicializar ' + LTRIM(RTRIM(STR(YEAR(fecha)))) + '; '
		FROM
			inserted
		FOR XML PATH('')
	)

EXEC sp_executesql @cmd
GO
