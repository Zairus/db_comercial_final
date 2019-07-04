USE db_comercial_final
GO
IF OBJECT_ID('_ct_rpt_diotDatos') IS NOT NULL
BEGIN
	DROP PROCEDURE _ct_rpt_diotDatos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190625
-- Description:	Informacion para DIOT
-- =============================================
CREATE PROCEDURE [dbo].[_ct_rpt_diotDatos]
	@ejercicio AS INT = NULL
	, @periodo AS INT = NULL
AS

SET NOCOUNT ON

SELECT @ejercicio = ISNULL(@ejercicio, YEAR(GETDATE()))
SELECT @periodo = ISNULL(@periodo, MONTH(GETDATE()))

SELECT
	[tipo_tercero] = cid.tipo_tercero
	, [tipo_operacion] = cid.tipo_operacion
	, [rfc] = cid.rfc
	, [campo_id] = cid.campo_id
	, [nombre_extranjero] = cid.nombre_extranjero
	, [pais_residencia] = cid.pais_residencia
	, [nacionalidad] = cid.nacionalidad

	, [valor_actos_16] = SUM(cid.valor_actos_16)
	, [valor_actos_15] = SUM(cid.valor_actos_15)
	, [iva_no_acreditable_16] = SUM(cid.iva_no_acreditable_16)
	, [valor_actos_11] = SUM(cid.valor_actos_11)
	, [valor_actos_10] = SUM(cid.valor_actos_10)
	, [valor_actos_8] = SUM(cid.valor_actos_8)
	, [iva_no_acreditable_11] = SUM(cid.iva_no_acreditable_11)
	, [iva_no_acreditable_8] = SUM(cid.iva_no_acreditable_8)
	, [valor_actos_importacion_16] = SUM(cid.valor_actos_importacion_16)
	, [iva_no_acreditable_importacion_16] = SUM(cid.iva_no_acreditable_importacion_16)
	, [valor_actos_importacion_11] = SUM(cid.valor_actos_importacion_11)
	, [iva_no_acreditable_importacion_11] = SUM(cid.iva_no_acreditable_importacion_11)
	, [valor_actos_importacion_0] = SUM(cid.valor_actos_importacion_0)
	, [valor_actos_0] = SUM(cid.valor_actos_0)
	, [valor_actos_E] = SUM(cid.valor_actos_E)
	, [iva_retenido] = SUM(cid.iva_retenido)
	, [iva_devoluciones] = SUM(cid.iva_devoluciones)
FROM 
	ew_od_ct_informacion_diot AS cid
WHERE
	cid.ejercicio = @ejercicio
	AND cid.periodo = @periodo
GROUP BY
	cid.tipo_tercero
	, cid.tipo_operacion
	, cid.rfc
	, cid.campo_id
	, cid.nombre_extranjero
	, cid.pais_residencia
	, cid.nacionalidad
GO
