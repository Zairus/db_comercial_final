USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091026
-- Description:	Datos de proveedor par compras
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_proveedorDatos]
	@codigo AS VARCHAR(30)
	,@idsucursal AS SMALLINT
AS

SET NOCOUNT ON

SELECT
	codproveedor = p.codigo
	,p.idproveedor
	,proveedor = p.nombre
	,p.rfc
	,p.telefono1
	,p.telefono2
	,p.telefono3
	,[idcontacto]= p.idcontacto
	,[contacto] = cc.nombre
	,pc.horario
	,[contacto_telefono] = ISNULL((
		SELECT TOP 1
			ccc.dato1
		FROM ew_cat_contactos_contacto AS ccc
		WHERE
			ccc.idcontacto = cc.idcontacto
			AND ccc.tipo = 1
	), p.telefono1)
	,[contacto_email] = ISNULL((
		SELECT TOP 1
			ccc.dato1
		FROM ew_cat_contactos_contacto AS ccc
		WHERE
			ccc.idcontacto = cc.idcontacto
			AND ccc.tipo = 4
	), p.email)
	,[dias_credito] = pt.credito_plazo
	,[dias_entrega] = p.plazo_entrega
	,[proveedor_saldo] = ISNULL(csa.saldo, 0)
	,[proveedor_limite] = ISNULL(pt.credito_limite, 0)
	,proveedor_credito = (CASE WHEN ((ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))) < 0 THEN 0 ELSE ((ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))) END)	
	,[idimpuesto1] = CASE WHEN p.idimpuesto1 = 0 THEN (SELECT idimpuesto FROM ew_sys_sucursales WHERE idsucursal = @idsucursal) ELSE p.idimpuesto1 END
	,[idimpuesto1_valor] = CASE WHEN p.idimpuesto1 = 0 THEN (SELECT imp2.valor FROM ew_sys_sucursales ss LEFT JOIN  ew_cat_impuestos imp2 ON imp2.idimpuesto=ss.idimpuesto WHERE ss.idsucursal=@idsucursal) ELSE imp.valor END
	,[IVA] = CASE WHEN p.idimpuesto1 = 0 THEN (SELECT (imp2.valor * 100) FROM ew_sys_sucursales ss LEFT JOIN  ew_cat_impuestos imp2 ON imp2.idimpuesto=ss.idimpuesto WHERE ss.idsucursal=@idsucursal) ELSE (imp.valor *100) END
	,p.idmoneda
	,[tipocambio]=m.tipoCambio
	,idrelacion = 3
	,entidad_codigo = p.codigo
	,entidad_nombre = p.nombre
	,identidad = p.idproveedor
	,p.contabilidad
	,p.cfd_iduso
FROM 
	ew_proveedores AS p
	LEFT JOIN ew_proveedores_contactos AS pc 
		ON pc.idcontacto = p.idcontacto 
		AND pc.idproveedor = p.idproveedor 
	LEFT JOIN ew_cat_contactos AS cc 
		ON cc.idcontacto = pc.idcontacto
	LEFT JOIN ew_proveedores_terminos AS pt 
		ON pt.idproveedor = p.idproveedor
	LEFT JOIN ew_cxp_saldos_actual AS csa 
		ON csa.idproveedor = p.idproveedor 
		AND csa.idmoneda = 0
	LEFT JOIN ew_cat_impuestos AS imp 
		ON imp.idimpuesto = p.idimpuesto1
	LEFT JOIN ew_ban_monedas AS m 
		ON m.idmoneda=p.idmoneda
WHERE
	p.codigo = @codigo
GO
