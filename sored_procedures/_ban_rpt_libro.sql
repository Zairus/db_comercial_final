USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100416
-- Description:	Libro de bancos
-- =============================================
ALTER PROCEDURE [dbo].[_ban_rpt_libro]
	 @idcuenta AS INT = 0
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

CREATE TABLE #_tmp_libro (
	 idr INT IDENTITY
	,cuenta VARCHAR (200)
	,idcuenta INT
	,fecha SMALLDATETIME
	,folio VARCHAR(15)
	,movimiento VARCHAR(200)
	,saldo_inicial DECIMAL(18,2)
	,cargos DECIMAL(18,2)
	,abonos DECIMAL(18,2)
	,saldo_final DECIMAL(18,2)
	,idtran INT
)

INSERT INTO #_tmp_libro (
	 cuenta
	,idcuenta
	,fecha
	,folio
	,movimiento
	,saldo_inicial
	,cargos
	,abonos
	,saldo_final
	,idtran
)
SELECT
	 [cuenta] = bc.no_cuenta + ' - ' + b.nombre
	,bc.idcuenta
	,bt.fecha
	,bt.folio
	,[movimiento] = o.nombre
	,[saldo_inicial] = 0
	,[cargos] = (CASE bt.tipo WHEN 1 THEN bt.importe ELSE 0 END)
	,[abonos] = (CASE bt.tipo WHEN 2 THEN bt.importe ELSE 0 END)
	,[saldo_final] = 0
	,bt.idtran
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = bt.idcuenta
	LEFT JOIN ew_ban_bancos AS b
		ON b.idbanco = bc.idbanco
	LEFT JOIN objetos AS o
		ON o.codigo = bt.transaccion
WHERE
	bt.cancelado = 0
	AND bt.tipo IN(1,2)
	AND bt.idcuenta = (CASE @idcuenta WHEN 0 THEN bt.idcuenta ELSE @idcuenta END)
	AND bt.fecha BETWEEN @fecha1 AND @fecha2

UPDATE tl SET
	tl.saldo_inicial = (
		ISNULL((
			SELECT 
				CASE MONTH(@fecha1)
					WHEN 1 THEN bs.periodo0
					WHEN 2 THEN bs.periodo1 + bs.periodo0
					WHEN 3 THEN bs.periodo2 + bs.periodo0
					WHEN 4 THEN bs.periodo3 + bs.periodo0
					WHEN 5 THEN bs.periodo4 + bs.periodo0
					WHEN 6 THEN bs.periodo5 + bs.periodo0
					WHEN 7 THEN bs.periodo6 + bs.periodo0
					WHEN 8 THEN bs.periodo7 + bs.periodo0
					WHEN 9 THEN bs.periodo8 + bs.periodo0
					WHEN 10 THEN bs.periodo9 + bs.periodo0
					WHEN 11 THEN bs.periodo10 + bs.periodo0
					WHEN 12 THEN bs.periodo11 + bs.periodo0
				END
			FROM
				ew_ban_saldos AS bs
			WHERE
				bs.tipo = 1 
				AND bs.idcuenta = tlc.idcuenta
				AND bs.ejercicio = YEAR(@fecha1)
		), 0)
		+(
			CASE
				WHEN DAY(@fecha1) <> 1 THEN (
					SELECT
						SUM(
							CASE 
								WHEN bt.tipo = 1 THEN bt.importe 
								ELSE (bt.importe * -1) 
							END
						)
					FROM
						ew_ban_transacciones AS bt
					WHERE
						bt.tipo IN (1,2)
						AND bt.cancelado = 0
						AND bt.idcuenta = tlc.idcuenta
						AND bt.fecha BETWEEN 
							CONVERT(SMALLDATETIME, '01/' + LTRIM(RTRIM(STR(MONTH(@fecha1)))) + '/' + LTRIM(RTRIM(STR(YEAR(@fecha1)))) + ' 00:00') 
							AND CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), DATEADD(DAY, -1, @fecha1), 3) + ' 23:59')
				)
				ELSE 0
			END
		)
	)
	,tl.saldo_final = (
		ISNULL((
			SELECT 
				CASE MONTH(@fecha1)
					WHEN 1 THEN bs.periodo0
					WHEN 2 THEN bs.periodo1 + bs.periodo0
					WHEN 3 THEN bs.periodo2 + bs.periodo0
					WHEN 4 THEN bs.periodo3 + bs.periodo0
					WHEN 5 THEN bs.periodo4 + bs.periodo0
					WHEN 6 THEN bs.periodo5 + bs.periodo0
					WHEN 7 THEN bs.periodo6 + bs.periodo0
					WHEN 8 THEN bs.periodo7 + bs.periodo0
					WHEN 9 THEN bs.periodo8 + bs.periodo0
					WHEN 10 THEN bs.periodo9 + bs.periodo0
					WHEN 11 THEN bs.periodo10 + bs.periodo0
					WHEN 12 THEN bs.periodo11 + bs.periodo0
				END
			FROM
				ew_ban_saldos AS bs
			WHERE
				bs.tipo = 1 
				AND bs.idcuenta = tlc.idcuenta
				AND bs.ejercicio = YEAR(@fecha1)
		), 0)
		+(
			CASE
				WHEN DAY(@fecha1) <> 1 THEN (
					SELECT
						SUM(
							CASE 
								WHEN bt.tipo = 1 THEN bt.importe 
								ELSE (bt.importe * -1) 
							END
						)
					FROM
						ew_ban_transacciones AS bt
					WHERE
						bt.tipo IN (1,2)
						AND bt.cancelado = 0
						AND bt.idcuenta = tlc.idcuenta
						AND bt.fecha BETWEEN 
							CONVERT(SMALLDATETIME, '01/' + LTRIM(RTRIM(STR(MONTH(@fecha1)))) + '/' + LTRIM(RTRIM(STR(YEAR(@fecha1)))) + ' 00:00') 
							AND CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), DATEADD(DAY, -1, @fecha1), 3) + ' 23:59')
				)
				ELSE 0
			END
		)
		+ISNULL((
			SELECT
				SUM(tli.cargos)
			FROM
				#_tmp_libro AS tli
			WHERE
				tli.idcuenta = tlc.idcuenta
		), 0)
		-ISNULL((
			SELECT
				SUM(tle.abonos)
			FROM
				#_tmp_libro AS tle
			WHERE
				tle.idcuenta = tlc.idcuenta
		), 0)
	)
FROM 
	(
		SELECT DISTINCT
			 tl1.idcuenta
			,[idr] = (
				SELECT
					MIN(tl2.idr)
				FROM
					#_tmp_libro AS tl2
				WHERE
					tl2.idcuenta = tl1.idcuenta
			)
		FROM
			#_tmp_libro AS tl1
	) AS tlc
	LEFT JOIN #_tmp_libro AS tl
		ON tl.idr = tlc.idr

SELECT * 
FROM 
	#_tmp_libro
ORDER BY
	 cuenta
	,fecha

DROP TABLE #_tmp_libro
GO
