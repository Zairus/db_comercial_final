USE db_comercial_final
GO
IF OBJECT_ID('tg_objetos_conceptos_i') IS NOT NULL
BEGIN
	DROP TRIGGER [dbo].[tg_objetos_conceptos_i]
END
GO
CREATE TRIGGER [dbo].[tg_objetos_conceptos_i]
	ON [dbo].[objetos_conceptos]
	INSTEAD OF INSERT
AS

INSERT INTO [dbo].[ew_sys_objetos_conceptos] (
	objeto
	, idconcepto
	, bancario
	, contabilidad1
	, contabilidad2
)
SELECT
	i.objeto
	, i.idconcepto
	, [bancario] = ISNULL(i.bancario, 0)
	, [contabilidad1] = ISNULL(i.contabilidad, '')
	, [contabilidad2] = ISNULL(i.contabilidad2, '')
FROM
	inserted AS i
GO
IF OBJECT_ID('tg_objetos_conceptos_u') IS NOT NULL
BEGIN
	DROP TRIGGER [dbo].[tg_objetos_conceptos_u]
END
GO
CREATE TRIGGER [dbo].[tg_objetos_conceptos_u]
	ON [dbo].[objetos_conceptos]
	INSTEAD OF UPDATE
AS

UPDATE oc SET
	oc.bancario = i.bancario
	, oc.contabilidad1 = i.contabilidad
	, oc.contabilidad2 = i.contabilidad2
FROM
	inserted AS i
	LEFT JOIN [dbo].[ew_sys_objetos_conceptos] AS oc
		ON oc.idr = i.idr
GO
IF OBJECT_ID('tg_objetos_conceptos_d') IS NOT NULL
BEGIN
	DROP TRIGGER [dbo].[tg_objetos_conceptos_d]
END
GO
CREATE TRIGGER [dbo].[tg_objetos_conceptos_d]
	ON [dbo].[objetos_conceptos]
	INSTEAD OF DELETE
AS

DELETE FROM [dbo].[ew_sys_objetos_conceptos] 
WHERE idr IN (SELECT idr FROM deleted)
GO
