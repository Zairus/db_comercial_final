USE db_comercial_final
GO
IF OBJECT_ID('_xac_BPR4_cargarDoc') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_BPR4_cargarDoc
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190407
-- Description:	Cargar informacion para estado de cuenta bancario
-- =============================================
CREATE PROCEDURE _xac_BPR4_cargarDoc
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[transaccion] = becp.transaccion
	, [banco] = becp.banco
	, [cuenta] = becp.cuenta
	, [periodo] = becp.periodo
	, [ejercicio] = becp.ejercicio
	, [idr] = becp.idr
	, [idtran] = becp.idtran
	, [spa1] = ''
FROM 
	ew_ban_estado_cuenta_periodo AS becp
WHERE
	becp.idtran = @idtran

SELECT
	[fecha] = becpm.fecha
	, [folio] = becpm.folio
	, [concepto] = becpm.concepto
	, [ingresos] = becpm.ingresos
	, [egresos] = becpm.egresos

	, [conciliado_folio] = ISNULL(conc.folio, '')
	, [conciliado_mov] = ISNULL(conc.transaccion, '')

	, [idtran2] = ISNULL(conc.idtran, 0)
	, [objidtran] = ISNULL(conc.idtran, 0)

	, [idr] = becpm.idr
	, [idtran] = becpm.idtran
	, [spa2] = ''
FROM 
	ew_ban_estado_cuenta_periodo_mov AS becpm
	LEFT JOIN ew_ban_transacciones AS conc
		ON conc.idr = (
			SELECT TOP 1
				bt1.idr
			FROM
				ew_ban_transacciones AS bt1
			WHERE
				bt1.conciliado_id = becpm.idr
		)
WHERE
	becpm.idtran = @idtran
ORDER BY
	becpm.fecha
GO
