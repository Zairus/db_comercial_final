USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_programacionComprasObtener') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_programacionComprasObtener
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091008
-- Description:	Obtener programación de compras
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_programacionComprasObtener]
	@idtran AS BIGINT
	, @idu SMALLINT = 0
AS

SET NOCOUNT ON

DECLARE
	@idsucursal AS INT
	, @idalmacen AS INT

SELECT
	@idsucursal = idsucursal
	, @idalmacen = idalmacen
FROM
	ew_com_programacion
WHERE
	idtran = @idtran

DELETE FROM ew_com_programacion_det 
WHERE 
	idtran = @idtran

INSERT INTO ew_com_programacion_det (
	idtran
	, consecutivo
	, idarticulo
	, idalmacen
	, cantidad_solicitada
	, cantidad_ordenada
)
SELECT
	[idtran] = @idtran
	, [consecutivo] = ROW_NUMBER() OVER (ORDER BY a.codigo)
	, [idarticulo] = a.idarticulo
	, [idalmacen] =  @idalmacen
	, [cantidad_solicitada] = 0
	, [cantidad_ordenada] = 0
FROM
	ew_articulos AS a
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idarticulo = a.idarticulo
		AND [as].idsucursal = @idsucursal
WHERE
	a.activo = 1
	AND a.idtipo = 0
	AND a.inventariable = 1
	AND [as].idtipo_venta = 1

	AND a.idarticulo NOT IN (
		SELECT
			cpd.idarticulo
		FROM
			ew_com_programacion_det AS cpd
			LEFT JOIN ew_com_programacion AS cp
				ON cp.idtran = cpd.idtran
			LEFT JOIN ew_sys_transacciones AS st
				ON st.idtran = cp.idtran
		WHERE
			cp.cancelado = 0
			AND cp.transaccion = 'CPR1'
			AND st.idestado IN (0, 21)
	)

UPDATE cpd SET
	cpd.cantidad_solicitada = ISNULL((
		SELECT
			SUM(aa.maximo - aa.existencia)
		FROM
			ew_articulos_almacenes AS aa
		WHERE
			aa.idarticulo = cpd.idarticulo
			AND aa.idalmacen = ISNULL(NULLIF(cpd.idalmacen, 0), aa.idalmacen)
			AND aa.existencia <= aa.reorden
	), 0)
FROM
	ew_com_programacion_det AS cpd
WHERE
	cpd.idtran = @idtran

UPDATE cpd SET
	cpd.cantidad_solicitada = (
		cpd.cantidad_solicitada
		-ISNULL((
			SELECT 
				SUM(com.cantidad_autorizada - com.cantidad_surtida)
			FROM 
				ew_com_ordenes AS co
				LEFT JOIN ew_sys_transacciones AS st
					ON st.idtran = co.idtran
				LEFT JOIN ew_com_ordenes_mov AS com
					ON com.idtran = co.idtran
			WHERE 
				co.transaccion = 'COR1'
				AND co.cancelado = 0
				AND st.idestado IN (3, 44)
				AND (com.cantidad_autorizada - com.cantidad_surtida) > 0
				AND com.idalmacen = ISNULL(NULLIF(cpd.idalmacen, 0), com.idalmacen)
				AND com.idarticulo = cpd.idarticulo
		), 0)
	)
FROM
	ew_com_programacion_det AS cpd
WHERE
	cpd.idtran = @idtran

UPDATE cpd SET
	cpd.cantidad_solicitada = (
		cpd.cantidad_solicitada
		+ISNULL((
			SELECT SUM(vom.cantidad_autorizada - vom.cantidad_surtida)
			FROM 
				ew_ven_ordenes AS vo 
				LEFT JOIN ew_sys_transacciones AS st
					ON st.idtran = vo.idtran
				LEFT JOIN ew_ven_ordenes_mov AS vom
					ON vom.idtran = vo.idtran
			WHERE 
				vo.transaccion = 'EOR1'
				AND vo.cancelado = 0
				AND st.idestado IN (3, 44)
				AND vom.idalmacen = ISNULL(NULLIF(cpd.idalmacen, 0), vom.idalmacen)
				AND vom.idarticulo = cpd.idarticulo
		), 0)
	)
FROM
	ew_com_programacion_det AS cpd
WHERE
	cpd.idtran = @idtran
	AND cpd.cantidad_solicitada < 0

DELETE FROM ew_com_programacion_det 
WHERE
	idtran = @idtran
	AND cantidad_solicitada <= 0

UPDATE cpd SET
	cpd.costo_unitario = ISNULL((
		SELECT TOP 1
			det.costo_unitario
		FROM
			ew_com_transacciones_mov AS det
			LEFT JOIN ew_com_transacciones AS docs
				ON docs.idtran = det.idtran
		WHERE
			docs.transaccion LIKE 'CFA%'
			AND docs.cancelado = 0
			AND det.idarticulo = cpd.idarticulo
		ORDER BY
			det.costo_unitario ASC
	), 0),
	cpd.idproveedor = ISNULL((
		SELECT TOP 1
			docs.idproveedor
		FROM
			ew_com_transacciones_mov AS det
		LEFT JOIN ew_com_transacciones AS docs
			ON docs.idtran = det.idtran
		WHERE
			docs.transaccion LIKE 'CFA%'
			AND docs.cancelado = 0
			AND det.idarticulo = cpd.idarticulo
		ORDER BY
			det.costo_unitario ASC
	), ISNULL([as].idproveedor, 0))
FROM
	ew_com_programacion_det AS cpd
	LEFT JOIN ew_com_programacion AS cp
		ON cp.idtran = cpd.idtran
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idsucursal = cp.idsucursal
		AND [as].idarticulo = cpd.idarticulo
WHERE
	cpd.idtran = @idtran

UPDATE ew_com_programacion_det SET
	costo_total = (cantidad_solicitada * costo_unitario)
WHERE
	idtran = @idtran

UPDATE cp SET
	total = ISNULL((
		SELECT 
			SUM(cpd.costo_total)
		FROM
			ew_com_programacion_det AS cpd
		WHERE
			cpd.idtran = @idtran
	), 0)
FROM
	ew_com_programacion AS cp
WHERE
	cp.idtran = @idtran

UPDATE cpd SET
	cpd.idalmacen = (
		ISNULL(
			NULLIF(@idalmacen, 0)
			, (
				SELECT TOP 1
					alm.idalmacen
				FROM
					ew_inv_almacenes AS alm
				WHERE
					alm.tipo = 1
					AND alm.idsucursal = @idsucursal
				ORDER BY
					alm.idalmacen
			)
		)
	)
FROM
	ew_com_programacion_det AS cpd
WHERE
	cpd.idtran = @idtran

--Cambiar estado
IF NOT EXISTS (
	SELECT *
	FROM
		ew_sys_transacciones2
	WHERE
		idtran = @idtran
		AND idestado = 21
)
BEGIN
	INSERT INTO ew_sys_transacciones2 (
		idtran
		,idestado
		,idu
	)
	SELECT
		[idtran] = @idtran
		, [idestado] = 21
		, [idu] = @idu
END
GO
