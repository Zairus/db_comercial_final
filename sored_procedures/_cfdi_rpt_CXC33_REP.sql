USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180824
-- Description:	Formato de impreison CFDi 33 para REP
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_rpt_CXC33_REP]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[cliente_banco_rfc] = c_bb.rfc
	,[cliente_banco_nombre] = c_bb.nombre
	,[cliente_cuenta] = ccb.clabe

	,[empresa_banco_rfc] = bb.rfc
	,[empresa_banco_nombre] = bb.nombre
	,[empresa_cuenta] = bc.clabe

	,[fecha_operacion] = ct.fecha
	,[forma_pago] = '[' + cc.cfd_metodoDePago + ']' + ISNULL(' ' + csf.descripcion, '')
	,[tipo_cambio] = cc.cfd_tipoCambio
	,[moneda] = cc.cfd_moneda
	,[no_operacion] = ''
	,[monto] = cc.cfd_total
	,[tipo_pago] = (
	CASE 
		WHEN ct.idcomprobante > 0 THEN 'SPEI' 
		ELSE (
			CASE 
				WHEN cc.cfd_metodoDePago = '03' THEN 'TEF' 
				ELSE '' 
			END
		) 
	END
	)
	,[certificado_pago] = cc.cfd_noCertificado
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_clientes_cuentas_bancarias AS ccb
		ON ccb.idcliente = ct.idcliente
		AND ccb.clabe = ct.clabe_origen
	LEFT JOIN ew_ban_bancos As c_bb
		ON c_bb.idbanco = ccb.idbanco
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = ct.idcuenta
	LEFT JOIN ew_ban_bancos AS bb
		ON bb.idbanco = bc.idbanco
	LEFT JOIN ew_cfd_comprobantes AS cc
		ON cc.idtran = ct.idtran
	LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_formapago AS csf
		ON csf.c_formapago = cc.cfd_metodoDePago
WHERE
	ct.idtran = @idtran
GO
