USE db_comercial_final
GO
IF EXISTS (SELECT * FROM sys.indexes WHERE [name] = 'PK_ew_articulos_niveles_1')
BEGIN
	ALTER TABLE [dbo].[ew_articulos_niveles] 
	DROP CONSTRAINT [PK_ew_articulos_niveles_1] WITH ( ONLINE = OFF )
END
GO
IF EXISTS (SELECT * FROM sys.indexes WHERE [name] = 'PK_ew_articulos_niveles')
BEGIN
	ALTER TABLE [dbo].[ew_articulos_niveles] 
	DROP CONSTRAINT [PK_ew_articulos_niveles] WITH ( ONLINE = OFF )
END
GO

ALTER TABLE ew_articulos_niveles ALTER COLUMN codigo VARCHAR(30) NOT NULL
GO

ALTER TABLE ew_articulos_niveles ALTER COLUMN codigo_superior VARCHAR(30) NOT NULL
GO

ALTER TABLE [dbo].[ew_articulos_niveles]
ADD CONSTRAINT [PK_ew_articulos_niveles] PRIMARY KEY CLUSTERED (
	[nivel] ASC,
	[codigo] ASC
) WITH (
	PAD_INDEX = OFF, 
	STATISTICS_NORECOMPUTE = OFF, 
	IGNORE_DUP_KEY = OFF, 
	ONLINE = OFF, 
	ALLOW_ROW_LOCKS = ON, 
	ALLOW_PAGE_LOCKS = ON
) ON [PRIMARY]
GO