USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170124
-- Description:	Aplicar toma de inventario
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_invFisicoCongelar]
	@idtran AS BIGINT
	,@comentario AS VARCHAR(4000) = ''
	,@idu AS SMALLINT
	,@password AS VARCHAR(20)
AS

SET NOCOUNT ON

DECLARE 
	@msg AS VARCHAR(1000)
	,@cont AS SMALLINT

-- Comprobando la seguridad del usuario
SELECT 
	@cont = COUNT(*) 
FROM 
	ew_usuarios 
WHERE 
	idu = @idu 
	AND [password] = @password

IF @cont = 0
BEGIN
	SELECT @msg = 'Contraseña incorrecta...'

	RAISERROR(@msg, 16, 1)
	RETURN
END

--- CONGELAMOS LOS ARTICULOS PARA SU CONTEO  ---
UPDATE ew_inv_documentos_mov SET 
	congelar = 1
WHERE 
	idtran = @idtran

UPDATE b SET 
	b.congelar = 1
FROM 
	ew_inv_documentos_mov AS a
	LEFT JOIN ew_inv_documentos AS c 
		ON c.idtran = a.idtran
	LEFT JOIN ew_articulos_almacenes AS b 
		ON b.idalmacen = c.idalmacen 
		AND b.idarticulo = a.idarticulo
WHERE 
	a.idtran = @idtran

-- Registrando el cambio de estado en el inventario fisico
INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, idu
	, host
	, fechahora
	, comentario
)
SELECT
	[idtran] = @idtran
	,[idestado] = 48 --CNT~
	,[idu] = @idu
	,[host] = dbo.fnhost()
	,[fechahora] = GETDATE()
	,[comentario] = @comentario

IF @@error != 0 OR @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'No se logró cambiar el estado al inventario Fisico ....'
	RAISERROR(@msg, 16, 1)
	RETURN
END
GO
