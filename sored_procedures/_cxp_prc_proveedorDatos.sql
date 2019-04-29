USE db_comercial_final
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[_cxp_prc_proveedorDatos]
	@codigo AS VARCHAR(30)
	, @idsucursal AS SMALLINT
AS

SET NOCOUNT ON

SELECT
	[idproveedor] = p.idproveedor
	, [codacreedor] = p.codigo
	, [acreedor] = p.nombre
	, [rfc] = p.rfc 
	, [telefono1] = p.telefono1
	, [credito_dias] = pt.credito_plazo
	, [acreedor_saldo] = ISNULL(csa.saldo, 0)
	, [acreedor_limite] = ISNULL(pt.credito_limite, 0)
	, [acreedor_credito] = (ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))
	, [idimpuesto1] = ISNULL(NULLIF(p.idimpuesto1, 0), s.idimpuesto)
	, [idimpuesto1_valor] = ISNULL(NULLIF((s.iva / 100.00), 0), imp.valor)
	, [iva] = ISNULL(NULLIF(s.iva, 0), imp.valor)
	, [idmoneda] = p.idmoneda
	, [acreedor_cuenta] = p.contabilidad
FROM 
	ew_proveedores AS p
	LEFT JOIN ew_proveedores_terminos AS pt 
		ON pt.idproveedor = p.idproveedor
	LEFT JOIN ew_cxp_saldos_actual AS csa 
		ON csa.idproveedor = p.idproveedor 
		AND csa.idmoneda = 0
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = @idsucursal
	LEFT JOIN ew_cat_impuestos AS imp 
		ON imp.idimpuesto = ISNULL(NULLIF(p.idimpuesto1, 0), s.idimpuesto)
WHERE
	p.codigo = @codigo
GO
