USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091008
-- Description:	Obtener programación de compras
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_programacionComprasObtener]
	@idtran AS BIGINT
AS

SET NOCOUNT ON

DECLARE
	@idalmacen AS INT

SELECT
	@idalmacen = idalmacen
FROM
	ew_com_programacion
WHERE
	idtran = @idtran

DELETE FROM ew_com_programacion_det 
WHERE 
	idtran = @idtran

INSERT INTO ew_com_programacion_det (
	idtran
	,consecutivo
	,idarticulo
	,idalmacen
	,cantidad_solicitada
	,cantidad_ordenada
)
SELECT
	[idtran] = @idtran
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY aa.idarticulo)
	,aa.idarticulo
	,aa.idalmacen
	,[cantidad_solicitada] = (
		(aa.maximo - aa.existencia)
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
				AND com.idarticulo = aa.idarticulo
		), 0)
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
				AND vom.idarticulo = aa.idarticulo
		), 0)
	)
	,[cantidad_ordenada] = 0 --aa.cantidad_ordenada
FROM 
	ew_articulos_almacenes AS aa
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = aa.idarticulo
WHERE
	a.inventariable = 1
	AND aa.maximo > 0
	AND aa.existencia <= aa.reorden
	AND aa.idalmacen = (CASE WHEN @idalmacen = 0 THEN aa.idalmacen ELSE @idalmacen END)
	AND aa.idarticulo NOT IN (
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
			AND cp.transaccion = 'COPR'
			AND st.idestado IN (0, 21)
	)
	AND (
		(aa.maximo - aa.existencia)
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
				AND com.idarticulo = aa.idarticulo
		), 0)
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
				AND vom.idarticulo = aa.idarticulo
		), 0)
	) > 0
ORDER BY
	aa.idarticulo
	,aa.idalmacen

DELETE FROM ew_com_programacion_det 
WHERE
	cantidad_solicitada <= 0
	AND idtran = @idtran
	
UPDATE cpd SET
	cpd.costo_unitario = ISNULL((
		SELECT TOP 1
			det.costo_unitario
		FROM
			ew_com_transacciones_mov AS det
			LEFT JOIN ew_com_transacciones AS docs
				ON docs.idtran = det.idtran
		WHERE
			docs.transaccion = 'CFA1'
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
			docs.transaccion = 'CFA1'
			AND docs.cancelado = 0
			AND det.idarticulo = cpd.idarticulo
		ORDER BY
			det.costo_unitario ASC
	), ISNULL([as].idproveedor, 0))
FROM
	ew_com_programacion_det AS cpd
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idsucursal = 1
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
		, idestado
	)
	SELECT
		[idtran] = @idtran
		, [idestado] = 21
END
GO
