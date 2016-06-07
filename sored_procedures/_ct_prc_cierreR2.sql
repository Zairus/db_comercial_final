 USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160531
-- Description:	Cierre de Ejercicio
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_cierreR2]
	@ejercicio AS INT
	,@cuenta AS VARCHAR(20)
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@fecha AS SMALLDATETIME
	,@idsucursal AS INT = 1
	,@referencia AS VARCHAR(50)
	,@poliza_idtran_i AS INT
	,@poliza_idtran_e AS INT

SELECT @fecha = CONVERT(SMALLDATETIME, '31/12/' + LTRIM(RTRIM(STR(@ejercicio))))
SELECT @referencia = 'CIERRE-' + LTRIM(RTRIM(STR(@ejercicio)))

EXEC _ct_prc_ejercicioInicializar @ejercicio

EXEC _ct_prc_polizaCrearSinReferencia
	@fecha
	,3
	,@idu
	,@idsucursal
	,@referencia
	,@poliza_idtran_i OUTPUT
	,13

INSERT INTO ew_ct_poliza_mov (
	idtran
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
	[idtran] = @poliza_idtran_i
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY csg.cuenta)
	,[idsucursal] = @idsucursal
	,[cuenta] = csg.cuenta
	,[tipomov] = 0
	,[referencia] = @referencia
	,[cargos] = csg.saldo_final
	,[abonos] = 0
	,[importe] = csg.saldo_final
	,[concepto] = @referencia
FROM
	ew_ct_saldosGlobales AS csg
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = csg.cuenta
WHERE
	cc.tipo = 4
	AND cc.afectable = 1
	AND csg.idsucursal = 1
	AND csg.periodo = 14
	AND csg.saldo_final <> 0

	AND csg.ejercicio = @ejercicio

EXEC _ct_prc_polizaCuadrar @poliza_idtran_i, @cuenta, @referencia

EXEC _ct_prc_polizaCrearSinReferencia
	@fecha
	,3
	,@idu
	,@idsucursal
	,@referencia
	,@poliza_idtran_e OUTPUT
	,13

INSERT INTO ew_ct_poliza_mov (
	idtran
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
	[idtran] = @poliza_idtran_e
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY csg.cuenta)
	,[idsucursal] = @idsucursal
	,[cuenta] = csg.cuenta
	,[tipomov] = 1
	,[referencia] = @referencia
	,[cargos] = 0
	,[abonos] = csg.saldo_final
	,[importe] = csg.saldo_final
	,[concepto] = @referencia
FROM
	ew_ct_saldosGlobales AS csg
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = csg.cuenta
WHERE
	cc.tipo = 5
	AND cc.afectable = 1
	AND csg.idsucursal = 1
	AND csg.periodo = 14
	AND csg.saldo_final <> 0

	AND csg.ejercicio = @ejercicio

EXEC _ct_prc_polizaCuadrar @poliza_idtran_e, @cuenta, @referencia

SELECT * 
FROM 
	ew_ct_polizaDetalle 
WHERE 
	idtran IN (@poliza_idtran_i, @poliza_idtran_e)
ORDER BY
	idtran
	,consecutivo
GO
BEGIN TRAN

EXEC [dbo].[_ct_prc_cierreR2] 2015, '3130001000', 1

ROLLBACK TRAN
