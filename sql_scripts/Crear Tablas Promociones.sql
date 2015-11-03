USE db_comercial_final
GO

IF OBJECT_ID('[dbo].[ew_ven_promociones]') IS NOT NULL
BEGIN
	PRINT 'Dropped ew_ven_promociones'
	DROP TABLE ew_ven_promociones
END

CREATE TABLE [dbo].[ew_ven_promociones](
	[idr] [int] IDENTITY(1,1) NOT NULL,
	[idpromocion] [int] NOT NULL,
	[codigo] [varchar](10) NOT NULL,
	[nombre] [varchar](200) NOT NULL CONSTRAINT [DF_ew_ven_promociones_nombre]  DEFAULT (''),
	[activo] [bit] NOT NULL CONSTRAINT [DF_ew_ven_promociones_activo]  DEFAULT ((1)),
	[idsucursal] [smallint] NOT NULL CONSTRAINT [DF_ew_ven_promociones_idsucursal]  DEFAULT ((0)),
	[fecha_inicial] [smalldatetime] NOT NULL CONSTRAINT [DF_ew_ven_promociones_fecha_inicial]  DEFAULT (getdate()),
	[fecha_final] [smalldatetime] NOT NULL CONSTRAINT [DF_ew_ven_promociones_fecha_final]  DEFAULT (dateadd(month,(1),getdate())),
	[prioridad] [smallint] NOT NULL CONSTRAINT [DF_ew_ven_promociones_prioridad]  DEFAULT ((0)),
	[condicion] [varchar](20) NOT NULL CONSTRAINT [DF_ew_ven_promociones_condicion]  DEFAULT (''),
	[comentario] [text] NOT NULL CONSTRAINT [DF_ew_ven_promociones_comentario]  DEFAULT (''),
 CONSTRAINT [PK_ew_ven_promociones] PRIMARY KEY CLUSTERED 
(
	[idpromocion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_ew_ven_promociones_codigo] UNIQUE NONCLUSTERED 
(
	[idr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de registro' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'idr'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de promoción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'idpromocion'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Código de promoción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'codigo'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nombre de la promición' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'nombre'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indica promoción activa' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'activo'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Sucursal en la que aplica: 0 = Todas' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'idsucursal'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de inicio de la promoción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'fecha_inicial'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fecha de fin de la promoción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'fecha_final'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Prioridad para aplicar la promoción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'prioridad'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Condicion adicional' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'condicion'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Comentarios adicionales' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones', @level2type=N'COLUMN',@level2name=N'comentario'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Promociones para ventas' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones'

PRINT 'Created ew_ven_promociones'
creado_promociones:
GO

IF OBJECT_ID('[dbo].[ew_ven_promociones_acciones]') IS NOT NULL
BEGIN
	PRINT 'Created ew_ven_promociones_acciones'
	DROP TABLE ew_ven_promociones_acciones
END

CREATE TABLE [dbo].[ew_ven_promociones_acciones](
	[idr] [int] IDENTITY(1,1) NOT NULL,
	[idpromocion] [int] NOT NULL,
	[idarticulo] [int] NOT NULL,
	[idum] [smallint] NOT NULL CONSTRAINT [DF_ew_ven_promociones_acciones_idum]  DEFAULT ((0)),
	[cantidad] [decimal](18, 6) NOT NULL CONSTRAINT [DF_ew_ven_promociones_acciones_cantidad]  DEFAULT ((0)),
	[precio_venta] [decimal](18, 6) NOT NULL CONSTRAINT [DF_ew_ven_promociones_acciones_precio_venta]  DEFAULT ((0)),
	[cantidad_total] [decimal](18, 6) NOT NULL CONSTRAINT [DF_ew_ven_promociones_acciones_cantidad_total]  DEFAULT ((0)),
	[cantidad_ejercida] [decimal](18, 6) NOT NULL CONSTRAINT [DF_ew_ven_promociones_acciones_cantidad_ejercida]  DEFAULT ((0)),
 CONSTRAINT [PK_ew_ven_promociones_acciones] PRIMARY KEY CLUSTERED 
(
	[idpromocion] ASC,
	[idarticulo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de registro' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_acciones', @level2type=N'COLUMN',@level2name=N'idr'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de promoción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_acciones', @level2type=N'COLUMN',@level2name=N'idpromocion'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de artículo' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_acciones', @level2type=N'COLUMN',@level2name=N'idarticulo'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unidad de medida' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_acciones', @level2type=N'COLUMN',@level2name=N'idum'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Cantidad a ofrecer' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_acciones', @level2type=N'COLUMN',@level2name=N'cantidad'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Precio de venta' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_acciones', @level2type=N'COLUMN',@level2name=N'precio_venta'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Cantidad total' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_acciones', @level2type=N'COLUMN',@level2name=N'cantidad_total'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Cantidad ejercida de la promoción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_acciones', @level2type=N'COLUMN',@level2name=N'cantidad_ejercida'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Acciones a realizar si se cumplen condiciones de promoción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_acciones'

PRINT 'Created ew_ven_promociones_acciones'
creado_promociones_acciones:
GO

IF OBJECT_ID('[dbo].[ew_ven_promociones_condiciones]') IS NOT NULL
BEGIN
	PRINT 'Dropped ew_ven_promociones_condiciones'
	DROP TABLE ew_ven_promociones_condiciones
END

CREATE TABLE [dbo].[ew_ven_promociones_condiciones](
	[idr] [int] IDENTITY(1,1) NOT NULL,
	[idpromocion] [int] NOT NULL,
	[articulo_grupo] [int] NOT NULL CONSTRAINT [DF_ew_ven_promociones_condiciones_articulo_grupo]  DEFAULT ((255)),
	[articulo_id] [int] NOT NULL CONSTRAINT [DF_ew_ven_promociones_condiciones_articulo_id]  DEFAULT ((0)),
	[cliente_grupo] [int] NOT NULL CONSTRAINT [DF_ew_ven_promociones_condiciones_cliente_grupo]  DEFAULT ((255)),
	[cliente_id] [int] NOT NULL CONSTRAINT [DF_ew_ven_promociones_condiciones_cliente_id]  DEFAULT ((0)),
	[idum] [smallint] NOT NULL CONSTRAINT [DF_ew_ven_promociones_condiciones_idum]  DEFAULT ((0)),
	[cantidad_minima] [decimal](18, 6) NOT NULL CONSTRAINT [DF_ew_ven_promociones_condiciones_cantidad_minima]  DEFAULT ((0)),
	[cantidad_maxima] [decimal](18, 6) NOT NULL CONSTRAINT [DF_ew_ven_promociones_condiciones_cantidad_maxima]  DEFAULT ((0)),
	[idcondicionpago] [smallint] NOT NULL CONSTRAINT [DF_ew_ven_promociones_condiciones_idcondicionpago]  DEFAULT ((0)),
	[tipo_condicion] [tinyint] NOT NULL CONSTRAINT [DF_ew_ven_promociones_condiciones_tipo_condicion]  DEFAULT ((0)),
	[falso] [bit] NOT NULL CONSTRAINT [DF_ew_ven_promociones_condiciones_falso]  DEFAULT ((0)),
 CONSTRAINT [PK_ew_ven_promociones_condiciones] PRIMARY KEY CLUSTERED 
(
	[idpromocion] ASC,
	[articulo_grupo] ASC,
	[articulo_id] ASC,
	[cliente_grupo] ASC,
	[cliente_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de registro' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'idr'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de promoción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'idpromocion'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Grupo de artículos' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'articulo_grupo'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de grupo de artículo' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'articulo_id'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Grupo de clientes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'cliente_grupo'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de grupo de cliente' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'cliente_id'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unidad de medida' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'idum'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Cantidad mínima a comprar para aplicar' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'cantidad_minima'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Cantidad máxima a comprar para aplicar' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'cantidad_maxima'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Condición de pago ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'idcondicionpago'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tipo de condición para aplicar: 0 = Y (AND); 1 = O (OR)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'tipo_condicion'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indica si se debe cumplir o no se debe cumplir' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones', @level2type=N'COLUMN',@level2name=N'falso'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Condiciones para aplicar la promoción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_promociones_condiciones'

PRINT 'Created ew_ven_promociones_condiciones'
creado_promociones_condiciones:
GO
