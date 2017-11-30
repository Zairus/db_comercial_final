USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151216
-- Description:	Migracion de saldos inciales CXC
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_migrarSaldosIniciales]
	@prueba AS BIT = 1
AS

SET NOCOUNT ON

BEGIN TRAN

DECLARE
	@transaccion AS VARCHAR(4)
	,@idr AS INT
	,@idconcepto AS INT = 21
	,@usuario AS VARCHAR(20) = 'IMPLEMENT'
	,@password AS VARCHAR(20) = '_admin'
	,@idsucursal AS INT
	,@serie AS VARCHAR(3) = ''
	,@carga_idtran AS INT
	,@folio AS VARCHAR(15)

DECLARE cur_cxcMigracion CURSOR FOR
	SELECT
		cm.idr
		,[transaccion] = (CASE WHEN cm.saldo < 0 THEN 'FDA1' ELSE 'FDC1' END)
		,cm.idsucursal
	FROM 
		ew_cxc_migracion AS cm
	WHERE
		cm.saldo <> 0
		AND cm.importe <> 0
		AND cm.idcliente IN (
			SELECT c.idcliente 
			FROM ew_clientes AS c
		)

OPEN cur_cxcMigracion

FETCH NEXT FROM cur_cxcMigracion INTO
	@idr
	,@transaccion
	,@idsucursal

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC _sys_prc_insertarTransaccion
		@usuario
		,@password
		,@transaccion
		,@idsucursal
		,@serie
		,'' --SQL
		,6 --foliolen
		,@carga_idtran OUTPUT
	
	SELECT
		@folio = folio
	FROM
		ew_sys_transacciones AS st
	WHERE
		st.idtran = @carga_idtran

	INSERT INTO ew_cxc_transacciones (
		idtran
		,idconcepto
		,idsucursal
		,fecha
		,vencimiento
		,transaccion
		,folio
		,referencia
		,tipo
		,idcliente
		,credito
		,credito_dias
		,idmoneda
		,tipocambio
		,tipocambio_dof
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
		,saldo
		,idu
		,comentario
	)
	SELECT
		[idtran] = @carga_idtran
		,[idconcepto] = @idconcepto
		,[idsucursal] = @idsucursal
		,[fecha] = cm.fecha
		,[vencimiento] = cm.vencimiento
		,[transaccion] = @transaccion
		,[folio] = cm.folio
		,[referencia] = CONVERT(VARCHAR(20), @idr)
		,[tipo] = (CASE WHEN cm.saldo > 0 THEN 1 ELSE 2 END)
		,[idcliente] = cm.idcliente
		,[credito] = (CASE WHEN DATEDIFF(DAY, cm.fecha, cm.vencimiento) > 0 THEN 1 ELSE 0 END)
		,[credito_dias] = DATEDIFF(DAY, cm.fecha, cm.vencimiento)
		,[idmoneda] = cm.idmoneda
		,[tipocambio] = dbo.fn_ban_obtenerTC(cm.idmoneda, cm.fecha)
		,[tipocambio_dof] = dbo.fn_ban_obtenerTC(cm.idmoneda, cm.fecha)
		,[idimpuesto1] = 1
		,[idimpuesto1_valor] = (cm.impuesto1 / cm.importe)
		,[idimpuesto2] = 11
		,[idimpuesto2_valor] = (cm.impuesto2 / cm.importe)
		,[idimpuesto1_ret] = 0
		,[idimpuesto1_ret_valor] = 0
		,[idimpuesto2_ret] = 0
		,[idimpuesto2_ret_valor] = 0
		,[subtotal] = (
			cm.saldo
			-(cm.saldo * (cm.impuesto1 / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret)))
			-(cm.saldo * (cm.impuesto2 / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret)))
			-(cm.saldo * (cm.impuesto3 / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret)))
			-(cm.saldo * (cm.impuesto4 / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret)))
			+(cm.saldo * (cm.impuesto1_ret / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret)))
			+(cm.saldo * (cm.impuesto2_ret / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret)))
		)
		,[impuesto1] = cm.saldo * (cm.impuesto1 / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret))
		,[impuesto2] = cm.saldo * (cm.impuesto2 / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret))
		,[impuesto3] = cm.saldo * (cm.impuesto3 / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret))
		,[impuesto4] = cm.saldo * (cm.impuesto4 / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret))
		,[impuesto1_ret] = cm.saldo * (cm.impuesto1_ret / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret))
		,[impuesto2_ret] = cm.saldo * (cm.impuesto2_ret / (cm.importe + cm.impuesto1 + cm.impuesto2 + cm.impuesto3 + cm.impuesto4 - cm.impuesto1_ret - cm.impuesto2_ret))
		,[saldo] = 0
		,[idu] = 1
		,[comentario] = 'De carga automatica'
	FROM
		ew_cxc_migracion AS cm
	WHERE
		cm.idr = @idr
	
	FETCH NEXT FROM cur_cxcMigracion INTO
		@idr
		,@transaccion
		,@idsucursal
END

CLOSE cur_cxcMigracion
DEALLOCATE cur_cxcMigracion

SELECT
	ct.idtran
	,ct.transaccion
	,ct.idsucursal
	,ct.fecha
	,ct.folio
	,ct.idcliente
	,ct.referencia
	,ct.subtotal
	,ct.impuesto1
	,ct.impuesto2
	,ct.total
	,ct.saldo

	,cm.saldo
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_migracion AS cm
		ON cm.idr = LTRIM(RTRIM(STR(ct.referencia)))
WHERE
	ct.idconcepto = @idconcepto

IF @prueba = 1
BEGIN
	SELECT [resultado] = '** Efectuado en modo pruebas'
	ROLLBACK TRAN
END
	ELSE
BEGIN
	COMMIT TRAN
END
GO
