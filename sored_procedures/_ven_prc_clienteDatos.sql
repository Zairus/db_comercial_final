USE db_comercial_final
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: 20091111
-- Description:	Datos del Cliente para ventas
-- Ejemplo    : EXEC _ven_prc_clienteDatos '0001', 1
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_clienteDatos]
	@codigo AS VARCHAR(30)
	,@idsucursal AS SMALLINT
AS

SET NOCOUNT ON

SELECT
	[codcliente] = c.codigo
	,c.idcliente
	,[cliente] = c.nombre
	,cf.telefono1
	,cf.telefono2
	,telefono3=cf.fax
	,c.idcontacto
	,[horario] = ISNULL(cc.horario, '')
	,[contacto_telefono] = 0
	,[contacto_email] = 0
	,[facturara] = cf.razon_social
	,c.idfacturacion
	,cf.rfc
	,direccion = cf.calle + ISNULL(' '+cf.noExterior,'') + ISNULL(' '+cf.noInterior,'') 
	,cf.direccion1
	,cf.colonia
	,cf.codpostal
	,[codigopostal] = cf.codpostal
	,[ciudad] = fac.ciudad
	,[estado] = fac.estado
	,[f_direccion] = cf.calle + ISNULL(' '+cf.noExterior,'') + ISNULL(' '+cf.noInterior,'') 
	,[f_colonia] = cf.colonia
	,[f_ciudad] = fac.ciudad
	,[f_municipio] = fac.municipio
	,[f_estado] = fac.estado
	,[f_codigopostal] = cf.codpostal
	,[entregara] = cu.nombre
	,c.idubicacion
	,[e_dir] = cu.direccion1
	,[e_col] = cu.colonia
	,[e_cd] = ent.ciudad
	,[e_edo] = ent.estado
	,[e_cp] = cu.codpostal
	,[e_direccion] = cu.direccion1
	,[e_colonia] = cu.colonia
	,[e_ciudad] = ent.ciudad
	,[e_estado] = ent.estado
	,[e_codigopostal] = cu.codpostal
	,ct.idvendedor
	,[vendedor] = ISNULL(v.nombre, '- Sin Asignar -')
	,[idimpuesto1] = (CASE WHEN cf.idimpuesto1 <>0 THEN cf.idimpuesto1 ELSE s.idimpuesto END)
	,[idimpuesto1_valor] = (CASE WHEN cf.idimpuesto1 <>0 THEN imp.valor ELSE impSuc.valor END)
	,[idimpuesto1_cuenta]=imp.contabilidad
	,[iva]= (CASE WHEN cf.idimpuesto1 <>0 THEN (imp.valor*100) ELSE  (impSuc.valor*100) END)
	,[idlista] = (CASE ct.idlista WHEN 0 THEN s.idlista ELSE ct.idlista END)
	,[dias_entrega] = 0
	,[idpolitica] = ISNULL(ct.idpolitica,0)
	,[credito] = CONVERT(SMALLINT, ct.credito)
	,[t_credito] = ct.credito
	,ct.credito_plazo
	,[cliente_limite] = ct.credito_limite
	,[cliente_saldo] = ISNULL((CASE WHEN csa.saldo < 0 THEN 0 ELSE csa.saldo END),0)
	,[idmoneda] = c.idmoneda
	,[tipoCambio] = dbo.fn_ban_tipocambio (c.idmoneda,0)
	,[forma_moneda] = c.idmoneda
	,[forma_tipoCambio] = dbo.fn_ban_tipocambio (c.idmoneda,0)	
	,[email]=cf.email
	,idrelacion = 4
	,entidad_codigo = c.codigo
	,entidad_nombre = c.nombre
	,identidad = c.idcliente
	,politica=p.nombre
	,cf.contabilidad
	,p.dias_pp1
	,p.dias_pp2
	,p.dias_pp3
	,[metodoDePago] = RTRIM(c.cfd_metodoDePago) + ' ' + RTRIM(c.cfd_NumCtaPago)
	,c.idforma
	,c.cfd_iduso
FROM 
	ew_clientes AS c
	LEFT JOIN ew_clientes_terminos AS ct 
		ON ct.idcliente = c.idcliente
	LEFT JOIN ew_cxc_saldos_actual AS csa 
		ON csa.idcliente = c.idcliente 
		AND csa.idmoneda = c.idmoneda
	LEFT JOIN ew_clientes_contactos AS cc 
		ON cc.idcliente = c.idcliente
		AND cc.idcontacto = c.idcontacto
	LEFT JOIN ew_cat_contactos AS ecc 
		ON ecc.idcontacto = cc.idcontacto
	LEFT JOIN ew_clientes_facturacion AS cf	
		ON cf.idcliente = c.idcliente 
		AND cf.idfacturacion = c.idfacturacion
	LEFT JOIN ew_clientes_ubicaciones AS cu	
		ON cu.idcliente = c.idcliente 
		AND cu.idubicacion = c.idubicacion
	LEFT JOIN ew_ven_vendedores AS v 
		ON v.idvendedor = ct.idvendedor
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = @idsucursal
	LEFT JOIN ew_cat_impuestos AS imp 
		ON imp.idimpuesto = cf.idimpuesto1
	LEFT JOIN ew_cat_impuestos AS impSuc 
		ON impSuc.idimpuesto = s.idimpuesto
	LEFT JOIN ew_sys_ciudades AS fac 
		ON fac.idciudad = cf.idciudad
	LEFT JOIN ew_sys_ciudades AS ent 
		ON ent.idciudad = cu.idciudad
	LEFT JOIN ew_ven_politicas AS p 
		ON p.idpolitica=ct.idpolitica
WHERE
	c.codigo = @codigo 
GO