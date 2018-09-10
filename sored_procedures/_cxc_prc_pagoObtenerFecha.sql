USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180906
-- Description:	Obtiene fecha de registro en pago de cliente
-- =============================================
ALTER PROCEDURE _cxc_prc_pagoObtenerFecha
	@fecha_operacion AS DATETIME
AS

SET NOCOUNT ON

DECLARE
	@rep_aut AS BIT = dbo._sys_fnc_parametroActivo('CFDI_REP_AUTOMATICO')
	,@fecha AS DATETIME = GETDATE()

SELECT 
	@fecha_operacion = CONVERT(DATETIME, (
		CONVERT(VARCHAR(8), @fecha_operacion, 3) 
		+ ' ' + dbo._sys_fnc_rellenar(DATEPART(HOUR, @fecha), 2, '0')
		+ ':' + dbo._sys_fnc_rellenar(DATEPART(MINUTE, @fecha), 2, '0')
		+ ':' + dbo._sys_fnc_rellenar(DATEPART(SECOND, @fecha), 2, '0')
	))

SELECT [rep_aut] = @rep_aut, [fecha] = (CASE WHEN @rep_aut = 0 THEN @fecha_operacion ELSE @fecha END)
GO
