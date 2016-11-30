USE db_comercial_final
GO
ALTER VIEW [dbo].[ew_sys_transacciones_contabilidad]
AS
SELECT
	 pm.idr
	,pol.idtran
	,pm.idtran2
	,[idmov] = 0
	,pol.fecha
	,pol.folio
	,[pol_referencia] = pol.referencia
	,[pol_concepto] = pol.concepto
	,pm.consecutivo
	,pm.cuenta
	,cc.nombre
	,pol.periodo
	,pol.ejercicio
	,pm.referencia
	,pm.cargos
	,pm.abonos
	,pm.concepto
	,pm.fechahora
FROM 
	ew_ct_poliza_mov AS pm
	LEFT JOIN ew_ct_poliza AS pol
		ON pol.idtran = pm.idtran
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = pm.cuenta
GO
