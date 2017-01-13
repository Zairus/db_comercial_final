USE db_comercial_final
GO
ALTER VIEW [dbo].[objetos_conceptos]
AS
SELECT
	oc.idr
	, oc.objeto
	, oc.idconcepto
	, [nombre] = (
		SELECT
			c.nombre
		FROM
			db_comercial.dbo.evoluware_conceptos AS c
		WHERE
			c.idconcepto = oc.idconcepto
	)
	, [contabilidad] = oc.contabilidad
	, [contabilidad2] = oc.contabilidad2
FROM
	db_comercial.dbo.evoluware_objetos_conceptos AS oc
GO
