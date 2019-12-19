USE db_comercial_final
GO
IF OBJECT_ID('_ct_rpt_cfdiEmitidos') IS NOT NULL
BEGIN
	DROP PROCEDURE _ct_rpt_cfdiEmitidos
END
GO
-- =============================================
-- Author:		Vladimir Barreras
-- Create date: 20190525
-- Description:	RELACION DE CFDI EMITIDOS
-- =============================================
CREATE PROCEDURE [dbo].[_ct_rpt_cfdiEmitidos]
	@idsucursal SMALLINT = 0
	, @tipo AS VARCHAR(1) = '-'
	, @fecha1 AS DATETIME = NULL
	, @fecha2 AS DATETIME = NULL
	, @condicion AS SMALLINT = -1 -- Crédito, Contado
	, @cancelado AS SMALLINT = -1 -- Todos, Activo, Cancelado
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(
	 DATETIME
	, CONVERT(
		VARCHAR(10)
		,ISNULL(@fecha1, GETDATE()), 103
	) + ' 00:00'
)

SELECT @fecha2 = CONVERT(
	 DATETIME
	, CONVERT(
		VARCHAR(10)
		,ISNULL(@fecha2, GETDATE()), 103
	) + ' 23:59'
)

SELECT
	[sucursal] = s.nombre
	, [moneda] = bm.nombre
	, [fecha] = cxc.fecha
	, [folio] = cxc.folio
	, [receptor] = cf.razon_social
	, [tipo] = tc.descripcion
	, [formaPago] = ISNULL(
		(
			SELECT TOP 1 bf.nombre
			FROM ew_ban_formas AS bf
			WHERE
				bf.codigo = cc.cfd_metodoDePago
		)
		, (
			CASE
				WHEN cxc.idforma > 0 THEN cxc.idforma
				ELSE (
					SELECT TOP 1 bf.nombre 
					FROM ew_ban_formas AS bf 
					WHERE 
						bf.activo = 1 
						AND bf.codigo = '99'
				)
			END
		)
	)
	, [moneda2] = bm.nombre -- para que lo agrupe y aparte lo ponga como columna
	, [condicion] = (CASE WHEN cxc.credito=1 THEN 'Crédito' ELSE 'Contado' END)
	, [subtotal] = cxc.subtotal
	, [impuesto1] = cxc.impuesto1
	, [total] = cxc.total
	, [cancelado] = (CASE WHEN cxc.cancelado = 1 THEN 'Cancelado' ELSE 'Activo' END)
	, [cancelado_fecha] = (CASE WHEN cxc.cancelado = 1 THEN cxc.cancelado_fecha ELSE NULL END)
	, [cfdi_UUID] = cfdi.cfdi_UUID
	, [idtran] = cxc.idtran
	, [acuse] = ISNULL(SUBSTRING(ccc.acuse, 1, 20), '')
FROM
	ew_cfd_comprobantes_timbre AS cfdi
	LEFT JOIN ew_cxc_transacciones AS cxc 
		ON cxc.idtran=cfdi.idtran
	LEFT JOIN ew_clientes_facturacion AS cf 
		ON cf.idcliente=cxc.idcliente 
		AND cf.idfacturacion = 0
	LEFT JOIN ew_ban_formas AS bf 
		ON bf.idforma = cxc.idforma
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = cxc.idsucursal
	LEFT JOIN ew_cfd_comprobantes AS cfd 
		ON cfd.idtran = cfdi.idtran
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_tipodecomprobante AS tc 
		ON tc.c_tipodecomprobante = SUBSTRING(cfd.cfd_tipoDeComprobante, 1, 1)
	LEFT JOIN ew_ban_monedas AS bm 
		ON bm.idmoneda = cxc.idmoneda
	LEFT JOIN ew_cfd_comprobantes AS cc 
		ON cc.idtran = cxc.idtran
	LEFT JOIN ew_cfd_comprobantes_cancelados AS ccc 
		ON ccc.idtran = cfdi.idtran
WHERE
	cxc.idsucursal = ISNULL(NULLIF(@idsucursal, 0), cxc.idsucursal)
	AND cxc.fecha BETWEEN @fecha1 AND @fecha2
	AND SUBSTRING(cfd.cfd_tipoDeComprobante, 1, 1) = (
		CASE 
			WHEN @tipo = '-' THEN SUBSTRING(cfd.cfd_tipoDeComprobante, 1, 1) 
			ELSE @tipo 
		END
	)
	AND cxc.credito = ISNULL(NULLIF(@condicion, -1), cxc.credito)
	AND cxc.cancelado = ISNULL(NULLIF(@cancelado, -1), cxc.cancelado)
ORDER BY
	cxc.idsucursal
	, bm.nombre
	, cxc.fecha
GO
