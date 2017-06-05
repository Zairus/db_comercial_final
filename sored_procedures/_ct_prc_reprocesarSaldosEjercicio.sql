USE db_refriequipos_datos
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 200901
-- Description:	Regenera los saldos de un ejercicio en TYP
--				Es necesario que ningun usuario utilize el sistema
--				mientras se ejecuta el procedimiento
-- =============================================
CREATE PROCEDURE [dbo].[_ct_prc_reprocesarSaldosEjercicio]
	@ejercicio AS SMALLINT
AS

SET NOCOUNT ON

DECLARE 
	@p0 AS DECIMAL(15,2)
	,@p1 AS DECIMAL(15,2)
	,@p2 AS DECIMAL(15,2)
	,@p3 AS DECIMAL(15,2)
	,@p4 AS DECIMAL(15,2)
	,@p5 AS DECIMAL(15,2)
	,@p6 AS DECIMAL(15,2)
	,@p7 AS DECIMAL(15,2)
	,@p8 AS DECIMAL(15,2)
	,@p9 AS DECIMAL(15,2)
	,@p10 AS DECIMAL(15,2)
	,@p11 AS DECIMAL(15,2)
	,@p12 AS DECIMAL(15,2)
	,@p13 AS DECIMAL(15,2)
	,@p14 AS DECIMAL(15,2)
	,@cont AS INT
	,@error AS VARCHAR(200)
	,@cuenta AS VARCHAR(20)
	,@tipomov AS BIT
	,@idsucursal AS SMALLINT

ALTER TABLE ew_ct_poliza_mov DISABLE TRIGGER tg_ct_poliza_mov_u

UPDATE ew_ct_poliza_mov SET 
	importe = (cargos + abonos)

UPDATE ew_ct_poliza_mov SET 
	tipomov = 0 WHERE cargos != 0

UPDATE ew_ct_poliza_mov SET 
	tipomov = 1 WHERE abonos != 0

ALTER TABLE ew_ct_poliza_mov ENABLE TRIGGER tg_ct_poliza_mov_u

SELECT @cont = 0

-- Eliminado los saldos del ejercicio
PRINT 'Eliminado saldos del ejercicio ...'

UPDATE ew_ct_saldos SET
	 periodo1 = 0
	,periodo2 = 0
	,periodo3 = 0
	,periodo4 = 0
	,periodo5 = 0
	,periodo6 = 0
	,periodo7 = 0
	,periodo8 = 0
	,periodo9 = 0
	,periodo10 = 0
	,periodo11 = 0
	,periodo12 = 0
	,periodo13 = 0
WHERE 
	ejercicio = @ejercicio

PRINT 'Saldos en ceros ...'

PRINT 'Pivote ....'

-- Generando el pivote
DECLARE cur_pivote CURSOR FOR
	SELECT 
		 ejercicio
		,cuenta
		,tipomov
		,idsucursal
		,[1] AS periodo1
		,[2] AS periodo2 
		,[3] AS periodo3
		,[4] AS periodo4
		,[5] AS periodo5
		,[6] AS periodo6
		,[7] AS periodo7
		,[8] AS periodo8
		,[9] AS periodo9
		,[10] AS periodo10
		,[11] AS periodo11
		,[12] AS periodo12
		,[13] AS periodo13
		,[14] AS periodo14
	FROM (
		SELECT 
			pol.ejercicio
			,pm.tipomov
			,pm.cuenta
			,pm.idsucursal
			,pm.importe
			,pol.periodo
		FROM 
			ew_ct_poliza_mov AS pm
			LEFT JOIN ew_ct_poliza AS pol
				ON pol.idtran = pm.idtran
		WHERE 
			pm.idsucursal > 0 
			AND pm.importe <> 0
			AND pol.ejercicio = @ejercicio
	) AS p
	PIVOT (
		SUM (importe)
		FOR periodo IN([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14])
	) AS pvt
	ORDER BY 
		ejercicio
		,cuenta
		,tipomov

OPEN cur_pivote

FETCH NEXT FROM cur_pivote INTO
	@ejercicio
	, @cuenta
	, @tipomov
	, @idsucursal
	, @p1
	, @p2
	, @p3
	, @p4
	, @p5
	, @p6
	, @p7
	, @p8
	, @p9
	, @p10
	, @p11
	, @p12
	, @p13
	, @p14

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @cont = @cont + 1, @error = ''
	
	PRINT CONVERT(VARCHAR(5), @cont) + ' | ' + @cuenta
	
	-- Acumulando el saldo
	EXEC _ct_prc_acumularSaldosEjercicio
		@cuenta
		,@idsucursal
		,@ejercicio
		,@p1
		,@p2
		,@p3
		,@p4
		,@p5
		,@p6
		,@p7
		,@p8
		,@p9
		,@p10
		,@p11
		,@p12
		,@p13
		,@tipomov
		,@error OUTPUT
		,1
	
	IF @error != ''
	BEGIN
		RAISERROR(@error, 16, 1)
	END
	
	FETCH NEXT FROM cur_pivote INTO
		@ejercicio
		, @cuenta
		, @tipomov
		, @idsucursal
		, @p1
		, @p2
		, @p3
		, @p4
		, @p5
		, @p6
		, @p7
		, @p8
		, @p9
		, @p10
		, @p11
		, @p12
		, @p13
		, @p14
END

CLOSE cur_pivote
DEALLOCATE cur_pivote
GO
