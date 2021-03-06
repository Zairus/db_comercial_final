USE db_comercial_final
GO
IF OBJECT_ID('_cxp_prc_pagoProcesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxp_prc_pagoProcesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091203
-- Description:	Procesar pago de acreedor
-- =============================================
CREATE PROCEDURE [dbo].[_cxp_prc_pagoProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idestado AS SMALLINT

DECLARE
	 @fecha AS SMALLDATETIME
	,@idu AS SMALLINT
	,@bancos_idtran AS INT

SELECT
	@idestado = idestado
FROM
	ew_sys_transacciones
WHERE
	idtran = @idtran

SELECT
	@bancos_idtran = idtran
FROM
	ew_ban_transacciones
WHERE
	idtran2 = @idtran

IF @idestado >= 3
BEGIN
	SELECT
		 @fecha = fecha
		,@idu = idu
	FROM
		ew_cxp_transacciones
	WHERE
		idtran = @idtran

	EXEC _cxp_prc_aplicarTransaccion 
		 @idtran
		,@fecha
		,@idu
END

IF @bancos_idtran IS NOT NULL
BEGIN
	EXEC _ct_prc_polizaAplicarDeConfiguracion @bancos_idtran, 'DDA3', @idtran, NULL, 1, @fecha
END
GO
