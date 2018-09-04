USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091203
-- Description:	Procesar pago de cliente
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_pagoProcesar]
	@idtran AS BIGINT
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@cfd_version AS VARCHAR(10) = dbo._sys_fnc_parametroTexto('CFDI_VERSION')
	,@mensaje AS VARCHAR(1000) = ''
	,@rep_auto AS BIT

SELECT @rep_auto = dbo._sys_fnc_parametroActivo('CFDI_REP_AUTOMATICO')

IF @rep_auto = 1 AND EXISTS (
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

EXEC [dbo].[_ct_prc_contabilizarBDC2] @idtran

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
