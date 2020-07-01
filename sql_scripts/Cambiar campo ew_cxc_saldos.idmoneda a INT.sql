USE db_comercial_final
GO
IF EXISTS (SELECT * FROM sys.indexes WHERE [name] = 'PK_ew_cxc_saldos')
BEGIN
	ALTER TABLE [dbo].[ew_cxc_saldos] DROP CONSTRAINT [PK_ew_cxc_saldos]
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_saldos') AND [name] = 'periodo0')
BEGIN
	ALTER TABLE [dbo].[ew_cxc_saldos] DROP COLUMN periodo0
END
GO

IF EXISTS(SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_cxc_saldos') AND [name] = 'periodo13')
BEGIN
	ALTER TABLE [dbo].[ew_cxc_saldos] DROP COLUMN periodo13
END
GO

ALTER TABLE [dbo].[ew_cxc_saldos] ALTER COLUMN [idmoneda] INT NOT NULL
GO

ALTER TABLE [dbo].[ew_cxc_saldos] ADD periodo0 AS ([dbo].[fn_cxc_clienteSaldoInicial]([idcliente],[idmoneda],[tipo],[ejercicio]))
GO

ALTER TABLE [dbo].[ew_cxc_saldos] ADD periodo13 AS ([dbo].[fn_cxc_clienteSaldoInicial]([idcliente],[idmoneda],[tipo],[ejercicio])+[periodo12])
GO

ALTER TABLE [dbo].[ew_cxc_saldos] ADD CONSTRAINT [PK_ew_cxc_saldos] PRIMARY KEY CLUSTERED (
	[idcliente] ASC,
	[idmoneda] ASC,
	[ejercicio] ASC,
	[tipo] ASC
) WITH (
	PAD_INDEX = OFF, 
	STATISTICS_NORECOMPUTE = OFF, 
	SORT_IN_TEMPDB = OFF, 
	IGNORE_DUP_KEY = OFF, 
	ONLINE = OFF, 
	ALLOW_ROW_LOCKS = ON, 
	ALLOW_PAGE_LOCKS = ON
) ON [PRIMARY]
GO
