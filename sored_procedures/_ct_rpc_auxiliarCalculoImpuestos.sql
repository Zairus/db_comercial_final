USE db_comercial_final
GO
IF OBJECT_ID('_ct_rpc_auxiliarCalculoImpuestos') IS NOT NULL
BEGIN
	DROP PROCEDURE _ct_rpc_auxiliarCalculoImpuestos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190610
-- Description:	Reporte auxiliar para calculo de impuestos
-- =============================================
CREATE PROCEDURE [dbo].[_ct_rpc_auxiliarCalculoImpuestos]
	@idsucursal AS INT = 0
	, @ejercicio AS INT = NULL
AS

SET NOCOUNT ON

--EWValueReplacementType (str_code, str_value)
DECLARE
	@tabla_valores AS EWValueReplacementType

DECLARE
	@p AS INT = 1

SELECT @ejercicio = ISNULL(@ejercicio, YEAR(GETDATE()))

CREATE TABLE #_tmp_cuentas_ACIF (
	idr INT IDENTITY
	, orden INT NOT NULL
	, cuenta VARCHAR(200) NOT NULL
	, titulo VARCHAR(500) NOT NULL DEFAULT ''
	, operacion VARCHAR(4000) NOT NULL DEFAULT ''
	, oculto BIT NOT NULL DEFAULT 0
) ON [PRIMARY]

CREATE TABLE #_tmp_resultados_ACIF (
	idr INT IDENTITY
	, orden INT
	, oculto BIT NOT NULL DEFAULT 0
	, descripcion VARCHAR(MAX)
	, periodo1 DECIMAL(18,2)
	, periodo2 DECIMAL(18,2)
	, periodo3 DECIMAL(18,2)
	, periodo4 DECIMAL(18,2)
	, periodo5 DECIMAL(18,2)
	, periodo6 DECIMAL(18,2)
	, periodo7 DECIMAL(18,2)
	, periodo8 DECIMAL(18,2)
	, periodo9 DECIMAL(18,2)
	, periodo10 DECIMAL(18,2)
	, periodo11 DECIMAL(18,2)
	, periodo12 DECIMAL(18,2)
) ON [PRIMARY]

INSERT INTO #_tmp_cuentas_ACIF (
	orden
	, cuenta
	, titulo
	, operacion
)
VALUES
	
	(3, '4100002000', 'VENTAS 0', '')
	, (3, '4100003000', 'VENTAS EXENTAS I.V.A.', '')
	, (7, '4200000000', 'DEVOLUCIONES Y DESC', '')
	, (7, '', '----------------------------------------', '')
	, (7, '', 'TOTAL INGRESOS NETOS', '4100002000 + 4100003000 - 4200000000')
	, (7, '', '', '')
	, (7, '', '', '')

	, (8, '2130002004', 'RETENCIONES ISR POR SUELDOS Y SALARIOS  (ISPT)', '')
	, (7, '', '', '')
	, (9, '2130002001', 'RETENCIONES ISR POR ASIMILADOS A SALARIOS', '')
	, (7, '', '', '')
	, (10, '2130002003', 'RETENCIONES ISR 10% ARRENDAMIENTOS PAGADO', '')
	, (7, '', '', '')

	, (11, '', 'REPORTE DE GASTOS "PAGADOS" POR TIPO DE IMPUESTO', '')
	, (12, ':CXPP_GASTOS16', 'TOTAL GASTOS PAGADOS AL 16% DE IVA -GASTOS-', '')
	, (13, '1150003001', 'IVA ACREDITABLE PAGADO AL 16%', '')
	, (14, ':CXPP_GASTOS8', 'GASTOS PAGADOS AL 8% DE IVA', '')
	, (15, '1150003003', 'IVA ACREDITABLE PAGADO AL 8%', '')
	, (7, '', '', '')

	, (16, '', 'REPORTE DE COMPRAS "PAGADOS" POR TIPO DE IMPUESTO', '')
	, (17, ':CXPP_COMPRAS0', 'TOTAL ACTOS PAGADOS AL 0% DE IVA-COMPRA MCIAS-', '')
	, (7, '', '', '')

	, (18, '', 'REPORTE DE VENTAS INGRESADAS  POR TIPO DE IMPUESTOS', '')
	, (19, '4100001000', 'TOTAL ACTOS GRAVADOS AL 16% DE IVA-VENTAS-', '')
	, (20, '2130001002', 'IVA POR PAGAR AL 16%', '')
	, (6, '4100005000', 'TOTAL ACTOS GRAVADOS AL 8% DE IVA-VENTAS-', '')
	, (20, '2130001004', 'IVA TRASLADADO 8% POR COBRAR', '')
	, (7, '', '----------------------------------------', '')
	, (21, '', 'TOTAL VENTAS CON IVA', '2130001002 + 2130001004 - 1150003001 - 1150003003')
	, (7, '', '', '')

	, (22, '2130002012', 'RETENCIONES IVA 4% FLETES PAGADO', '')
	, (22, '2130002014', 'RETENCIONES IVA DE ARRENDAMIENTOS PAGADO', '')
	, (22, '2130002005', 'RETENCIONES IVA DE HONORARIOS PAGADO', '')
	, (7, '', '----------------------------------------', '')
	, (22, '', 'TOTAL IVA RETENCIONES', '2130002012 + 2130002014 + 2130002005')
	, (7, '', '', '')

	, (23, '', 'REPORTE DE VENTAS DESGL POR CADA IEPS', '')
	, (24, ':VEN_IEPS9', 'VENTA IEPS AL 9%', '')
	, (25, ':VEN_IEPS7', 'VENTA IEPS AL 7%', '')
	, (26, ':VEN_IEPS6', 'VENTA IEPS AL 6%', '')
	, (27, ':VEN_IEPS0', 'VENTA IEPS AL 0%', '')
	, (7, '', '----------------------------------------', '')
	, (28, '', 'TOTAL VENTAS CON IEPS', ':VEN_IEPS9 + :VEN_IEPS7 + :VEN_IEPS6 + :VEN_IEPS0')
	, (7, '', '', '')

	, (29, '', 'REPORTE DE IEPS EFECTIVAMENTE COBRADO EN VENTAS', '')
	, (30, ':VENI_IEPSP9', 'IEPS COBRADO POR VENTAS AL 9%', '')
	, (31, ':VENI_IEPSP7', 'IEPS COBRADO POR VENTAS AL 7%', '')
	, (32, ':VENI_IEPSP6', 'IEPS COBRADO PO R VENTAS AL 6%', '')
	, (7, '', '----------------------------------------', '')
	, (33, '', 'TOTAL IEPS COBRADO POR VENTAS', ':VENI_IEPSP9 + :VENI_IEPSP7 + :VENI_IEPSP6')
	, (7, '', '', '')

	, (34, '', 'REPORTE DE COMPRAS PAGADAS POR TIPO DE IMPUESTOS', '')
	, (35, ':COM_IEPS9', 'COMPRAS IEPS PAGADO AL 9%', '')
	, (36, ':COM_IEPS7', 'COMPRA IEPS PAGADO AL 7%', '')
	, (37, ':COM_IEPS6', 'COMPRA IEPS PAGADO AL 6%', '')
	, (38, ':COM_IEPS0', 'COMPRA IEPS PAGADO AL 0%', '')
	, (7, '', '----------------------------------------', '')
	, (39, '', 'TOTAL COMPRAS CON IEPS EFECT. PAGADO', ':COM_IEPS9 + :COM_IEPS7 + :COM_IEPS6 + :COM_IEPS0')
	, (7, '', '', '')

	, (40, '', 'REPORTE DE IEPS EFECTIVAMENTE PAGADO', '')
	, (41, ':COMI_IEPS9', 'IEPS POR COMPRAS AL 9%', '')
	, (42, ':COMI_IEPS7', 'IEPS POR COMPRAS AL 7%', '')
	, (43, ':COMI_IEPS6', 'IEPS POR COMPRAS AL 6%', '')
	, (7, '', '----------------------------------------', '')
	, (44, '', 'TOTAL IEPS ACREDITABLE POR COMPRAS', ':COMI_IEPS9 + :COMI_IEPS7 + :COMI_IEPS6')
	, (7, '', '', '')

UPDATE #_tmp_cuentas_ACIF SET orden = idr

INSERT INTO #_tmp_resultados_ACIF (
	orden
	, descripcion
	, periodo1
	, periodo2
	, periodo3
	, periodo4
	, periodo5
	, periodo6
	, periodo7
	, periodo8
	, periodo9
	, periodo10
	, periodo11
	, periodo12
)

SELECT
	[orden] = acif.orden --ROW_NUMBER() OVER (ORDER BY acif.orden)
	, [descripcion]= ISNULL(cc.nombre, acif.titulo)

	, [periodo1] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 1, @idsucursal)
	, [periodo2] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 2, @idsucursal)
	, [periodo3] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 3, @idsucursal)
	, [periodo4] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 4, @idsucursal)
	, [periodo5] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 5, @idsucursal)
	, [periodo6] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 6, @idsucursal)
	, [periodo7] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 7, @idsucursal)
	, [periodo8] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 8, @idsucursal)
	, [periodo9] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 9, @idsucursal)
	, [periodo10] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 10, @idsucursal)
	, [periodo11] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 11, @idsucursal)
	, [periodo12] = [dbo].[_ct_fnc_cuentaSaldoPeriodo](cc.cuenta, @ejercicio, 12, @idsucursal)
FROM
	#_tmp_cuentas_ACIF AS acif
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = acif.cuenta

UPDATE racif SET
	racif.periodo1 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 1)
	, racif.periodo2 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 2)
	, racif.periodo3 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 3)
	, racif.periodo4 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 4)
	, racif.periodo5 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 5)
	, racif.periodo6 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 6)
	, racif.periodo7 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 7)
	, racif.periodo8 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 8)
	, racif.periodo9 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 9)
	, racif.periodo10 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 10)
	, racif.periodo11 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 11)
	, racif.periodo12 = [dbo].[_cxp_fnc_dato](cacif.cuenta, @idsucursal, @ejercicio, 12)
FROM
	#_tmp_resultados_ACIF AS racif
	LEFT JOIN #_tmp_cuentas_ACIF AS cacif
		ON cacif.orden = racif.orden
WHERE
	cacif.cuenta LIKE ':%'

WHILE @p < 13
BEGIN
	DELETE FROM @tabla_valores

	INSERT INTO @tabla_valores (
		str_code
		, str_value
	)
	SELECT
		cacif.cuenta
		, [str_value] = (
			CASE @p
				WHEN 1 THEN racif.periodo1
				WHEN 2 THEN racif.periodo2
				WHEN 3 THEN racif.periodo3
				WHEN 4 THEN racif.periodo4
				WHEN 5 THEN racif.periodo5
				WHEN 6 THEN racif.periodo6
				WHEN 7 THEN racif.periodo7
				WHEN 8 THEN racif.periodo8
				WHEN 9 THEN racif.periodo9
				WHEN 10 THEN racif.periodo10
				WHEN 11 THEN racif.periodo11
				WHEN 12 THEN racif.periodo12
			END
		)
	FROM 
		#_tmp_resultados_ACIF AS racif
		LEFT JOIN #_tmp_cuentas_ACIF AS cacif
			ON cacif.orden = racif.orden
	WHERE
		LEN(cacif.cuenta) > 0

	UPDATE racif SET
		racif.periodo1 = (
			CASE 
				WHEN @p = 1 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo1 
			END
		)
		, racif.periodo2 = (
			CASE 
				WHEN @p = 2 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo2 
			END
		)
		, racif.periodo3 = (
			CASE 
				WHEN @p = 3 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo3
			END
		)
		, racif.periodo4 = (
			CASE 
				WHEN @p = 4 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo4
			END
		)
		, racif.periodo5 = (
			CASE 
				WHEN @p = 5 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo5
			END
		)
		, racif.periodo6 = (
			CASE 
				WHEN @p = 6 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo6
			END
		)
		, racif.periodo7 = (
			CASE 
				WHEN @p = 7 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo7
			END
		)
		, racif.periodo8 = (
			CASE 
				WHEN @p = 8 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo8
			END
		)
		, racif.periodo9 = (
			CASE 
				WHEN @p = 9 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo9
			END
		)
		, racif.periodo10 = (
			CASE 
				WHEN @p = 10 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo10
			END
		)
		, racif.periodo11 = (
			CASE 
				WHEN @p = 11 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo11
			END
		)
		, racif.periodo12 = (
			CASE 
				WHEN @p = 12 THEN [dbEVOLUWARE].[dbo].[txt_eval]([dbo].[_sys_fnc_cadenaReemplazarMultiple](cacif.operacion, @tabla_valores)) 
				ELSE racif.periodo12
			END
		)
	FROM 
		#_tmp_resultados_ACIF AS racif
		LEFT JOIN #_tmp_cuentas_ACIF AS cacif
			ON cacif.orden = racif.orden
	WHERE
		LEN(cacif.operacion) > 0

	SELECT @p = @p + 1
END

SELECT * 
FROM 
	#_tmp_resultados_ACIF 
WHERE 
	oculto = 0 
ORDER BY 
	orden

DROP TABLE #_tmp_cuentas_ACIF
DROP TABLE #_tmp_resultados_ACIF
GO

