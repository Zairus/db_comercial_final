USE db_comercial_final
GO
-- =============================================
-- Author:		Vladimir Barreras
-- Create date: 20180101
-- Description:	
-- Descripcion: Re-Genera los consecutivos de las tablas ew_ven_documentos_mov (cotizaciones) y
-- ew_ven_ordenes_mov (ordenes de venta)
-- Se hizo porque al modificar una cotizacion u orden y quitar e insertar partidas el consecutivo
-- se genera mal y se repeite. Esto ocasiona que la factura marque error al querer guardar en
-- ew_cfd_comprobantes por error de primary key.
-- =============================================
ALTER PROCEDURE [dbo].[_sys_prc_genera_consecutivo]
	@idtran AS INT
	,@transaccion AS VARCHAR(4) = ''
AS

SET NOCOUNT ON

DECLARE
	@cmd AS NVARCHAR(MAX)

DECLARE cur_consecutivos CURSOR FOR
	SELECT
		[cmd] = (
			'UPDATE mov SET
		mov.consecutivo = mov1.consecutivo
	FROM
		' + t.[table] + ' AS mov
		LEFT JOIN (
			SELECT
				m1.idr
				,[consecutivo] = ROW_NUMBER() OVER (ORDER BY m1.idr)
			FROM
				' + t.[table] + ' AS m1
			WHERE
				idtran = ' + LTRIM(RTRIM(STR(@idtran))) + '
		) AS mov1
			ON mov1.idr = mov.idr
	WHERE
		mov.idtran = ' + LTRIM(RTRIM(STR(@idtran)))
		)
	FROM
		(
			SELECT [table] = 'ew_ven_documentos_mov' UNION ALL
			SELECT [table] = 'ew_ven_ordenes_mov' UNION ALL
			SELECT [table] = 'ew_ven_transacciones_mov' UNION ALL
			SELECT [table] = 'ew_com_documentos_mov' UNION ALL
			SELECT [table] = 'ew_com_ordenes_mov' UNION ALL
			SELECT [table] = 'ew_com_transacciones_mov' 
		) AS t

OPEN cur_consecutivos

FETCH NEXT FROM cur_consecutivos INTO
	@cmd

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC sp_executesql @cmd

	FETCH NEXT FROM cur_consecutivos INTO
		@cmd
END

CLOSE cur_consecutivos
DEALLOCATE cur_consecutivos
GO
