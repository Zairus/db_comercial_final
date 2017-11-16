USE db_comercial_final
GO
ALTER VIEW [dbo].[vew_clientes]
AS
SELECT
	c.idr
	, c.idcliente
	, c.codigo
	, c.nombre
	, c.nombre_corto
	, c.activo
	, c.idubicacion
	, c.idclasifica
	, c.idcontacto
	, c.idmoneda
	, cf.razon_social
	, cf.tipo
	, cf.rfc
	, cf.curp
	, cf.calle
	, cf.noExterior
	, cf.noInterior
	, cf.referencia
	, cf.colonia
	, cf.idciudad
	, cf.codpostal
	, cf.telefono1
	, cf.telefono2
	, cf.fax
	, cf.sitio_web
	, cf.email
	, cf.idimpuesto1
	, cf.idimpuesto_ret1
	, cf.idimpuesto_ret2
	, c.fecha_alta
	, cf.contabilidad
	, [comentario_fiscal] = cf.comentario
	, c.comentario
	, c.cfd_metodoDePago
	, c.cfd_NumCtaPago
	, c.idforma
	, c.mayoreo
	, c.inventario_partes
	, c.inventario_partes_actualizar
	, c.modificar
	, c.cfd_iduso
FROM
	dbo.ew_clientes AS c
	LEFT JOIN dbo.ew_clientes_facturacion AS cf
		ON cf.idcliente = c.idcliente 
		AND cf.idfacturacion = 0
GO
