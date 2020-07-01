USE db_comercial_final
GO
IF OBJECT_ID('_com_rpt_CDE2') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_rpt_CDE2
END
GO
-- =============================================
-- Author:		Vladimir Barreras P.
-- Create date: 20160415
-- Description:	Reporte Transaccion CDE2 Devolucion de Suministros.
-- =============================================
CREATE PROCEDURE [dbo].[_com_rpt_CDE2] 
	@idtran INT
AS

SET NOCOUNT ON

SELECT
	[transaccion] = o.transaccion
	, [sucursal] = s.nombre
	, [almacen] = alm.nombre
	, [folio] = o.folio
	, [fecha] = o.fecha
	, [usuario] = u.nombre
	, [idr] = o.idr
	, [idtran] = o.idtran
	, [codproveedor] = p.codigo
	, [idproveedor] = o.idproveedor
	, [proveedor] = p.nombre
	, [rfc] = p.rfc
	, [direccion1] = p.direccion1
	, [colonia] = p.colonia
	, [cp] = p.codigo_postal
	, [ciudad] = cd.ciudad
	, [estado] = cd.estado
	, [telefono1] = p.telefono1
	, [telefono2] = p.telefono2
	, [telefono3] = p.telefono3
	, [contacto] = cc.nombre + ' ' + cc.apellido
	, [horario] = pc.horario
	, [depto] = (
		SELECT TOP 1 nombre 
		FROM 
			ew_cat_departamentos 
		WHERE 
			iddepto = pc.iddepto
	)
	, [tel_contacto] = dbo.fn_cat_contactoInformacion (pc.idcontacto, 1, 1)
	, [cel_contacto] = dbo.fn_cat_contactoInformacion (pc.idcontacto, 1, 2)
	, [correo_contacto] = dbo.fn_cat_contactoInformacion (pc.idcontacto, 4, 1)
	, [iva] = s.iva
	, [proveedor_saldo] = ISNULL(csa.saldo, 0)
	, [proveedor_limite] = ISNULL(pt.credito_limite, 0)
	, [proveedor_credito] = (ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))
	, [tipocambio] = o.tipocambio
	, [subtotal] = o.subtotal
	, [gastos] = o.gastos
	, [impuesto1] = o.impuesto1
	, [total] = o.total
	, [d_comentario] = o.comentario
	, [cancelado] = o.cancelado
	, [cancelado_fecha] = o.cancelado_fecha
	, [consecutivo] = mov.consecutivo
	, [codarticulo] = a.codigo
	, [idarticulo] = mov.idarticulo
	, [descripcion] = a.nombre
	, [almacenmov] = almov.nombre
	, [unidad] = um.codigo
	, [existencia] = mov.existencia
	, [cantidad_ordenada] = mov.cantidad_ordenada
	, [cantidad_autorizada] = mov.cantidad_autorizada
	, [cantidad_devuelta] = mov.cantidad_devuelta
	, [costo_unitario] = mov.costo_unitario
	, [descuento1] = mov.descuento1
	, [descuento2] = mov.descuento2
	, [descuento3] = mov.descuento3
	, [importemov] = mov.importe
	, [gastosmov] = mov.gastos
	, [impuesto1mov] = mov.impuesto1
	, [totalmov] = mov.total
	, [comentariomov] = mov.comentario
	, [empresa] = dbo.fn_sys_empresa()
	, [realizo] = u.nombre		
	, [moneda] = m.nombre
	, [factura] = emp.razon_social
	, [emp_rfc] = emp.rfc
	, [emp_dir] = emp.calle + ' ' + emp.noExterior
	, [emp_col] = emp.colonia
	, [emp_cd] = c_emp.ciudad+', '+c_emp.estado
	, [emp_tel] = emp.telefono1
	, [emp_telfax] = emp.fax
	, [requisicion] = ISNULL(dr.folio,'')
	, [ieps6] = ISNULL((SELECT SUM(vtm.impuesto2) FROM ew_com_transacciones_mov AS vtm WHERE vtm.idtran = @idtran),0)
	, [ieps7] = 0
	, [ieps9] = 0
FROM 
	ew_com_transacciones_mov AS mov
	LEFT JOIN ew_com_transacciones AS o 
		ON o.idtran = mov.idtran
	LEFT JOIN ew_proveedores AS p 
		ON p.idproveedor = o.idproveedor
	LEFT JOIN ew_sys_ciudades AS cd 
		ON cd.idciudad=p.idciudad
	LEFT JOIN ew_proveedores_contactos AS pc 
		ON pc.idproveedor = o.idproveedor 
		AND pc.idcontacto = o.idcontacto
	LEFT JOIN ew_cat_contactos AS cc 
		ON cc.idcontacto = pc.idcontacto
	LEFT JOIN ew_proveedores_terminos AS pt 
		ON pt.idproveedor = p.idproveedor
	LEFT JOIN ew_cxp_saldos_actual AS csa 
		ON csa.idproveedor = o.idproveedor 
		AND csa.idmoneda = o.idmoneda
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = mov.idarticulo
	LEFT JOIN ew_cat_unidadesMedida AS um 
		ON um.idum = mov.idum
	LEFT JOIN ew_inv_almacenes AS almov 
		ON almov.idalmacen = mov.idalmacen
	LEFT JOIN sucursales AS s 
		ON s.idsucursal = o.idsucursal
	LEFT JOIN ew_inv_almacenes AS alm 
		ON alm.idalmacen = o.idalmacen
	LEFT JOIN usuarios AS u 
		ON u.idu = o.idu
	LEFT JOIN ew_ban_monedas AS m 
		ON m.idmoneda = o.idmoneda
	LEFT JOIN ew_clientes_facturacion AS emp 
		ON emp.idfacturacion = o.idsucursal 
		AND emp.idcliente=0
	LEFT JOIN ew_sys_ciudades AS c_emp
		ON c_emp.idciudad = emp.idciudad
	LEFT JOIN ew_com_documentos AS dr 
		ON dr.idtran = o.idtran2 
		AND dr.transaccion = 'CSO1'
WHERE 
	mov.idtran = @idtran 
ORDER BY 
	o.idtran
	, mov.consecutivo
GO
