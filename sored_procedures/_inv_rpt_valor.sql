USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: yyyymmdd
-- Description:	Valor del inventario
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_valor]
	 @codalm AS SMALLINT = 0
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

IF @idu = 0
	SELECT @idu = 1

SELECT @sucursales = sucursales 
FROM evoluware_usuarios 
WHERE idu = @idu

SELECT @codalm1 = 1
SELECT @codalm2 = 100

IF @codalm > 0
BEGIN
	SELECT @codalm1 = @codalm
	SELECT @codalm2 = @codalm
END

SELECT 
	[almacen] = alm.nombre
	,[nombre] = ('('+a.codigo+')  ' + a.nombre)
	,a.codigo
	,[proveedor] = ISNULL(p.nombre, '-No especificado-')
	,[marca] = ISNULL(m.nombre, '-No especificado-')
	,ic.idarticulo
	,ac.existencia
	,ac.idcapa
	,[unidad] = um.codigo
	,[cu] = (ic.costo / ic.existencia)
	,[costo] = ic.costo
	,[empresa] = dbo.fn_sys_empresa()	
	,[serie] = ic.serie
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
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = [as].idproveedor
	LEFT JOIN ew_cat_marcas AS m
		ON m.idmarca = a.idmarca
WHERE
	ac.existencia > 0
	AND ac.idalmacen BETWEEN @codalm1 AND @codalm2
	AND a.codigo = (CASE @codigo WHEN '' THEN a.codigo ELSE @codigo END)	
	AND (@sucursales = '0' OR alm.idsucursal in (SELECT idsucursal = valor FROM dbo.fn_sys_split(@sucursales,',')))
	AND ISNULL(p.codigo, '') = (CASE WHEN @codprovee = '' THEN ISNULL(p.codigo, '') ELSE @codprovee END)
	AND a.idmarca = (CASE WHEN @idmarca = 0 THEN a.idmarca ELSE @idmarca END)
ORDER BY
	ac.idalmacen
	,a.codigo
GO
