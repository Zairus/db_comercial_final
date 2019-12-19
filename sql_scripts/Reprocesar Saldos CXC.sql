USE db_comercial_final

BEGIN TRAN

------------------------------------------------------------------------
-- Si no hay error, correr sin BEGIN / ROLLBACK
------------------------------------------------------------------------

SET NOCOUNT ON
SET DEADLOCK_PRIORITY 10

TRUNCATE TABLE ew_cxc_saldos

DECLARE
	@cmd AS NVARCHAR(1000)

DECLARE cur_acumulaCXC CURSOR FOR
	SELECT
		[cmd] = (
			'EXEC [dbo].[_cxc_prc_acumularSaldos] '
			+ LTRIM(RTRIM(STR(ct.idcliente)))
			+ ', ' + LTRIM(RTRIM(STR(YEAR(ct.fecha))))
			+ ', ' + LTRIM(RTRIM(STR(MONTH(ct.fecha))))
			+ ', ' + LTRIM(RTRIM(STR(ct.idmoneda)))
			+ (
				CASE
					WHEN ct.tipo = 1 THEN
						', ' + CONVERT(VARCHAR(20), SUM(ct.total))
					ELSE ', 0'
				END
			)
			+ (
				CASE
					WHEN ct.tipo = 2 THEN
						', ' + CONVERT(VARCHAR(20), SUM(ct.total))
					ELSE ', 0'
				END
			)
			+ ', ' + CONVERT(VARCHAR(20), SUM(ct.total))
			+ ', NULL'
		)
	FROM 
		ew_cxc_transacciones AS ct
	WHERE
		ct.cancelado = 0
		AND ct.aplicado = 1
		AND ct.tipo IN (1,2)
		AND ct.acumula = 1
	GROUP BY
		ct.idcliente
		, YEAR(ct.fecha)
		, MONTH(ct.fecha)
		, ct.idmoneda
		, ct.tipo
	ORDER BY
		ct.idcliente
		, YEAR(ct.fecha)
		, MONTH(ct.fecha)
		, ct.tipo
		, ct.idmoneda

OPEN cur_acumulaCXC

FETCH NEXT FROM cur_acumulaCXC INTO
	@cmd

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC sp_executesql @cmd
	
	PRINT @cmd

	FETCH NEXT FROM cur_acumulaCXC INTO
		@cmd
END

CLOSE cur_acumulaCXC
DEALLOCATE cur_acumulaCXC

------------------------------------------------------------------------

ROLLBACK TRAN