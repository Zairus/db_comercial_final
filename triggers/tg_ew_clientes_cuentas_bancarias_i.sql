USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171120
-- Description:	Validar informacion de cuentas bancarias de cliente
-- =============================================
ALTER TRIGGER [dbo].[tg_ew_clientes_cuentas_bancarias_i]
	ON [dbo].[ew_clientes_cuentas_bancarias]
	FOR INSERT, UPDATE
AS 

SET NOCOUNT ON

DECLARE
	@mensaje AS VARCHAR(500)

IF EXISTS(
	SELECT *
	FROM 
		inserted AS i
		LEFT JOIN ew_ban_formas AS bf
			ON bf.idforma = i.idforma
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_formapago AS csf
			ON csf.c_formapago = bf.codigo
	WHERE
		[dbEVOLUWARE].[dbo].[regex_match](i.clabe, csf.cuenta_ordenante_patron) = 0
)
BEGIN
	SELECT
		@mensaje = (
			'Error: '
			+ 'El valor ['
			+ i.clabe
			+ '], '
			+ 'es incorrecto para la forma de pago '
			+ ISNULL(bf.nombre, '-No Especificado-')
		)
	FROM 
		inserted AS i
		LEFT JOIN ew_ban_formas AS bf
			ON bf.idforma = i.idforma
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_formapago AS csf
			ON csf.c_formapago = bf.codigo
	WHERE
		[dbEVOLUWARE].[dbo].[regex_match](i.clabe, csf.cuenta_ordenante_patron) = 0

	RAISERROR(@mensaje, 16, 1)
	RETURN
END
GO
