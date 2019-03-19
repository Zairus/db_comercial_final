USE db_comercial_final
GO
IF OBJECT_ID('objetos_enviables') IS NOT NULL
BEGIN
	DROP VIEW objetos_enviables
END
GO
CREATE VIEW objetos_enviables
AS
SELECT
	[objeto] = 0
	, [objeto_nombre] = 'Todos'
	, [objeto_codigo] = ''

UNION ALL

SELECT 
	soe.objeto 
	, [objeto_nombre] = o.nombre
	, [objeto_codigo] = o.codigo
FROM 
	ew_sys_objetos_empresa AS soe
	LEFT JOIN objetos AS o
		ON o.objeto = soe.objeto
WHERE
	o.visible = 1
	AND o.tipo = 'XAC'
	AND o.objeto IN (
		SELECT 
			os.objeto 
		FROM 
			objetos_scripts AS os 
		WHERE 
			CONVERT(VARCHAR(MAX), os.valor) LIKE '%_sys_prc_enviarEmail%'
	)
GO
