USE db_comercial_final
GO
IF OBJECT_ID('tg_ser_ordenes_bitacora_id') IS NOT NULL
BEGIN
	DROP TRIGGER tg_ser_ordenes_bitacora_id
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200125
-- Description:	Administrar IDMOV basado en idtran
-- =============================================
CREATE TRIGGER [dbo].[tg_ser_ordenes_bitacora_id]
	ON [dbo].[ew_ser_ordenes_bitacora] 
FOR INSERT
AS

SET NOCOUNT ON

DECLARE
	@idtran AS INT
	, @cont AS INT
	, @msg AS VARCHAR(250)
	, @idr AS BIGINT
	, @idmov AS MONEY
	, @idmov2 AS MONEY
	, @tabla AS VARCHAR(400)
	, @tabla2 AS VARCHAR(100)
	, @oid AS INT

SELECT @tabla = ''

DECLARE tg_ser_ordenes_bitacora_id CURSOR FOR
	SELECT
		m.idr
		, m.idtran
		, m.idmov
	FROM 
		inserted AS m
	WHERE
		idmov IS NULL

OPEN tg_ser_ordenes_bitacora_id

FETCH NEXT FROM tg_ser_ordenes_bitacora_id INTO 
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
			evoluware_tablas
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
	UPDATE ew_ser_ordenes_bitacora SET
		idmov = @idmov2 
	WHERE 
		idr = @idr
	
	FETCH NEXT FROM tg_ser_ordenes_bitacora_id INTO 
		@idr
		, @idtran
		, @idmov
END

CLOSE tg_ser_ordenes_bitacora_id
DEALLOCATE tg_ser_ordenes_bitacora_id
GO
