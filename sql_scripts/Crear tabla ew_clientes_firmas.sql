USE db_comercial_final
GO
IF OBJECT_ID('ew_clientes_firmas') IS NOT NULL
BEGIN
	DROP TABLE ew_clientes_firmas
END
GO
CREATE TABLE [dbo].[ew_clientes_firmas] (
	[idr] [smallint] IDENTITY(1,1) NOT NULL,
	[idcliente] [int] NOT NULL,
	[idfirma] [smallint] NOT NULL,
	[nombre] [varchar](200) NOT NULL,
	[telefono] [varchar](50) NOT NULL,
	[direccion] [varchar](200) NOT NULL,
	[comentarios] [text] NOT NULL,
 CONSTRAINT [PK_ew_clientes_firmas] PRIMARY KEY CLUSTERED 
(
	[idcliente] ASC,
	[idfirma] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[ew_clientes_firmas] ADD  CONSTRAINT [DF_ew_clientes_firmas_nombre]  DEFAULT ('') FOR [nombre]
GO

ALTER TABLE [dbo].[ew_clientes_firmas] ADD  CONSTRAINT [DF_ew_clientes_firmas_telefono]  DEFAULT ('') FOR [telefono]
GO

ALTER TABLE [dbo].[ew_clientes_firmas] ADD  CONSTRAINT [DF_ew_clientes_firmas_direccion]  DEFAULT ('') FOR [direccion]
GO

ALTER TABLE [dbo].[ew_clientes_firmas] ADD  CONSTRAINT [DF_ew_clientes_firmas_comentarios]  DEFAULT ('') FOR [comentarios]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Firmas de clientes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_clientes_firmas'
GO
