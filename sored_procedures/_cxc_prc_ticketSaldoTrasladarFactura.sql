USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160415
-- Description:	Cancelar saldos de tickets
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_ticketSaldoTrasladarFactura]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idtran2 AS INT
	,@idsucursal AS INT
	,@abono_idtran AS INT
	,@fecha AS SMALLDATETIME
	,@folio AS VARCHAR(15)
	,@idu AS INT
	,@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@transaccion AS VARCHAR(5) = 'FDA1'
	,@sql AS VARCHAR(MAX) = ''

SELECT
	@idsucursal = ct.idsucursal
	,@fecha = ct.fecha
	,@idu = ct.idu
	,@usuario = u.usuario
	,@password = u.[password]
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = ct.idu
WHERE
	ct.idtran = @idtran

DECLARE cur_cancelaSaldos CURSOR FOR
	SELECT ctr.idtran2
	FROM 
		ew_cxc_transacciones_rel AS ctr
		LEFT JOIn ew_cxc_transacciones AS ct
			On ct.idtran = ctr.idtran2
	wHERE 
		ct.saldo > 0
		AND ctr.idtran = @idtran

OPEN cur_cancelaSaldos

FETCH NEXT FROM cur_cancelaSaldos INTO
	@idtran2

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC _sys_prc_insertarTransaccion 
		@usuario
		,@password
		,@transaccion
		,@idsucursal
		,'A' --serie
		,@sql
		,6 --foliolen
		,@abono_idtran OUTPUT
		,'' --afolio
		,@fecha --afecha
	
	SELECT
		@folio = st.folio
	FROM
		ew_sys_transacciones AS st
	WHERE
		st.idtran = @abono_idtran

	INSERT INTO ew_cxc_transacciones (
		idtran
		,idtran2
		,idconcepto
		,idsucursal
		,fecha
		,transaccion
		,folio
		,referencia
		,tipo
		,idcliente
		,idfacturacion
		,idmoneda
		,tipocambio
		,idimpuesto1
		,idimpuesto1_valor
		,idimpuesto2
		,idimpuesto2_valor
		,idimpuesto1_ret
		,idimpuesto1_ret_valor
		,idimpuesto2_ret
		,idimpuesto2_ret_valor
		,subtotal
		,impuesto1
		,impuesto2
		,impuesto3
		,impuesto4
		,impuesto1_ret
		,impuesto2_ret
		,redondeo
		,idu
		,comentario
	)
	SELECT
		[idtran] = @abono_idtran
		,[idtran2] = ct.idtran
		,[idconcepto] = 1
		,[idsucursal] = ct.idsucursal
		,[fecha] = @fecha
		,[transaccion] = @transaccion
		,[folio] = @folio
		,[referencia] = ''
		,[tipo] = 2
		,[idcliente] = ct.idcliente
		,[idfacturacion] = ct.idfacturacion
		,[idmoneda] = ct.idmoneda
		,[tipocambio] = ct.tipocambio
		,[idimpuesto1] = ct.idimpuesto1
		,[idimpuesto1_valor] = ct.idimpuesto1_ret
		,[idimpuesto2] = ct.idimpuesto2
		,[idimpuesto2_valor] = ct.idimpuesto2_valor
		,[idimpuesto1_ret] = ct.idimpuesto1_ret
		,[idimpuesto1_ret_valor] = ct.idimpuesto1_ret_valor
		,[idimpuesto2_ret] = ct.idimpuesto2_ret
		,[idimpuesto2_ret_valor] = ct.idimpuesto2_ret_valor
		,[subtotal] = ct.saldo
		,[impuesto1] = 0
		,[impuesto2] = 0
		,[impuesto3] = 0
		,[impuesto4] = 0
		,[impuesto1_ret] = 0
		,[impuesto2_ret] = 0
		,[redondeo] = 0
		,[idu] = @idu
		,[comentario] = 'Facturado'
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran2

	INSERT INTO ew_cxc_transacciones_mov (
		idtran
		,consecutivo
		,idtran2
		,fecha
		,tipocambio
		,importe
		,importe2
		,impuesto1
		,impuesto2
		,impuesto3
		,impuesto4
		,impuesto1_ret
		,impuesto2_ret
		,idu
	)
	SELECT
		[idtran] = @abono_idtran
		,[consecutivo] = 1
		,[idtran2] = ct.idtran
		,[fecha] = @fecha
		,[tipocambio] = ct.tipocambio
		,[importe] = ct.saldo
		,[importe2] = ct.saldo
		,[impuesto1] = 0
		,[impuesto2] = 0
		,[impuesto3] = 0
		,[impuesto4] = 0
		,[impuesto1_ret] = 0
		,[impuesto2_ret] = 0
		,[idu] = @idu
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran2

	EXEC _cxc_prc_aplicarTransaccion
		@abono_idtran
		,@fecha
		,@idu
	
	FETCH NEXT FROM cur_cancelaSaldos INTO
		@idtran2
END

CLOSE cur_cancelaSaldos
DEALLOCATE cur_cancelaSaldos
GO
