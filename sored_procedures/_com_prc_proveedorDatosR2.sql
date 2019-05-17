USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190429
-- Description:	Obtiene datos de proveedor y/o acreedor para Compras y CXP
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_proveedorDatosR2]
	@codigo AS VARCHAR(30)
	, @idsucursal AS SMALLINT
	, @compra AS BIT = 0
	, @idmoneda AS INT = 0
AS

SET NOCOUNT ON

DECLARE
	@activo AS BIT
	, @error_mensaje AS VARCHAR(200)

SELECT
	@activo = p.activo
FROM
	ew_proveedores AS p
WHERE
	p.codigo = @codigo

IF @compra = 1
BEGIN
	IF @activo = 0
	BEGIN
		SELECT 
			@error_mensaje = 'Error: El proveedor [' + p.nombre + '] no se encuentra activo'
		FROM
			ew_proveedores AS p
		WHERE
			p.codigo = @codigo
		
		RAISERROR(@error_mensaje, 16, 1)
		RETURN
	END
END

SELECT
	[codproveedor] = p.codigo
	, [codacreedor] = p.codigo
	, [idproveedor] = p.idproveedor
	, [proveedor] = p.nombre
	, [acreedor] = p.nombre
	, [nombre] = p.nombre
	, [nombre_corto] = p.nombre_corto
	, [rfc] = p.rfc
	, [telefono1] = p.telefono1
	, [telefono2] = p.telefono2
	, [telefono3] = p.telefono3
	, [fax] = p.telefono3
	, [idcontacto]= p.idcontacto
	, [contacto] = cc.nombre
	, [contacto_nombre] = cc.nombre
	, [contacto_telefono] = ISNULL(dbo.fn_sys_contactoDato(pc.idcontacto, 'TEL'), p.telefono1)
	, [contacto_fax] = dbo.fn_sys_contactoDato(pc.idcontacto, 'FAX')
	, [contacto_horario] = pc.horario
	, [contacto_email] = ISNULL(dbo.fn_sys_contactoDato(pc.idcontacto, 'EML'), p.email)
	, [horario] = pc.horario
	, [credito_dias] = pt.credito_plazo
	, [dias_credito] = pt.credito_plazo
	, [dias_entrega] = p.plazo_entrega
	, [proveedor_saldo] = ISNULL(csa.saldo, 0)
	, [proveedor_limite] = ISNULL(pt.credito_limite, 0)
	, [proveedor_credito] = (CASE WHEN ((ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))) < 0 THEN 0 ELSE ((ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))) END)	
	, [acreedor_saldo] = ISNULL(csa.saldo, 0)
	, [acreedor_limite] = ISNULL(pt.credito_limite, 0)
	, [acreedor_credito] = (ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))
	, [acreedor_cuenta] = p.contabilidad
	
	, [idimpuesto1] = ISNULL(NULLIF(p.idimpuesto1, 0), s.idimpuesto)
	, [idimpuesto1_valor] = ISNULL(NULLIF((s.iva / 100.00), 0), imp.valor)
	, [iva] = ISNULL(NULLIF(s.iva, 0), imp.valor)
	
	, [idmoneda] = p.idmoneda
	, [tipocambio] = m.tipoCambio
	, [idrelacion] = 3
	, [entidad_codigo] = p.codigo
	, [entidad_nombre] = p.nombre
	, [identidad] = p.idproveedor
	, [contabilidad] = p.contabilidad
	, [cfd_iduso] = p.cfd_iduso
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
		AND csa.idmoneda = @idmoneda
	LEFT JOIN ew_ban_monedas AS m 
		ON m.idmoneda = p.idmoneda
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = @idsucursal
	LEFT JOIN ew_cat_impuestos AS imp 
		ON imp.idimpuesto = ISNULL(NULLIF(p.idimpuesto1, 0), s.idimpuesto)
WHERE
	p.codigo = @codigo
GO
