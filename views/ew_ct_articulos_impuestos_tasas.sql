USE db_comercial_final
GO
IF OBJECT_ID('ew_ct_articulos_impuestos_tasas') IS NOT NULL
BEGIN
	DROP VIEW ew_ct_articulos_impuestos_tasas
END
GO
CREATE VIEW ew_ct_articulos_impuestos_tasas
AS
SELECT
	a.idarticulo
	, a.idtipo
	, ait.idtasa
	, ait.idzona
	, cit.tipo
	, cit.tasa
	, ci.idimpuesto
	, ci.grupo

	, cit.contabilidad1
	, cit.contabilidad2
	, cit.contabilidad3
	, cit.contabilidad4
	, cit.contabilidad5

	, a.idimpuesto1
	, a.idimpuesto2
	, a.idimpuesto3
	, a.idimpuesto4
	, a.idimpuesto1_ret
	, a.idimpuesto2_ret
FROM 
	ew_articulos AS a
	LEFT JOIN ew_articulos_impuestos_tasas AS ait
		ON ait.idarticulo = a.idarticulo
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idtasa = ait.idtasa
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = cit.idimpuesto
GO
