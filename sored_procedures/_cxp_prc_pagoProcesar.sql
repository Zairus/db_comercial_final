USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091203
-- Description:	Procesar pago de acreedor
-- =============================================
ALTER PROCEDURE [dbo].[_cxp_prc_pagoProcesar]
	@idtran AS BIGINT
AS

SET NOCOUNT ON

DECLARE
	@idestado AS SMALLINT

DECLARE
	 @fecha AS SMALLDATETIME
	,@idu AS SMALLINT

SELECT
	@idestado = idestado
FROM
	ew_sys_transacciones
WHERE
	idtran = @idtran

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
GO
