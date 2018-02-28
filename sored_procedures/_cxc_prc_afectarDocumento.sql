USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180220
-- Description:	Afectar documento CXC
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_afectarDocumento]
	@idtran AS INT
	,@fecha AS SMALLDATETIME
	,@tipo AS TINYINT
	,@importe AS DECIMAL(18,6)
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@usuario VARCHAR(20)
	,@password VARCHAR(20)
	,@transaccion VARCHAR(5)
	,@idsucursal INT
	,@serie VARCHAR(3) = 'A'
	,@sql VARCHAR(MAX) = ''
	,@foliolen TINYINT = 6
	,@cxc_idtran INT
	,@poliza_idtran INT
	,@afolio VARCHAR(10) = ''
	,@afecha VARCHAR(20) = CONVERT(VARCHAR(8), @fecha, 3)

SELECT
	@usuario = usuario
	,@password = [password]
FROM
	evoluware_usuarios
WHERE
	idu = @idu

SELECT @transaccion = (CASE WHEN @tipo = 1 THEN 'FDC1' ELSE 'FDA1' END)

SELECT
	@idsucursal = idsucursal
FROM
	ew_sys_transacciones
WHERE
	idtran = @idtran

EXEC _sys_prc_insertarTransaccion
	@usuario
	,@password
	,@transaccion
	,@idsucursal
	,@serie
	,@sql
	,@foliolen
	,@cxc_idtran OUTPUT
	,@afolio
	,@afecha

INSERT INTO ew_cxc_transacciones (
	idtran
	,idconcepto
	,idsucursal
	,fecha
	,transaccion
	,folio
	,referencia
	,tipo
	,idcliente
	,idmoneda
	,tipocambio
	,tipocambio_dof
	,subtotal
	,idu
	,comentario
)
SELECT
	[idtran] = st.idtran
	,[idconcepto] = 31
	,[idsucursal] = st.idsucursal
	,[fecha] = st.fecha
	,[transaccion] = st.transaccion
	,[folio] = st.folio
	,[referencia] = ''
	,[tipo] = @tipo
	,[idcliente] = ct.idcliente
	,[idmoneda] = ct.idmoneda
	,[tipocambio] = ct.tipocambio
	,[tipocambio_dof] = dbo.fn_ban_obtenerTC(ct.idmoneda, @fecha)
	,[subtotal] = @importe
	,[idu] = @idu
	,[comentario] = ''
FROM
	ew_sys_transacciones AS st
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = @idtran
WHERE
	st.idtran = @cxc_idtran

INSERT INTO ew_cxc_transacciones_mov (
	idtran
	,consecutivo
	,idtran2
	,fecha
	,tipocambio
	,importe
	,importe2
	,idu
	,comentario
)
SELECT
	[idtran] = st.idtran
	,[consecutivo] = 1
	,[idtran2] = ct.idtran
	,[fecha] = st.fecha
	,[tipocambio] = ct.tipocambio
	,[importe] = @importe
	,[importe2] = @importe
	,[idu] = @idu
	,[comentario] = ''
FROM
	ew_sys_transacciones AS st
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = @idtran
WHERE
	st.idtran = @cxc_idtran

EXEC _cxc_prc_aplicarTransaccion
	@cxc_idtran
	,@fecha
	,@idu

EXEC _ct_prc_polizaAplicarDeConfiguracion @cxc_idtran, 'FDC1_A', @cxc_idtran, @poliza_idtran OUTPUT
GO
