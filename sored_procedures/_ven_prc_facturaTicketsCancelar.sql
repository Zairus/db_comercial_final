USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_facturaTicketsCancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_facturaTicketsCancelar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150915
-- Description:	Cancelar factura de tickets
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_facturaTicketsCancelar]
	@idtran AS INT
	, @fecha AS SMALLDATETIME
	, @idu AS INT
	, @confirmacion AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@fecha_factura AS DATETIME
	, @total AS DECIMAL(18,6)
	, @tipocambio AS DECIMAL(18,6)

SELECT 
	@fecha_factura = fecha
FROM 
	ew_ven_transacciones 
WHERE 
	idtran = @idtran

SELECT
	@total = total
	, @tipocambio = tipocambio
FROM
	ew_cxc_transacciones
WHERE
	idtran = @idtran

IF @confirmacion = 0
BEGIN
	IF (DATEDIFF (HOUR, @fecha_factura, GETDATE()) > 72 AND (@total * @tipocambio) > 5000)
	BEGIN
		RAISERROR('Error: No se pueden cancelar facturas cuya fecha de emisión sea mayor a 72 horas con respecto al dia de cancelación y el importe no debe ser mayor a $5000.00 MXN.', 16, 1)
		RETURN
	END
END

UPDATE ew_cxc_transacciones SET
	cancelado = 1
	, cancelado_fecha = GETDATE()
WHERE
	idtran = @idtran

UPDATE ew_ven_transacciones SET
	cancelado = 1
	, cancelado_fecha = GETDATE()
WHERE
	idtran = @idtran

INSERT INTO ew_sys_transacciones2 (
	 idtran
	,idestado
	,idu
)
SELECT
	[idtran] = @idtran
	, [idestado] = 255
	, [idu] = @idu
WHERE
	@confirmacion = 1

INSERT INTO ew_sys_transacciones2 (
	 idtran
	,idestado
	,idu
)
SELECT
	 [idtran] = ctr.idtran2
	,[idestado] = (CASE WHEN ct.saldo = 0 THEN 50 ELSE 0 END)
	,[idu] = ft.idu
FROM
	ew_cxc_transacciones_rel AS ctr
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = ctr.idtran2
	LEFT JOIN ew_cxc_transacciones AS ft
		ON ft.idtran = ctr.idtran
WHERE
	ctr.idtran = @idtran
GO
