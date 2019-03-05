USE [db_comercial_final]
GO
IF OBJECT_ID('vew_clientes') IS NOT NULL
BEGIN
	DROP VIEW [dbo].[vew_clientes]
END
GO

ALTER TABLE ew_clientes DISABLE TRIGGER tg_clientes_u
UPDATE [dbo].[ew_clientes] SET [comentario] = ISNULL([comentario], '')
ALTER TABLE ew_clientes ENABLE TRIGGER tg_clientes_u
ALTER TABLE [dbo].[ew_clientes] DROP CONSTRAINT [DF_ew_clientes_comentario]
ALTER TABLE [dbo].[ew_clientes] ALTER COLUMN [comentario] VARCHAR(MAX) NOT NULL
ALTER TABLE [dbo].[ew_clientes] ADD CONSTRAINT [DF_ew_clientes_comentario] DEFAULT ('') FOR [comentario]

UPDATE [dbo].[ew_clientes_facturacion] SET [comentario] = ISNULL([comentario], '')
ALTER TABLE [dbo].[ew_clientes_facturacion] DROP CONSTRAINT [DF_ew_clientes_facturacion_comentario]
ALTER TABLE [dbo].[ew_clientes_facturacion] ALTER COLUMN [comentario] VARCHAR(MAX) NOT NULL
ALTER TABLE [dbo].[ew_clientes_facturacion] ADD CONSTRAINT [DF_ew_clientes_facturacion_comentario] DEFAULT ('') FOR [comentario]

GO
CREATE VIEW [dbo].[vew_clientes]
WITH SCHEMABINDING
AS
SELECT
	[idr] = c.idr
	, [idcliente] = c.idcliente
	, [codigo] = c.codigo
	, [nombre] = c.nombre
	, [nombre_corto] = c.nombre_corto
	, [activo] = c.activo
	, [idubicacion] = c.idubicacion
	, [idclasifica] = c.idclasifica
	, [idcontacto] = c.idcontacto
	, [idmoneda] = c.idmoneda
	, [razon_social] = cf.razon_social
	, [tipo] = cf.tipo
	, [rfc] = cf.rfc
	, [curp] = cf.curp
	, [calle] = cf.calle
	, [noExterior] = cf.noExterior
	, [noInterior] = cf.noInterior
	, [referencia] = cf.referencia
	, [colonia] = cf.colonia
	, [idciudad] = cf.idciudad
	, [codpostal] = cf.codpostal
	, [telefono1] = cf.telefono1
	, [telefono2] = cf.telefono2
	, [fax] = cf.fax
	, [sitio_web] = cf.sitio_web
	, [email] = cf.email
	, [idimpuesto1] = cf.idimpuesto1
	, [idimpuesto_ret1] = cf.idimpuesto_ret1
	, [idimpuesto_ret2] = cf.idimpuesto_ret2
	, [fecha_alta] = c.fecha_alta
	, [contabilidad] = cf.contabilidad
	, [comentario_fiscal] = cf.comentario
	, [comentario] = c.comentario
	, [cfd_metodoDePago] = c.cfd_metodoDePago
	, [cfd_NumCtaPago] = c.cfd_NumCtaPago
	, [idforma] = c.idforma
	, [mayoreo] = c.mayoreo
	, [inventario_partes] = c.inventario_partes
	, [inventario_partes_actualizar] = c.inventario_partes_actualizar
	, [modificar] = c.modificar
	, [cfd_iduso] = c.cfd_iduso
FROM
	[dbo].[ew_clientes] AS c
	INNER JOIN [dbo].[ew_clientes_facturacion] AS cf
		ON cf.idcliente = c.idcliente 
		AND cf.idfacturacion = 0
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vew_clientes] ON [dbo].[vew_clientes](idcliente)
GO
