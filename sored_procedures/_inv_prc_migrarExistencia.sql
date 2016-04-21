USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151216
-- Description:	Migrar existencias de prodcutos
-- =============================================
ALTER PROCEDURE [dbo].[_inv_prc_migrarExistencia]
	@prueba AS BIT = 1
AS

SET NOCOUNT ON

BEGIN TRAN

DECLARE
	@idalmacen AS INT
	,@transaccion AS VARCHAR(4) = 'GDC1'
	,@idconcepto AS INT = 21
	,@usuario AS VARCHAR(20) = 'IMPLEMENT'
	,@password AS VARCHAR(20) = '_admin'
	,@idsucursal AS INT
	,@serie AS VARCHAR(3) = ''
	,@carga_idtran AS INT
	,@folio AS VARCHAR(15)

INSERT INTO ew_articulos (
	idarticulo
	,codigo
	,nombre
	,nombre_corto
	,idtipo
	,activo
	,inventariable
	,series
	,lotes
	,caduca
	,comentario
)
SELECT DISTINCT
	[idarticulo] = (
		ROW_NUMBER() OVER (ORDER BY eac.codigo)
		+ISNULL((SELECT MAX(a.idarticulo) FROM ew_articulos AS a), 0) + 1
	)
	,[codigo] = eac.codigo
	,[nombre] = eac.nombre
	,[nombre_corto] = LEFT(eac.nombre, 10)
	,[idtipo] = 1
	,[activo] = 1
	,[inventariable] = 1
	,[series] = (CASE WHEN LEN(eac.serie) > 0 THEN 1 ELSE 0 END)
	,[lotes] = (CASE WHEN LEN(eac.lote) > 0 THEN 1 ELSE 0 END)
	,[caduca] = (CASE WHEN LEN(eac.lote) > 0 THEN 1 ELSE 0 END)
	,[comentario] = 'Carga de existencias iniciales'
FROM
	ew_articulos_existencia_carga AS eac
WHERE
	eac.codigo NOT IN (
		SELECT a.codigo 
		FROM ew_articulos AS a
	)
	AND eac.idalmacen = (SELECT TOP 1 eac1.idalmacen FROM ew_articulos_existencia_carga AS eac1 ORDER BY eac1.idalmacen)
	
UPDATE a SET
	a.nombre = aec.nombre
FROM 
	ew_articulos_existencia_carga AS aec
	LEFT JOIN ew_articulos AS a
		ON a.idtipo = 0
		AND a.codigo = aec.codigo
WHERE
	aec.nombre <> a.nombre

UPDATE vlm SET
	vlm.idmoneda = aec.idmoneda
FROM 
	ew_articulos_existencia_carga AS aec
	LEFT JOIN ew_articulos AS a
		ON a.idtipo = 0
		AND a.codigo = aec.codigo
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idarticulo = a.idarticulo
WHERE
	vlm.idmoneda <> aec.idmoneda

DELETE FROM ew_articulos_impuestos_tasas
WHERE
	idarticulo IN (
		SELECT DISTINCT
			a.idarticulo
		FROM 
			ew_articulos_existencia_carga AS aec
			LEFT JOIN ew_articulos AS a
				ON a.idtipo = 0
				AND a.codigo = aec.codigo
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idimpuesto = 11
				AND cit.tasa = aec.idimpuesto2_valor
		WHERE
			cit.idr IS NOT NULL
	)
	
INSERT INTO ew_articulos_impuestos_tasas (
	idarticulo
	,idtasa
)
SELECT DISTINCT
	a.idarticulo
	,cit.idtasa
FROM 
	ew_articulos_existencia_carga AS aec
	LEFT JOIN ew_articulos AS a
		ON a.idtipo = 0
		AND a.codigo = aec.codigo
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idimpuesto = 11
		AND cit.tasa = aec.idimpuesto2_valor
WHERE
	cit.idr IS NOT NULL
	AND a.idarticulo IS NOT NULL

DECLARE cur_almacenCarga CURSOR FOR
	SELECT DISTINCT idalmacen 
	FROM ew_articulos_existencia_carga

OPEN cur_almacenCarga

FETCH NEXT FROM cur_almacenCarga INTO
	@idalmacen

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT
		@idsucursal = alm.idsucursal
	FROM
		ew_inv_almacenes AS alm
	WHERE
		alm.idalmacen = @idalmacen

	EXEC _sys_prc_insertarTransaccion
		@usuario
		,@password
		,@transaccion
		,@idsucursal
		,@serie
		,'' --SQL
		,6 --foliolen
		,@carga_idtran OUTPUT

	SELECT
		@folio = folio
	FROM
		ew_sys_transacciones AS st
	WHERE
		st.idtran = @carga_idtran

	INSERT INTO ew_inv_transacciones (
		idtran
		,idconcepto
		,idsucursal
		,idalmacen
		,fecha
		,folio
		,transaccion
		,referencia
		,idu
		,comentario
	)
	SELECT
		[idtran] = @carga_idtran
		,[idconcepto] = @idconcepto
		,[idsucursal] = @idsucursal
		,[idalmacen] = @idalmacen
		,[fecha] = GETDATE()
		,[folio] = @folio
		,[transaccion] = @transaccion
		,[referencia] = 'INI'
		,[idu] = 1
		,[comentario] = 'Carga de existencias iniciales'

	INSERT INTO ew_inv_transacciones_mov (
		idtran
		,consecutivo
		,tipo
		,idalmacen
		,idarticulo
		,series
		,lote
		,fecha_caducidad
		,idum
		,cantidad
		,existencia
		,costo
		,comentario
	)
	SELECT
		[idtran] = @carga_idtran
		,[consecutivo] = ROW_NUMBER() OVER (ORDER BY eac.codigo)
		,[tipo] = 1
		,[idalmacen] = @idalmacen
		,[idarticulo] = a.idarticulo
		,[series] = eac.serie
		,[lote] = eac.lote
		,[fecha_caducidad] = (CASE WHEN LEN(eac.lote) > 0 THEN eac.caducidad ELSE NULL END)
		,[idum] = a.idum_almacen
		,[cantidad] = eac.existencia
		,[existencia] = 0
		,[costo] = eac.costo
		,[comentario] = 'Carga de existencias iniciales'
	FROM
		ew_articulos_existencia_carga AS eac
		LEFT JOIN ew_articulos AS a
			ON a.codigo = eac.codigo
	WHERE
		eac.existencia > 0
		AND a.idarticulo IS NOT NULL
		AND eac.idalmacen = @idalmacen

	FETCH NEXT FROM cur_almacenCarga INTO
		@idalmacen
END

CLOSE cur_almacenCarga
DEALLOCATE cur_almacenCarga

SELECT *
FROM
	ew_inv_transacciones AS it
WHERE
	it.idconcepto = @idconcepto

SELECT *
FROM
	ew_inv_transacciones_mov AS it
WHERE
	it.idtran IN (
		SELECT it.idtran
		FROM
			ew_inv_transacciones AS it
		WHERE
			it.idconcepto = @idconcepto
	)

IF @prueba = 1
BEGIN
	SELECT [resultado] = '** Efectuado en modo pruebas'
	ROLLBACK TRAN
END
	ELSE
BEGIN
	COMMIT TRAN
END
GO
