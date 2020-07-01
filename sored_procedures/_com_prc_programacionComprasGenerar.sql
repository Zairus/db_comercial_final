USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_programacionComprasGenerar') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_programacionComprasGenerar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091008
-- Description:	Generación de ordenes de compras de programación
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_programacionComprasGenerar]
	@idtran AS BIGINT
	, @idu AS SMALLINT = 1
AS

SET NOCOUNT ON

DECLARE	
	@idproveedor AS INT
	, @fecha AS SMALLDATETIME
	, @subtotal AS DECIMAL(12,2)

DECLARE
	@idzona_fiscal_emisor AS INT
	, @extranjero AS BIT

DECLARE	
	@usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @sql AS VARCHAR(8000)
	, @orden_idtran AS INT
	, @transaccion AS VARCHAR(4)
	, @idsucursal AS SMALLINT
	, @serie AS VARCHAR(25) = 'A'
	, @foliolen AS TINYINT = 6
	, @afolio AS VARCHAR(10) = ''
	, @afecha AS VARCHAR(20) = ''

SELECT 
	@fecha = GETDATE()

-- ########################################################
-- OBTENER DATOS

IF EXISTS (
	SELECT * 
	FROM 
		ew_com_programacion_det 
	WHERE 
		cantidad_ordenada = 0 
		AND idtran = @idtran
)
BEGIN
	RAISERROR('Error: Se debe indicar cantidad a ordenar en todos los registros.', 16, 1)
	RETURN
END

IF EXISTS (
	SELECT * 
	FROM 
		ew_com_programacion_det 
	WHERE 
		idproveedor = 0 
		AND idtran = @idtran
)
BEGIN
	RAISERROR('Error: Se debe indicar proveedor en todos los registros.', 16, 1)
	RETURN
END

SELECT
	@transaccion = 'COR1'
	, @idsucursal = idsucursal
FROM
	ew_com_programacion
WHERE
	idtran = @idtran

SELECT
	@usuario = usuario
	, @password = [password]
FROM 
	ew_usuarios
WHERE
	idu = @idu
	
-- ########################################################
-- GENERAR ORDENES DE COMPRA

DECLARE cur_proveedores CURSOR FOR
	SELECT DISTINCT 
		idproveedor
	FROM
		ew_com_programacion_det
	WHERE
		idproveedor > 0
		AND cantidad_ordenada > 0
		AND idtran = @idtran

OPEN cur_proveedores

FETCH NEXT FROM cur_proveedores INTO
	@idproveedor

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT 
		@subtotal = SUM(costo_total) 
	FROM
		ew_com_programacion_det 
	WHERE 
		idtran = @idtran 
		AND idproveedor = @idproveedor
	
	SELECT @subtotal = ISNULL(@subtotal, 0)
	
	SELECT 
		@idzona_fiscal_emisor = [dbo].[_ct_fnc_idzonaFiscalCP](p.codigo_postal)
		, @extranjero = p.extranjero
	FROM
		ew_proveedores AS p
	WHERE
		p.idproveedor = @idproveedor

	SELECT @idzona_fiscal_emisor = ISNULL(@idzona_fiscal_emisor, 1)
	SELECT @extranjero = ISNULL(@extranjero, 0)

	SELECT @sql = ''
	
	EXEC _sys_prc_insertarTransaccion
		@usuario
		, @password
		, @transaccion
		, @idsucursal
		, @serie
		, @sql
		, @foliolen
		, @orden_idtran OUTPUT
		, @afolio
		, @afecha

	IF @orden_idtran IS NULL OR @orden_idtran = 0
	BEGIN
		RAISERROR('No se pudo generar orden de compra.', 16, 1)
		RETURN
	END
	
	INSERT INTO ew_com_ordenes (
		idtran
		, idmov
		, idtran2
		, idconcepto
		, idsucursal
		, idalmacen
		, fecha
		, folio
		, transaccion
		, idproveedor
		, idcontacto
		, dias_entrega
		, dias_credito
		, pedimento
		, idpedimento
		, idu
		, idimpuesto1
		, idmoneda
		, tipocambio
		, subtotal
		, gastos
		, impuesto1
		, impuesto2
		, impuesto3
		, impuesto4
		, total
		, comentario
		, cancelado
		, cancelado_fecha
	)
	SELECT
		[idtran] = st.idtran
		, [idmov] = NULL
		, [idtran2] = cprg.idtran
		, [idconcepto] = 16
		, [idsucursal] = cprg.idsucursal
		, [idalmacen] = (
			SELECT TOP 1 cprgd.idalmacen 
			FROM 
				ew_com_programacion_det AS cprgd 
			WHERE 
				cprgd.idtran = cprg.idtran
		)
		, [fecha] = cprg.fecha
		, [folio] = st.folio
		, [transaccion] = st.transaccion
		, [idproveedor] = @idproveedor
		, [idcontacto] = 0
		, [dias_entrega] = p.plazo_entrega
		, [dias_credito] = ptr.credito_plazo
		, [pedimento] = ''
		, [idpedimento] = 0
		, [idu] = cprg.idu
		, [idimpuesto1] = 0
		, [idmoneda] = 0
		, [tipocambio] = 1
		, [subtotal] = @subtotal
		, [gastos] = 0
		, [impuesto1] = 0
		, [impuesto2] = 0
		, [impuesto3] = 0
		, [impuesto4] = 0
		, [total] = @subtotal
		, [comentario] = cprg.comentario
		, [cancelado] = 0
		, [cancelado_fecha] = NULL
	FROM
		ew_sys_transacciones AS st
		LEFT JOIN ew_com_programacion AS cprg
			ON cprg.idtran = @idtran
		LEFT JOIN ew_proveedores AS p
			ON p.idproveedor = @idproveedor
		LEFT JOIN ew_proveedores_terminos AS ptr
			ON ptr.idproveedor = @idproveedor
	WHERE
		st.idtran = @orden_idtran
		
	INSERT INTO ew_com_ordenes_mov (
		idtran
		, consecutivo
		, idmov2
		, idarticulo
		, codigo_proveedor
		, idum
		, idalmacen
		, existencia
		, cantidad_ordenada
		, cantidad_autorizada
		, costo_unitario
		, importe
		, comentario
	)
	SELECT
		[idtran] = st.idtran
		, [consecutivo] = ROW_NUMBER() OVER (ORDER BY cprgd.idr)
		, [idmov2] = cprgd.idmov
		, [idarticulo] = cprgd.idarticulo
		, [codigo_proveedor] = ISNULL(ap.codigo_proveedor, '')
		, [idum] = a.idum_compra
		, [idalmacen] = cprgd.idalmacen
		, [existencia] = ISNULL(aa.existencia, 0)
		, [cantidad_ordenada] = cprgd.cantidad_ordenada
		, [cantidad_autorizada] = cprgd.cantidad_ordenada
		, [costo_unitario] = cprgd.costo_unitario
		, [importe] = cprgd.costo_total
		, [comentario] = cprgd.comentario
	FROM
		ew_sys_transacciones AS st
		LEFT JOIN ew_com_programacion_det AS cprgd
			ON cprgd.idtran = @idtran
		LEFT JOIN ew_proveedores AS p
			ON p.idproveedor = cprgd.idproveedor
		LEFT JOIN ew_articulos AS a
			ON a.idarticulo = cprgd.idarticulo
		LEFT JOIN ew_articulos_almacenes AS aa
			ON aa.idarticulo = cprgd.idarticulo
			AND aa.idalmacen = cprgd.idalmacen
		LEFT JOIN ew_articulos_proveedores AS ap
			ON ap.idarticulo = cprgd.idarticulo
			AND ap.idproveedor = cprgd.idproveedor
	WHERE
		st.idtran = @orden_idtran
		AND cprgd.idproveedor = @idproveedor

	-- IMPUESTOS
	UPDATE com SET
		com.idimpuesto1 = ISNULL(cai.idimpuesto1, 0)
		, com.idimpuesto1_valor = ISNULL(cai.idimpuesto1_valor, 0)
		, com.idimpuesto2 = ISNULL(cai.idimpuesto2, 0)
		, com.idimpuesto2_valor = ISNULL(cai.idimpuesto2_valor, 0)
		, com.idimpuesto1_ret = ISNULL(cai.idimpuesto1_ret, 0)
		, com.idimpuesto1_ret_valor = ISNULL(cai.idimpuesto1_ret_valor, 0)
		, com.idimpuesto2_ret = ISNULL(cai.idimpuesto2_ret, 0)
		, com.idimpuesto2_ret_valor = ISNULL(cai.idimpuesto2_ret_valor, 0)
	FROM
		ew_com_ordenes_mov AS com
		LEFT JOIN ew_articulos AS a
			ON a.idarticulo = com.idarticulo
		LEFT JOIN ew_ct_articulos_impuestos AS cai
			ON cai.idarticulo = a.idarticulo
			AND (
				cai.idzona = @idzona_fiscal_emisor
				OR cai.idzona = 0
			)
			AND @extranjero = 0
	WHERE
		com.idtran = @orden_idtran

	UPDATE com SET
		com.idimpuesto1 = com.importe * com.idimpuesto1_valor
		, com.idimpuesto2 = com.importe * com.idimpuesto2_valor
		, com.idimpuesto1_ret = com.importe * com.idimpuesto1_ret_valor
		, com.idimpuesto2_ret = com.importe * com.idimpuesto2_ret_valor
	FROM
		ew_com_ordenes_mov AS com
	WHERE
		com.idtran = @orden_idtran

	UPDATE com SET
		com.total = (
			com.importe
			+ com.impuesto1
			+ com.impuesto2
			- com.impuesto1_ret
		)
	FROM
		ew_com_ordenes_mov AS com
	WHERE
		com.idtran = @orden_idtran

	UPDATE co SET
		co.subtotal = ISNULL((
			SELECT SUM(com.importe) 
			FROM 
				ew_com_ordenes_mov AS com 
			WHERE 
				com.idtran = co.idtran
		), 0)
		, co.impuesto1 = ISNULL((
			SELECT SUM(com.impuesto1) 
			FROM 
				ew_com_ordenes_mov AS com 
			WHERE 
				com.idtran = co.idtran
		), 0)
		, co.impuesto2 = ISNULL((
			SELECT SUM(com.impuesto2) 
			FROM 
				ew_com_ordenes_mov AS com 
			WHERE 
				com.idtran = co.idtran
		), 0)
		, co.impuesto1_ret = ISNULL((
			SELECT SUM(com.impuesto1_ret) 
			FROM 
				ew_com_ordenes_mov AS com 
			WHERE 
				com.idtran = co.idtran
		), 0)
		, co.idimpuesto1 = ISNULL((
			SELECT TOP 1
				com.idimpuesto1
			FROM
				ew_com_ordenes_mov AS com
			WHERE
				com.idtran = @idtran
			ORDER BY
				com.idr
		), 0)
		, co.idimpuesto1_ret = ISNULL((
			SELECT TOP 1
				com.idimpuesto1_ret
			FROM
				ew_com_ordenes_mov AS com
			WHERE
				com.idtran = @idtran
			ORDER BY
				com.idr
		), 0)
	FROM
		ew_com_ordenes AS co
	WHERE
		co.idtran = @idtran
		
	UPDATE co SET
		co.total = (
			co.subtotal
			+ co.impuesto1
			+ co.impuesto2
			+ co.impuesto3
			+ co.impuesto4
			- co.impuesto1_ret
		)
	FROM
		ew_com_ordenes AS co
	WHERE
		co.idtran = @idtran

	INSERT INTO ew_sys_transacciones2
		(idtran, idestado, idu)
	VALUES
		(@orden_idtran, 3, @idu)

	FETCH NEXT FROM cur_proveedores INTO
		@idproveedor
END

CLOSE cur_proveedores
DEALLOCATE cur_proveedores

--------------------------------------------------------------------------------
-- CAMBIAR ESTADO DE LA PROGRAMACIÓN ###########################################

INSERT INTO ew_sys_transacciones2
	(idtran, idestado, idu)
VALUES
	(@idtran, 13, @idu)
GO
