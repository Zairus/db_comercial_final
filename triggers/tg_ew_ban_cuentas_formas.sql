USE db_comercial_final
GO
-- =============================================
-- Author:	Vladimir Barreras
-- Create date: 20190323
-- Description:	Validar cambio de moneda en cuenta
-- =============================================
ALTER TRIGGER [dbo].[tg_ew_ban_cuentas_formas]
	ON [dbo].[ew_ban_cuentas]
	FOR INSERT
AS 

SET NOCOUNT ON

INSERT INTO ew_ban_cuentas_formas (
	idcuenta
	, idforma
)

SELECT
	i.idcuenta
	, bf.idforma
FROM 
	inserted AS i
	LEFT JOIN ew_ban_formas AS bf
		ON bf.codigo IN ('01', '02', '28', '04', '03')
GO
