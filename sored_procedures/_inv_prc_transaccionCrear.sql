USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110224
-- Description:	Crear transacción de almacén
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_transaccionCrear]
	 @idtran2 AS INT
	,@fecha AS SMALLDATETIME
	,@tipo AS TINYINT
	,@idalmacen AS SMALLINT
	,@idconcepto AS INT
	,@idu AS SMALLINT
	,@inv_idtran AS INT OUTPUT
AS

SET NOCOUNT ON

DECLARE
	 @usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@transaccion AS VARCHAR(4)
	,@idsucursal AS SMALLINT
	,@serie AS VARCHAR(20)
	,@sql AS VARCHAR(MAX)
	,@foliolen AS SMALLINT
	,@afolio AS VARCHAR(15)
	,@afecha AS VARCHAR(10)

DECLARE
	 @ref_transaccion AS VARCHAR(5)
	,@ref_folio AS VARCHAR(15)

DECLARE
	@error_mensaje AS VARCHAR(500)

SELECT
	 @usuario = u.usuario
	,@password = u.[password]
FROM
	ew_usuarios AS u
WHERE
	u.idu = @idu

IF @usuario IS NULL
BEGIN
	SELECT @error_mensaje = 'Error: Ocurrió un error al obtener información de usuario [' + LTRIM(RTRIM(STR(@idu))) + '].'
	
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

SELECT 
	 @transaccion = (CASE @tipo WHEN 1 THEN 'GDC1' WHEN 2 THEN 'GDA1' END)
	,@serie = ''
	,@foliolen = 6
	,@afolio = ''
	,@afecha = ''
	,@ref_transaccion = st.transaccion
	,@ref_folio = st.folio
FROM
	ew_sys_transacciones AS st
WHERE
	st.idtran = @idtran2

SELECT
	@idsucursal = alm.idsucursal
FROM
	ew_inv_almacenes AS alm
WHERE
	alm.idalmacen = @idalmacen

SELECT
	@sql = 'INSERT INTO ew_inv_transacciones (
	 idtran
	,idtran2
	,idsucursal
	,idalmacen
	,fecha
	,folio
	,transaccion
	,idconcepto
	,referencia
	,comentario
)
VALUES (
	 {idtran}
	,' + LTRIM(RTRIM(STR(@idtran2))) + '
	,' + LTRIM(RTRIM(STR(@idsucursal))) + '
	,' + LTRIM(RTRIM(STR(@idalmacen))) + '
	,''' + CONVERT(VARCHAR(8), @fecha, 3) + '''
	,''{folio}''
	,''' + @transaccion + '''
	,' + LTRIM(RTRIM(STR(@idconcepto))) + '
	,''' + @ref_transaccion + ' - ' + @ref_folio + '''
	,''''
)'

EXEC _sys_prc_insertarTransaccion 
	 @usuario
	,@password
	,@transaccion
	,@idsucursal
	,@serie
	,@sql
	,@foliolen
	,@inv_idtran OUTPUT
	,@afolio
	,@afecha

IF @inv_idtran IS NULL OR @inv_idtran = 0
BEGIN
	RAISERROR('Error: No se pudo crear transacción de inventario.', 16, 1)
	RETURN
END
GO
