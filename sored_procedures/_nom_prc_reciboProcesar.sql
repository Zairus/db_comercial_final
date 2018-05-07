USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20140402
-- Description:	Procesar recibo de nomina
-- =============================================
ALTER PROCEDURE [dbo].[_nom_prc_reciboProcesar]
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@dias_pagados AS INT

SELECT
	@dias_pagados = DATEDIFF(DAY, nt.fecha_inicial, nt.fecha_final)
FROM
	ew_nom_transacciones AS nt
WHERE
	nt.idtran = @idtran

IF @dias_pagados <= 0
BEGIN
	RAISERROR('Error: No se indico correctament el periodo a pagar.', 16, 1)
	RETURN
END
GO
