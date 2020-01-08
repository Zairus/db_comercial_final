USE db_comercial_final
GO
IF OBJECT_ID('_cfdi_prc_cancelarComprobantesPendientes') IS NOT NULL
BEGIN
	DROP PROCEDURE _cfdi_prc_cancelarComprobantesPendientes
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20191231
-- Description:	Procesa cancelaciones de CFDi Pendienres
-- =============================================
CREATE PROCEDURE [dbo].[_cfdi_prc_cancelarComprobantesPendientes]
AS

SET NOCOUNT ON

DECLARE
	@cmd AS NVARCHAR(MAX)

DECLARE cur_cancelaCFDI CURSOR FOR
	SELECT
		[cmd] = 'EXEC [dbo].[_cfdi_prc_cancelarFacturaSAT] ' + LTRIM(RTRIM(STR(cc.idtran))) + '; WAITFOR DELAY ''00:00:02''; '
	FROM 
		ew_cfd_comprobantes AS cc
		LEFT JOIN ew_cfd_comprobantes_timbre AS cct
			ON cct.idtran = cc.idtran
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = cc.idtran
	WHERE
		ct.cancelado = 1
		AND (SELECT COUNT(*) FROM ew_cfd_comprobantes_cancelados AS ccc WHERE ccc.idtran = cc.idtran AND LEN(ccc.acuse) > 0) = 0

OPEN cur_cancelaCFDI

FETCH NEXT FROM cur_cancelaCFDI INTO
	@cmd

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC sp_executesql @cmd

	FETCH NEXT FROM cur_cancelaCFDI INTO
		@cmd
END

CLOSE cur_cancelaCFDI
DEALLOCATE cur_cancelaCFDI
GO
