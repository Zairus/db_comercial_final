USE db_comercial_final
GO
IF OBJECT_ID('_ban_prc_bdt2_obtenerPagos') IS NOT NULL
BEGIN
	DROP PROCEDURE _ban_prc_bdt2_obtenerPagos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190503
-- Description:	Obtener pagos para integracion de deposito
-- =============================================
CREATE PROCEDURE [dbo].[_ban_prc_bdt2_obtenerPagos]
	@fecha_inicial AS DATETIME
	, @fecha_final AS DATETIME
	, @idcuenta AS INT
	, @formas AS VARCHAR(MAX)
AS

SET NOCOUNT ON

SELECT @fecha_inicial = CONVERT(DATETIME, CONVERT(VARCHAR(10), @fecha_inicial, 103) + ' 00:00')
SELECT @fecha_final = CONVERT(DATETIME, CONVERT(VARCHAR(10), @fecha_final, 103) + ' 23:59')

CREATE TABLE #_tmp_formas (
	idr INT IDENTITY
	, seleccionar BIT
	, nombre VARCHAR(200)
	, idforma INT
)

IF CHARINDEX('|', @formas) > 0
BEGIN
	INSERT INTO #_tmp_formas (
		seleccionar
		, nombre
		, idforma
	)
	SELECT
		[seleccionar] = REPLACE(dbo.fn_sys_campoDeCadena(valor, '|', 1), '-', '')
		, [nombre] = dbo.fn_sys_campoDeCadena(valor, '|', 2)
		, [idforma] = dbo.fn_sys_campoDeCadena(valor, '|', 3)
	FROM 
		dbo._sys_fnc_separarMultilinea(@formas, '	')
END
	ELSE
BEGIN
	INSERT INTO #_tmp_formas (
		seleccionar
		, nombre
		, idforma
	)
	SELECT
		[seleccionar] = REPLACE(dbo.fn_sys_campoDeCadena(valor, '	', 1), '-', '')
		, [nombre] = dbo.fn_sys_campoDeCadena(valor, '	', 2)
		, [idforma] = dbo.fn_sys_campoDeCadena(valor, '	', 3)
	FROM 
		dbo._sys_fnc_separarMultilinea(@formas, CHAR(13))
END

SELECT
	[ref_forma] = bf.nombre
	, [ref_fecha] = bt.fecha
	, [ref_movimiento] = o.nombre
	, [ref_folio] = bt.folio

	, [idforma] = bt.idforma
	, [cantidad] = 1

	, [pago_total] = bt.importe
	, [pago_saldo] = (
		bt.importe 
		- ISNULL((
			SELECT SUM(bdm1.importe) 
			FROM 
				ew_ban_documentos_mov AS bdm1 
				LEFT JOIN ew_ban_documentos AS bd1 
					ON bd1.idtran = bdm1.idtran
			WHERE
				bdm1.idtran2 = bt.idtran
				AND bd1.cancelado = 0
		), 0)
	)
	, [importe] = (
		bt.importe 
		- ISNULL((
			SELECT SUM(bdm1.importe) 
			FROM 
				ew_ban_documentos_mov AS bdm1 
				LEFT JOIN ew_ban_documentos AS bd1 
					ON bd1.idtran = bdm1.idtran
			WHERE
				bdm1.idtran2 = bt.idtran
				AND bd1.cancelado = 0
		), 0)
	)
	
	, [comentario] = ''

	, [idtran2] = bt.idtran
	, [objidtran] = bt.idtran
FROM 
	ew_ban_transacciones AS bt 
	LEFT JOIN objetos AS o
		ON o.codigo = bt.transaccion
	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = bt.idforma
WHERE 
	bt.cancelado = 0 
	AND bt.tipo = 1 
	AND bt.idforma IN (
		SELECT tf.idforma 
		FROM #_tmp_formas AS tf 
		WHERE tf.seleccionar = 1
	)
	AND bt.idcuenta = @idcuenta
	AND bt.fecha BETWEEN @fecha_inicial AND @fecha_final

	AND (
		bt.importe 
		- ISNULL((
			SELECT SUM(bdm1.importe) 
			FROM 
				ew_ban_documentos_mov AS bdm1 
				LEFT JOIN ew_ban_documentos AS bd1 
					ON bd1.idtran = bdm1.idtran
			WHERE
				bdm1.idtran2 = bt.idtran
				AND bd1.cancelado = 0
		), 0)
	) > 0

ORDER BY
	bt.idforma
	, bt.transaccion
	, bt.folio
GO
