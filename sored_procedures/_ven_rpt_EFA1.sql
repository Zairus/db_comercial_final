USE db_comercial_final
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: 2010 Noviembre
-- Edited date: 2011 Julio
-- Description:	Reporte WEB para factura de venta.
-- Ejemplo : EXEC _ven_rpt_EFA1 100888
-- =============================================
ALTER PROCEDURE [dbo].[_ven_rpt_EFA1]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[folio] = (d.serie + dbo.fnRellenar(d.folio, 5, 0))
	,[folio_orden] = vo.folio
	,[fecha] = d.fecha
	,[formaDePago] = d.formaDePago
	,[condiciones_pago] = d.condicionesDePago
	,[emisor] = d.emisorNombre
	,[emisorRfc] = d.emisorRfc
	,[dir_emisor] = (
		d.emisorDomicilio_Calle 
		+ ' ' + d.emisorDomicilio_NoExterior 
		+ ' - ' 
		+ d.emisorDomicilio_NoInterior 
		+ ' C.P '
		+ d.emisorDomicilio_CodigoPostal 
		+ ' Col.' + d.emisorDomicilio_Colonia
	)
	,[local_emi] = (
		d.emisorDomicilio_Localidad 
		+ ', ' 
		+ d.emisorDomicilio_Estado 
		+ ' , '
		+ d.emisorDomicilio_Pais
	)
	,[tel_emi] = (
		d.emisorTelefono1 
		+ ' ' + d.emisorTelefono2
	)
	,[noAprobacion] = d.noAprobacion
	,[añoAprobacion] = d.añoAprobacion
	,[noCertificado] = d.noCertificado

--	,receptor=d.receptor_nombre -- lo jala de cfd
	,[receptor] = cf.razon_social
	,[receptor_rfc] = d.receptor_rfc
	,[dir_receptor] = (
		d.receptorDomicilio_Calle 
		+ ' ' + d.receptorDomicilio_NoExterior 
		+ ' - ' + d.receptorDomicilio_NoInterior 
		+ ' C.P ' + d.receptorDomicilio_CodigoPostal 
		+ ' Col.' + d.receptorDomicilio_Colonia
	)
	,[local_receptor] = (
		d.receptorDomicilio_Localidad 
		+ ', ' + d.receptorDomicilio_Estado 
		+ ' , '+ d.receptorDomicilio_Pais
	)
	,[tel_receptor] = (
		d.telefono1 
		+ ' ' + d.telefono2
	)
	,m.orden
	,[cantidad] = (
		m.cantidad
		/*+ISNULL((
			SELECT SUM(vtm1.cantidad_facturada)
			FROM
				ew_ven_transacciones_mov AS vtm1
			WHERE
				vtm1.idtran = vm.idtran
				AND vtm1.consecutivo > vm.consecutivo
				AND vtm1.agrupar = 1
				AND vtm1.consecutivo < ISNULL((
					SELECT TOP 1 vtm2.consecutivo
					FROM
						ew_ven_transacciones_mov AS vtm2
					WHERE
						vtm2.idtran = vtm1.idtran
						AND vtm2.consecutivo > vm.consecutivo
						AND vtm2.agrupar = 0
				), 999)
		), 0)*/
	)
	,m.unidad
	,a.codigo
	,[descripcion] = a.nombre
	,[comentario_detalle] = vm.comentario
	,[valorUnitario] = (
		(
			m.importe
			+ISNULL((
				SELECT SUM(vtm1.importe)
				FROM
					ew_ven_transacciones_mov AS vtm1
				WHERE
					vtm1.idtran = vm.idtran
					AND vtm1.consecutivo > vm.consecutivo
					AND vtm1.agrupar = 1
					AND vtm1.consecutivo < ISNULL((
						SELECT TOP 1 vtm2.consecutivo
						FROM
							ew_ven_transacciones_mov AS vtm2
						WHERE
							vtm2.idtran = vtm1.idtran
							AND vtm2.consecutivo > vm.consecutivo
							AND vtm2.agrupar = 0
					), 999)
			), 0)
		)
		/(
			m.cantidad
			/*+ISNULL((
				SELECT SUM(vtm1.cantidad_facturada)
				FROM
					ew_ven_transacciones_mov AS vtm1
				WHERE
					vtm1.idtran = vm.idtran
					AND vtm1.consecutivo > vm.consecutivo
					AND vtm1.agrupar = 1
					AND vtm1.consecutivo < ISNULL((
						SELECT TOP 1 vtm2.consecutivo
						FROM
							ew_ven_transacciones_mov AS vtm2
						WHERE
							vtm2.idtran = vtm1.idtran
							AND vtm2.consecutivo > vm.consecutivo
							AND vtm2.agrupar = 0
					), 999)
			), 0)*/
		)
	) --vm.precio_unitario
	,[importe] = (
		m.importe
		+ISNULL((
			SELECT SUM(vtm1.importe)
			FROM
				ew_ven_transacciones_mov AS vtm1
			WHERE
				vtm1.idtran = vm.idtran
				AND vtm1.consecutivo > vm.consecutivo
				AND vtm1.agrupar = 1
				AND vtm1.consecutivo < ISNULL((
					SELECT TOP 1 vtm2.consecutivo
					FROM
						ew_ven_transacciones_mov AS vtm2
					WHERE
						vtm2.idtran = vtm1.idtran
						AND vtm2.consecutivo > vm.consecutivo
						AND vtm2.agrupar = 0
				), 999)
		), 0)
	)
	,d.subtotal
	,[ivaTrasladoTasa]=d.ivaTrasladoTasa*100
	,d.ivaTrasladoImporte
	,d.IvaRetenidoImporte
	,d.total
	,[total_letra] = d.cantidad_letra
	,[comentario_doc] = doc.comentario
	,d.sello
	,vm.series
------------------------------------
-- Inicia Cambios para CFDI	
------------------------------------
	--,d.cadenaOriginal	
	,[cadenaOriginal] = cfdi.cfdi_cadenaOriginal
	,[FechaTimbrado] = cfdi.cfdi_FechaTimbrado
	,[UUID] = cfdi.cfdi_UUID
	,[noCertificadoSAT] = cfdi.cfdi_noCertificadoSAT
	,[selloDigitalSAT] = cfdi.cfdi_selloDigital
	,cfdi.QRCode
	,[vencimiento] = (
		d.fecha 
		+ewct.credito_plazo
	)
	,[vendedor] = (
		v.codigo 
		+ ' - ' + v.nombre
	)
	--,a.codigo_fabricante
------------------------------------
-- Inicia Cambios CFDI v3.2
------------------------------------
	,[metodoDePago] = (
		CASE 
			WHEN ccc.cfd_metodoDePago = '' THEN 'NO IDENTIFICADO' ELSE ISNULL(ccc.cfd_metodoDePago + ' ' + ccc.cfd_NumCtaPago, 'NO IDENTIFICADO') 
		END
	)

	,[RegimenFiscal] = (
		SELECT TOP 1 regimenfiscal 
		FROM ew_cfd_parametros
	)
	,[LugarExpedicion] = ISNULL(cd.ciudad,'MEXICO') + ', ' + ISNULL(cd.estado,'')	
------------------------------------
-- Finaliza Cambios para CFDI	
------------------------------------
FROM 
	vCFD AS d
	LEFT JOIN vCFDMov AS m ON 
		m.idtran = d.idtran
	LEFT JOIN ew_ven_transacciones_mov AS vm 
		ON vm.idtran = d.idtran
		AND (RTRIM(CONVERT(VARCHAR(4), vm.consecutivo)) + '.0') = m.orden
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = vm.idarticulo
	LEFT JOIN ew_ven_transacciones AS doc 
		ON doc.idtran = d.idtran
	LEFT JOIN ew_clientes_terminos AS ewct ON 
		ewct.idcliente = doc.idcliente
	LEFT JOIN ew_ven_vendedores AS v 
		ON v.idvendedor = doc.idvendedor

	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = doc.idcliente
-- Cambios CFDI
	LEFT JOIN ew_cfd_comprobantes_timbre AS cfdi 
		ON cfdi.idtran = d.idtran
-- Cambios CFDI v3.2
	LEFT JOIN ew_cfd_comprobantes AS ccc 
		ON ccc.idtran = d.idtran
	LEFT JOIN ew_clientes_facturacion AS sss 
		ON sss.idcliente = 0 
		AND sss.idfacturacion = ccc.idsucursal
	LEFT JOIN ew_clientes_facturacion AS cf ON 
		doc.idcliente = cf.idcliente
		AND cf.idfacturacion = c.idfacturacion
	LEFT JOIN ew_sys_ciudades AS cd 
		ON cd.idciudad=sss.idciudad
	LEFT JOIN ew_ven_ordenes AS vo 
		ON vo.idtran = doc.idtran2
WHERE
	RIGHT(m.orden,1) = '0'
	AND vm.agrupar = 0
	AND d.idtran = @idtran
ORDER BY
	CONVERT(NUMERIC(3,0), m.orden)
GO
