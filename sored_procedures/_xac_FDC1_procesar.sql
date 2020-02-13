USE db_comercial_final
GO
IF OBJECT_ID('_xac_FDC1_procesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_FDC1_procesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200213
-- Description:	Procesar cargo a proveedor
-- =============================================
CREATE PROCEDURE [dbo].[_xac_FDC1_procesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idu AS INT
	, @fecha AS DATETIME
	, @bancario AS BIT
	, @idcuenta AS INT

DECLARE
	@usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @transaccion AS VARCHAR(4) = 'BDA1'
	, @idsucursal AS INT
	, @serie AS VARCHAR(1) = 'A'
	, @sql AS VARCHAR(MAX) = ''
	, @foliolen AS SMALLINT = 6
	, @bancos_idtran AS INT
	, @bancos_folio AS VARCHAR(15)
	, @afolio AS VARCHAR(15) = ''
	, @afecha AS VARCHAR(15) = ''
	, @concepto_cuenta AS VARCHAR(50)

SELECT
	@idu = ct.idu
	, @fecha = ct.fecha
	, @bancario = oc.bancario
	, @idcuenta = ct.idcuenta

	, @usuario = u.usuario
	, @password = u.[password]
	, @idsucursal = ct.idsucursal
	, @concepto_cuenta = ISNULL(oc.contabilidad, '')
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN objetos_conceptos AS oc
		ON oc.idconcepto = ct.idconcepto
		AND oc.objeto = o.objeto
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = ct.idu
WHERE
	ct.idtran = @idtran

IF @bancario = 1
BEGIN
	IF @idcuenta = 0
	BEGIN
		RAISERROR('Error: No se ha indicado cuenta bancaria a afectar para el concepto seleccionado.', 16, 1)
		RETURN
	END

	SELECT
		@afecha = CONVERT(VARCHAR(8), ct.fecha, 3)
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran

	EXEC _sys_prc_insertarTransaccion
		@usuario
		, @password
		, @transaccion
		, @idsucursal
		, @serie
		, @sql
		, @foliolen
		, @bancos_idtran OUTPUT
		, @afolio
		, @afecha

	IF @bancos_idtran IS NULL OR @bancos_idtran = 0
	BEGIN
		RAISERROR('Error: No se pudo generar transaccion de bancos.', 16, 1)
		RETURN
	END

	SELECT
		@bancos_folio = st.folio
	FROM
		ew_sys_transacciones AS st
	WHERE
		st.idtran = @bancos_idtran

	INSERT INTO ew_ban_transacciones (
		idtran
		, idtran2
		, idmov2
		, transaccion
		, fecha
		, folio
		, idconcepto
		, idcuenta
		, idsucursal
		, identidad
		, referencia
		, tipo
		, importe
		, iva
		, subtotal
		, impuesto
		, tipocambio
		, idforma
		, idu
		, comentario
		, idmoneda
	)
	SELECT
		[idtran] = @bancos_idtran
		, [idtran2] = ct.idtran
		, [idmov2] = ct.idmov
		, [transaccion] = @transaccion
		, [fecha] = ct.fecha
		, [folio] = @bancos_folio
		, [idconcepto] = ct.idconcepto
		, [idcuenta] = ct.idcuenta
		, [idsucursal] = ct.idsucursal
		, [identidad] = ct.idcliente
		, [referencia] = ct.transaccion + ' - ' + ct.folio
		, [tipo] = 2
		, [importe] = ct.total
		, [iva] = ct.idimpuesto1_valor
		, [subtotal] = ct.subtotal
		, [impuesto] = ct.impuesto1
		, [tipocambio] = ct.tipocambio
		, [idforma] = ct.idforma
		, [idu] = ct.idu
		, [comentario] = ct.comentario
		, [idmoneda] = ct.idmoneda
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran

	INSERT INTO ew_ban_transacciones_mov (
		idtran
		, consecutivo
		, idmov2
		, idconcepto
		, importe
		, idimpuesto
		, impuesto_tasa
		, impuesto
		, comentario
		, idtran2
	)
	SELECT
		[idtran] = @bancos_idtran
		, [consecutivo] = 1
		, [idmov2] = ct.idmov
		, [idconcepto] = ct.idconcepto
		, [importe] = ct.total
		, [idimpuesto] = ct.idimpuesto1
		, [impuesto_tasa] = ct.idimpuesto1_valor
		, [impuesto] = ct.impuesto1
		, [comentario] = ct.comentario
		, [idtran2] = ct.idtran
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran

	EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @idtran, 'FDC1', @idtran
END
	ELSE
BEGIN
	IF LEN(@concepto_cuenta) > 0
	BEGIN
		EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @idtran, 'FDC1_A', @idtran
	END
END

EXEC [dbo].[_xac_FDC1_procesarUUID] @idtran
GO
