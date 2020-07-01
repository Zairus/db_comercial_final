USE db_comercial_final
GO
IF OBJECT_ID('tg_ew_inv_transacciones_mov_id') IS NOT NULL
BEGIN
	DROP TRIGGER tg_ew_inv_transacciones_mov_id
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200125
-- Description:	Administrar IDMOV basado en idtran
-- =============================================
CREATE TRIGGER [dbo].[tg_ew_inv_transacciones_mov_id]
	ON [dbo].[ew_inv_transacciones_mov] 
FOR INSERT
AS

SET NOCOUNT ON

DECLARE
	@tabla AS VARCHAR(400)
	, @idr AS BIGINT
	, @idtran AS INT
	, @idmov AS MONEY

	, @oid AS INT
	, @tabla2 AS VARCHAR(400)
	, @idmov2 AS MONEY

SELECT @tabla = ''

DECLARE tg_ew_inv_transacciones_mov_id CURSOR FOR
	SELECT
		m.idr
		, m.idtran
		, m.idmov
	FROM 
		inserted AS m
	WHERE
		idmov IS NULL

OPEN tg_ew_inv_transacciones_mov_id

FETCH NEXT FROM tg_ew_inv_transacciones_mov_id INTO 
	@idr
	, @idtran
	, @idmov

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Encontrando la tabla 
	IF @tabla = ''
	BEGIN
		SELECT 
			@oid = parent_object_id 
		FROM 
			sys.objects
		WHERE 
			OBJECT_ID = @@PROCID

		SELECT @tabla2 = OBJECT_NAME(@oid)

		SELECT 
			@tabla = tabla
		FROM
			db_comercial.dbo.evoluware_tablas
		WHERE
			nombre = @tabla2
	END

	-- Obtenemos el ultimo idmov para el IDTRAN
	SELECT @idmov2 = dbo.NewIDMOV(@idtran, @tabla)

	-- insertando el IDMOV en la tabla EW_SYS_TRANSACCIONES_MOV
	INSERT INTO ew_sys_movimientos (
		idmov
		, tabla
	) 
	VALUES (
		@idmov2
		, @tabla
	)
	
	-- Actualizando el IDMOV para el registro actual
	UPDATE ew_inv_transacciones_mov SET
		idmov = @idmov2 
	WHERE 
		idr = @idr
	
	FETCH NEXT FROM tg_ew_inv_transacciones_mov_id INTO 
		@idr
		, @idtran
		, @idmov
END

CLOSE tg_ew_inv_transacciones_mov_id
DEALLOCATE tg_ew_inv_transacciones_mov_id
GO
EXEC sp_settriggerorder @triggername=N'[dbo].[tg_ew_inv_transacciones_mov_id]', @order=N'First', @stmttype=N'INSERT'
