USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20100201
-- Description:	Trigger que se encarga de disminuir los saldos pendientes de aplicar
-- =============================================
ALTER TRIGGER [dbo].[tg_cxc_transacciones_mov_i] 
	ON [dbo].[ew_cxc_transacciones_mov]
	FOR INSERT
AS

SET NOCOUNT ON

--------------------------------------------------------------------------------
-- Afectando el saldo pendiente de aplicar en la transaccion principal IDTRAN
--------------------------------------------------------------------------------
UPDATE t SET
	t.saldo = t.saldo - m.importe
FROM
	(
		SELECT
			i.idtran
			, [importe] = SUM(i.importe)
		FROM
			inserted AS i
		WHERE
			i.importe > 0
		GROUP BY
			i.idtran
	) AS m 
	LEFT JOIN ew_cxc_transacciones AS t 
		ON t.idtran = m.idtran

--------------------------------------------------------------------------------
-- Afectando el saldo pendiente de aplicar en las transacciones referenciadas IDTRAN2
--------------------------------------------------------------------------------
UPDATE t SET
	t.saldo = (
		t.saldo 
		+ (
			CASE
				WHEN p.tipo = t.tipo THEN m.importe2
				ELSE m.importe2 * -1
			END
		)
	)
FROM
	(
		SELECT
			i.idtran
			,i.idtran2
			,[importe2] = SUM(i.importe2)
		FROM
			inserted AS i
		WHERE
			i.importe > 0
		GROUP BY
			i.idtran
			,i.idtran2
	) AS m 
	LEFT JOIN ew_cxc_transacciones AS p
		ON p.idtran = m.idtran
	LEFT JOIN ew_cxc_transacciones AS t 
		ON t.idtran = m.idtran2

--------------------------------------------------------------------------------
-- Aplicando en cartera la diferencia en saldos por diferentes monedas
--------------------------------------------------------------------------------
IF EXISTS (
	SELECT	
		i.idtran
	FROM	
		inserted AS i
		LEFT JOIN ew_cxc_transacciones AS c1 
			ON c1.idtran = i.idtran
		LEFT JOIN ew_cxc_transacciones AS c2 
			ON c2.idtran = i.idtran2
	WHERE
		c1.aplicado = 1
		AND c2.aplicado = 1
		AND i.importe != 0
		AND i.importe2 != 0
)
BEGIN
	DECLARE 
		@idtran AS INT
		,@fecha AS SMALLDATETIME
		,@idu AS SMALLINT
	
	DECLARE cur_cxc_mov_1 CURSOR FOR
		SELECT	
			i.idtran, i.fecha, i.idu
		FROM	
			inserted AS i
			LEFT JOIN ew_cxc_transacciones AS c1 
				ON c1.idtran = i.idtran
			LEFT JOIN ew_cxc_transacciones AS c2 
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

	OPEN cur_cxc_mov_1

	FETCH NEXT FROM cur_cxc_mov_1 INTO 
		@idtran
		, @fecha
		, @idu

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC _cxc_prc_aplicarTransaccion @idtran, @fecha, @idu

		FETCH NEXT FROM cur_cxc_mov_1 INTO 
			@idtran
			, @fecha
			, @idu
	END

	CLOSE cur_cxc_mov_1
	DEALLOCATE cur_cxc_mov_1
END
GO
