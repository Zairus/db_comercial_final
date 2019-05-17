USE db_comercial_final
GO
IF OBJECT_ID('_ban_prc_bdt2_procesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ban_prc_bdt2_procesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190430
-- Description:	Procesar integracion de deposito ventas
-- =============================================
CREATE PROCEDURE [dbo].[_ban_prc_bdt2_procesar]
	@idtran AS INT
AS

SET NOCOUNT ON

GO
