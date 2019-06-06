USE [db_comercial_final]
GO
IF EXISTS (SELECT * FROM sys.indexes WHERE [name] = 'IX_ew_cat_contactos_entidades_envios')
BEGIN
	DROP INDEX [IX_ew_cat_contactos_entidades_envios] ON [dbo].[ew_cat_contactos_entidades]
END
GO
CREATE NONCLUSTERED INDEX [IX_ew_cat_contactos_entidades_envios]
ON [dbo].[ew_cat_contactos_entidades] (
	[idrelacion]
	, [identidad]
	, [enviar_facturas]
)
GO
