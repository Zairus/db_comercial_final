USE db_comercial_final

ALTER TABLE ew_ven_ordenes_mov
DROP COLUMN cantidad_porFacturar
GO

ALTER TABLE ew_ven_ordenes_mov
DROP COLUMN cantidad_porSurtir
GO

ALTER TABLE ew_ven_ordenes_mov
ADD cantidad_porFacturar AS ([cantidad_ordenada] - CASE WHEN [cantidad_facturada] > [cantidad_ordenada] THEN [cantidad_ordenada] ELSE [cantidad_facturada] END)
GO


ALTER TABLE ew_ven_ordenes_mov
ADD cantidad_porSurtir AS ([cantidad_ordenada] - CASE WHEN [cantidad_surtida] > [cantidad_ordenada] THEN [cantidad_ordenada] ELSE [cantidad_surtida] END)
GO
