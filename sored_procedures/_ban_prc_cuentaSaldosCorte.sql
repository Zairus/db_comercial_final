USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100906
-- Description:	Informaci�n de cuenta bancaria para corte
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_cuentaSaldosCorte]
	@idcuenta AS INT
	,@fecha AS SMALLDATETIME = NULL
AS

DECLARE
	@corte_idtran AS INT
	,@corte_folio AS VARCHAR(15)
	,@error_mensaje AS VARCHAR(500)

SELECT
	@corte_idtran = bd.idtran
	,@corte_folio = bd.folio
FROM
	ew_ban_documentos AS bd
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = bd.idtran
WHERE
	st.idestado = 0
	AND bd.cancelado = 0
	AND bd.transaccion = 'BPR2'
	AND bd.idcuenta1 = @idcuenta

IF @corte_idtran IS NOT NULL
BEGIN
	SELECT @error_mensaje = 'Error: Existe el corte folio ' + @corte_folio + ', elaborado para esta caja. Favor de autorizar o cerrar el corte abierto.'

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

SELECT @fecha = CONVERT(VARCHAR(8), ISNULL(@fecha, GETDATE()), 3) + ' 00:00'

SELECT
	[no_cuenta] = bc.no_cuenta
	,[banco] = bb.nombre
	,[idmoneda] = bc.idmoneda
	,[tipocambio] = 1
	,[cargos] = ISNULL((
		SELECT 
			SUM(bt.importe) 
		FROM 
			ew_ban_transacciones AS bt 
		WHERE 
			bt.cancelado = 0 
			AND bt.idcuenta = 3 
			AND bt.tipo = 1
			AND CONVERT(VARCHAR(8), bt.fecha, 3) = @fecha
	), 0)
	,[abonos] = ISNULL((
		SELECT 
			SUM(bt.importe) 
		FROM 
			ew_ban_transacciones AS bt 
		WHERE 
			bt.cancelado = 0 
			AND bt.idcuenta = 3 
			AND bt.tipo = 2
			AND CONVERT(VARCHAR(8), bt.fecha, 3) = @fecha
	), 0)
	,[saldo_inicial] = [dbo].[fn_ban_saldoDia](bc.idcuenta, DATEADD(DAY, -1, @fecha))
	,[saldo_dia] = ISNULL((
		SELECT 
			SUM(CASE WHEN bt.tipo = 1 THEN bt.importe ELSE bt.importe * -1 END) 
		FROM 
			ew_ban_transacciones AS bt 
		WHERE 
			bt.cancelado = 0 
			AND bt.idcuenta = 3 
			AND bt.tipo IN (1,2) 
			AND CONVERT(VARCHAR(8), bt.fecha, 3) = @fecha
	), 0)
	,[saldo_actual] = [dbo].[fn_ban_saldoDia](bc.idcuenta, @fecha)

	,bc.idcuenta
	,[contabilidad_origen] = bc.contabilidad1
FROM
	ew_ban_cuentas AS bc
	LEFT JOIN ew_ban_bancos AS bb
		ON bb.idbanco = bc.idbanco
WHERE
	bc.idcuenta = @idcuenta
GO