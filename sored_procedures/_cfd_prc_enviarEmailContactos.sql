USE db_comercial_final
GO
IF OBJECT_ID('_cfd_prc_enviarEmailContactos') IS NOT NULL
BEGIN
	DROP PROCEDURE _cfd_prc_enviarEmailContactos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170602
-- Description:	Enviar factura a los contactos de cliente indicados
-- =============================================
CREATE PROCEDURE [dbo].[_cfd_prc_enviarEmailContactos]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@correo AS VARCHAR(1000)
	, @idcliente AS INT

SELECT
	@idcliente = idcliente
FROM
	ew_ven_transacciones
WHERE
	idtran = @idtran

DECLARE cur_enviar CURSOR FOR
	SELECT
		ccc.dato1
	FROM 
		ew_clientes_contactos AS cc
		LEFT JOIN ew_cat_contactos_contacto AS ccc
			ON ccc.idcontacto = cc.idcontacto
	WHERE 
		cc.enviar_facturas = 1
		AND ccc.tipo = 5
		AND LEN(LTRIM(RTRIM(ccc.dato1))) > 0
		AND cc.idcliente = @idcliente

OPEN cur_enviar

FETCH NEXT FROM cur_enviar INTO
	@correo

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC [dbo].[_cfd_prc_enviarEmail] @idtran, @correo

	IF @@ERROR != 0
	BEGIN
		CLOSE cur_enviar
		DEALLOCATE cur_enviar
	END

	FETCH NEXT FROM cur_enviar INTO
		@correo
END

CLOSE cur_enviar
DEALLOCATE cur_enviar

SELECT
	@correo = email
FROM 
	vew_clientes AS c
WHERE
	c.idcliente = @idcliente

IF LEN(ISNULL(@correo, '')) > 0
BEGIN
	EXEC [dbo].[_cfd_prc_enviarEmail] @idtran, @correo
END
GO
