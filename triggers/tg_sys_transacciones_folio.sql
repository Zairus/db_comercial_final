USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160822
-- Description:	Verificar folios duplicados
-- =============================================
ALTER TRIGGER [dbo].[tg_sys_transacciones_folio]
	ON [dbo].[ew_sys_transacciones]
	FOR INSERT
AS 

SET NOCOUNT ON

DECLARE
	@idtran AS INT
	,@transaccion AS VARCHAR(5)
	,@idsucursal AS INT
	,@serie AS VARCHAR(3)
	,@folio AS VARCHAR(20)

	,@idtran_d AS INT
	,@error_mensaje AS VARCHAR(500)

DECLARE
	@automatico AS INT

SELECT
	@idtran = idtran
	,@transaccion = transaccion
	,@idsucursal = idsucursal
	,@serie = serie
	,@folio = folio
FROM 
	inserted

SELECT 
	@automatico = CONVERT(INT, od.valor) 
FROM
	objetos_datos AS od
	LEFT JOIN objetos AS o
		ON o.objeto = od.objeto
WHERE 
	od.codigo = 'AUTOMATICO' 
	AND o.codigo = @transaccion

SELECT @automatico = ISNULL(@automatico, 1)

IF @automatico = 1
BEGIN
	SELECT
		@idtran_d = st.idtran
	FROM
		ew_sys_transacciones AS st
	WHERE
		st.transaccion <> 'APO1'
		AND st.transaccion = @transaccion
		AND st.idsucursal = @idsucursal
		AND st.serie = @serie
		AND st.folio = @folio
		AND st.idtran <> @idtran
		AND @idtran IS NOT NULL

	IF @idtran_d IS NOT NULL
	BEGIN
		SELECT @error_mensaje = (
			'Error: '
			+'idtran [' + LTRIM(RTRIM(STR(@idtran))) + '], transaccion [' + @transaccion + '], folio [' + @folio + '], '
			+'duplicado con idtran: ' + LTRIM(RTRIM(STR(@idtran_d)))
		)

		RAISERROR(@error_mensaje, 16, 1)
	END
END
GO
