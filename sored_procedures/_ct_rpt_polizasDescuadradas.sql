USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20140806
-- Description:	Polizas descuadradas
-- =============================================
ALTER PROCEDURE [dbo].[_ct_rpt_polizasDescuadradas]
	@tolerancia AS DECIMAL(18,6) = 0.01
AS

SET NOCOUNT ON

SELECT
	pm.idtran
	,[ejercicio] = pol.ejercicio
	,[periodo] = pol.periodo
	,st.transaccion
	,[cargos] = SUM(pm.cargos)
	,[abonos] = SUM(pm.abonos)
	,[diferencia] = SUM(pm.cargos) - SUM(pm.abonos)
FROM
	ew_ct_poliza_mov AS pm
	LEFT JOIN ew_ct_poliza AS pol
		ON pol.idtran = pm.idtran
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = pm.idtran2
GROUP BY
	pm.idtran
	,pol.ejercicio
	,pol.periodo
	,st.transaccion
HAVING
	ABS(SUM(pm.cargos) - SUM(pm.abonos)) > @tolerancia
ORDER BY
	pol.ejercicio
	,pol.periodo
	,pm.idtran
GO
