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

IF EXISTS (
	SELECT *
	FROM
		ew_cxc_transacciones
	WHERE
		LEN(clabe_origen) = 0
		AND idtran = @idtran
)
BEGIN
	RAISERROR('Error: No se indico cuenta bancaria del cliente.', 16, 1)
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
	AND (SELECT COUNT(*) FROM ew_sys_transacciones2 AS st2 WHERE st2.idestado = 50 AND st2.idtran = f.idtran) = 0
	AND ctm.idtran = @idtran
GO
