USE db_comercial_final
GO
IF OBJECT_ID('_xac_CONTABILIDAD_cargarDoc') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_CONTABILIDAD_cargarDoc
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190530
-- Description:	Cargar datos para grid de contabilidad
-- =============================================
CREATE PROCEDURE [dbo].[_xac_CONTABILIDAD_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[idr] = c.idr
	, [objidtran] = c.objidtran
	, [idtran2] = c.idtran2
	, [consecutivo] = c.consecutivo
	, [fecha] = c.fecha
	, [tipo_nombre] = c.tipo_nombre
	, [folio] = c.folio
	, [referencia] = c.referencia
	, [cuenta] = c.cuenta
	, [cuenta_nombre] = c.cuenta_nombre
	, [cargos] = c.cargos
	, [abonos] = c.abonos
	, [concepto] = c.concepto
FROM
	contabilidad AS c
WHERE
	c.idtran2 = @idtran
GO
