USE db_comercial_final
GO
ALTER VIEW [dbo].[ew_ven_transacciones_mov_impuestos]
AS
SELECT
	[idtran] = vtm.idtran
	,[idtipo] = 1
	,[cfd_impuesto] = ci.grupo
	,[cfd_tasa] = (CASE WHEN SUM(vtm.impuesto1) = 0 THEN 0 ELSE (ci.valor * 100) END)
	,[cfd_importe] = SUM(vtm.impuesto1)
FROM
	dbo.ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = vtm.idimpuesto1
WHERE
	vtm.idimpuesto1 > 0
GROUP BY
	vtm.idtran
	,ci.grupo
	,ci.valor
	,(CASE WHEN vtm.impuesto1 = 0 THEN 0 ELSE ci.valor END)

UNION ALL

SELECT
	[idtran] = vtm.idtran
	,[idtipo] = cit.tipo
	,[cfd_impuesto] = ci.grupo
	,[cfd_tasa] = (cit.tasa * 100)
	,[cfd_importe] = SUM(vtm.impuesto1_ret)
FROM
	dbo.ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idimpuesto = 1
		AND cit.tipo = 2
		AND cit.tasa > 0
		AND cit.tasa = vtm.idimpuesto1_ret_valor
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = cit.idimpuesto
WHERE
	vtm.impuesto1_ret <> 0
GROUP BY
	vtm.idtran
	,cit.tipo
	,ci.grupo
	,cit.tasa

UNION ALL

SELECT
	[idtran] = vtm.idtran
	,[idtipo] = cit.tipo
	,[cfd_impuesto] = ci.grupo
	,[cfd_tasa] = (cit.tasa * 100)
	,[cfd_importe] = SUM(vtm.impuesto2_ret)
FROM
	dbo.ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idimpuesto = 6
		AND cit.tipo = 2
		AND cit.tasa > 0
		AND cit.tasa = vtm.idimpuesto2_ret_valor
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = cit.idimpuesto
WHERE
	vtm.impuesto2_ret <> 0
GROUP BY
	vtm.idtran
	,cit.tipo
	,ci.grupo
	,cit.tasa

UNION ALL

SELECT
	[idtran] = vtm.idtran
	,[idtipo] = cit.tipo
	,[cfd_impuesto] = ci.grupo
	,[cfd_tasa] = (cit.tasa * 100)
	,[cfd_importe] = SUM(vtm.impuesto2)
FROM
	dbo.ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idimpuesto = 11
		AND cit.tipo = 1
		AND cit.tasa > 0
		AND cit.tasa = vtm.idimpuesto2_valor
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = cit.idimpuesto
WHERE
	vtm.impuesto2 <> 0
	AND cit.tipo IS NOT NULL
GROUP BY
	vtm.idtran
	,cit.tipo
	,ci.grupo
	,cit.tasa
GO
