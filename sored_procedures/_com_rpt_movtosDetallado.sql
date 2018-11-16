USE db_comercial_final
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: 200911
-- Description:	Auxiliar de movimientos de compras detallada
-- =============================================
ALTER PROCEDURE [dbo].[_com_rpt_movtosDetallado]
	@idmoneda AS SMALLINT = -1
	, @idsucursal AS SMALLINT
	, @objeto AS INT = -1
	, @idestado AS INT = -1
	, @fecha1 AS VARCHAR(50)
	, @fecha2 AS VARCHAR(50)
	, @codigo AS VARCHAR(20) = ''
	, @idarticulo AS INT
	, @idmarca AS SMALLINT = 0
AS

SET DATEFORMAT DMY
SET NOCOUNT ON 

SELECT @fecha2 = @fecha2 + ' 23:59'

DECLARE @objetocodigo VARCHAR(5) = ''

SELECT @objetocodigo = codigo 
FROM objetos 
WHERE objeto=@objeto

SELECT @objetocodigo = ISNULL(@objetocodigo,'')

SELECT 
	[moneda] = m.nombre
	, [sucursal] = s.nombre
	, [transaccion] = o.nombre
	, [concepto] = c.nombre
	, [movimiento] = o.nombre
	, [codigo] = ISNULL(ep.codigo + ' - '+ ep.nombre, 'Sin Especificar')
	, ct.idtran
	, ct.fecha
	, ct.folio
	, estado = ISNULL(oe.nombre,'')
	, ct.cancelado
	, [codarticulo]=ea.codigo
	, [articulo] = ea.nombre
	, [nombre_corto] = ea.nombre_corto
	, ctm.cantidad_solicitada
	, ctm.cantidad_autorizada
	, ctm.cantidad_recibida
	, ctm.pendiente
	, ctm.costo_unitario
	, [costo_total] = ctm.costo_unitario*(CASE WHEN ct.transaccion LIKE 'CFA%' THEN ctm.cantidad_autorizada ELSE ctm.cantidad_solicitada END)
	, empresa = dbo.fn_sys_empresa()
FROM
	 com_movtosDetallado AS ctm
	LEFT JOIN  com_transacciones AS ct 
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = ct.idsucursal
	LEFT JOIN objetos AS o 
		ON o.codigo = ct.transaccion
	LEFT JOIN ew_proveedores AS ep 
		ON ep.idproveedor = ct.idproveedor
	LEFT JOIN ew_articulos AS ea 
		ON ea.idarticulo = ctm.idarticulo
	LEFT JOIN c_transacciones AS t 
		ON t.idtran = ct.idtran 
	LEFT JOIN objetos_estados AS oe 
		ON oe.idestado = t.idestado 
		AND oe.objeto = o.objeto
	LEFT JOIN ew_ban_monedas AS m 
		ON m.idmoneda = ct.idmoneda
	LEFT JOIN conceptos AS c 
		ON c.idconcepto = ct.idconcepto
	LEFT JOIN ew_cat_marcas AS marca 
		ON marca.idmarca = ea.idmarca
WHERE
	ct.idmoneda = (
		CASE @idmoneda 
			WHEN -1 THEN ct.idmoneda 
			ELSE @idmoneda 
		END
	)
	AND ct.idsucursal = (
		CASE @idsucursal 
			WHEN 0 THEN ct.idsucursal 
			ELSE @idsucursal 
		END
	)
	AND o.codigo IN (
		SELECT ov.codigo 
		FROM objetos AS ov 
		WHERE 
			ov.codigo LIKE 
				CASE 
					WHEN @objeto = -1 THEN ov.codigo 
					WHEN @objeto = -2 THEN 
						CASE 
							WHEN ct.transaccion='CFA1' THEN 'CFA1' 
							ELSE 
								CASE WHEN ct.transaccion='CFA2' THEN 'CFA2'
								END 
						END 
					ELSE @objetocodigo 
				END
	)
	AND t.idestado = (
		CASE @idestado 
			WHEN -1 THEN t.idestado 
			ELSE @idestado 
		END
	)
	AND ct.fecha BETWEEN @fecha1 AND @fecha2
	AND ep.codigo = (
		CASE @codigo 
			WHEN '' THEN ep.codigo 
			ELSE @codigo 
		END
	)
	AND ctm.idarticulo = (
		CASE @idarticulo 
			WHEN 0 THEN ctm.idarticulo 
			ELSE @idarticulo 
		END
	)
	AND ea.idmarca = (
		CASE @idmarca 
			WHEN 0 THEN ea.idmarca 
			ELSE @idmarca 
		END
	)
	AND o.menu = 2
ORDER BY
	ct.idmoneda
	, ct.transaccion
	, ct.folio
GO
