USE [db_comercial_final]
GO
ALTER PROCEDURE [dbo].[_sys_prc_foliosGet]
	@transaccion AS VARCHAR(5)
	, @idsucursal AS SMALLINT
	, @serie AS VARCHAR(10)
	, @usuario AS VARCHAR(15)
	, @estacion AS VARCHAR(15)
	, @rellenar AS VARCHAR(10) = ''
	, @cfd AS BIT = 0
AS

SET NOCOUNT ON

DECLARE 
	 @nLen AS TINYINT
	, @nChar AS VARCHAR(1)
	, @msg AS VARCHAR(250)
	, @segundos AS INT

DECLARE 
	@cfd_idfolio AS SMALLINT
	, @cfd_folio AS INT
	, @cfd_serie AS VARCHAR(10)

SELECT @nLen = 0
SELECT @nChar = ''
SELECT @rellenar = RTRIM(LTRIM(@rellenar))
SELECT @nLen = LEN(@rellenar)

IF @nLen > 1
BEGIN
	SELECT @nChar = LEFT(@rellenar, 1)
END

SELECT
	@segundos = CAST(DATEDIFF(SECOND, hora, GETDATE()) AS INT)  
FROM
	ew_sys_folios 
WHERE	
	idsucursal = @idsucursal 
	AND transaccion = @transaccion 
	AND serie = @serie
	AND estatus = 1

SELECT @segundos = ISNULL(@segundos, 0)

UPDATE ew_sys_folios SET  
	estatus = 1
	, usuario = @usuario
	, estacion = @estacion
	, hora = GETDATE() 
WHERE 
	idsucursal = @idSucursal 
	AND transaccion = @transaccion
	AND serie = @serie 
	AND (
		estatus = 0
		OR @segundos > 60
	)

IF @@ROWCOUNT > 0
BEGIN
	-- Documento bloqueado con exito
	-- Vamos a regresar el folio del siguiente documento
	IF @cfd = 1
	BEGIN
		EXEC _cfd_prc_obtenerFolio 
			@idsucursal
			, @transaccion
			, @cfd_idfolio OUTPUT
			, @cfd_folio OUTPUT
			, @cfd_serie OUTPUT

		IF @cfd_idfolio > 0 AND @cfd_folio > 0
		BEGIN
			SELECT	
				folio = RTRIM(ISNULL(@cfd_serie, '')) + dbo.fnRellenar(CONVERT(VARCHAR(10), @cfd_folio), @nLen, @nChar)
				,cfd_idfolio = @cfd_idfolio
				,cfd_folio = @cfd_folio
		END
	END
		ELSE
	BEGIN
		SELECT	
			folio = RTRIM(folioserie) + dbo.fnRellenar(CONVERT(VARCHAR(10),folio + 1), @nLen, @nChar)
		FROM
			ew_sys_folios 
		WHERE	
			idsucursal = @idsucursal 
			AND transaccion = @transaccion 
			AND serie = @serie
	END
END
	ELSE
BEGIN
	-- Folio ocupado
	-- Vamos a regresar el mensaje 
	SELECT 
		@msg =
'Ultimo Folio: ' + CONVERT(VARCHAR(10),folio) + '
Bloqueado por: ' + usuario + '
Desde PC: ' + estacion + '
Segundos: ' + LTRIM(RTRIM(STR(@segundos))) + '
Favor de esperar unos minutos e intentar de nuevo.'
	FROM	
		ew_sys_folios 
	WHERE	
		idsucursal = @idsucursal 
		AND transaccion = @transaccion 
		AND serie = @serie

	RAISERROR(@msg, 16, 1)
	RETURN
END
GO
