USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171024
-- Description:	Surtir factura de venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaSurtir]
	@idtran AS INT
	,@cancelacion AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@usuario AS VARCHAR(20)
	,@password AS VARChAR(20)
	,@transaccion AS VARCHAR(4)
	,@idsucursal AS INT
	,@idalmacen AS INT
	,@sql AS VARCHAR(MAX) = ''
	,@inv_idtran AS INT
	,@folio AS VARCHAR(15)
	,@tipo AS SMALLINT

SELECT
	@usuario = u.usuario
	,@password = u.[password]
	,@idsucursal = vt.idsucursal
	,@idalmacen = vt.idalmacen
	,@tipo = (CASE WHEN @cancelacion = 0 THEN 2 ELSE 1 END)
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = vt.idu
WHERE
	vt.idtran = @idtran

SELECT @transaccion = (CASE WHEN @tipo = 2 THEN 'GDA1' ELSE 'GDC1' END)

IF EXISTS(
	SELECT	
		m.idarticulo 
	FROM	
		ew_ven_transacciones_mov AS m
		LEFT JOIN ew_articulos AS a 
			ON a.idarticulo = m.idarticulo
	WHERE
		m.cantidad_facturada != 0
		AND m.cantidad_surtida != 0
		AND a.inventariable = 1
		AND idtran = @idtran
	)
BEGIN
	EXEC _sys_prc_insertarTransaccion
		@usuario
		,@password
		,@transaccion
		,@idsucursal
		,'A' --Serie
		,@sql
		,6 --Longitod del folio
		,@inv_idtran OUTPUT
		,'' --Afolio
		,'' --Afecha
	
	IF @@ERROR != 0 OR @inv_idtran IS NULL OR @inv_idtran = 0
	BEGIN
		RAISERROR('No se pudo crear salida de almacén.', 16, 1)
		RETURN
	END

	SELECT
		@folio = st.folio
	FROM
		ew_sys_transacciones AS st
	WHERE
		st.idtran = @inv_idtran

	INSERT INTO ew_inv_transacciones (
		idtran
		, idtran2
		, idsucursal
		, idalmacen
		, fecha
		, folio
		, transaccion
		, referencia
		, comentario
		, idconcepto
	)
	SELECT
		[idtran] = @inv_idtran
		, [idtran2] = vt.idtran
		, [idsucursal] = @idsucursal
		, [idalmacen] = @idalmacen
		, [fecha] = vt.fecha
		, [folio] = @folio
		, [transaccion] = @transaccion
		, [referencia] = vt.transaccion + ' - ' + vt.folio
		, [comentario] = vt.comentario
		, [idconcepto] = 19
	FROM
		ew_ven_transacciones AS vt
	WHERE
		vt.idtran = @idtran

	INSERT INTO ew_inv_transacciones_mov (
		idtran
		, idtran2
		, idmov2
		, consecutivo
		, tipo
		, idalmacen
		, idarticulo
		, series
		, lote
		, fecha_caducidad
		, idcapa
		, idum
		, cantidad
		, costo
		, afectainv
		, comentario
	)
	SELECT
		[idtran] = @inv_idtran
		, [idtran2] = vtm.idtran
		, [idmov2] = vtm.idmov
		, [consecutivo] = ROW_NUMBER() OVER (ORDER BY vtm.idmov)
		, [tipo] = @tipo
		, [idalmacen] = @idalmacen
		, [idarticulo] = vtm.idarticulo
		, [series] = vtm.series
		, [lote] = ISNULL(ic.lote, '')
		, [fecha_caducidad] = NULL
		, [idcapa] = vtm.idcapa
		, [idum] = vtm.idum
		, [cantidad] = (vtm.cantidad_surtida * um.factor)
		, [costo] = (CASE WHEN @tipo = 2 THEN 0 ELSE vtm.costo END)
		, [afectainv] = 1
		, [comentario] = vtm.comentario
	FROM
		ew_ven_transacciones_mov AS vtm
		LEFT JOIN ew_articulos AS a 
			ON a.idarticulo = vtm.idarticulo
		LEFT JOIN ew_cat_unidadesmedida AS um 
			ON vtm.idum = um.idum
		LEFT JOIN ew_inv_capas AS ic 
			ON vtm.idcapa = ic.idcapa 
			AND vtm.idarticulo = ic.idarticulo
	WHERE
		vtm.cantidad_facturada != 0
		AND vtm.cantidad_surtida != 0
		AND a.inventariable = 1
		AND vtm.idtran = @idtran

	UPDATE fcd SET
		fcd.costo = ISNULL(itm.costo, 0)
	FROM 
		ew_ven_transacciones_mov AS fcd
		LEFT JOIN ew_inv_transacciones_mov AS itm 
			ON itm.idmov2 = fcd.idmov 
			AND itm.tipo = 2
		LEFT JOIN ew_inv_transacciones AS it ON 
			it.idtran = itm.idtran
	WHERE
		fcd.idtran = @idtran
		AND it.idtran2 = @idtran
		
	--------------------------------------------------------------------
	-- Referenciando en el Tracking la salida de almacen
	INSERT INTO ew_sys_movimientos_acumula
		(idmov1, idmov2, campo, valor)
	VALUES
		(@idtran, @inv_idtran, '', 0)
END
GO
