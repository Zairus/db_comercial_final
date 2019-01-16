USE db_comercial_final

BEGIN TRAN

/*
################################################################
Correr sin ejecutar una vez, si no hay errores, aplicar cambios
Ver la variable @ejecutar
*/

DECLARE
	@ejecutar AS BIT = 0 -- 0 : No ejecuta; 1 = Aplica cambios

DECLARE
	@command AS NVARCHAR(MAX)

DECLARE cur_corrijepago CURSOR FOR
	SELECT
		[cmd] = (
			'EXEC [dbo].[_cxp_prc_pagoCancelar] '
			+ LTRIM(RTRIM(STR(dda.idtran)))
			+ ', ''' + CONVERT(VARCHAR(8), dda.fecha , 3) + ''''
			+ ', ' + LTRIM(RTRIM(STR(dda.idu)))
			+ ', 1'
		)
	FROM 
		ew_cxp_transacciones AS dda
		LEFT JOIN ew_ban_transacciones AS bt
			ON bt.idtran2 = dda.idtran
		LEFT JOIN ew_proveedores AS p
			ON p.idproveedor = dda.idproveedor
	WHERE
		dda.transaccion = 'DDA4'
		AND dda.cancelado = 0
		AND bt.cancelado = 1

OPEN cur_corrijepago

FETCH NEXT FROM cur_corrijepago INTO
	@command

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC sp_executesql @command

	FETCH NEXT FROM cur_corrijepago INTO
		@command
END

CLOSE cur_corrijepago
DEALLOCATE cur_corrijepago

IF @ejecutar = 1
BEGIN
	SELECT [resultado] = 'Se corrigieron los registros.'
	COMMIT TRAN
END
	ELSE
BEGIN
	SELECT [resultado] = '** PRUEBA SE DESCARTO LA INSTRUCCION'
	ROLLBACK TRAN
END
