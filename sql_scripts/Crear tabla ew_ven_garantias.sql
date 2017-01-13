USE db_comercial_final
GO
IF OBJECT_ID('ew_ven_garantias') IS NOT NULL
BEGIN
	DROP TABLE ew_ven_garantias
END
GO
CREATE TABLE [dbo].[ew_ven_garantias] (
	[idr] [int] IDENTITY(1,1) NOT NULL,
	[idtran] [int] NOT NULL,
	[idcliente] [int] NOT NULL,
	[codigo] [varchar](30) NOT NULL,
	[nombre] [varchar](200) NOT NULL,
	[direccion1] [varchar](200) NOT NULL,
	[direccion2] [varchar](200) NOT NULL,
	[ubicacion_instalacion] [text] NOT NULL,
 CONSTRAINT [PK_ew_ven_garantias] PRIMARY KEY CLUSTERED 
(
	[idtran] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[ew_ven_garantias] ADD  CONSTRAINT [DF_ew_ven_garantias_idcliente]  DEFAULT ((0)) FOR [idcliente]
GO

ALTER TABLE [dbo].[ew_ven_garantias] ADD  CONSTRAINT [DF_ew_ven_garantias_codigo]  DEFAULT ('') FOR [codigo]
GO

ALTER TABLE [dbo].[ew_ven_garantias] ADD  CONSTRAINT [DF_ew_ven_garantias_nombre]  DEFAULT ('') FOR [nombre]
GO

ALTER TABLE [dbo].[ew_ven_garantias] ADD  CONSTRAINT [DF_ew_ven_garantias_direccion1]  DEFAULT ('') FOR [direccion1]
GO

ALTER TABLE [dbo].[ew_ven_garantias] ADD  CONSTRAINT [DF_ew_ven_garantias_direccion2]  DEFAULT ('') FOR [direccion2]
GO

ALTER TABLE [dbo].[ew_ven_garantias] ADD  CONSTRAINT [DF_ew_ven_garantias_ubicacion_instalacion]  DEFAULT ('') FOR [ubicacion_instalacion]
GO
