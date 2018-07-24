USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100701
-- Description:	Balanza de Comprobación
-- =============================================
ALTER PROCEDURE [dbo].[_ct_rpt_balanzaComprobacionB]
	 @ejercicio AS SMALLINT = NULL
	,@idsucursal AS SMALLINT = 0
	,@periodo1 AS SMALLINT = NULL
	,@periodo2 AS SMALLINT = NULL
	,@nivel AS TINYINT = 6
AS

SET NOCOUNT ON

DECLARE
	@anterior_debe AS DECIMAL(18,6)
	,@anterior_haber AS DECIMAL(18,6)
	,@movimientos_debe AS DECIMAL(18,6)
	,@movimientos_haber AS DECIMAL(18,6)
	,@saldo_debe AS DECIMAL(18,6)
	,@saldo_haber AS DECIMAL(18,6)
	,@errores AS VARCHAR(MAX) = ''

SELECT @ejercicio = ISNULL(@ejercicio, YEAR(GETDATE()))
SELECT @periodo1 = ISNULL(@periodo1, MONTH(GETDATE()))
SELECT @periodo2 = ISNULL(@periodo2, MONTH(GETDATE()))

CREATE TABLE #tmp_balanza (
	[objlevel] SMALLINT
	,cuenta VARCHAR (100)
	,nombre VARCHAR (100)
	,nivel SMALLINT
	,anterior_debe DECIMAL(18,2)
	,anterior_haber DECIMAL(18,2)
	,movimientos_debe DECIMAL (18,2)
	,movimientos_haber DECIMAL (18,2)
	,saldo_debe DECIMAL(18,2)
	,saldo_haber DECIMAL (18,2)
)

INSERT INTO #tmp_balanza (
	objlevel
	,cuenta	
	,nombre	
	,nivel	
	,anterior_debe
	,anterior_haber
	,movimientos_debe
	,movimientos_haber
	,saldo_debe 
	,saldo_haber
)

SELECT
	 [objlevel] = cc.nivel
	,csg.cuenta
	,cc.nombre
	,cc.nivel
	,[anterior_debe] = SUM(CASE WHEN cc.naturaleza = 0 AND csg.periodo = @periodo1 THEN csg.saldo_inicial ELSE 0 END)
	,[anterior_haber] = SUM(CASE WHEN cc.naturaleza = 1 AND csg.periodo = @periodo1 THEN csg.saldo_inicial ELSE 0 END)
	,[movimientos_debe] = SUM(csg.cargos)
	,[movimientos_haber] = SUM(csg.abonos)
	,[saldo_debe] = SUM(CASE WHEN cc.naturaleza = 0 AND csg.periodo = @periodo2 THEN csg.saldo_final ELSE 0 END)
	,[saldo_haber] = SUM(CASE WHEN cc.naturaleza = 1 AND csg.periodo = @periodo2 THEN csg.saldo_final ELSE 0 END)
FROM
	ew_ct_saldosGlobales AS csg
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = csg.cuenta
WHERE
	csg.ejercicio = @ejercicio
	AND csg.idsucursal = @idsucursal
	AND csg.periodo BETWEEN @periodo1 AND @periodo2
	AND cc.nivel <= @nivel
	AND cc.idcuenta NOT IN (8,9,10)
GROUP BY
	 cc.nivel
	,csg.cuenta
	,cc.nombre
	,cc.llave
ORDER BY
	cc.llave

SELECT
	@anterior_debe = SUM(tb.anterior_debe)
	,@anterior_haber = SUM(tb.anterior_haber)
	,@movimientos_debe = SUM(tb.movimientos_debe)
	,@movimientos_haber = SUM(tb.movimientos_haber)
	,@saldo_debe = SUM(tb.saldo_debe)
	,@saldo_haber = SUM(tb.saldo_haber)
FROM 
	#tmp_balanza AS tb
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = tb.cuenta
WHERE
	cc.nivel = 0

IF ABS(@anterior_debe - @anterior_haber) > 0.0
BEGIN
	SELECT @errores = @errores + 'Los Saldos Anteriores no coinciden [' + FORMAT((@anterior_debe - @anterior_haber), '#,##0.#0', 'ES-MX') + '].' + CHAR(10) + CHAR(13)
END

IF ABS(@movimientos_debe - @movimientos_haber) > 0.0
BEGIN
	SELECT @errores = @errores + 'Los Movimientos Debe y Haber no coinciden [' + FORMAT((@movimientos_debe - @movimientos_haber), '#,##0.#0', 'ES-MX') + '].' + CHAR(10) + CHAR(13)
END

IF ABS(@saldo_debe - @saldo_haber) > 0.0
BEGIN
	SELECT @errores = @errores + 'Los Saldos Finales no coinciden [' + FORMAT((@movimientos_debe - @movimientos_haber), '#,##0.#0', 'ES-MX') + '].' + CHAR(10) + CHAR(13)
END

SELECT
	tb.objlevel
	,tb.cuenta
	,tb.nombre
	,tb.nivel
	,tb.anterior_debe
	,tb.anterior_haber
	,tb.movimientos_debe
	,tb.movimientos_haber
	,tb.saldo_debe
	,tb.saldo_haber
	,[titulo] = UPPER(
		'Balanza de Comprobacion '
		+ 'del '
		+ [dbo].[_sys_fnc_rellenar](1, 2, '0')
		+ '/'
		+ [dbo].[_sys_fnc_rellenar](@periodo1, 2, '0')
		+ '/'
		+ [dbo].[_sys_fnc_rellenar](@ejercicio, 4, '0')
		+ ' al '
		+ [dbo].[_sys_fnc_rellenar](DAY(DATEADD(MONTH, @periodo2 - 1, '31/01/1900')), 2, '0')
		+ '/'
		+ [dbo].[_sys_fnc_rellenar](@periodo2, 2, '0')
		+ '/'
		+ [dbo].[_sys_fnc_rellenar](@ejercicio, 4, '0')
	) 
	,[fecha_imp] = (
		'Fecha: '
		+ [dbo].[_sys_fnc_rellenar](DAY(GETDATE()), 2, '0')
		+ '/'
		+ [dbo].[_sys_fnc_rellenar](MONTH(GETDATE()), 2, '0')
		+ '/'
		+ [dbo].[_sys_fnc_rellenar](YEAR(GETDATE()), 4, '0')
	)

	,[suma_anterior_debe] = @anterior_debe
	,[suma_anterior_haber] = @anterior_haber
	,[suma_mov_debe] = @movimientos_debe
	,[suma_mov_haber] = @movimientos_haber
	,[suma_saldo_debe] = @saldo_debe
	,[suma_saldo_haber] = @saldo_haber
	,[errores] = (CASE WHEN LEN(@errores) = 0 THEN 'No se encontraron errores.' ELSE @errores END)
FROM 
	#tmp_balanza AS tb
WHERE 
	tb.anterior_debe <> 0
	OR tb.anterior_haber <> 0
	OR tb.movimientos_debe <> 0
	OR tb.movimientos_haber <> 0
	OR tb.saldo_debe <> 0
	OR tb.saldo_haber <> 0
	
DROP TABLE #tmp_balanza
GO
