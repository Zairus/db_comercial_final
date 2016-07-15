USE [db_comercial_final]
GO
ALTER VIEW [dbo].[vew_clientes]
AS
SELECT
	dbo.ew_clientes.idr, dbo.ew_clientes.idcliente, dbo.ew_clientes.codigo, dbo.ew_clientes.nombre, dbo.ew_clientes.nombre_corto, 
                      dbo.ew_clientes.activo, dbo.ew_clientes.idubicacion, dbo.ew_clientes.idclasifica, dbo.ew_clientes.idcontacto, dbo.ew_clientes.idmoneda, 
                      dbo.ew_clientes_facturacion.razon_social, dbo.ew_clientes_facturacion.tipo, dbo.ew_clientes_facturacion.rfc, dbo.ew_clientes_facturacion.curp, 
                      dbo.ew_clientes_facturacion.calle, dbo.ew_clientes_facturacion.noExterior, dbo.ew_clientes_facturacion.noInterior, 
                      dbo.ew_clientes_facturacion.referencia, dbo.ew_clientes_facturacion.colonia, dbo.ew_clientes_facturacion.idciudad, 
                      dbo.ew_clientes_facturacion.codpostal, dbo.ew_clientes_facturacion.telefono1, dbo.ew_clientes_facturacion.telefono2, 
                      dbo.ew_clientes_facturacion.fax, dbo.ew_clientes_facturacion.sitio_web, dbo.ew_clientes_facturacion.email, dbo.ew_clientes_facturacion.idimpuesto1, 
                      dbo.ew_clientes_facturacion.idimpuesto_ret1, dbo.ew_clientes_facturacion.idimpuesto_ret2, dbo.ew_clientes.fecha_alta, 
                      dbo.ew_clientes_facturacion.contabilidad, dbo.ew_clientes_facturacion.comentario AS comentario_fiscal, dbo.ew_clientes.comentario
                      ,dbo.ew_clientes.cfd_metodoDePago, dbo.ew_clientes.cfd_NumCtaPago, dbo.ew_clientes.idforma
FROM
	dbo.ew_clientes 
	LEFT OUTER JOIN dbo.ew_clientes_facturacion 
		ON dbo.ew_clientes_facturacion.idcliente = dbo.ew_clientes.idcliente 
		AND dbo.ew_clientes_facturacion.idfacturacion = 0
GO
