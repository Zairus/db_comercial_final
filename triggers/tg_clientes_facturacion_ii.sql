USE db_comercial_final
GO
IF OBJECT_ID('tg_clientes_facturacion_ii') IS NOT NULL
BEGIN
	DROP TRIGGER tg_clientes_facturacion_ii
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20080226
-- Description:	No permitir eliminar registros
-- =============================================
CREATE TRIGGER [dbo].[tg_clientes_facturacion_ii]
	ON [dbo].[ew_clientes_facturacion]
	FOR INSERT
AS

DECLARE
	@mensaje AS VARCHAR(3000)
	, @idcliente AS SMALLINT
	, @rfc AS VARCHAR(13)
	, @razon_social AS VARCHAR(200)
	, @email AS VARCHAR(150)
	, @idciudad AS SMALLINT

SELECT
	@idcliente = idcliente
	, @rfc = RTRIM(LTRIM(rfc))
	, @razon_social = RTRIM(LTRIM(razon_social))
	, @email = RTRIM(LTRIM(email))
	, @idciudad = idciudad 
FROM 
	inserted

SELECT @rfc = REPLACE(@rfc,'-','')
SELECT @rfc = REPLACE(@rfc,' ','')

IF LEN(@razon_social) = 0
BEGIN
	SELECT @mensaje = 'Capture la Razon Social. Corrija e intente guardar de nuevo.'

	RAISERROR(@mensaje, 16, 1)
	RETURN
END

IF LEN(@razon_social) > 100
BEGIN
	SELECT @mensaje = 'La longitud de la razon social no puede ser mayor a 100 caracteres.'

	RAISERROR(@mensaje, 16, 1)
	RETURN
END

IF [dbo].[_sys_fnc_parametroActivo]('CTE_RFC_REQUERIR') = 1
BEGIN
	IF LEN(@rfc) < 12
	BEGIN
		SELECT @mensaje = 'La longitud del RFC debe ser de 12 caracteres para persona moral y de 13 para persona fisica. Corrija e intente guardar de nuevo.'

		RAISERROR(@mensaje, 16, 1)
		RETURN
	END

	IF @rfc NOT IN('XAXX010101000','XEXX010101000') AND [dbo].[_sys_fnc_parametroActivo]('CTE_RFC_DUPLICAR') = 0
	BEGIN
		IF EXISTS(SELECT * FROM ew_clientes_facturacion WHERE rfc=@rfc AND idcliente <> @idcliente)
		BEGIN
			SELECT @mensaje = 'EL RFC ya se encuentra registrado con otro cliente. Corrija e intente guardar de nuevo.'

			RAISERROR(@mensaje, 16, 1)
			RETURN
		END
	END
END

IF @idcliente > 1 AND [dbo].[_sys_fnc_parametroActivo]('CTE_EMAIL_REQUERIR') = 1
BEGIN
	IF LEN(@email) = 0
	BEGIN
		SELECT @mensaje = 'Capture un email valido a donde se enviaran las facturas emitidas. Corrija e intente guardar de nuevo.'

		RAISERROR(@mensaje, 16, 1)
		RETURN
	END
END

IF @idciudad = 0 AND [dbo].[_sys_fnc_parametroActivo]('CTE_CIUDAD_REQUERIR') = 1
BEGIN
	SELECT @mensaje = 'Seleccione la ciudad. Corrija e intente guardar de nuevo.'

	RAISERROR(@mensaje,16,1)
	RETURN
END
GO
