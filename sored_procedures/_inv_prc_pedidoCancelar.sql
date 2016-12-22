USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110505
-- Description:	Cancelar pedido de sucursal
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_pedidoCancelar]
	 @idtran AS INT
	,@fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACION DE VARIABLES ####################################################

DECLARE
	@idestado AS SMALLINT

--------------------------------------------------------------------------------
-- OBTENER DATOS ###############################################################

SELECT
	@idestado = idestado
FROM
	ew_sys_transacciones
WHERE
	idtran = @idtran 

IF @idestado NOT IN (0,44)
BEGIN
	RAISERROR('Error: Estado no disponible para cancelar.', 16, 1)
	RETURN
END

--------------------------------------------------------------------------------
-- CANCELAR DOCUMENTO ##########################################################

UPDATE ew_inv_documentos SET
	 cancelado = 1
	,cancelado_fecha = @fecha
WHERE
	idtran = @idtran
GO
