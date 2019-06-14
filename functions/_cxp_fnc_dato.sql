USE db_comercial_final
GO
IF OBJECT_ID('_cxp_fnc_dato') IS NOT NULL
BEGIN
	DROP FUNCTION _cxp_fnc_dato
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190611
-- Description:	Regresa un dato ne relacion a pago de compras / gastps
-- =============================================
CREATE FUNCTION [dbo].[_cxp_fnc_dato]
(
	@dato AS VARCHAR(200)
	, @idsucursal AS INT
	, @ejercicio AS INT
	, @periodo AS INT
)
RETURNS DECIMAL(18,6)
AS
BEGIN
	DECLARE
		@valor AS DECIMAL(18,6)

	SELECT
		@valor = (
			CASE @dato
				WHEN ':CXPP_GASTOS16' THEN
					(
						SELECT SUM(occp.concepto_importe * occp.factura_proporcion_pago)
						FROM
							ew_od_cxp_conceptos_pagados AS occp
						WHERE
							occp.tipo = 'Gasto'
							AND occp.concepto_impuesto1_tasa = 0.16
							AND (occp.idsucursal = @idsucursal OR @idsucursal = 0)
							AND occp.ejercicio = @ejercicio
							AND occp.periodo = @periodo
					)
				WHEN ':CXPP_GASTOS8' THEN
					(
						SELECT SUM(occp.concepto_importe * occp.factura_proporcion_pago)
						FROM
							ew_od_cxp_conceptos_pagados AS occp
						WHERE
							occp.tipo = 'Gasto'
							AND occp.concepto_impuesto1_tasa = 0.08
							AND (occp.idsucursal = @idsucursal OR @idsucursal = 0)
							AND occp.ejercicio = @ejercicio
							AND occp.periodo = @periodo
					)
				WHEN ':CXPP_COMPRAS0' THEN
					(
						SELECT SUM(occp.concepto_importe * occp.factura_proporcion_pago)
						FROM
							ew_od_cxp_conceptos_pagados AS occp
						WHERE
							occp.tipo = 'Compra'
							AND occp.concepto_impuesto1_tasa = 0
							AND (occp.idsucursal = @idsucursal OR @idsucursal = 0)
							AND occp.ejercicio = @ejercicio
							AND occp.periodo = @periodo
					)
				WHEN ':COM_IEPS9' THEN
					(
						SELECT SUM(occp.concepto_importe * occp.factura_proporcion_pago)
						FROM
							ew_od_cxp_conceptos_pagados AS occp
						WHERE
							occp.tipo = 'Compra'
							AND occp.concepto_impuesto2_tasa = 0.09
							AND (occp.idsucursal = @idsucursal OR @idsucursal = 0)
							AND occp.ejercicio = @ejercicio
							AND occp.periodo = @periodo
					)
				WHEN ':COM_IEPS7' THEN
					(
						SELECT SUM(occp.concepto_importe * occp.factura_proporcion_pago)
						FROM
							ew_od_cxp_conceptos_pagados AS occp
						WHERE
							occp.tipo = 'Compra'
							AND occp.concepto_impuesto2_tasa = 0.07
							AND (occp.idsucursal = @idsucursal OR @idsucursal = 0)
							AND occp.ejercicio = @ejercicio
							AND occp.periodo = @periodo
					)
				WHEN ':COM_IEPS6' THEN
					(
						SELECT SUM(occp.concepto_importe * occp.factura_proporcion_pago)
						FROM
							ew_od_cxp_conceptos_pagados AS occp
						WHERE
							occp.tipo = 'Compra'
							AND occp.concepto_impuesto2_tasa = 0.06
							AND (occp.idsucursal = @idsucursal OR @idsucursal = 0)
							AND occp.ejercicio = @ejercicio
							AND occp.periodo = @periodo
					)
				WHEN ':COM_IEPS0' THEN
					(
						SELECT SUM(occp.concepto_importe * occp.factura_proporcion_pago)
						FROM
							ew_od_cxp_conceptos_pagados AS occp
						WHERE
							occp.tipo = 'Compra'
							AND occp.concepto_impuesto2_tasa = 0
							AND (occp.idsucursal = @idsucursal OR @idsucursal = 0)
							AND occp.ejercicio = @ejercicio
							AND occp.periodo = @periodo
					)

				-----------------------------------------------
				WHEN ':COMI_IEPS9' THEN
					(
						SELECT SUM(occp.concepto_impuesto2 * occp.factura_proporcion_pago)
						FROM
							ew_od_cxp_conceptos_pagados AS occp
						WHERE
							occp.tipo = 'Compra'
							AND occp.concepto_impuesto2_tasa = 0.09
							AND (occp.idsucursal = @idsucursal OR @idsucursal = 0)
							AND occp.ejercicio = @ejercicio
							AND occp.periodo = @periodo
					)
				WHEN ':COMI_IEPS7' THEN
					(
						SELECT SUM(occp.concepto_impuesto2 * occp.factura_proporcion_pago)
						FROM
							ew_od_cxp_conceptos_pagados AS occp
						WHERE
							occp.tipo = 'Compra'
							AND occp.concepto_impuesto2_tasa = 0.07
							AND (occp.idsucursal = @idsucursal OR @idsucursal = 0)
							AND occp.ejercicio = @ejercicio
							AND occp.periodo = @periodo
					)
				WHEN ':COMI_IEPS6' THEN
					(
						SELECT SUM(occp.concepto_impuesto2 * occp.factura_proporcion_pago)
						FROM
							ew_od_cxp_conceptos_pagados AS occp
						WHERE
							occp.tipo = 'Compra'
							AND occp.concepto_impuesto2_tasa = 0.06
							AND (occp.idsucursal = @idsucursal OR @idsucursal = 0)
							AND occp.ejercicio = @ejercicio
							AND occp.periodo = @periodo
					)

				-------------------------------------------------
				WHEN ':VEN_IEPS9' THEN
					(
						SELECT SUM(ovc.concepto_importe)
						FROM
							ew_od_ven_conceptos AS ovc
						WHERE
							ovc.concepto_impuesto2_tasa = 0.09
							AND (ovc.idsucursal = @idsucursal OR @idsucursal = 0)
							AND ovc.ejercicio = @ejercicio
							AND ovc.periodo = @periodo
					)
				WHEN ':VEN_IEPS7' THEN
					(
						SELECT SUM(ovc.concepto_importe)
						FROM
							ew_od_ven_conceptos AS ovc
						WHERE
							ovc.concepto_impuesto2_tasa = 0.07
							AND (ovc.idsucursal = @idsucursal OR @idsucursal = 0)
							AND ovc.ejercicio = @ejercicio
							AND ovc.periodo = @periodo
					)
				WHEN ':VEN_IEPS6' THEN
				(
						SELECT SUM(ovc.concepto_importe)
						FROM
							ew_od_ven_conceptos AS ovc
						WHERE
							ovc.concepto_impuesto2_tasa = 0.06
							AND (ovc.idsucursal = @idsucursal OR @idsucursal = 0)
							AND ovc.ejercicio = @ejercicio
							AND ovc.periodo = @periodo
					)
				WHEN ':VEN_IEPS0' THEN
					(
						SELECT SUM(ovc.concepto_importe)
						FROM
							ew_od_ven_conceptos AS ovc
						WHERE
							ovc.concepto_impuesto2_tasa = 0
							AND (ovc.idsucursal = @idsucursal OR @idsucursal = 0)
							AND ovc.ejercicio = @ejercicio
							AND ovc.periodo = @periodo
					)

				-------------------------------------
				WHEN ':VENI_IEPSP9'THEN
					(
						SELECT SUM(ovc.concepto_impuesto2 * ovc.factura_proporcion_pago)
						FROM
							ew_od_ven_conceptos AS ovc
						WHERE
							ovc.concepto_impuesto2_tasa = 0.09
							AND (ovc.idsucursal = @idsucursal OR @idsucursal = 0)
							AND ovc.ejercicio = @ejercicio
							AND ovc.periodo = @periodo
					)
				WHEN ':VENI_IEPSP7'THEN
					(
						SELECT SUM(ovc.concepto_impuesto2 * ovc.factura_proporcion_pago)
						FROM
							ew_od_ven_conceptos AS ovc
						WHERE
							ovc.concepto_impuesto2_tasa = 0.07
							AND (ovc.idsucursal = @idsucursal OR @idsucursal = 0)
							AND ovc.ejercicio = @ejercicio
							AND ovc.periodo = @periodo
					)
				WHEN ':VENI_IEPSP6'THEN
					(
						SELECT SUM(ovc.concepto_impuesto2 * ovc.factura_proporcion_pago)
						FROM
							ew_od_ven_conceptos AS ovc
						WHERE
							ovc.concepto_impuesto2_tasa = 0.06
							AND (ovc.idsucursal = @idsucursal OR @idsucursal = 0)
							AND ovc.ejercicio = @ejercicio
							AND ovc.periodo = @periodo
					)
			END
		)

	SELECT @valor = ISNULL(@valor, 0)

	RETURN @valor
END
GO
