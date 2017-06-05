USE db_comercial_final
GO
CREATE VIEW ew_ban_conceptos_egreso
AS
SELECT
	[idconcepto] = a.idarticulo
	,[concepto_nombre] = a.nombre
	,[concepto_cuenta] = a.contabilidad1
FROM
	ew_articulos AS a
WHERE
	a.activo = 1
	AND a.idtipo = 2
	AND a.contabilidad1 <> ''

UNION ALL

SELECT DISTINCT 
	oc.idconcepto
	, [concepto_nombre] = oc.nombre
	, [concepto_cuenta] = oc.contabilidad 
FROM 
	objetos_conceptos AS oc
WHERE
	oc.contabilidad <> ''
GO