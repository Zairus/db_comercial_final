USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180605
-- Description:	Timbra una factura en proceso de facturacion de servicio
-- =============================================
ALTER PROCEDURE [dbo].[_srt_prc_timbrarFacturaServicio]
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@email AS VARCHAR(500)
	, @mensaje AS VARCHAR(500) = 'Se adjunta su comprobante electornico.'
	, @cfd_folio AS VARCHAR(20)

SELECT
	@email = c.email
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = ct.idcliente
WHERE
	ct.idtran = @idtran

EXEC _cfd_prc_timbrarComprobante @idtran, @idu

IF LEN(@email) > 0
BEGIN
	EXEC [dbo].[_cfd_prc_enviarEmail] @idtran, @email, @mensaje, 1
END

SELECT
	@cfd_folio = (cc.cfd_serie + dbo._sys_fnc_rellenar(cc.cfd_folio, 6, '0'))
FROM
	ew_cfd_comprobantes AS cc
WHERE
	cc.idtran = @idtran

IF @cfd_folio IS NOT NULL
BEGIN
	UPDATE ew_sys_transacciones SET folio = @cfd_folio WHERE idtran = @idtran
	UPDATE ew_cxc_transacciones SET folio = @cfd_folio WHERE idtran = @idtran
	UPDATE ew_ven_transacciones SET folio = @cfd_folio WHERE idtran = @idtran
END

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
