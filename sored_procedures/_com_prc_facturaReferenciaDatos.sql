USE db_aguate_datos
GO
IF OBJECT_ID('_com_prc_facturaReferenciaDatos') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_facturaReferenciaDatos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190820
-- Description:	Datos para referencia en factura
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_facturaReferenciaDatos]
	@idsucursal AS INT
	, @referencia AS VARCHAR(20)
AS

SET NOCOUNT ON

IF EXISTS (
	SELECT * 
	FROM 
		ew_com_transacciones
	WHERE 
		cancelado = 0 
		AND transaccion IN ('CDC1') 
		AND idsucursal = @idsucursal 
		AND folio = 'NC' + @referencia
)
BEGIN
	SELECT
		[referencia] = co.folio
		, [idtran2] = co.idtran
		, [idsucursal] = co.idsucursal
		, [idalmacen] = co.idalmacen
		, [codproveedor] = p.codigo
		, [idproveedor] = co.idproveedor
		, [proveedor] = p.nombre
		, [rfc] = p.rfc
		, [telefono1] = p.telefono1
		, [telefono2] = p.telefono2
		, [telefono3] = p.telefono3
		, [idcontacto] = co.idcontacto
		, [horario] = pc.horario
		, [contacto_telefono] = dbo.fn_cat_contactoInformacion (co.idcontacto,1,1)		
		, [contacto_email] = dbo.fn_cat_contactoInformacion (co.idcontacto,4,1)
		, [horario] = pc.horario
		, [credito] = pt.credito
		, [dias_credito] = pt.credito_plazo 
		, [vencimiento]= DATEADD(DAY, pt.credito_plazo, GETDATE()) 
		, [dias_entrega] = p.plazo_entrega
		, [idimpuesto1] = (
			CASE 
				WHEN p.idimpuesto1 = 0 THEN (SELECT idimpuesto FROM ew_sys_sucursales WHERE idsucursal = @idsucursal) 
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
		, [idimpuesto1_ret] = 0
		, [idmoneda] = co.idmoneda
		, [tipocambio] = [dbo].[fn_ban_obtenerTC](co.idmoneda, GETDATE())
		, [tipocambio_dof] = [dbo].[fn_ban_obtenerTC](co.idmoneda, GETDATE())
		, [contabilidad] = p.contabilidad
	FROM 
		ew_com_transacciones AS co
		LEFT JOIN ew_proveedores AS p 
			ON p.idproveedor = co.idproveedor
		LEFT JOIN ew_proveedores_contactos AS pc 
			ON pc.idcontacto = p.idcontacto 
			AND pc.idproveedor = p.idproveedor
		LEFT JOIN ew_cat_contactos AS cc 
			ON cc.idcontacto = pc.idcontacto 
		LEFT JOIN ew_proveedores_terminos AS pt 
			ON pt.idproveedor = p.idproveedor
		LEFT JOIN ew_cat_impuestos AS imp 
			ON imp.idimpuesto = p.idimpuesto1
		LEFT JOIN ew_ban_monedas AS bm 
			ON bm.idmoneda = co.idmoneda
	WHERE
		co.cancelado = 0
		AND co.transaccion = 'CDC1'
		AND co.idsucursal = @idsucursal
		AND co.folio = @referencia
END
	ELSE
BEGIN
	SELECT
		[referencia] = co.folio
		, [idtran2] = co.idtran
		, [idsucursal] = co.idsucursal
		, [idalmacen] = co.idalmacen
		, [codproveedor] = p.codigo
		, [idproveedor] = co.idproveedor
		, [proveedor] = p.nombre
		, [rfc] = p.rfc
		, [telefono1] = p.telefono1
		, [telefono2] = p.telefono2
		, [telefono3] = p.telefono3
		, [idcontacto] = co.idcontacto
		, [horario] = pc.horario
		, [contacto_telefono] = dbo.fn_cat_contactoInformacion (co.idcontacto,1,1)		
		, [contacto_email] = dbo.fn_cat_contactoInformacion (co.idcontacto,4,1)
		, [horario] = pc.horario
		, [credito] = pt.credito
		, [dias_credito] = (
			CASE 
				WHEN co.dias_credito = 0 THEN pt.credito_plazo 
				ELSE co.dias_credito 
			END
		)
		, [vencimiento]= DATEADD(DAY, (CASE WHEN co.dias_credito = 0 THEN pt.credito_plazo ELSE co.dias_credito END), GETDATE()) 
		, [dias_entrega] = p.plazo_entrega
		, [idimpuesto1] = (
			CASE 
				WHEN p.idimpuesto1 = 0 THEN (SELECT idimpuesto FROM ew_sys_sucursales WHERE idsucursal = @idsucursal) 
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
		, [idimpuesto1_ret] = co.idimpuesto1_ret
		, [idmoneda] = co.idmoneda
		, [tipocambio] = [dbo].[fn_ban_obtenerTC](co.idmoneda, GETDATE())
		, [tipocambio_dof] = [dbo].[fn_ban_obtenerTC](co.idmoneda, GETDATE())
		, [contabilidad] = p.contabilidad
	FROM 
		ew_com_ordenes AS co
		LEFT JOIN ew_proveedores AS p 
			ON p.idproveedor = co.idproveedor
		LEFT JOIN ew_proveedores_contactos AS pc 
			ON pc.idcontacto = p.idcontacto 
			AND pc.idproveedor = p.idproveedor
		LEFT JOIN ew_cat_contactos AS cc 
			ON cc.idcontacto = pc.idcontacto 
		LEFT JOIN ew_proveedores_terminos AS pt 
			ON pt.idproveedor = p.idproveedor
		LEFT JOIN ew_cat_impuestos AS imp 
			ON imp.idimpuesto = p.idimpuesto1
		LEFT JOIN ew_ban_monedas AS bm 
			ON bm.idmoneda = co.idmoneda
	WHERE
		co.cancelado = 0
		AND co.transaccion IN ('COR1', 'COR2')
		AND co.idsucursal = @idsucursal
		AND co.folio = @referencia
END
GO
