USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170112
-- Description:	Contabilizar objeto por poliza automatica
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_polizaAplicarDeConfiguracion]
	@idtran AS INT
	,@objeto_codigo AS VARCHAR(10) = NULL
	,@idtran2 AS INT = NULL
	,@poliza_idtran AS INT = NULL OUTPUT
	,@regenerar AS BIT = 0
AS

SET ANSI_WARNINGS OFF
SET NOCOUNT ON

DECLARE
	@idsucursal AS INT
	,@referencia AS VARCHAR(50)
	,@concepto AS VARCHAR(200)

DECLARE
	@fecha AS DATETIME
	,@idtipo AS SMALLINT
	,@idu AS INT

DECLARE
	@cuadrar AS BIT
	,@cuenta_cuadre_cargos AS VARCHAR(100)
	,@cuenta_cuadre_abonos AS VARCHAR(100)
	,@diferencia AS DECIMAL(18,6)

IF @regenerar = 1
BEGIN
	EXEC _ct_prc_transaccionAnularCT @idtran2, 1
END

SELECT
	@idsucursal = st.idsucursal
	,@referencia = st.transaccion + ' - ' + st.folio
	,@concepto = o.nombre + ': ' + st.folio
	,@objeto_codigo = ISNULL(@objeto_codigo, st.transaccion)

	,@fecha = st.fecha
	,@idu = (
		SELECT TOP 1 st2.idu 
		FROM ew_sys_transacciones2 AS st2 
		WHERE 
			st2.idu > 0
			AND st2.idtran = st.idtran 
		ORDER BY st2.id
	)
FROM
	ew_sys_transacciones AS st
	LEFT JOIN objetos AS o
		ON o.codigo = st.transaccion
WHERE
	st.idtran = @idtran
	
SELECT
	@idtipo = pc.idtipo
	,@cuadrar = pc.cuadrar
	,@cuenta_cuadre_cargos = pc.cuenta_cuadre_cargos
	,@cuenta_cuadre_abonos = pc.cuenta_cuadre_abonos
FROM
	ew_ct_polizas_configuracion AS pc
WHERE
	pc.objeto_codigo = @objeto_codigo

CREATE TABLE #_tmp_prepoliza (
	idr INT IDENTITY
	,orden INT NOT NULL DEFAULT 0
	,cuenta VARCHAR(500) NOT NULL DEFAULT ''
	,tipomov INT NOT NULL DEFAULT 0
	,importe DECIMAL(18,6) NOT NULL DEFAULT 0
)

DECLARE
	@idr AS INT
	,@line_sql AS NVARCHAR(MAX)

DECLARE cur_prepoliza CURSOR FOR
	SELECT
		cpm.idr
	FROM
		ew_ct_polizas_configuracion_mov AS cpm
	WHERE
		cpm.objeto_codigo = @objeto_codigo
	ORDER BY
		cpm.orden

OPEN cur_prepoliza

FETCH NEXT FROM cur_prepoliza INTO
	@idr

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @line_sql = N'SELECT
		[orden] = ' + LTRIM(RTRIM(STR(pcm.orden))) + '
		,[cuenta] = ' + pcm.cuenta + '
		,[tipomov] = ' + LTRIM(RTRIM(STR(pcm.tipomov))) + '
		,[importe] = ' + pcm.importe + '
	FROM
		' + pcm.tabla + '
	WHERE
		' + pcm.campo_llave + ' = ' + LTRIM(RTRIM(STR(@idtran))) + '
	'
	+ (
		CASE
			WHEN LEN(pcm.agrupacion) > 0 THEN
				'GROUP BY
				' + pcm.agrupacion + '
				'
			ELSE ''
		END
	)
	+ (
		CASE
			WHEN LEN(pcm.condicion_agrupacion) > 0 THEN
				'HAVING
				' + pcm.condicion_agrupacion  + '
				'
			ELSE ''
		END
	)
	FROM
		ew_ct_polizas_configuracion_mov AS pcm
	WHERE
		pcm.idr = @idr

	INSERT INTO #_tmp_prepoliza (orden, cuenta, tipomov, importe)
	EXEC sp_executesql @line_sql

	FETCH NEXT FROM cur_prepoliza INTO
		@idr
END

CLOSE cur_prepoliza
DEALLOCATE cur_prepoliza

IF NOT EXISTS(SELECT * FROM #_tmp_prepoliza)
BEGIN
	RETURN
END

IF @cuadrar = 1
BEGIN
	SELECT @diferencia = SUM(CASE WHEN tipomov = 0 THEN importe ELSE importe * -1 END)
	FROM
		#_tmp_prepoliza

	SELECT @diferencia = ISNULL(@diferencia, 0)

	INSERT INTO #_tmp_prepoliza (
		orden
		, cuenta
		, tipomov
		, importe
	)
	SELECT
		[orden] = 99
		, [cuenta] = (CASE WHEN @diferencia < 0 THEN @cuenta_cuadre_cargos ELSE @cuenta_cuadre_abonos END)
		, [tipomov] = (CASE WHEN @diferencia < 0 THEN 0 ELSE 1 END)
		, [importe] = ABS(@diferencia)
	WHERE
		ABS(@diferencia) > 0.01
END

EXEC _ct_prc_polizaCrear
	@idtran
	,@fecha
	,@idtipo
	,@idu
	,@poliza_idtran OUTPUT
	,@referencia

IF @poliza_idtran IS NULL OR @poliza_idtran = 0
BEGIN
	RAISERROR('Error: No fue posible crear poliza contable.', 16, 1)
	RETURN
END

INSERT INTO ew_ct_poliza_mov (
	idtran
	,idtran2
	,consecutivo
	,idsucursal
	,cuenta
	,tipomov
	,referencia
	,cargos
	,abonos
	,importe
	,concepto
)
SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = ISNULL(@idtran2, @idtran)
	,[consecutivo] = tpp.orden
	,[idsucursal] = @idsucursal
	,[cuenta] = tpp.cuenta
	,[tipomov] = tpp.tipomov
	,[referencia] = @referencia
	,[cargos] = (CASE WHEN tpp.tipomov = 0 THEN tpp.importe ELSE 0 END)
	,[abonos] = (CASE WHEN tpp.tipomov = 1 THEN tpp.importe ELSE 0 END)
	,[importe] = tpp.importe
	,[concepto] = @concepto

FROM
	#_tmp_prepoliza AS tpp
ORDER BY 
	tpp.orden

DROP TABLE #_tmp_prepoliza

EXEC _ct_prc_polizaValidarDualidad @poliza_idtran
GO
