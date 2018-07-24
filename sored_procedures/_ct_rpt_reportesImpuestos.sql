USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180717
-- Description:	Presentacion de reportes para impuestos
-- =============================================
ALTER PROCEDURE [dbo].[_ct_rpt_reportesImpuestos]
	@idreporte AS INT
	, @ejercicio AS INT = NULL
	, @periodo AS INT = NULL
AS

SET NOCOUNT ON

SELECT @ejercicio = ISNULL(@ejercicio, YEAR(GETDATE()))
SELECT @periodo = ISNULL(@periodo, MONTH(GETDATE()))

SELECT
	[grupo] = cs.nombre + ' (' + cs.cuenta + ')'
	, [nombre] = cc.nombre + ' (' + cc.cuenta + ')'
	, [tipo] = t.nombre
	, [folio] = pol.folio
	, [referencia] = pm.referencia
	, [fecha] = pol.fecha
	, [cargos] = pm.cargos
	, [abonos] = pm.abonos
	, [saldo_final] = (pm.cargos - pm.abonos) * (CASE WHEN circ.restar = 1 THEN -1 ELSE 1 END)
	, [sucursal] = ISNULL(s.nombre, '-Err.-')
	, [concepto] = pm.concepto
	, [idtran] = pm.idtran
FROM 
	ew_cat_impuestos_reportes AS cir
	LEFT JOIN ew_cat_impuestos_reportes_cuentas AS circ
		ON circ.idreporte = cir.idreporte
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = circ.cuenta
	LEFT JOIN ew_ct_cuentas AS cs
		ON cs.cuenta = cc.cuentasup
	LEFT JOIN ew_ct_poliza AS pol
		ON pol.ejercicio = @ejercicio
		AND pol.periodo = @periodo
	LEFT JOIN ew_ct_tipos AS t
		ON t.idtipo = pol.idtipo
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.idtran = pol.idtran
		AND pm.cuenta = circ.cuenta
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = pm.idsucursal
WHERE
	cir.idreporte = @idreporte

	AND pm.idr IS NOT NULL
ORDER BY
	circ.orden
	, cs.llave
	, cc.llave
GO
