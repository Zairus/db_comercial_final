USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180928
-- Description:	Indica si un pago se puede timbrar
-- =============================================
ALTER FUNCTION _cxc_fnc_pagoPosibleTimbrar
(
	@idtran AS INT
)
RETURNS BIT
AS
BEGIN
	DECLARE 
		@posible AS BIT
		,@registros AS INT
		,@timbrados AS INT
		,@no_timbrados AS INT

	SELECT
		@registros = COUNT(*)
	FROM
		ew_cxc_transacciones_mov AS ctm
	WHERE
		ctm.idtran = @idtran

	SELECT
		@timbrados = SUM(CASE WHEN LEN(ISNULL(cct.cfdi_uuid, '')) > 0 THEN 1 ELSE 0 END)
		, @no_timbrados = SUM(CASE WHEN LEN(ISNULL(cct.cfdi_uuid, '')) > 0 THEN 0 ELSE 1 END)
	FROM
		ew_cxc_transacciones_mov AS ctm
		LEFT JOIN ew_cfd_comprobantes_timbre AS cct
			ON cct.idtran = ctm.idtran2
	WHERE
		ctm.idtran = @idtran

	SELECT @timbrados = ISNULL(@timbrados, 0)
	SELECT @no_timbrados = ISNULL(@no_timbrados, 0)

	IF @no_timbrados = @registros
	BEGIN
		SELECT @posible = 0
	END

	IF @registros = 0 OR @timbrados > 0
	BEGIN
		SELECT @posible = 1
	END

	SELECT @posible = ISNULL(@posible, 1)

	RETURN @posible
END
GO
