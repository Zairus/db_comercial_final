USE db_comercial_final
GO
ALTER VIEW [dbo].[objetos_conceptos]
AS
SELECT
	[idr] = oc.idr
	, [objeto] = oc.objeto
	, [idconcepto] = oc.idconcepto
	, [nombre] = ISNULL(c.nombre, '')
	, [bancario] = 0
	, [contabilidad] = oc.contabilidad
	, [contabilidad2] = oc.contabilidad2
FROM
	db_comercial.dbo.evoluware_objetos_conceptos AS oc
	LEFT JOIN dbo.conceptos AS c
		ON c.idconcepto = oc.idconcepto
WHERE
	oc.idconcepto NOT IN (
		SELECT
			soc.idconcepto
		FROM
			ew_sys_objetos_conceptos AS soc
		WHERE
			soc.objeto = oc.objeto
	)

UNION ALL

SELECT
	[idr] = soc.idr
	, [objeto] = soc.objeto
	, [idconcepto] = soc.idconcepto
	, [nombre] = ISNULL(c.nombre, '')
	, [bancario] = soc.bancario
	, [contabilidad] = soc.contabilidad1
	, [contabilidad2] = soc.contabilidad2
FROM
	dbo.ew_sys_objetos_conceptos AS soc
	LEFT JOIN dbo.conceptos AS c
		ON c.idconcepto = soc.idconcepto
GO
