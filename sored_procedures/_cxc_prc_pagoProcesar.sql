USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091203
-- Description:	Procesar pago de cliente
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_pagoProcesar]
	@idtran AS BIGINT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@cfd_version AS VARCHAR(10) = dbo._sys_fnc_parametroTexto('CFDI_VERSION')
	, @mensaje AS VARCHAR(1000) = ''
	, @rep_auto AS BIT
	, @fecha_operacion AS DATETIME

DECLARE
	@total_timbrados AS INT
	, @total_relacionados AS INT

SELECT @rep_auto = dbo._sys_fnc_parametroActivo('CFDI_REP_AUTOMATICO')

IF @rep_auto = 1
BEGIN
	IF EXISTS (
		SELECT *
		FROM
			ew_cxc_transacciones_mov AS ctm
			LEFT JOIN ew_cxc_transacciones AS f
				ON f.idtran = ctm.idtran2
		WHERE
			ctm.idtran = @idtran
			AND f.total <> ctm.importe2
			AND f.idmetodo = 1
	)
	BEGIN
		SELECT 
			@mensaje = (
				'Error: LA factura ' + f.folio
				+ ', esta generada con metodo de pago '
				+ 'PUE: Pago en una sola exhibicion. '
				+ 'Y no se esta pagando completamente, se debe pagar en una sola exhibicion.'
			)
		FROM
			ew_cxc_transacciones_mov AS ctm
			LEFT JOIN ew_cxc_transacciones AS f
				ON f.idtran = ctm.idtran2
		WHERE
			ctm.idtran = @idtran
			AND f.total <> ctm.importe2
			AND f.idmetodo = 1

		RAISERROR(@mensaje, 16, 1)
		RETURN
	END
	
	IF EXISTS (
		SELECT *
		FROM
			ew_cxc_transacciones AS ct
			LEFT JOIN ew_ban_formas_aplica AS bfa
				ON bfa.idforma = ct.idforma
			LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_formapago AS csf
				ON csf.c_formapago = bfa.codigo
		WHERE
			ct.idtran = @idtran
			AND ISNULL(csf.bancarizado, 0) = 1
			AND LEN(ct.clabe_origen) = 0
	)
	BEGIN
		SELECT 
			@mensaje = (
				'Error: Se indico como forma de pago: '
				+ ISNULL(bfa.descripcion, '-No seleccionada-')
				+ ', la cual es bancarizada y requiere de cuenta bancaria del Ordenante del pago.'
				+ ' Verifique que el cliente tiene capturadas sus cuentas bancarias y seleccione la correspondiente.'
			)
		FROM
			ew_cxc_transacciones AS ct
			LEFT JOIN ew_ban_formas_aplica AS bfa
				ON bfa.idforma = ct.idforma
		WHERE
			ct.idtran = @idtran
		
		RAISERROR(@mensaje, 16, 1)
		RETURN
	END

	IF EXISTS (
		SELECT
			*
		FROM
			ew_cxc_transacciones AS ct
			LEFT JOIN ew_ban_formas_aplica AS bfa
				ON bfa.idforma = ct.idforma
			LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_formapago AS csf
				ON csf.c_formapago = bfa.codigo
		WHERE
			ct.idtran = @idtran
			AND ISNULL(csf.bancarizado, 0) = 1
			AND [dbEVOLUWARE].[dbo].[regex_match](ct.clabe_origen, csf.cuenta_ordenante_patron) = 0
	)
	BEGIN
		SELECT
			@mensaje = (
				'Error: La cuenta del cliente [' + ct.clabe_origen + '], '
				+ 'no cumple con el patron indicado por el SAT para la forma de pago '
				+ csf.descripcion
			)
		FROM
			ew_cxc_transacciones AS ct
			LEFT JOIN ew_ban_formas_aplica AS bfa
				ON bfa.idforma = ct.idforma
			LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_formapago AS csf
				ON csf.c_formapago = bfa.codigo
		WHERE
			ct.idtran = @idtran

		RAISERROR(@mensaje, 16, 1)
		RETURN
	END

	IF EXISTS (
		SELECT *
		FROM
			ew_cxc_transacciones AS ct
			LEFT JOIN ew_ban_cuentas AS bc
				ON bc.idcuenta = ct.idcuenta
			LEFT JOIN ew_ban_bancos AS bb
				ON bb.idbanco = bc.idbanco
		WHERE
			LEN(ISNULL(bb.rfc, '')) = 0
			AND ct.idtran = @idtran
	)
	BEGIN
		SELECT
			@mensaje = (
				'Error: El banco de la empresa ['
				+ ISNULL(bb.nombre, '-Sin Especificar-')
				+ '], '
				+ 'no tiene RFC en su registro. '
				+ 'Corregir en Bancos / Catalogos / Bancos y cuentas.'
			)
		FROM
			ew_cxc_transacciones AS ct
			LEFT JOIN ew_ban_cuentas AS bc
				ON bc.idcuenta = ct.idcuenta
			LEFT JOIN ew_ban_bancos AS bb
				ON bb.idbanco = bc.idbanco
		WHERE
			LEN(ISNULL(bb.rfc, '')) = 0
			AND ct.idtran = @idtran

		RAISERROR(@mensaje, 16, 1)
		RETURN
	END

	SELECT
		@total_timbrados = SUM(CASE WHEN LEN(ISNULL(cct.cfdi_uuid, '')) > 0 THEN 1 ELSE 0 END)
		, @total_relacionados = SUM(CASE WHEN LEN(ISNULL(cct.cfdi_uuid, '')) > 0 THEN 0 ELSE 1 END)
	FROM
		ew_cxc_transacciones_mov AS ctm
		LEFT JOIN ew_cfd_comprobantes_timbre AS cct
			ON cct.idtran = ctm.idtran2
	WHERE
		ctm.idtran = @idtran

	SELECT @total_timbrados = ISNULL(@total_timbrados, 0)
	SELECT @total_relacionados = ISNULL(@total_relacionados, 0)

	IF @total_timbrados > 0 AND @total_relacionados > 0
	BEGIN
		SELECT @mensaje = 'Error: No se pueden mezclar documentos timbrados y no timbrados en un pago.'

		RAISERROR(@mensaje, 16, 1)
		RETURN
	END

	IF EXISTS(
		SELECT *
		FROM
			ew_cxc_transacciones_mov AS ctm
			LEFT JOIN ew_cxc_transacciones AS ct
				ON ct.idtran = ctm.idtran
			LEFT JOIN ew_cxc_transacciones_mov AS ctmc
				ON ctmc.idtran2 = ctm.idtran2
			LEFT JOIN ew_cxc_transacciones AS ctc
				ON ctc.idtran = ctmc.idtran
		WHERE
			ctc.cancelado = 1
			AND ct.idtran2 = 0
			AND ctm.idtran = @idtran
	)
	BEGIN
		SELECT
			@mensaje = (
				'Error: Se esta aplicando pago a la factura '
				+ ct.folio
				+ ', que tieneun pago previo cancelado (' + ctc.folio + '). '
				+ 'Y no seesta indicando un documentorelacionado para reemplazar el CFDi.'
			)
		FROM
			ew_cxc_transacciones_mov AS ctm
			LEFT JOIN ew_cxc_transacciones AS ct
				ON ct.idtran = ctm.idtran
			LEFT JOIN ew_cxc_transacciones_mov AS ctmc
				ON ctmc.idtran2 = ctm.idtran2
			LEFT JOIN ew_cxc_transacciones AS ctc
				ON ctc.idtran = ctmc.idtran
			LEFT JOIN ew_cxc_transacciones AS f
				ON f.idtran = ctm.idtran2
		WHERE
			ctc.cancelado = 1
			AND ct.idtran2 = 0
			AND ctm.idtran = @idtran

		RAISERROR(@mensaje, 16, 1)
		RETURN
	END

	SELECT
		@fecha_operacion = ct.fecha_operacion
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran
END

EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @idtran, 'BDC2', @idtran, NULL, 0, @fecha_operacion

INSERT INTO ew_sys_transacciones2 (
	idtran
	,idestado
	,idu
)
SELECT
	f.idtran
	,[idestado] = 50
	,[idu] = @idu
FROM 
	ew_cxc_transacciones_mov AS ctm
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
WHERE
	f.saldo = 0
	AND ctm.idtran = @idtran

UPDATE cep SET
	cep.aplicado = 1
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cfd_cep AS cep
		ON cep.idcomprobante = ct.idcomprobante
WHERE
	ct.idcomprobante > 0
	AND ct.idtran = @idtran
GO
