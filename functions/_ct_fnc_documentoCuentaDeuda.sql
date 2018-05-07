USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180504
-- Description:	Obtiene cuenta contable para provision o pago de deuda
-- =============================================
ALTER FUNCTION _ct_fnc_documentoCuentaDeuda
(
	@idtran AS INT
)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE
		@cuenta AS VARCHAR(20)

	SELECT
		@cuenta = (
			CASE
				WHEN ct.tipo_cargo = 1 THEN
					CASE
						WHEN p.extrangero = 0 AND p.parte_relacionada = 0 THeN [dbo].[fn_sys_obtenerDato]('GLOBAL', 'ACREEDORES') 
						WHEN p.extrangero = 0 AND p.parte_relacionada = 1 THeN [dbo].[fn_sys_obtenerDato]('GLOBAL', 'ACREEDORES_PR') 
						WHEN p.extrangero = 1 AND p.parte_relacionada = 0 THeN [dbo].[fn_sys_obtenerDato]('GLOBAL', 'ACREEDORES_E') 
						ELSE [dbo].[fn_sys_obtenerDato]('GLOBAL', 'ACREEDORES_E_PR') 
					END
				ELSE
					CASE
						WHEN p.extrangero = 0 AND p.parte_relacionada = 0 THeN [dbo].[fn_sys_obtenerDato]('GLOBAL', 'PROVEEDOR_NACIONAL') 
						WHEN p.extrangero = 0 AND p.parte_relacionada = 1 THeN [dbo].[fn_sys_obtenerDato]('GLOBAL', 'PROVEEDOR_NACIONAL_R') 
						WHEN p.extrangero = 1 AND p.parte_relacionada = 0 THeN [dbo].[fn_sys_obtenerDato]('GLOBAL', 'PROVEEDOR_EXT') 
						ELSE [dbo].[fn_sys_obtenerDato]('GLOBAL', 'PROVEEDOR_EXT_R') 
					END
			END
		)
	FROM
		ew_cxp_transacciones AS ct
		LEFT JOIN ew_proveedores AS p
			ON p.idproveedor = ct.idproveedor
	WHERE
		ct.idtran = @idtran

	SELECT @cuenta = ISNULL(@cuenta, '')

	RETURN @cuenta
END
GO
