USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 2018086
-- Description:	Regresa numro de documentos no timbrados afectdos por una transaccion de CXC
-- =============================================
ALTER FUNCTION _cxc_fnc_aplicaNoTimbrados
(
	@idtran AS INT
)
RETURNS INT
AS
BEGIN
	DECLARE
		@no_timbrados AS INT = 0

	SELECT
		@no_timbrados = COUNT(*)
	FROM
		ew_cxc_transacciones_mov AS ctm
		LEFT JOIN ew_cfd_comprobantes_timbre AS cct
			ON cct.idtran = ctm.idtran
	WHERE
		ctm.idtran = @idtran
		AND LEN(ISNULL(cct.cfdi_uuid, '')) = 0

	SELECT @no_timbrados = ISNULL(@no_timbrados, 0)

	RETURN @no_timbrados
END
GO
