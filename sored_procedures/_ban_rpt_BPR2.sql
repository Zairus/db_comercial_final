USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160407
-- Description:	Formato impresion corte de caja
-- =============================================
ALTER PROCEDURE [dbo].[_ban_rpt_BPR2]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	bd.idtran
	,[movimiento] = o.nombre
	,bd.fecha
	,bd.folio
	,[sucursal] = s.nombre

	,[cuenta_origen] = bb1.nombre + ' - ' + bc1.no_cuenta
	,[cuenta_destino] = bb2.nombre + ' - ' + bc2.no_cuenta
	
	,[total] = bd.importe

	,bdm.consecutivo
	
	,bdm.cantidad
	,[forma] = bf.nombre
	,[concepto] = bfc.nombre
	,bfc.denominacion
	,bdm.importe

	,[usuario] = u.nombre
FROM 
	ew_ban_documentos_mov AS bdm
	LEFT JOIN ew_ban_documentos AS bd
		ON bd.idtran = bdm.idtran
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = bd.idsucursal
	LEFT JOIN objetos AS o
		ON o.codigo = bd.transaccion

	LEFT JOIN ew_ban_cuentas AS bc1
		ON bc1.idcuenta = bd.idcuenta1
	LEFT JOIN ew_ban_bancos AS bb1
		ON bb1.idbanco = bc1.idbanco

	LEFT JOIN ew_ban_cuentas AS bc2
		ON bc2.idcuenta = bd.idcuenta2
	LEFT JOIN ew_ban_bancos AS bb2
		ON bb2.idbanco = bc2.idbanco

	LEFT JOIN ew_ban_formas AS bf
		ON bf.idforma = bdm.idforma
	LEFT JOIN ew_ban_formas_conceptos AS bfc
		ON bfc.idforma = bdm.idforma
		AND bfc.idconcepto = bdm.idconcepto

	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = bd.idu
WHERE 
	bdm.importe <> 0
	AND bdm.idtran = @idtran
GO
