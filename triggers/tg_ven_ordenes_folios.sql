USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171215
-- Description:	Validar folios
-- =============================================
ALTER TRIGGER [dbo].[tg_ven_ordenes_folios]
	ON [dbo].[ew_ven_ordenes]
	FOR INSERT
AS 

SET NOCOUNT ON

DECLARE
	@idtran AS INT
	,@idsucursal AS INT
	,@folio AS VARCHAR(15)

DECLARE cur_validaFolios CURSOR FOR
SELECT
	i.idtran
	,i.idsucursal
	,i.folio
FROM
	inserted AS i

OPEN cur_validaFolios

FETCH NEXT FROM cur_validaFolios INTO
	@idtran
	,@idsucursal
	,@folio

WHILE @@FETCH_STATUS = 0
BEGIN
	IF EXISTS (
		SELECT
			vo.idr
		FROM
			ew_ven_ordenes AS vo
		WHERE
			vo.idtran <> @idtran
			AND vo.idsucursal = @idsucursal
			AND vo.folio = @folio
	)
	BEGIN
		RAISERROR('Error: Hubo un problema con el consecutivo de folios debido a que se cambio de sucursal sin cerrar la transaccion. Por favor cierre la transaccion e intente de nuevo.', 16, 1)
		RETURN
	END

	FETCH NEXT FROM cur_validaFolios INTO
		@idtran
		,@idsucursal
		,@folio
END

CLOSE cur_validaFolios
DEALLOCATE cur_validaFolios
GO
