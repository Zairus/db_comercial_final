USE db_comercial_final
GO
ALTER VIEW ew_ven_datos_busqueda
AS
SELECT DISTINCT 
	[codigo] = vtmd.valor 
	,[nombre] = (
		SELECT TOP 1 vtmd1.valor 
		FROM 
			ew_ven_transacciones_mov_datos AS vtmd1 
		WHERE 
			vtmd1.iddato = 2 
			AND vtmd1.idtran = vtmd.idtran 
			AND vtmd1.idarticulo = vtmd.idarticulo
	)
FROM 
	ew_ven_transacciones_mov_datos AS vtmd 
WHERE 
	vtmd.iddato = 1
GO
