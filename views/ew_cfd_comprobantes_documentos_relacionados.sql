USE db_comercial_final
GO
IF OBJECT_ID('ew_cfd_comprobantes_documentos_relacionados') IS NOT NULL
BEGIN
	DROP VIEW ew_cfd_comprobantes_documentos_relacionados
END
GO
CREATE VIEW [dbo].[ew_cfd_comprobantes_documentos_relacionados]
AS
SELECT
	[idtran] = ct.idtran
	, [idtran2] = COALESCE(ctm.idtran2, nv_rel.idtran2, ctrc.idtran2, ct.idtran2)
	, [tiporelacion] = ISNULL(cst.c_tiporelacion, csto.c_tiporelacion)
	, cc1.cfdi_UUID
FROM
	ew_cxc_transacciones AS ct
	
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ct.transaccion NOT IN ('BDC2')
		AND ctm.idtran = ct.idtran

	LEFT JOIN (
		SELECT
			ctr.idtran
			, ctr.idtran2
		FROM
			ew_cxc_transacciones_rel AS ctr
			LEFT JOIN ew_cxc_transacciones AS fg
				ON fg.idtran = ctr.idtran
		WHERE
			fg.cancelado = 0
			AND fg.transaccion = 'EFA4'
	) AS nv_rel
		ON ct.tipo = 2
		AND ct.idtran2 > 0
		AND ct.transaccion IN ('EFA7', 'BDC2')
		AND nv_rel.idtran2 = ct.idtran2

	LEFT JOIN ew_cxc_transacciones_rel AS ctrc
		ON ct.transaccion IN ('EFA1', 'EFA6')
		AND ctrc.idtran2 > 0
		AND ctrc.idtran = ct.idtran

	LEFT JOIN ew_cfd_comprobantes_timbre AS cc1
		ON cc1.idtran = COALESCE(ctm.idtran2, ctrc.idtran2, nv_rel.idtran, ct.idtran2)
	
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion

	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_tiporelacion AS cst
		ON cst.idr = ISNULL(NULLIF(ctrc.idrelacion, 0), ct.idrelacion)
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_tiporelacion_objetos AS csto
		ON csto.objeto = o.objeto
WHERE 
	LEN(ISNULL(cc1.cfdi_UUID, '')) > 0
GO
