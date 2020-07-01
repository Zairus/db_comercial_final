USE db_comercial_final
GO
IF OBJECT_ID('ew_cxc_saldosGlobales') IS NOT NULL
BEGIN
	DROP VIEW ew_cxc_saldosGlobales
END
GO
CREATE VIEW [dbo].[ew_cxc_saldosGlobales]
AS
SELECT
	[idcliente] = c.idcliente
	, [nombre] = c.nombre
	, [ejercicio] = ej.ejercicio
	, [idmoneda] = mon.idmoneda
	, [moneda_sistema] = ms.moneda_sistema
	, [periodo] = CONVERT(INT, per.valor)
	, [saldo_inicial] = ISNULL((
		SELECT
			CASE CONVERT(INT, per.valor)
				WHEN 0 THEN 0
				WHEN 1 THEN cs0.periodo0
				WHEN 2 THEN cs0.periodo1 + cs0.periodo0
				WHEN 3 THEN cs0.periodo2 + cs0.periodo0
				WHEN 4 THEN cs0.periodo3 + cs0.periodo0
				WHEN 5 THEN cs0.periodo4 + cs0.periodo0
				WHEN 6 THEN cs0.periodo5 + cs0.periodo0
				WHEN 7 THEN cs0.periodo6 + cs0.periodo0
				WHEN 8 THEN cs0.periodo7 + cs0.periodo0
				WHEN 9 THEN cs0.periodo8 + cs0.periodo0
				WHEN 10 THEN cs0.periodo9 + cs0.periodo0
				WHEN 11 THEN cs0.periodo10 + cs0.periodo0
				WHEN 12 THEN cs0.periodo11 + cs0.periodo0
				WHEN 13 THEN cs0.periodo12 + cs0.periodo0
				ELSE 0
			END
		FROM
			ew_cxc_saldos AS cs0
		WHERE
			cs0.tipo = 1
			AND cs0.idcliente = c.idcliente
			AND cs0.idmoneda = mon.idmoneda
			ANd cs0.ejercicio = ej.ejercicio
	), 0)
	, [cargos] = ISNULL((
		SELECT
			CASE CONVERT(INT, per.valor)
				WHEN 0 THEN cs1.periodo0
				WHEN 1 THEN cs1.periodo1
				WHEN 2 THEN cs1.periodo2
				WHEN 3 THEN cs1.periodo3
				WHEN 4 THEN cs1.periodo4
				WHEN 5 THEN cs1.periodo5
				WHEN 6 THEN cs1.periodo6
				WHEN 7 THEN cs1.periodo7
				WHEN 8 THEN cs1.periodo8
				WHEN 9 THEN cs1.periodo9
				WHEN 10 THEN cs1.periodo10
				WHEN 11 THEN cs1.periodo11
				WHEN 12 THEN cs1.periodo12
				WHEN 13 THEN cs1.periodo13
			END
		FROM
			ew_cxc_saldos AS cs1
		WHERE
			cs1.tipo = 2
			AND cs1.idcliente = c.idcliente
			AND cs1.idmoneda = mon.idmoneda
			AND cs1.ejercicio = ej.ejercicio
	), 0)
	, [abonos] = ISNULL((
		SELECT
			CASE CONVERT(INT, per.valor)
				WHEN 0 THEN cs2.periodo0
				WHEN 1 THEN cs2.periodo1
				WHEN 2 THEN cs2.periodo2
				WHEN 3 THEN cs2.periodo3
				WHEN 4 THEN cs2.periodo4
				WHEN 5 THEN cs2.periodo5
				WHEN 6 THEN cs2.periodo6
				WHEN 7 THEN cs2.periodo7
				WHEN 8 THEN cs2.periodo8
				WHEN 9 THEN cs2.periodo9
				WHEN 10 THEN cs2.periodo10
				WHEN 11 THEN cs2.periodo11
				WHEN 12 THEN cs2.periodo12
				WHEN 13 THEN cs2.periodo13
			END
		FROM
			ew_cxc_saldos AS cs2
		WHERE
			cs2.tipo = 3
			AND cs2.idcliente = c.idcliente
			AND cs2.idmoneda = mon.idmoneda
			AND cs2.ejercicio = ej.ejercicio
	), 0)
	, [saldo_final] = ISNULL((
		SELECT
			CASE CONVERT(INT, per.valor)
				WHEN 0 THEN cs4.periodo0
				WHEN 1 THEN cs4.periodo1 + cs4.periodo0
				WHEN 2 THEN cs4.periodo2 + cs4.periodo0
				WHEN 3 THEN cs4.periodo3 + cs4.periodo0
				WHEN 4 THEN cs4.periodo4 + cs4.periodo0
				WHEN 5 THEN cs4.periodo5 + cs4.periodo0
				WHEN 6 THEN cs4.periodo6 + cs4.periodo0
				WHEN 7 THEN cs4.periodo7 + cs4.periodo0
				WHEN 8 THEN cs4.periodo8 + cs4.periodo0
				WHEN 9 THEN cs4.periodo9 + cs4.periodo0
				WHEN 10 THEN cs4.periodo10 + cs4.periodo0
				WHEN 11 THEN cs4.periodo11 + cs4.periodo0
				WHEN 12 THEN cs4.periodo12 + cs4.periodo0
				WHEN 13 THEN cs4.periodo13
				ELSE 0
			END
		FROM
			ew_cxc_saldos AS cs4
		WHERE
			cs4.tipo = 1
			AND cs4.idcliente = c.idcliente
			AND cs4.idmoneda = mon.idmoneda
			ANd cs4.ejercicio = ej.ejercicio
	), 0)
	, [saldo_promedio] = CONVERT(DECIMAL(15,2), ISNULL((
		SELECT
			CASE CONVERT(INT, per.valor)
				WHEN 0 THEN cs4.periodo0
				WHEN 1 THEN cs4.periodo1 + cs4.periodo0
				WHEN 2 THEN cs4.periodo2 + cs4.periodo0
				WHEN 3 THEN cs4.periodo3 + cs4.periodo0
				WHEN 4 THEN cs4.periodo4 + cs4.periodo0
				WHEN 5 THEN cs4.periodo5 + cs4.periodo0
				WHEN 6 THEN cs4.periodo6 + cs4.periodo0
				WHEN 7 THEN cs4.periodo7 + cs4.periodo0
				WHEN 8 THEN cs4.periodo8 + cs4.periodo0
				WHEN 9 THEN cs4.periodo9 + cs4.periodo0
				WHEN 10 THEN cs4.periodo10 + cs4.periodo0
				WHEN 11 THEN cs4.periodo11 + cs4.periodo0
				WHEN 12 THEN cs4.periodo12 + cs4.periodo0
				WHEN 13 THEN cs4.periodo13
				ELSE 0
			END
		FROM
			ew_cxc_saldos AS cs4
		WHERE
			cs4.tipo = 1
			AND cs4.idcliente = c.idcliente
			AND cs4.idmoneda = mon.idmoneda
			ANd cs4.ejercicio = ej.ejercicio
	), 0) / CONVERT(DECIMAL(15,2), per.valor))
FROM 
	ew_clientes AS c
	LEFT JOIN (
		SELECT DISTINCT
			ejercicio
		FROM
			ew_cxc_saldos
	) AS ej
		ON ej.ejercicio = ej.ejercicio
	LEFT JOIN (
		SELECT
			 idmoneda
			,[moneda] = nombre
			,[moneda_codigo] = nombre_corto
		FROM
			ew_ban_monedas 
	) AS mon
		ON mon.idmoneda = mon.idmoneda
	LEFT JOIN dbo._sys_fnc_separarMultilinea('1,2,3,4,5,6,7,8,9,10,11,12', ',') AS per
		ON per.valor = per.valor
	LEFT JOIN (SELECT [moneda_sistema] = CONVERT(BIT, valor) FROM dbo._sys_fnc_separarMultilinea('0,1', ',')) AS ms
		ON ms.moneda_sistema = ms.moneda_sistema
GO
