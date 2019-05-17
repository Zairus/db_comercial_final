USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180928
-- Description:	Indica si un pago se puede timbrar
-- =============================================
ALTER FUNCTION [dbo].[_cxc_fnc_pagoPosibleTimbrar]
(
	@idtran AS INT
)
RETURNS BIT
AS
BEGIN
	DECLARE 
		@posible AS BIT
		, @registros AS INT
		, @timbrados AS INT
		, @no_timbrados AS INT

	-- Obtener cuantas facturas se estan pagando
	SELECT
		@registros = COUNT(*)
	FROM
		ew_cxc_transacciones_mov AS ctm
	WHERE
		ctm.idtran = @idtran

	-- De las facturas que se estan pagando, obtener cuantas son timbradas y cuantas no timbradas
	SELECT
		@timbrados = SUM(CASE WHEN LEN(ISNULL(cct.cfdi_uuid, '')) > 0 THEN 1 ELSE 0 END)
		, @no_timbrados = SUM(CASE WHEN LEN(ISNULL(cct.cfdi_uuid, '')) > 0 THEN 0 ELSE 1 END)
	FROM
		ew_cxc_transacciones_mov AS ctm
		LEFT JOIN ew_cfd_comprobantes_timbre AS cct
			ON cct.idtran = ctm.idtran2
	WHERE
		ctm.idtran = @idtran

	-- Eliminar nulos
	SELECT @timbrados = ISNULL(@timbrados, 0)
	SELECT @no_timbrados = ISNULL(@no_timbrados, 0)

	-- Si todos los registros son no timbrados, no es posible timbrar
	IF @no_timbrados = @registros
	BEGIN
		SELECT @posible = 0
	END

	-- Si no tiene facturas pagadas (es anticipo), o todas estan timbradas, si es posible timbrar
	IF @registros = 0 OR @timbrados > 0
	BEGIN
		SELECT @posible = 1
	END

	SELECT @posible = ISNULL(@posible, 1)

	-- Si el pago se creo de una factura de contado, no se puede timbrar
	SELECT
		@registros = COUNT(*)
	FROM
		ew_cxc_transacciones_mov AS ctm
		LEFT JOIN ew_cxc_transacciones AS f
			ON f.idtran = ctm.idtran2
	WHERE
		ctm.idtran = @idtran
		AND f.credito = 0
		AND (SELECT COUNT(*) FROM ew_ven_transacciones_pagos AS vtp WHERE vtp.idtran = f.idtran) > 0

	IF @registros > 0
	BEGIN
		SELECT @posible = 0
	END
	
	-- Si el pago se recibio en una cuenta de caja, no se puede timbrar
	SELECT
		@registros = COUNT(*)
	FROM
		ew_cxc_transacciones AS ct
		LEFT JOIN ew_ban_cuentas AS bc
			ON bc.idcuenta = ct.idcuenta
	WHERE
		ct.idtran = @idtran
		AND bc.tipo IN (3,4,5)

	IF @registros > 0
	BEGIN
		SELECT @posible = 0
	END

	RETURN @posible
END
GO
