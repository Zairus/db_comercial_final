USE db_comercial_final
GO
IF OBJECT_ID('ew_ct_articulos_impuestos') IS NOT NULL
BEGIN
	DROP VIEW ew_ct_articulos_impuestos
END
GO
CREATE VIEW ew_ct_articulos_impuestos
AS
SELECT
	cait.idarticulo
	, idzona = csz.idzona
	, [idimpuesto1] = MAX(CASE WHEN cait.grupo IS NULL THEN i1.idimpuesto WHEN cait.grupo = 'IVA' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.idimpuesto ELSE 0 END)
	, [idimpuesto1_valor] = MAX(CASE WHEN cait.grupo IS NULL THEN i1.valor WHEN cait.grupo = 'IVA' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.tasa ELSE 0 END)
	, [idimpuesto1_c1] = MAX(CASE WHEN cait.grupo IS NULL THEN i1.contabilidad WHEN cait.grupo = 'IVA' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad1 ELSE '' END)
	, [idimpuesto1_c2] = MAX(CASE WHEN cait.grupo IS NULL THEN i1.contabilidad2 WHEN cait.grupo = 'IVA' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad2 ELSE '' END)
	, [idimpuesto1_c3] = MAX(CASE WHEN cait.grupo IS NULL THEN i1.contabilidad3 WHEN cait.grupo = 'IVA' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad3 ELSE '' END)
	, [idimpuesto1_c4] = MAX(CASE WHEN cait.grupo IS NULL THEN i1.contabilidad4 WHEN cait.grupo = 'IVA' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad4 ELSE '' END)
	, [idimpuesto1_c5] = MAX(CASE WHEN cait.grupo = 'IVA' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad5 ELSE '' END)
	, [idimpuesto2] = MAX(CASE WHEN cait.grupo IS NULL THEN i2.idimpuesto WHEN cait.grupo = 'IEPS' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.idimpuesto ELSE 0 END)
	, [idimpuesto2_valor] = MAX(CASE WHEN cait.grupo IS NULL THEN i2.valor WHEN cait.grupo = 'IEPS' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.idimpuesto ELSE 0 END)
	, [idimpuesto2_c1] = MAX(CASE WHEN cait.grupo IS NULL THEN i2.contabilidad WHEN cait.grupo = 'IEPS' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad1 ELSE '' END)
	, [idimpuesto2_c2] = MAX(CASE WHEN cait.grupo IS NULL THEN i2.contabilidad2 WHEN cait.grupo = 'IEPS' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad2 ELSE '' END)
	, [idimpuesto2_c3] = MAX(CASE WHEN cait.grupo IS NULL THEN i2.contabilidad3 WHEN cait.grupo = 'IEPS' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad3 ELSE '' END)
	, [idimpuesto2_c4] = MAX(CASE WHEN cait.grupo IS NULL THEN i2.contabilidad4 WHEN cait.grupo = 'IEPS' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad4 ELSE '' END)
	, [idimpuesto2_c5] = MAX(CASE WHEN cait.grupo = 'IEPS' AND cait.tipo = 1 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad5 ELSE '' END)
	, [idimpuesto3] = 0
	, [idimpuesto3_valor] = 0
	, [idimpuesto3_c1] = ''
	, [idimpuesto3_c2] = ''
	, [idimpuesto3_c3] = ''
	, [idimpuesto3_c4] = ''
	, [idimpuesto3_c5] = ''
	, [idimpuesto4] = 0
	, [idimpuesto4_valor] = 0
	, [idimpuesto4_c1] = ''
	, [idimpuesto4_c2] = ''
	, [idimpuesto4_c3] = ''
	, [idimpuesto4_c4] = ''
	, [idimpuesto4_c5] = ''
	, [idimpuesto1_ret] = MAX(CASE WHEN cait.grupo IS NULL THEN i1_ret.idimpuesto WHEN cait.grupo = 'IVA' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.idimpuesto ELSE 0 END)
	, [idimpuesto1_ret_valor] = MAX(CASE WHEN cait.grupo IS NULL THEN i1_ret.valor WHEN cait.grupo = 'IVA' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.tasa ELSE 0 END)
	, [idimpuesto1_ret_c1] = MAX(CASE WHEN cait.grupo IS NULL THEN i1_ret.contabilidad WHEN cait.grupo = 'IVA' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad1 ELSE '' END)
	, [idimpuesto1_ret_c2] = MAX(CASE WHEN cait.grupo IS NULL THEN i1_ret.contabilidad2 WHEN cait.grupo = 'IVA' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad2 ELSE '' END)
	, [idimpuesto1_ret_c3] = MAX(CASE WHEN cait.grupo IS NULL THEN i1_ret.contabilidad3 WHEN cait.grupo = 'IVA' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad3 ELSE '' END)
	, [idimpuesto1_ret_c4] = MAX(CASE WHEN cait.grupo IS NULL THEN i1_ret.contabilidad4 WHEN cait.grupo = 'IVA' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad4 ELSE '' END)
	, [idimpuesto1_ret_c5] = MAX(CASE WHEN cait.grupo = 'IVA' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad5 ELSE '' END)
	, [idimpuesto2_ret] = MAX(CASE WHEN cait.grupo IS NULL THEN i2_ret.idimpuesto WHEN cait.grupo = 'ISR' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.idimpuesto ELSE 0 END)
	, [idimpuesto2_ret_valor] = MAX(CASE WHEN cait.grupo IS NULL THEN i2_ret.valor WHEN cait.grupo = 'ISR' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.tasa ELSE 0 END)
	, [idimpuesto2_ret_c1] = MAX(CASE WHEN cait.grupo IS NULL THEN i2_ret.contabilidad WHEN cait.grupo = 'ISR' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad1 ELSE '' END)
	, [idimpuesto2_ret_c2] = MAX(CASE WHEN cait.grupo IS NULL THEN i2_ret.contabilidad2 WHEN cait.grupo = 'ISR' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad2 ELSE '' END)
	, [idimpuesto2_ret_c3] = MAX(CASE WHEN cait.grupo IS NULL THEN i2_ret.contabilidad3 WHEN cait.grupo = 'ISR' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad3 ELSE '' END)
	, [idimpuesto2_ret_c4] = MAX(CASE WHEN cait.grupo IS NULL THEN i2_ret.contabilidad4 WHEN cait.grupo = 'ISR' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad4 ELSE '' END)
	, [idimpuesto2_ret_c5] = MAX(CASE WHEN cait.grupo = 'ISR' AND cait.tipo = 2 AND (cait.idzona = csz.idzona OR cait.idzona = 0) THEN cait.contabilidad5 ELSE '' END)
FROM
	ew_ct_articulos_impuestos_tasas AS cait
	LEFT JOIN ew_cat_impuestos AS i1
		ON i1.idimpuesto = cait.idimpuesto1
	LEFT JOIN ew_cat_impuestos AS i2
		ON i1.idimpuesto = cait.idimpuesto2
	LEFT JOIN ew_cat_impuestos AS i1_ret
		ON i1.idimpuesto = cait.idimpuesto1_ret
	LEFT JOIN ew_cat_impuestos AS i2_ret
		ON i1.idimpuesto = cait.idimpuesto2_ret

	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_zonas AS csz
		ON csz.idzona = csz.idzona
GROUP BY
	cait.idarticulo
	, csz.idzona
GO
