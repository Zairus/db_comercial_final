USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20091104
-- Description:	Afectar cartera
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_afectarCartera]
	 @idtran AS BIGINT
	,@idtran2 AS BIGINT
	,@tipo AS TINYINT
	,@idconcepto AS SMALLINT
	,@idcliente INT
	,@fecha AS SMALLDATETIME
	,@idmoneda AS SMALLINT
	,@importe AS DECIMAL(15,2)
	,@idu AS SMALLINT
	,@tipocambio AS DECIMAL(18,6) = 1
AS

SET NOCOUNT ON

INSERT INTO ew_cxc_movimientos (
	 idtran
	,idtran2
	,tipo
	,idconcepto
	,idcliente
	,fecha
	,idmoneda
	,importe
	,idu
	,tipocambio
)
VALUES (
	 @idtran
	,@idtran2
	,@tipo
	,@idconcepto
	,@idcliente
	,@fecha
	,@idmoneda
	,@importe
	,@idu
	,@tipocambio
)
GO
