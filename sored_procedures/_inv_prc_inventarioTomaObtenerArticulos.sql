USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170201
-- Description:	Alimentar toma de inventario con registros
-- =============================================
ALTER PROCEDURE _inv_prc_inventarioTomaObtenerArticulos
	@idtran AS INT
	,@idalmacen AS INT
	,@tipo AS INT --#0,Todos...|#1,Con Existencias|
	,@filtrar AS INT --#0,Ninguno|#1,Proveedor|#2,Sublínea|#3,Marca|#4,Rango de Articulos|
	,@parametro AS VARCHAR(100)
	,@codigo1 AS VARCHAR(30)
	,@codigo2 AS VARCHAR(30)
AS

SET NOCOUNT ON
	
DECLARE
	@idestado AS INT

SELECT
	@idestado = st.idestado
FROM
	ew_inv_documentos As id
	LEFT JOIN ew_sys_transacciones As st
		ON st.idtran = id.idtran
WHERE
	id.idtran = @idtran

IF (@idestado > 1)
BEGIN
	RAISERROR('Error: solo se puede cargar detalle cuando la transaccion no ha iniciado su conteo.', 16, 1)
	RETURN
END

DELETE FROM ew_inv_documentos_mov WHERE idtran = @idtran

INSERT INTO ew_inv_documentos_mov (
	idtran
	,consecutivo
	,idarticulo
	,idalmacen
	,idum
	,solicitado
)

SELECT
	[idtran] = @idtran
	,[consecutivo] = ROW_NUMBER() OVER (ORDER BY a.codigo)
	,[idarticulo] = a.idarticulo
	,[idalmacen] = @idalmacen
	,[idum] = a.idum_compra
	,[solicitado] = ISNULL(aa.existencia, 0)
FROM
	ew_articulos AS a
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = @idalmacen
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = a.idarticulo
		AND aa.idalmacen = alm.idalmacen
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idarticulo = a.idarticulo
		AND [as].idsucursal = alm.idsucursal
	LEFT JOIN ew_articulos_niveles AS an3
		ON an3.nivel = 3
		AND an3.codigo = a.nivel3
WHERE
	(
		@tipo = 1
		AND ISNULL(aa.existencia, 0) > 0
		AND @filtrar = 0
	)
	OR (
		@tipo = 0
		AND @filtrar = 0
	)
	OR (
		@filtrar = 1
		AND CONVERT(VARCHAR(100), [as].idproveedor) = @parametro
	)
	OR (
		@filtrar = 2
		AND ISNULL(an3.codigo, '') = @parametro
	)
	OR (
		@filtrar = 3
		AND CONVERT(VARCHAR(100), ISNULL(a.idmarca, 0)) = @parametro
	)
	OR (
		@filtrar = 4
		AND a.codigo BETWEEN @codigo1 AND @codigo2
	)
ORDER BY
	a.codigo
GO
