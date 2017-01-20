USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110522
-- Description:	Cancelar contabilidad de pago.
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_transaccionCancelarContabilidad]
	 @idtran AS INT
	,@tipo AS TINYINT
	,@cancelado_fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- DECLARACIÓN DE VARIABLES ####################################################

DECLARE
	 @poliza_idtran AS INT

--------------------------------------------------------------------------------
-- CREAR PÓLIZA CONTABLE #######################################################

EXEC _ct_prc_polizaCrear @idtran, @cancelado_fecha, @tipo, @idu, @poliza_idtran OUTPUT

--------------------------------------------------------------------------------
-- MOVIMIENTOS DE LA PÓLIZA ####################################################

INSERT INTO ew_ct_poliza_mov (
	 idtran
	,idtran2
	,consecutivo
	,idsucursal
	,cuenta
	,tipomov
	,referencia
	,cargos
	,abonos
	,importe
	,concepto
)

SELECT
	 [idtran] = @poliza_idtran
	,pm.idtran2
	,pm.consecutivo
	,pm.idsucursal
	,pm.cuenta
	,pm.tipomov
	,referencia = 'C' + pm.referencia
	,[cargos] = (cargos * -1)
	,[abonos] = (abonos * -1)
	,[importe] = (importe * -1)
	,[conceptos] = 'Cancelacion de ' + pm.concepto
FROM
	ew_ct_poliza_mov AS pm
WHERE
	pm.idtran2 = @idtran

UPDATE ew_ct_poliza SET
	concepto = 'Canc. ' + CONVERT(VARCHAR(MAX), concepto)
WHERE
	idtran = @poliza_idtran
GO
