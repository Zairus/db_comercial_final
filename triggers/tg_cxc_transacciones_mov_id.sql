USE db_comercial_final
GO
-- =================================================================
-- Programador:		Laurence Saavedra
-- Descripcion:		Obtener automaticamente el IDMOV basado en su idtran
-- Fecha Creacion:	2010-01
-- Fecha Cambio:	2010-02
-- =================================================================
CREATE TRIGGER [dbo].[tg_cxc_transacciones_mov_id] ON [dbo].[ew_cxc_transacciones_mov] 
FOR INSERT
AS

SET NOCOUNT ON

DECLARE
	 @idtran AS INT
	,@cont AS INT
	,@msg AS VARCHAR(250)
	,@idr AS BIGINT
	,@idmov AS MONEY
	,@idmov2 AS MONEY
	,@tabla AS VARCHAR(4)
	,@tabla2 AS VARCHAR(100)
	,@oid AS INT

SELECT @tabla = ''

DECLARE tg_cxc_transacciones_mov_id CURSOR FOR
	SELECT
		m.idr
		, m.idtran
		, m.idmov
	FROM 
		inserted AS m
	WHERE
		idmov IS NULL

OPEN tg_cxc_transacciones_mov_id

FETCH NEXT FROM tg_cxc_transacciones_mov_id INTO 
	@idr
	, @idtran
	, @idmov

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Encontrando la tabla 
	IF @tabla = ''
	BEGIN
		SELECT @oid = parent_object_id FROM sys.objects WHERE object_id = @@PROCID
		SELECT @tabla2 = OBJECT_NAME(@oid)
		SELECT @tabla = tabla FROM evoluware_tablas WHERE nombre = @tabla2
	END

	-- Obtenemos el ultimo idmov para el IDTRAN
	SELECT @idmov2 = dbo.NewIDMOV(@idtran, @tabla)
	
	-- insertando el IDMOV en la tabla EW_SYS_TRANSACCIONES_MOV
	INSERT INTO ew_sys_movimientos (
		idmov
		, tabla
	) VALUES (
		@idmov2
		, @tabla
	)
	
	-- Actualizando el IDMOV para el registro actual
	UPDATE ew_cxc_transacciones_mov SET
		idmov = @idmov2
	WHERE 
		idr = @idr
	
	FETCH NEXT FROM tg_cxc_transacciones_mov_id INTO 
		@idr
		, @idtran
		, @idmov
END

CLOSE tg_cxc_transacciones_mov_id
DEALLOCATE tg_cxc_transacciones_mov_id
GO
