USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20120911
-- Description:	Desgloce de IVA
-- =============================================
ALTER PROCEDURE [dbo].[_ct_rpt_ivaDesgloce]
	 @ejercicio AS SMALLINT = NULL
	,@periodo1 AS SMALLINT = NULL
	,@periodo2 AS SMALLINT = NULL
	,@cuenta AS VARCHAR(20) = ''
AS

SET NOCOUNT ON

SELECT @ejercicio = ISNULL(@ejercicio, YEAR(GETDATE()))
SELECT @periodo1  = ISNULL(@periodo1, MONTH(GETDATE()))
SELECT @periodo2  = ISNULL(@periodo2, MONTH(GETDATE()))

SELECT
	[cuenta_descripcion] = ('[' + canr.cuenta + '] ' +  canr.cuenta_nombre)
	,[proveedor_codigo] = canr.proveedor_codigo
	,[proveedor_nombre] = canr.proveedor_nombre
	,[proveedor_rfc] = canr.proveedor_rfc
	,[importe] = SUM(canr.importe)
FROM
	ew_ct_analisis_reembolsos AS canr
WHERE
	canr.ejercicio = @ejercicio
	AND canr.periodo BETWEEN @periodo1 AND @periodo2
	AND canr.cuenta = (CASE WHEN @cuenta = '' THEN canr.cuenta ELSE @cuenta END)
GROUP BY
	('[' + canr.cuenta + '] ' +  canr.cuenta_nombre)
	,canr.proveedor_codigo
	,canr.proveedor_nombre
	,canr.proveedor_rfc

UNION ALL

SELECT
	[cuenta_descripcion] = ('[' + cpd.cuenta + '] ' + cc.nombre)
	,[proveedor_codigo] = ISNULL(p.codigo, ISNULL(pr.codigo, LTRIM(RTRIM(STR(bb.idbanco)))))
	,[proveedor_nombre] = ISNULL(p.nombre, ISNULL(pr.nombre, bb.nombre))
	,[proveedor_rfc] = ISNULL(p.rfc, ISNULL(pr.rfc, ISNULL(bb.rfc, '-Banco ' + bb.nombre + ' sin RFC-')))
	--,st.transaccion
	--,[cpd_idtran2] = cpd.idtran2
	--,[bancos_idtran2] = ban.idtran2
	--,cpd.cargos
	--,cpd.abonos
	,[importe] = SUM(CASE WHEN cc.naturaleza = 0 THEN (cpd.cargos - cpd.abonos) ELSE (cpd.abonos - cpd.cargos) END)
FROM
	ew_ct_polizaDetalle AS cpd
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = cpd.idtran2
	LEFT JOIN ew_cxp_transacciones AS cxp
		ON cxp.idtran = cpd.idtran2
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = cxp.idproveedor
	LEFT JOIN ew_ban_transacciones AS ban
		ON ban.idtran = cpd.idtran2
	LEFT JOIN ew_sys_transacciones AS stb_rel
		ON stb_rel.idtran = ban.idtran2
	LEFT JOIN ew_cxp_transacciones AS cxpr
		ON cxpr.idtran = ban.idtran2
	LEFT JOIN ew_proveedores AS pr
		ON pr.idproveedor = cxpr.idproveedor
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = ban.idcuenta
	LEFT JOIN ew_ban_bancos AS bb
		ON bb.idbanco = bc.idbanco
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = cpd.cuenta
WHERE
	cpd.cuenta IN (
		SELECT DISTINCT
			ic.cuenta
		FROM 
			(
				SELECT [cuenta] = cit.contabilidad1 FROM ew_cat_impuestos_tasas AS cit
				UNION ALL
				SELECT [cuenta] = cit.contabilidad2 FROM ew_cat_impuestos_tasas AS cit
				UNION ALL
				SELECT [cuenta] = cit.contabilidad3 FROM ew_cat_impuestos_tasas AS cit
				UNION ALL
				SELECT [cuenta] = cit.contabilidad4 FROM ew_cat_impuestos_tasas AS cit
			) AS ic
		WHERE
			LEN(ic.cuenta) > 0
	)
	AND cpd.cuenta = (CASE WHEN @cuenta = '' THEN cpd.cuenta ELSE @cuenta END)
	AND ISNULL(stb_rel.transaccion, '') NOT IN ('BOR2')
	AND cpd.ejercicio = @ejercicio
	AND cpd.periodo BETWEEN @periodo1 AND @periodo2
GROUP BY
	('[' + cpd.cuenta + '] ' + cc.nombre)
	,ISNULL(p.codigo, ISNULL(pr.codigo, LTRIM(RTRIM(STR(bb.idbanco)))))
	,ISNULL(p.nombre, ISNULL(pr.nombre, bb.nombre))
	,ISNULL(p.rfc, ISNULL(pr.rfc, ISNULL(bb.rfc, '-Banco ' + bb.nombre + ' sin RFC-')))

ORDER BY
	cuenta_descripcion
	,proveedor_codigo
GO
