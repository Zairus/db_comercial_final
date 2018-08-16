USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180816
-- Description:	Valida que las aplicaciones de un documento sean todas timbradas o todas no timbradas
-- =============================================
CREATE PROCEDURE _cxc_prc_validarTimbreAplicacion
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@timbrados AS INT
	,@no_timbrados AS INT

SELECT
	@timbrados = COUNT(*)
FROM
	ew_cxc_transacciones_mov AS ctm
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = ctm.idtran
WHERE
	ctm.idtran = @idtran
	AND LEN(ISNULL(cct.cfdi_uuid, '')) > 0

SELECT
	@no_timbrados = COUNT(*)
FROM
	ew_cxc_transacciones_mov AS ctm
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = ctm.idtran
WHERE
	ctm.idtran = @idtran
	AND LEN(ISNULL(cct.cfdi_uuid, '')) = 0

SELECT @timbrados = ISNULL(@timbrados, 0)
SELECT @no_timbrados = ISNULL(@no_timbrados, 0)

IF ABS(@timbrados) > 0 AND ABS(@no_timbrados) > 0
BEGIN
	RAISERROR('Error: No se puede aplicar referenciando documentos timbrados y no timbrados.', 16, 1)
	RETURN
END
GO
