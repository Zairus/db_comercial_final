USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171024
-- Description:	Surtir factura de venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaSurtir]
	@idtran AS INT
	, @cancelacion AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@usuario AS VARCHAR(20)
	, @password AS VARChAR(20)
	, @transaccion AS VARCHAR(4)
	, @idsucursal AS INT
	, @idalmacen AS INT
	, @sql AS VARCHAR(MAX) = ''
	, @inv_idtran AS INT
	, @folio AS VARCHAR(15)
	, @tipo AS SMALLINT

DECLARE
	@error_mensaje AS VARCHAR(1500)

SELECT
	@usuario = u.usuario
	, @password = u.[password]
	, @idsucursal = vt.idsucursal
	, @idalmacen = vt.idalmacen
	, @tipo = (
		CASE ISNULL(ct.tipo, 1)
			WHEN 1 THEN (CASE WHEN @cancelacion = 0 THEN 2 ELSE 1 END)
			WHEN 2 THEN (CASE WHEN @cancelacion = 0 THEN 1 ELSE 2 END)
		END
	)
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vt.idtran
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = vt.idu
WHERE
	vt.idtran = @idtran

SELECT @transaccion = (CASE WHEN @tipo = 2 THEN 'GDA1' ELSE 'GDC1' END)

SELECT TOP 1
	@error_mensaje = (
		'Error: '
		+ 'Para el producto "[' + a.codigo + '] ' + a.nombre + '", '
		+ 'no se ha indicado la cantidad por lote correctamente. '
		+ 'Cantidad esperada: ' 
		+ CONVERT(VARCHAR(20), (
			CASE 
				WHEN vt.transaccion = 'EDE1' THEN vtm.cantidad 
				ELSE vtm.cantidad_facturada 
			END
		)) 
		+ ', '
		+ 'Cantidad capturada: '
		+ CONVERT(VARCHAR(20), ISNULL((
			SELECT SUM(vtml.cantidad) 
			FROM 
				ew_ven_transacciones_mov_lotes AS vtml 
			WHERE 
				vtml.idtran = vtm.idtran 
				AND vtml.idarticulo = vtm.idarticulo
		), 0))
		+ '.'
	)
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtm.idtran
WHERE
	vtm.idtran = @idtran
	AND a.lotes > 0
	AND (
		(
			CASE 
				WHEN vt.transaccion = 'EDE1' THEN vtm.cantidad 
				ELSE vtm.cantidad_facturada 
			END
		)
		<> ISNULL((
			SELECT SUM(vtml.cantidad) 
			FROM 
				ew_ven_transacciones_mov_lotes AS vtml 
			WHERE 
				vtml.idtran = vtm.idtran 
				AND vtml.idarticulo = vtm.idarticulo
		), 0)
	)

IF @error_mensaje IS NOT NULL
BEGIN
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

IF EXISTS(
	SELECT	
		m.idarticulo 
	FROM	
		ew_ven_transacciones_mov AS m
		LEFT JOIN ew_articulos AS a 
			ON a.idarticulo = m.idarticulo
		LEFT JOIN ew_ven_transacciones AS vt
			ON vt.idtran = m.idtran
	WHERE
		(
			CASE 
				WHEN vt.transaccion = 'EDE1' THEN m.cantidad 
				ELSE m.cantidad_facturada 
			END
		) != 0
		AND a.inventariable = 1
		AND m.idtran = @idtran
	)
BEGIN
	EXEC _sys_prc_insertarTransaccion
		@usuario
		, @password
		, @transaccion
		, @idsucursal
		, 'A' --Serie
		, @sql
		, 6 --Longitod del folio
		, @inv_idtran OUTPUT
		, '' --Afolio
		, '' --Afecha
	
	IF @@ERROR != 0 OR @inv_idtran IS NULL OR @inv_idtran = 0
	BEGIN
		RAISERROR('No se pudo crear salida de almac�n.', 16, 1)
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
		, idu
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
		, idu
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
		, [lote] = COALESCE(vtml.lote, ic.lote, '')
		, [fecha_caducidad] = ISNULL(icl.fecha_caducidad, ic.fecha_caducidad)
		, [idcapa] = ISNULL(icl.idcapa, vtm.idcapa)
		, [idum] = vtm.idum
		, [cantidad] = (
			ISNULL(
				vtml.cantidad
				, (
					CASE 
						WHEN vt.transaccion = 'EDE1' THEN vtm.cantidad 
						ELSE vtm.cantidad_facturada 
					END
				)
			) 
			* um.factor
		)
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
		LEFT JOIN ew_ven_transacciones_mov_lotes AS vtml
			ON vtml.idtran = vtm.idtran
			AND vtml.idarticulo = vtm.idarticulo
		LEFT JOIN ew_inv_capas AS icl
			ON ic.idarticulo = vtm.idarticulo
			AND icl.lote = vtml.lote
		LEFT JOIN ew_ven_transacciones AS vt
			ON vt.idtran = vtm.idtran
	WHERE
		(
			ISNULL(
				vtml.cantidad
				, (
					CASE 
						WHEN vt.transaccion = 'EDE1' THEN vtm.cantidad 
						ELSE vtm.cantidad_facturada 
					END
				)
			) 
			* um.factor
		) != 0
		AND a.inventariable = 1
		AND vtm.idtran = @idtran

	IF @tipo = 2
	BEGIN
		UPDATE fcd SET
			fcd.costo = ISNULL((
				SELECT
					SUM(itm.costo)
				FROM
					ew_inv_transacciones AS it
					LEFT JOIN ew_inv_transacciones_mov AS itm
						ON itm.tipo = 2
						AND itm.idtran = it.idtran
						AND itm.idmov2 = fcd.idmov
				WHERE
					it.idtran2 = @idtran
			), 0)
		FROM 
			ew_ven_transacciones_mov AS fcd
		WHERE
			fcd.idtran = @idtran
	END
		
	--------------------------------------------------------------------
	-- Referenciando en el Tracking la salida de almacen
	INSERT INTO ew_sys_movimientos_acumula
		(idmov1, idmov2, campo, valor)
	VALUES
		(@idtran, @inv_idtran, '', 0)
END
GO
