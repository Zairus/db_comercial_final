USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091029
-- Description:	Procesar recepción
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_entradaProcesar]
	@idtran AS BIGINT
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

--CERRAR LA GDA1
INSERT INTO ew_sys_transacciones2 (
	idtran
	,idestado
	,idu
)
VALUES (
	@idtran
	,251
	,@idu
)
GO
