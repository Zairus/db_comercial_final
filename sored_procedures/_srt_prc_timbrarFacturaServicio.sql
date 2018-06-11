USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180605
-- Description:	Timbra una factura en proceso de facturacion de servicio
-- =============================================
ALTER PROCEDURE _srt_prc_timbrarFacturaServicio
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

EXEC _cfd_prc_timbrarComprobante @idtran, @idu

SELECT
	[timbrada] = CONVERT(BIT, 1)
	,[uuid] = ISNULL((
		SELECT
			cci.cfdi_UUID
		FROM
			ew_cfd_comprobantes_timbre AS cci
		WHERE
			cci.idtran = @idtran
	), '')
GO
