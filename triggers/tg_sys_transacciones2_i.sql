USE [db_comercial_final]
GO
ALTER TRIGGER [dbo].[tg_sys_transacciones2_i] 
	ON [dbo].[ew_sys_transacciones2] 
	FOR INSERT
AS

SET NOCOUNT ON

DECLARE 
	@idtran AS BIGINT
	, @idestado AS TINYINT
	, @comando AS VARCHAR(4000)
	, @fecha AS VARCHAR(18)
	, @idu AS VARCHAR(3)
	, @host AS VARCHAR(20)
	, @comentario AS VARCHAR(4000)

DECLARE
	@transaccion AS VARCHAR(4)

DECLARE cur_c_tran2_i CURSOR LOCAL FOR 
	SELECT
		[idtran] = i.idtran
		, [idestado] = i.idestado
		, [comando] = ISNULL(RTRIM(e.comando), '')
		, [fecha] = RTRIM(CONVERT(VARCHAR(18), i.fechahora, 3))
		, [idu] = CONVERT(VARCHAR(3),i.idu)
		, [host] = i.host
	FROM
		inserted AS i
		LEFT JOIN ew_sys_transacciones AS c
			ON c.idtran = i.idtran
		LEFT JOIN objetos AS o
			ON o.codigo = c.transaccion
		LEFT JOIN objetos_estados AS e
			ON e.objeto = o.objeto
			AND e.idestado = i.idestado

OPEN cur_c_tran2_i

FETCH NEXT FROM cur_c_tran2_i INTO
	@idtran
	, @idestado
	, @comando
	, @fecha
	, @idu
	, @host

WHILE @@FETCH_STATUS = 0
BEGIN
	IF (
		@idestado BETWEEN 0 AND 255
		AND @idestado IN (
			SELECT
				oe.idestado
			FROM
				ew_sys_transacciones AS st
				LEFT JOIN objetos AS o
					ON o.codigo = st.transaccion
				LEFT JOIN objetos_estados AS oe
					ON oe.objeto = o.objeto
			WHERE
				st.idtran = @idtran
		)
	)
	BEGIN
		UPDATE ew_sys_transacciones SET
			idestado = @idestado
			, cancelado = (CASE WHEN @idestado = 255 THEN 1 ELSE cancelado END)
		WHERE
			idtran = @idtran
	END

	IF LEN(@comando) > 0 
	BEGIN
		-- Las macros que podemos usar son: 
		-- {idtran}, {idestado}, {fecha}, {idu}, {host}, {comentario}
		SELECT @comando = REPLACE(@comando, '{idtran}', RTRIM(LTRIM(STR(@idtran))))
		SELECT @comando = REPLACE(@comando, '{idestado}', RTRIM(LTRIM(STR(@idestado))))
		SELECT @comando = REPLACE(@comando, '{fecha}', @fecha)
		SELECT @comando = REPLACE(@comando, '{idu}', @idu)
		SELECT @comando = REPLACE(@comando, '{host}', @host)
		--print @comando
		EXEC (@comando)
	END

	FETCH NEXT FROM cur_c_tran2_i INTO
		@idtran
		, @idestado
		, @comando
		, @fecha
		, @idu
		, @host
END

CLOSE cur_c_tran2_i
DEALLOCATE cur_c_tran2_i
GO
