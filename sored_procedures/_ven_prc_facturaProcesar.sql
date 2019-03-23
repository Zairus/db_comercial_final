USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091113
-- Description:	Procesar factura de cliente.
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaProcesar]
	@idtran AS BIGINT
AS

SET NOCOUNT ON

DECLARE
	@surtir AS BIT
	, @registros AS INT
	, @mayoreo BIT
	, @error_mensaje AS VARCHAR(MAX)

DECLARE
	@idu AS SMALLINT
	, @idtran2 AS INT
	, @idarticulo AS INT
	, @nombrearticulo AS VARCHAR(200)=''
	, @comentario AS VARCHAR(MAX) = ''
	, @descripcion AS VARCHAR(MAX) = ''

DECLARE
	@idcliente AS INT
	, @rfc AS VARCHAR(20)
	, @idfacturacion AS INT

-- Re-Generar consecutivo porque a veces pasa que se repiten 
-- y deja un solo renglón en la factura porque agrupa por ese consecutivo
EXEC [dbo].[_sys_prc_genera_consecutivo] @idtran, ''

SELECT @surtir = [dbo].[_sys_fnc_parametroActivo]('VEN_SURFAC')

SELECT
	@idtran2 = vt.idtran2
	, @idu = vt.idu
	, @idcliente = vt.idcliente
	, @idfacturacion = (SELECT TOP 1 cfa.idfacturacion FROM ew_clientes_facturacion AS cfa WHERE cfa.idcliente = vt.idcliente)
	, @surtir = (CASE WHEN @surtir = 0 THEN 0 ELSE (CASE WHEN ISNULL(vo.remisionar, 0) = 1 THEN 0 ELSE @surtir END) END)
FROM 
	ew_ven_transacciones AS vt
	LEFT JOIN ew_ven_ordenes AS vo
		ON vo.idtran = vt.idtran2
WHERE
	vt.idtran = @idtran

SELECT
	@rfc = cf.rfc
	, @mayoreo = ISNULL(c.mayoreo, 0)
FROM
	ew_clientes_facturacion AS cf
	LEFT JOIN ew_sys_ciudades AS cd
		ON cd.idciudad = cf.idciudad
	LEFT JOIN ew_clientes c
		ON c.idcliente=cf.idcliente
WHERE
	cf.idcliente = @idcliente
	AND cf.idfacturacion = @idfacturacion

IF [dbo].[fn_sys_validaRFC](@rfc) = 0
BEGIN
	RAISERROR('Error: Hay un error con el RFC del cliente.', 16, 1)
	RETURN
END

IF @surtir = 1
BEGIN
	EXEC [dbo].[_ven_prc_facturaSurtir] @idtran, 0
END

IF EXISTS(SELECT * FROM ew_cxc_transacciones WHERE cfd_iduso = 0 AND idtran = @idtran)
BEGIN
	RAISERROR('Error: No se ha indicado uso para comprobante fiscal.', 16, 1)
	RETURN
END

--------------------------------------------------------------------
-- Surtimos la mercancia en la orden 
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	, idmov2
	, campo
	, valor
)
SELECT 
	[idmov] = m.idmov
	, [idmov2] = m.idmov2
	, [campo] = 'cantidad_surtida'
	, [valor] = m.cantidad_surtida
FROM	
	ew_ven_transacciones_mov AS m
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = m.idarticulo
WHERE 
	m.cantidad_surtida > 0
	AND a.inventariable = 1
	AND @surtir = 1
	AND idtran = @idtran

--------------------------------------------------------------------
-- Indicamos la mercancia facturada en la orden 
--------------------------------------------------------------------
INSERT INTO ew_sys_movimientos_acumula (
	idmov1
	, idmov2
	, campo
	, valor
)
SELECT 
	[idmov] = idmov
	, [idmov2] = idmov2
	, [campo] = 'cantidad_facturada'
	, [valor] = cantidad_facturada 
FROM	
	ew_ven_transacciones_mov
WHERE 
	cantidad_facturada > 0
	AND idtran = @idtran

EXEC _ven_prc_facturaPagos @idtran

--------------------------------------------------------------------
-- Cambiamos el estado de la orden
--------------------------------------------------------------------
IF EXISTS(
	SELECT *
	FROM
		ew_ven_transacciones_mov AS vtm
		LEFT JOIN ew_articulos AS a
			ON a.idarticulo = vtm.idarticulo
	WHERE
		vtm.idtran = @idtran
		AND LEN(ISNULL(a.nombre, '') + CONVERT(VARCHAR(MAX), vtm.comentario)) > 1000
)
BEGIN
	SELECT
		@error_mensaje = (
			'Error: La descripción del artículo es demasiado larga y excede los 1000 caracteres que el SAT especifica. '
			+ ISNULL(a.nombre, '') + CONVERT(VARCHAR(MAX), vtm.comentario)
		)
	FROM
		ew_ven_transacciones_mov AS vtm
		LEFT JOIN ew_articulos AS a
			ON a.idarticulo = vtm.idarticulo
	WHERE
		vtm.idtran = @idtran
		AND LEN(ISNULL(a.nombre, '') + CONVERT(VARCHAR(MAX), vtm.comentario)) > 1000

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

DECLARE cur_detalle CURSOR FOR
	SELECT DISTINCT 
		[idtran] = FLOOR(vtm.idmov2)
	FROM
		ew_ven_transacciones_mov AS vtm
	WHERE
		vtm.idtran = @idtran
		AND vtm.cantidad_facturada > 0

OPEN cur_detalle

FETCH NEXT FROM cur_detalle INTO
	@idtran2

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC _ven_prc_ordenEstado @idtran2, @idu
	
	FETCH NEXT FROM cur_detalle INTO 
		@idtran2
END

CLOSE cur_detalle
DEALLOCATE cur_detalle

IF @surtir = 1
BEGIN
	UPDATE vtm SET
		vtm.costo = ISNULL(itm.costo, 0)
	FROM
		ew_ven_transacciones_mov As vtm
		LEFT JOIN ew_inv_transacciones_mov AS itm
			ON itm.idmov2 = vtm.idmov
			AND itm.tipo = 2
	WHERE
		vtm.idtran = @idtran

	UPDATE vt SET
		vt.costo = ISNULL((
			SELECT SUM(vtm.costo) 
			FROM ew_ven_transacciones_mov AS vtm 
			WHERE vtm.idtran = vt.idtran
		), 0)
	FROM
		ew_ven_transacciones AS vt
	WHERE
		vt.idtran = @idtran

	SELECT 
		[costo] = ISNULL(SUM(costo), 0) 
	FROM 
		ew_ven_transacciones_mov 
	WHERE 
		idtran = @idtran
END

--------------------------------------------------------------------------------
-- VERIFICAR MARGENES ##########################################################

EXEC _ven_prc_facturaPreciosValidar @idtran, 1, @error_mensaje

IF @error_mensaje IS NOT NULL
BEGIN
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

EXEC _ct_prc_polizaAplicarDeconfiguracion @idtran, 'EFA6', @idtran
GO
