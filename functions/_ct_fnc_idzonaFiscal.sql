USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190208
-- Description:	Regresa la zona fiscal aplicable autorizada por el SAT
-- =============================================
ALTER FUNCTION [dbo].[_ct_fnc_idzonaFiscal]
(
	@idsucursal AS INT
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
		ew_sys_sucursales AS ss
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_codigopostal AS scp
			ON scp.c_codigopostal = ss.codpostal
	WHERE
		ss.idsucursal = @idsucursal
		AND @estimulo_autorizado = 1

	SELECT @idzona = ISNULL(@idzona, 1)

	RETURN @idzona
END
GO
