USE db_comercial_final
GO
ALTER VIEW [dbo].[objetos_conceptos]
AS
SELECT
	[idr] = oc.idr
	, [objeto] = oc.objeto
	, [objeto_codigo] = o.codigo
	, [idconcepto] = oc.idconcepto
	, [nombre] = ISNULL(c.nombre, '')
	, [bancario] = 0
	, [contabilidad] = oc.contabilidad
	, [contabilidad2] = oc.contabilidad2
FROM
	db_comercial.dbo.evoluware_objetos_conceptos AS oc
	LEFT JOIN db_comercial.dbo.evoluware_objetos AS o
		ON o.objeto = oc.objeto
	LEFT JOIN db_comercial.dbo.evoluware_conceptos AS c
		ON c.idconcepto = oc.idconcepto
WHERE
	oc.objeto NOT IN (
		SELECT
			soc.objeto
		FROM
			ew_sys_objetos_conceptos AS soc
	)

UNION ALL

SELECT
	[idr] = soc.idr
	, [objeto] = soc.objeto
	, [objeto_codigo] = o.codigo
	, [idconcepto] = soc.idconcepto
	, [nombre] = ISNULL(c.nombre, '')
	, [bancario] = soc.bancario
	, [contabilidad] = soc.contabilidad1
	, [contabilidad2] = soc.contabilidad2
FROM
	dbo.ew_sys_objetos_conceptos AS soc
	LEFT JOIN dbo.objetos AS o
		ON o.objeto = soc.objeto
	LEFT JOIN dbo.conceptos AS c
		ON c.idconcepto = soc.idconcepto
GO
