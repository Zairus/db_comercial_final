USE db_comercial_final
GO
ALTER PROCEDURE [dbo].[_com_prc_ordenCancelar]
	@idtran AS BIGINT
	,@cancelado_fecha AS SMALLDATETIME

AS

SET NOCOUNT ON

UPDATE ew_com_ordenes SET
	cancelado = 1
	,cancelado_fecha = @cancelado_fecha
WHERE 
	idtran = @idtran 
	and cancelado = 0

INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, idu
)

SELECT
	[idtran] = co.idtran2
	, [idestado] = 0
	, [idu] = co.idu
FROM
	ew_com_ordenes AS co
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = co.idtran2
WHERE
	st.transaccion = 'CCO1'
	AND co.idtran2 > 0
	AND co.idtran = @idtran
GO
