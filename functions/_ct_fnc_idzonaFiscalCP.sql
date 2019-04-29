USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190208
-- Description:	Regresa la zona fiscal aplicable por codigo postal
-- =============================================
CREATE FUNCTION [dbo].[_ct_fnc_idzonaFiscalCP]
(
	@codigo_postal AS VARCHAR(10)
)
RETURNS INT
AS
BEGIN
	DECLARE
		@idzona AS INT
		, @estimulo_autorizado AS BIT

	SELECT @estimulo_autorizado = [dbo].[_sys_fnc_parametroActivo] ('CFDI_ESTIMULO_FRONTERA')

	SELECT
		@idzona = scp.idzona
	FROM 
		db_comercial.dbo.evoluware_cfd_sat_codigopostal AS scp
	WHERE
		scp.c_codigopostal = @codigo_postal

	SELECT @idzona = ISNULL(@idzona, 1)

	RETURN @idzona
END
GO
