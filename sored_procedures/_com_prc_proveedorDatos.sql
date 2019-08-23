USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_proveedorDatos') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_proveedorDatos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091026
-- Description:	Datos de proveedor par compras
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_proveedorDatos]
	@codigo AS VARCHAR(30)
	, @idsucursal AS SMALLINT
AS

SET NOCOUNT ON

SELECT
	[codproveedor] = p.codigo
	, [idproveedor] = p.idproveedor
	, [proveedor] = p.nombre
	, [rfc] = p.rfc
	, [telefono1] = p.telefono1
	, [telefono2] = p.telefono2
	, [telefono3] = p.telefono3
	, [dias_credito] = pt.credito_plazo
	, [dias_entrega] = p.plazo_entrega
	, [proveedor_saldo] = ISNULL(csa.saldo, 0)
	, [proveedor_limite] = ISNULL(pt.credito_limite, 0)
	, [proveedor_credito] = (
		CASE 
			WHEN ((ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))) < 0 THEN 0 
			ELSE ((ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))) 
		END
	)
	, [idimpuesto1] = (
		CASE 
			WHEN p.idimpuesto1 = 0 THEN (
				SELECT 
					idimpuesto 
				FROM 
					ew_sys_sucursales 
				WHERE 
					idsucursal = @idsucursal
			)
			ELSE p.idimpuesto1 
		END
	)
	, [idimpuesto1_valor] = (
		CASE 
			WHEN p.idimpuesto1 = 0 THEN 
				(
					SELECT imp2.valor 
					FROM 
						ew_sys_sucursales AS ss 
						LEFT JOIN ew_cat_impuestos AS imp2 
							ON imp2.idimpuesto = ss.idimpuesto 
					WHERE 
						ss.idsucursal = @idsucursal
				)
			ELSE imp.valor 
		END
	)
	, [IVA] = (
		CASE 
			WHEN p.idimpuesto1 = 0 THEN 
				(
					SELECT (imp2.valor * 100) 
					FROM 
						ew_sys_sucursales AS ss 
						LEFT JOIN ew_cat_impuestos AS imp2 
							ON imp2.idimpuesto = ss.idimpuesto 
					WHERE 
						ss.idsucursal = @idsucursal
				)
			ELSE
				imp.valor * 100
		END
	)
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
	LEFT JOIN ew_proveedores_terminos AS pt 
		ON pt.idproveedor = p.idproveedor
	LEFT JOIN ew_cxp_saldos_actual AS csa 
		ON csa.idproveedor = p.idproveedor 
		AND csa.idmoneda = 0
	LEFT JOIN ew_cat_impuestos AS imp 
		ON imp.idimpuesto = p.idimpuesto1
	LEFT JOIN ew_ban_monedas AS m 
		ON m.idmoneda = p.idmoneda
WHERE
	p.codigo = @codigo
GO
