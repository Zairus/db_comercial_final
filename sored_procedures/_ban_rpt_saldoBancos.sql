USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190429
-- Description:	Saldos mensuales de bancos
-- =============================================
ALTER PROCEDURE [dbo].[_ban_rpt_saldoBancos]
	@ejercicio INT
	, @idcuenta INT 
AS

SET NOCOUNT ON 
DECLARE @sql VARCHAR(4000)

SET DATEFORMAT DMY

SELECT
	[banco] = ISNULL(bb.nombre, '')
	, [cuenta] = ISNULL(rtrim(bc.no_cuenta), '')
	, [enero] = (SELECT periodo1 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [febrero] = (SELECT periodo2 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [marzo] = (SELECT periodo3 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [abril] = (SELECT periodo4 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [mayo] = (SELECT periodo5 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [junio] = (SELECT periodo6 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [julio] = (SELECT periodo7 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [agosto] = (SELECT periodo8 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [septiembre] = (SELECT periodo9 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [octubre] = (SELECT periodo10 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [noviembre] = (SELECT periodo11 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [diciembre] = (SELECT periodo12 + periodo0 FROM ew_ban_saldos WHERE tipo = 1 AND idcuenta = bc.idcuenta AND ejercicio = @ejercicio)
	, [empresa] = dbo.fn_sys_empresa()
FROM
	ew_ban_cuentas AS bc
	LEFT JOIN ew_ban_bancos AS bb
		ON bb.idbanco = bc.idbanco
WHERE
	bc.idcuenta = (CASE WHEN @idcuenta > 0 THEN @idcuenta ELSE bc.idcuenta END)
ORDER BY
	bc.idcuenta
GO
