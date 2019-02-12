USE db_comercial_final

BEGIN TRAN

DECLARE
	@ejecutar AS BIT = 0 -- #### 0: Solo Prueba; 1: Ejecutar

DECLARE
	@idtasa8 AS INT
	, @idzona16 AS INT = 1
	, @idzona8 AS INT = 2

SELECT
	@idtasa8 = cit.idtasa
FROM 
	ew_cat_impuestos_tasas AS cit
WHERE
	cit.idimpuesto = 1
	AND cit.tipo = 1
	AND cit.tasa = 0.080000

SELECT
	ait.idr
	, ait.idarticulo
	, ait.idtasa
	, ait.idzona
INTO ##_tmp_ait
FROM 
	ew_articulos AS a
	LEFT JOIN ew_cfd_sat_clasificaciones AS csc
		ON csc.idclasificacion = a.idclasificacion_sat
	LEFT JOIN ew_articulos_impuestos_tasas AS ait
		ON ait.idarticulo = a.idarticulo
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idtasa = ait.idtasa
WHERE
	csc.clave IS NOT NULL
	AND csc.estimulo_frontera = 1
	AND cit.idimpuesto = 1
	AND cit.tasa = 0.160000
	AND cit.tipo = 1

UPDATE ait SET
	ait.idzona = @idzona16
FROM 
	##_tmp_ait AS tait
	LEFT JOIN ew_articulos_impuestos_tasas AS ait
		ON ait.idr = tait.idr
WHERE
	ait.idzona = 0

INSERT INTO ew_articulos_impuestos_tasas (
	idarticulo
	, idtasa
	, idzona
)
SELECT
	tait.idarticulo
	, [idtasa] = @idtasa8
	, [idzona] = @idzona8
FROM
	##_tmp_ait AS tait
WHERE
	(
		SELECT COUNT(*) 
		FROM ew_articulos_impuestos_tasas AS ait 
		WHERE 
			ait.idarticulo = tait.idarticulo 
			AND ait.idtasa = @idtasa8
	) = 0

DROP TABLE ##_tmp_ait

SELECT * FROM [dbo].[ew_articulos_impuestos_tasas] 

IF @ejecutar = 1
BEGIN
	COMMIT TRAN
	SELECT [resultado] = '## SE HA EJECUTADO LA INSTRUCCION ##'
END
	ELSE
BEGIN
	ROLLBACK TRAN
	SELECT [resultado] = '** NO EJECUTADO - MODO PRUEBA - **'
END
