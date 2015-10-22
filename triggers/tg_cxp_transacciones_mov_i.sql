USE db_comercial_final
GO
-- ==========================================================================================
-- Autor:		Laurence Saavedra
-- Fecha:		2010-02
-- Descripcion: Trigger que se encarga de disminuir los saldos pendientes de aplicar
-- ==========================================================================================
ALTER TRIGGER [dbo].[tg_cxp_transacciones_mov_i] ON [dbo].[ew_cxp_transacciones_mov]
FOR INSERT
AS

SET NOCOUNT ON

RETURN

DECLARE 
	@idtran AS INT
	,@fecha AS SMALLDATETIME
	,@idu AS SMALLINT

--------------------------------------------------------------------------------
-- Afectando el saldo pendiente de aplicar en la transaccion principal IDTRAN
--------------------------------------------------------------------------------
UPDATE t SET
	t.saldo = t.saldo - m.importe
FROM
	(
	SELECT
		idtran
		,[importe] = SUM(importe)
	FROM
		inserted
	WHERE
		importe > 0
	GROUP BY
		idtran
	) AS m 
	LEFT JOIN ew_cxp_transacciones t 
		ON t.idtran = m.idtran
WHERE
	t.aplicado = 1

--------------------------------------------------------------------------------
-- Afectando el saldo pendiente de aplicar en las transacciones referenciadas IDTRAN2
--------------------------------------------------------------------------------
UPDATE t SET
	t.saldo = t.saldo - m.importe2
FROM
	(
	SELECT
		idtran
		,idtran2
		,[importe2] = SUM(importe2)
	FROM
		inserted
	WHERE
		importe > 0
	GROUP BY
		idtran
		,idtran2
	) AS m 
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = m.idtran
	LEFT JOIN ew_cxp_transacciones t 
		ON t.idtran = m.idtran2
WHERE
	ct.aplicado = 1

--------------------------------------------------------------------------------
-- Aplicando en cartera la diferencia en saldos por diferentes monedas
--------------------------------------------------------------------------------
IF EXISTS (
	SELECT	
		i.idtran
	FROM	
		inserted i
		LEFT JOIN ew_cxp_transacciones c1 
			ON c1.idtran = i.idtran
		LEFT JOIN ew_cxp_transacciones c2 
			ON c2.idtran = i.idtran2
	WHERE
		c1.aplicado = 1
		AND c2.aplicado = 1
		AND i.importe! = 0
		AND i.importe2! = 0
)
BEGIN
	DECLARE cur_cxp_mov_1 CURSOR FOR
		SELECT
			i.idtran
			, i.fecha
			, i.idu
		FROM	
			inserted i
			LEFT JOIN ew_cxp_transacciones c1 
				ON c1.idtran = i.idtran
			LEFT JOIN ew_cxp_transacciones c2 
				ON c2.idtran = i.idtran2
		WHERE
			c1.aplicado = 1
			AND c2.aplicado = 1
			AND i.importe != 0
			AND i.importe2 != 0
		GROUP BY
			i.idtran
			, i.fecha
			, i.idu

	OPEN cur_cxp_mov_1

	FETCH NEXT FROM cur_cxp_mov_1 INTO 
		@idtran
		, @fecha
		, @idu

	WHILE @@FETCH_STATUS=0
	BEGIN
		-- aplicando la transaccion en cartera
		EXEC _cxp_prc_aplicarTransaccion @idtran, @fecha, @idu

		FETCH NEXT FROM cur_cxp_mov_1 INTO 
			@idtran
			, @fecha
			, @idu
	END

	CLOSE cur_cxp_mov_1
	DEALLOCATE cur_cxp_mov_1
END
GO
