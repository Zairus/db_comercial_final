USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091014
-- Description:	Borrar artículos
-- =============================================
ALTER TRIGGER [dbo].[tg_articulos_d]
	ON  [dbo].[ew_articulos]
	INSTEAD OF DELETE
AS 

SET NOCOUNT ON

DECLARE @idarticulo SMALLINT

SELECT @idarticulo = idarticulo FROM deleted 

IF EXISTS (SELECT idarticulo FROM ew_inv_transacciones_mov WHERE idarticulo=@idarticulo)
BEGIN
	RAISERROR('No es posible borrar artículos, ya que tiene movimientos.', 16, 1)
	RETURN
END

-- Primero verificamos si el articulo a tenido movimientos en COMPRAS.
-- Documentos de compras
IF EXISTS (SELECT idarticulo FROM ew_com_documentos_mov WHERE idarticulo=@idarticulo)
BEGIN
	RAISERROR('No es posible borrar artículos, ya que tiene movimientos.', 16, 1)
	RETURN
END

-- Ordenes de compras
IF EXISTS (SELECT idarticulo FROM ew_com_ordenes_mov WHERE idarticulo=@idarticulo)
BEGIN
	RAISERROR('No es posible borrar artículos, ya que tiene movimientos.', 16, 1)
	RETURN
END
-- transacciones de compras
IF EXISTS (SELECT idarticulo FROM ew_com_transacciones_mov WHERE idarticulo=@idarticulo)
BEGIN
	RAISERROR('No es posible borrar artículos, ya que tiene movimientos.', 16, 1)
	RETURN
END

------------ Segundo verificamos si el articulo a tenido movimientos en VENTAS.

-- Documentos de ventas
IF EXISTS (SELECT idarticulo FROM ew_ven_documentos_mov WHERE idarticulo=@idarticulo)
BEGIN
	RAISERROR('No es posible borrar artículos, ya que tiene movimientos.', 16, 1)
	RETURN
END
-- Ordenes de ventas
IF EXISTS (SELECT idarticulo FROM ew_ven_ordenes_mov WHERE idarticulo=@idarticulo)
BEGIN
	RAISERROR('No es posible borrar artículos, ya que tiene movimientos.', 16, 1)
	RETURN
END
-- transacciones de ventas
IF EXISTS (SELECT idarticulo FROM ew_ven_transacciones_mov WHERE idarticulo=@idarticulo)
BEGIN
	RAISERROR('No es posible borrar artículos, ya que tiene movimientos.', 16, 1)
	RETURN
END

-- Eliminamos el articulo en las tablas de articulos.
DELETE FROM ew_articulos WHERE idarticulo = @idarticulo
DELETE FROM ew_articulos_almacenes WHERE idarticulo = @idarticulo
DELETE FROM ew_articulos_sucursales WHERE idarticulo = @idarticulo
DELETE FROM ew_articulos_insumos WHERE idarticulo_superior = @idarticulo OR idarticulo = @idarticulo
DELETE FROM ew_articulos_proveedores WHERE idarticulo = @idarticulo
DELETE FROM ew_articulos_unidades WHERE idarticulo = @idarticulo
DELETE FROM ew_ven_listaprecios_mov WHERE idarticulo = @idarticulo
GO