USE db_comercial_final
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: ENERO 2010
-- Description:	"ECO1":"Cotización de Venta ECO1"
-- Ejemplo : EXEC _ven_rpt_ECO1 1991
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_ECO1] 
	@idtran INT
AS

SET NOCOUNT ON

SELECT
	[sucursal]=s.nombre
	,[fecha] = d.fecha
	,[folio] = d.folio
	,[razon_social] = (CASE WHEN LEN(cf.razon_social)=0 THEN c.nombre ELSE cf.razon_social END)
	,[cliente] = c.codigo +' - '+ c.nombre
	,[f_direccion] = ISNULL(cf.calle,'')+'  No. ' + cf.noExterior
	,[f_colonia] = ISNULL(cf.colonia,'')
	,[f_codigopostal] = ISNULL(cf.codpostal,'')
	,[telefono1] = ISNULL(cf.telefono1,'')
	,[telefono2] = ISNULL(cf.telefono2,'')
	,[contacto]=ISNULL(ccc.nombre + ' ' + ccc.apellido,'')
	,[horario] = ISNULL(cc.horario,'')
	,[ciudad]=ISNULL(cd.ciudad+ ', '+cd.estado,'')
	,[vendedor]=ISNULL(v.nombre,'')
	,[codarticulo] = a.codigo
	,[descripcion] = a.nombre_corto + ' - ' + a.nombre
	,[cantidad_solicitada] = dm.cantidad_solicitada
	,[precio_unitario] = dm.precio_unitario
	,[descuento1] = dm.descuento1
	,[importeM] = dm.importe
	,[impuesto1M] = dm.impuesto1
	,[totalM] = dm.total
	,[comentarioM] = dm.comentario
	,[importe] = d.subtotal
	,[impuesto1] = d.impuesto1
	,[total] = d.total
	,[comentario] = d.comentario
	,[idtran] = dm.idtran
	,[empresa_rpt] = dbo.fn_sys_empresa()
	,[dias_entrega] = d.dias_entrega
	,[cantidad_letra] = dbo.fnNum2Letra(d.total, d.idmoneda)
	,[usuario] = u.nombre
	,[usuario_email] = u.email
	,[descuento] = (dm.precio_unitario) - (dm.importe / dm.cantidad_solicitada)
	,[pu_descuento] = (dm.importe / dm.cantidad_solicitada)
	,[tasa] = CONVERT(VARCHAR(5), (dm.idimpuesto1_valor * 100)) + '%'

	,[terminos] = (CASE WHEN d.credito = 1 THEN 'CREDITO' ELSE 'CONTADO' END)
	,[credito_plazo] = d.credito_plazo
	,[vigencia] = d.vigencia
FROM 
	ew_ven_documentos_mov AS dm
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = dm.idarticulo
	LEFT JOIN ew_ven_documentos AS d 
		ON d.idtran=dm.idtran
	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = d.idcliente
	LEFT JOIN ew_clientes_contactos AS cc 
		ON cc.idcliente = d.idcliente 
		AND cc.idcontacto = d.idcontacto
	LEFT JOIN ew_cat_contactos AS ccc 
		ON ccc.idcontacto=cc.idcontacto
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = d.idsucursal
	LEFT JOIN ew_clientes_facturacion AS cf 
		ON cf.idcliente = d.idcliente 
		AND cf.idfacturacion = d.idfacturacion
	LEFT JOIN ew_ven_vendedores AS v 
		ON v.idvendedor = d.idvendedor	
	LEFT JOIN ew_sys_ciudades AS cd 
		ON cd.idciudad=cf.idciudad
	LEFT JOIN evoluware_usuarios AS u 
		ON u.idu = d.idu
WHERE 
	dm.idtran = @idtran
GO
