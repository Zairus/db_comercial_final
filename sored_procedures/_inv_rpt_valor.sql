USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: yyyymmdd
-- Description:	Valor del inventario
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_valor]
	@codsuc AS INT = 0
	,@codalm AS SMALLINT = 0
	,@codigo AS VARCHAR(30) = ''
	,@idu AS SMALLINT = 0
	,@codprovee AS VARCHAR(30) = ''
	,@idmarca AS INT = 0
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
--DECLARACIÓN DE VARIABLES######################################################

DECLARE
	@codalm1 AS SMALLINT
	,@codalm2 AS SMALLINT
	,@sucursales AS VARCHAR(20)

SELECT 
	[sucursal] = s.nombre
	,[almacen] = alm.nombre
	,[nombre] = ('[' + a.codigo + ']  ' + a.nombre)
	,[codigo] = ISNULL(p0.codigo, p.codigo)
	,[proveedor] = ISNULL(p0.codigo, ISNULL(p.nombre, ISNULL(p2.nombre, '-No especificado-')))
	,[marca] = ISNULL(m.nombre, '-No especificado-')
	,ic.idarticulo
	,ac.existencia
	,ac.idcapa
	,[unidad] = um.codigo
	,[cu] = (ac.costo / ac.existencia)
	,[costo] = ac.costo
	,[empresa] = dbo.fn_sys_empresa()	
	,[serie] = ic.serie

	,[referencia] = im.transaccion + ' - ' + im.folio
	,[fechacapa] = ic.fecha
FROM
	ew_inv_capas_existencia AS ac
	LEFT JOIN ew_inv_capas AS ic 
		ON ic.idcapa = ac.idcapa
	LEFT JOIN ew_articulos AS a	
		ON a.idarticulo = ic.idarticulo 
	LEFT JOIN ew_inv_almacenes AS alm 
		ON alm.idalmacen = ac.idalmacen
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idarticulo = ic.idarticulo
		AND [as].idsucursal = alm.idsucursal
	LEFT JOIN ew_articulos_unidades AS au 
		ON au.idum = a.idum_almacen 
		AND au.idarticulo = ic.idarticulo
	LEFT JOIN ew_cat_unidadesMedida AS um 
		ON um.idum = a.idum_almacen
	LEFT JOIN ew_cat_marcas AS m
		ON m.idmarca = a.idmarca
	LEFT JOIN ew_sys_sucursales s
		ON s.idsucursal = alm.idsucursal

	LEFT JOIN ew_inv_movimientos AS im
		ON im.tipo = 1
		AND im.idcapa = ac.idcapa
		AND im.idtran = ic.idtran
	LEFT JOIN ew_inv_transacciones_mov AS itm
		ON itm.idmov = im.idmov2
	LEFT JOIN ew_com_transacciones_mov AS ctm
		ON ctm.idmov = itm.idmov2
	LEFT JOIN ew_com_ordenes_mov AS com
		ON com.idmov = ctm.idmov2
	LEFT JOIN ew_com_ordenes AS co
		ON co.idtran = com.idtran
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = co.idproveedor
	LEFT JOIN ew_proveedores AS p2
		ON p2.idproveedor = [as].idproveedor
	LEFT JOIN ew_proveedores AS p0
		ON p0.idproveedor = itm.identidad
WHERE
	ac.existencia > 0
	AND [as].idsucursal = (CASE WHEN @codsuc=0 THEN [as].idsucursal ELSE @codsuc END)
	AND ac.idalmacen = (CASE WHEN @codalm=0 THEN ac.idalmacen ELSE @codalm END)
	AND a.codigo = (CASE @codigo WHEN '' THEN a.codigo ELSE @codigo END)
	AND ISNULL(p0.codigo, ISNULL(p.nombre, ISNULL(p2.nombre, '-No especificado-'))) = (CASE WHEN @codprovee = '' THEN ISNULL(p0.codigo, ISNULL(p.nombre, ISNULL(p2.nombre, '-No especificado-'))) ELSE @codprovee END)
	AND a.idmarca = (CASE WHEN @idmarca = 0 THEN a.idmarca ELSE @idmarca END)
ORDER BY
	ac.idalmacen
	,a.codigo
GO
