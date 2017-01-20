USE db_comercial_final
GO
-- SP: 	Inserta un transaccion ejecutando la sentencia SQL que se pasa como parametro,
--	simula lo que hace el ejecutable del cifra.
--	Requiere que en el comando SQL, el valor para el campo IDTRAN se identifique mediante 
--	macros cifra: {idtran} y el valor que tomará el campo FOLIO se debe representar como {folio}
-- 	Elaborado por Laurence Saavedra
-- 	Agosto del 2006
--	Modificado en Abril del 2008
--
ALTER PROCEDURE [dbo].[_sys_prc_insertarTransaccion]
	@usuario AS VARCHAR(20) -- Nombre de Usuario
	,@password AS VARCHAR(20) -- Contraseña de Usuario
	,@transaccion AS VARCHAR(5) -- Codigo de la Transaccion
	,@idsucursal AS SMALLINT -- Codigo de la Sucursal
	,@serie AS VARCHAR(3) = 'A' -- Serie para el Folio
	,@sql AS VARCHAR(8000) -- Sentencia SQL a ejecutar
	,@foliolen AS TINYINT = 0 -- Que longitud debe tener el folio, para rellenarse con ceros, independiente del 'prefijo', equivale al parametro ASCFILL:=n
	,@idtran AS BIGINT OUTPUT -- IDTRAN obtenido, se regresa
	,@afolio AS VARCHAR(10) = '' -- Folio desde el origen
	,@afecha AS VARCHAR(20) = '' -- Fecha de la transaccion
AS

SET NOCOUNT ON

SET DATEFORMAT DMY

DECLARE 
	@fecha AS SMALLDATETIME

DECLARE 
	@msg AS VARCHAR(1000)
	,@cont AS SMALLINT
	,@pass AS VARCHAR(20)
	,@folio AS INT
	,@nFolio AS VARCHAR(10)
	,@prefijo AS VARCHAR(3)
	,@error AS INT
	,@guardar AS BIT
	,@xFolio AS VARCHAR(20)
	,@rc AS INT

SELECT @pass = ''

IF @afecha!=''
BEGIN
	SELECT @fecha = CONVERT(SMALLDATETIME, @afecha)
END
	ELSE
BEGIN
	SELECT @fecha = GETDATE()
END

-- Validando el usuario
SELECT @pass = [password] 
FROM 
	ew_usuarios 
WHERE 
	activo = 1
	AND usuario = @usuario 

IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'El usuario [' + ISNULL(@usuario, 'NULL') + '] no es válido'
	RAISERROR(@msg, 16, 1)
	RETURN
END

-- comparando contraseña
IF @password != @pass
BEGIN
	SELECT @msg = 'Contraseña inválida'
	RAISERROR(@msg, 16, 1)
	RETURN
END

-- Comprobando si existe el registro para obtener el folio en la tabla FOLIOS_DOC, si no existe se inserta un nuevo registro
SELECT 
	@cont = COUNT(*) 
FROM 
	ew_sys_folios
WHERE 
	idsucursal = @idsucursal 
	AND transaccion = @transaccion 
	AND serie = @serie 

IF @cont = 0
BEGIN
	INSERT INTO ew_sys_folios
		(idsucursal, transaccion, serie, folioserie, folio, estatus)
	VALUES
		(@idsucursal, @transaccion, @serie, '', 0, '0')
END

SELECT @cont = 0
SELECT @folio = 0

-- Tenemos 5 intentos de bloqueo
WHILE @cont < 5
BEGIN
	-- Intentamos bloquear el folio exclusivamente
	UPDATE ew_sys_folios SET 
		estatus = 1
		,usuario = @usuario
		,estacion = dbo._sys_fnc_host()
		,hora = GETDATE()
	WHERE
		idsucursal = @idsucursal 
		AND transaccion = @transaccion 
		AND serie = @serie 
		AND estatus = 0
	
	SELECT @rc = @@rowcount
	
	IF @rc > 0
	BEGIN
		-- Se logró bloquear el folio, obtenemos el folio siguiente para asignar
		IF @afolio = ''
		BEGIN
			SELECT 
				@folio = (CASE WHEN folio IS NULL THEN 0 ELSE folio END) + 1
				,@nFolio = RTRIM((CASE WHEN folioserie IS NULL THEN '' ELSE folioserie END))
			FROM 
				ew_sys_folios
			WHERE 
				idsucursal = @idsucursal 
				AND transaccion = @transaccion 
				AND serie = @serie
			
			SELECT @xfolio = LTRIM(RTRIM(CONVERT(VARCHAR(10), @folio)))
			
			IF @foliolen > 0
			BEGIN
				SELECT @xfolio = dbo.fnRellenar(@xfolio, @foliolen, '0')
			END
			
			SELECT @nFolio = @nFolio + @xfolio
		END
			ELSE
		BEGIN
			SELECT @nFolio = @afolio
		END
		
		SELECT @idtran = 0
		SELECT @guardar = '1'
		
		-- Iniciamos el lote para guardar una nueva transaccion
		INSERT INTO ew_sys_transacciones
			(transaccion, idsucursal, serie, folio, transaccionref, fecha) 
		VALUES 
			(@transaccion, @idsucursal, @serie, @nFolio, '', @fecha)
		
		SELECT @error = @@ERROR
		
		IF @error = 0
		BEGIN
			-- Obtenemos el IDTRAN para la nueva transaccion
			SELECT @idtran = SCOPE_IDENTITY()
			
			-- Reemplazamos las macros
			SELECT @sql = REPLACE(@sql, '{idtran}',RTRIM(CONVERT(VARCHAR(8),@idtran)))
			SELECT @sql = REPLACE(@sql, '{folio}' ,@nFolio)
			
			EXEC (@sql)
			
			SELECT @error = @@error
			
			IF @error != 0
			BEGIN
				SELECT @msg = '
Ocurrió un error al ejecutar la sentencia SQL:
----------------------------------------------
' + @sql
				SELECT @guardar = 0
			END
		END
			ELSE
		BEGIN
			SELECT @msg='Ocurrió un error al intentar insertar un registro en la tabla EW_SYS_TRANSACCIONES'
			
			SELECT @guardar = 0
		END
		
		IF @guardar = 1
		BEGIN
			-- Finalizamos el lote con éxito
			--COMMIT TRAN
			-- Liberamos el folio
			UPDATE ew_sys_folios SET 
				folio = @folio
				,estatus = 0
			WHERE 
				idsucursal = @idsucursal 
				AND transaccion = @transaccion 
				AND serie = @serie
			-- Regresamos
			RETURN
		END
			ELSE
		BEGIN
			-- Al haber un error, cancelamos el lote
			--ROLLBACK TRAN
			-- Liberamos el folio
			UPDATE ew_sys_folios SET 
				estatus = 0
			WHERE 
				idsucursal = @idsucursal 
				AND transaccion = @transaccion 
				AND serie = @serie
			
			RAISERROR (@msg, 16, 1)
			
			-- Regresamos
			RETURN
		END
	END	
	
	-- Siguiente Intento ....
	SELECT @cont = @cont + 1
	
	IF @cont > 4
	BEGIN
		BREAK
	END
END

-- Si no tuvimos éxito tras los 5 intentos, generamos un error
IF @cont > 4
BEGIN
	SELECT @msg = 'Ultimo Folio Bloqueado no se pudo realizar la operación'
	RAISERROR(@msg, 16, 1)
END
GO
