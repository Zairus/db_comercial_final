USE db_comercial_final
GO
IF OBJECT_ID('ew_clientes_inventario') IS NOT NULL
BEGIN
	DROP TABLE ew_clientes_inventario
END
GO
CREATE TABLE [dbo].[ew_clientes_inventario] (
	[id] [int] IDENTITY(1,1) NOT NULL,
	[idcliente] [int] NOT NULL,
	[idarticulo] [int] NOT NULL,
	[no_parte] [varchar](30) NOT NULL,
	[descripcion] [varchar](100) NOT NULL,
	[negociado] [bit] NOT NULL,
	[aumento] [bit] NOT NULL,
	[precio_especial] [decimal](18, 6) NOT NULL,
	[cantidad] [decimal](18, 6) NOT NULL,
	[imagen_url] [varchar](500) NOT NULL,
	[catalogo] [varchar](500) NOT NULL,
	[entrega_dias] [smallint] NOT NULL,
	[comentario] [text] NOT NULL,
 CONSTRAINT [PK_ew_clientes_inventario] PRIMARY KEY CLUSTERED 
(
	[idcliente] ASC,
	[idarticulo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[ew_clientes_inventario] ADD  CONSTRAINT [DF_ew_clientes_inventario_no_parte]  DEFAULT ('') FOR [no_parte]
GO

ALTER TABLE [dbo].[ew_clientes_inventario] ADD  CONSTRAINT [DF_ew_clientes_inventario_descripcion]  DEFAULT ('') FOR [descripcion]
GO

ALTER TABLE [dbo].[ew_clientes_inventario] ADD  CONSTRAINT [DF_ew_clientes_inventario_negociado]  DEFAULT ((1)) FOR [negociado]
GO

ALTER TABLE [dbo].[ew_clientes_inventario] ADD  CONSTRAINT [DF_ew_clientes_inventario_aumento]  DEFAULT ((0)) FOR [aumento]
GO

ALTER TABLE [dbo].[ew_clientes_inventario] ADD  CONSTRAINT [DF_ew_clientes_inventario_precio_especial]  DEFAULT ((0)) FOR [precio_especial]
GO

ALTER TABLE [dbo].[ew_clientes_inventario] ADD  CONSTRAINT [DF_ew_clientes_inventario_cantidad]  DEFAULT ((0)) FOR [cantidad]
GO

ALTER TABLE [dbo].[ew_clientes_inventario] ADD  CONSTRAINT [DF_ew_clientes_inventario_imagen_url]  DEFAULT ('') FOR [imagen_url]
GO

ALTER TABLE [dbo].[ew_clientes_inventario] ADD  CONSTRAINT [DF_ew_clientes_inventario_catalogo]  DEFAULT ('') FOR [catalogo]
GO

ALTER TABLE [dbo].[ew_clientes_inventario] ADD  CONSTRAINT [DF_ew_clientes_inventario_entrega_dias]  DEFAULT ((0)) FOR [entrega_dias]
GO

ALTER TABLE [dbo].[ew_clientes_inventario] ADD  CONSTRAINT [DF_ew_clientes_inventario_comentario]  DEFAULT ('') FOR [comentario]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Inventario especial de clientes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_clientes_inventario'
GO
