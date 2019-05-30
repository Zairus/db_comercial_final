USE db_comercial_final
GO
IF OBJECT_ID('_xac_BITACORA_cargarDoc') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_BITACORA_cargarDoc
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190530
-- Description:	Cargar datos para grid de bitacora
-- =============================================
CREATE PROCEDURE [dbo].[_xac_BITACORA_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[fechahora] = b.fechahora
	, [codigo] = b.codigo
	, [nombre] = b.nombre
	, [usuario_nombre] = b.usuario_nombre
	, [host] = b.host
	, [comentario] = b.comentario
FROM
	bitacora AS b
WHERE
	b.idtran = @idtran
GO
