USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150821
-- Description:	Contabilizar BPR2
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_contabilizarBPR2]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@fecha AS SMALLDATETIME
	,@idtipo AS SMALLINT = 1
	,@idu AS INT
	,@poliza_idtran AS INT
	,@referencia AS VARCHAR(500)
	,@diferencia DECIMAL(18,6)

IF OBJECT_ID('tempdb.._tmp_poliza_mov') IS NOT NULL
BEGIN
	DROP TABLE #_tmp_poliza_mov
END

CREATE TABLE #_tmp_poliza_mov (
	id INT IDENTITY
	,idtran INT NOT NULL DEFAULT 0
	,idtran2 INT NOT NULL DEFAULT 0
	,estatus SMALLINT NOT NULL DEFAULT 0
	,consecutivo SMALLINT NOT NULL DEFAULT 0
	,idsucursal SMALLINT NOT NULL DEFAULT 0
	,cuenta VARCHAR(20) NOT NULL DEFAULT ''
	,tipomov SMALLINT NOT NULL DEFAULT 0
	,referencia VARCHAR(500) NOT NULL DEFAULT ''
	,cargos DECIMAL(18,6) NOT NULL DEFAULT 0
	,abonos DECIMAL(18,6) NOT NULL DEFAULT 0
	,importe DECIMAL(18,6) NOT NULL DEFAULT 0
	,moneda SMALLINT NOT NULL DEFAULT 0
	,tipocambio DECIMAL(18,6) NOT NULL DEFAULT 0
	,concepto VARCHAR(5000) NOT NULL DEFAULT ''
)

SELECT
	@fecha = bt.fecha
	,@idu = bt.idu
	,@referencia = bt.transaccion + ' - ' + bt.folio
FROM
	ew_ban_documentos AS bt
WHERE
	bt.idtran = @idtran

EXEC _ct_prc_polizaCrear @idtran, @fecha, @idtipo, @idu, @poliza_idtran OUTPUT, @referencia

INSERT INTO #_tmp_poliza_mov (
	idtran
	,idtran2
	,estatus
	,consecutivo
	,idsucursal
	,cuenta
	,tipomov
	,referencia
	,cargos
	,abonos
	,importe
	,moneda
	,tipocambio
	,concepto
)

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @idtran
	,[estatus] = 0
	,[consecutivo] = 1
	,[idsucursal] = bd.idsucursal
	,[cuenta] = bc.contabilidad1
	,[tipomov] = 0
	,[referencia] = (bd.transaccion + ' - ' + bd.folio)
	,[cargos] = (bd.importe * (CASE bd.idmoneda WHEN 0 THEN 1 ELSE bd.tipocambio END))
	,[abonos] = 0
	,[importe] = (bd.importe * (CASE bd.idmoneda WHEN 0 THEN 1 ELSE bd.tipocambio END))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + bd.folio)
FROM
	ew_ban_documentos AS bd
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = bd.idcuenta2
	LEFT JOIN objetos AS o
		ON o.codigo = bd.transaccion
WHERE
	bd.idtran = @idtran

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @idtran
	,[estatus] = 0
	,[consecutivo] = 1
	,[idsucursal] = bd.idsucursal
	,[cuenta] = bc.contabilidad1
	,[tipomov] = 1
	,[referencia] = (bd.transaccion + ' - ' + bd.folio)
	,[cargos] = 0
	,[abonos] = (bd.importe * (CASE bd.idmoneda WHEN 0 THEN 1 ELSE bd.tipocambio END))
	,[importe] = (bd.importe * (CASE bd.idmoneda WHEN 0 THEN 1 ELSE bd.tipocambio END))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + bd.folio)
FROM
	ew_ban_documentos AS bd
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = bd.idcuenta1
	LEFT JOIN objetos AS o
		ON o.codigo = bd.transaccion
WHERE
	bd.idtran = @idtran

INSERT INTO ew_ct_poliza_mov (
	[idtran]
	,[idtran2]
	,[estatus]
	,[consecutivo]
	,[idsucursal]
	,[cuenta]
	,[tipomov]
	,[referencia]
	,[cargos]
	,[abonos]
	,[importe]
	,[moneda]
	,[tipocambio]
	,[concepto]
)
SELECT
	[idtran]
	,[idtran2]
	,[estatus]
	,[consecutivo]
	,[idsucursal]
	,[cuenta]
	,[tipomov]
	,[referencia]
	,[cargos]
	,[abonos]
	,[importe]
	,[moneda]
	,[tipocambio]
	,[concepto]
FROM
	#_tmp_poliza_mov

DROP TABLE #_tmp_poliza_mov

EXEC _ct_prc_polizaValidarDualidad @idtran
GO
