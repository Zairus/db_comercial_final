USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_facturaRelacionProcesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_facturaRelacionProcesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180731
-- Description:	Procesar factura de relacion
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_facturaRelacionProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@credito AS BIT
	, @idforma AS INT
	, @relacion_idtran AS INT
	, @relacion_cancelado AS BIT
	, @relacion_saldo AS DECIMAL(18,6)
	, @idu AS INT

UPDATE ct SET
	ct.idtran2 = vt.idtran2
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vt.idtran
WHERE
	vt.idtran = @idtran

SELECT
	@credito = ct.credito
	, @idforma  = ct.idforma
	, @relacion_idtran = vt.idtran2
	, @relacion_cancelado = r.cancelado
	, @relacion_saldo = r.saldo
	, @idu = vt.idu
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones AS r
		ON r.idtran = vt.idtran2
WHERE 
	ct.idtran = @idtran
	
IF EXISTS (
	SELECT *
	FROM
		ew_cxc_transacciones
	WHERE
		idrelacion = 0
		AND idtran = @idtran
)
BEGIN
	RAISERROR('Error: Se debe indicar tipo de relacion.', 16, 1)
	RETURN
END

IF @credito = 1
BEGIN
	UPDATE ct SET
		ct.idforma = (
			SELECT TOP 1 bf.idforma 
			FROM ew_ban_formas_aplica AS bf
			WHERE codigo = '99'
		)
		, ct.idmetodo = 2
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran
END
	ELSE
BEGIN
	UPDATE ct SET
		ct.idmetodo = 1
	FROM
		ew_cxc_transacciones AS ct
	WHERE
		ct.idtran = @idtran

	IF NOT EXISTS (
		SELECT *
		FROM
			ew_ban_formas_aplica
		WHERE
			idforma = @idforma
	)
	BEGIN
		RAISERROR('Error: No ha seleccionado forma de pago para la nueva factura.', 16, 1)
		RETURN
	END
END

IF @relacion_cancelado = 0 OR @relacion_saldo = 0
BEGIN
	EXEC [dbo].[_cxc_prc_desaplicarTransaccion] @relacion_idtran, @idu
END
GO