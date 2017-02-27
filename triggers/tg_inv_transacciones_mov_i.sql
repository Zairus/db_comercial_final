USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 201103
-- Modificado:	2012-10
-- Description:	Convertir la unidad de la transacción a unidad de medida del almacén para el artículo. 
--              Afectar inv_movimientos. 
--              Toma la decisión de cómo crear capas o referenciar capas existentes. 
--              Decide como hacer movimientos en cuanto a series. 
--              Actualiza el costo del movimiento que genera la salida. 
--              Actualiza información de costo promedio y último costo en ew_articulos_sucursales.
-- =============================================
ALTER TRIGGER [dbo].[tg_inv_transacciones_mov_i]
   ON  [dbo].[ew_inv_transacciones_mov]
   AFTER INSERT
AS 

SET NOCOUNT ON

DECLARE 	
	@comentario AS VARCHAR(4000)
	,@idtran AS INT
	,@idr AS INT
	,@fecha AS SMALLDATETIME
	,@transaccion AS VARCHAR(5)
	,@folio AS VARCHAR(15)
	,@referencia AS VARCHAR(25)
	,@idalmacen AS SMALLINT
	,@consecutivo AS SMALLINT
	,@idcapa AS BIGINT
	,@idpedimento AS BIGINT
	,@tipo AS TINYINT
	,@idarticulo AS INT
	,@cantidad AS DECIMAL(15,4)
	,@costo AS DECIMAL(15,4)
	,@costo2 AS DECIMAL(15,4)
	,@afectainv AS BIT
	,@invafectado AS BIT
	,@series AS VARCHAR(4000)
	,@lote AS VARCHAR(25)
	,@fecha_caducidad AS SMALLDATETIME
	,@maneja_series AS BIT
	,@maneja_pedimentos AS BIT
	,@maneja_lotes AS BIT
	,@caduca AS BIT
	,@usuario AS SMALLINT
	,@inventariable AS BIT
	,@idum AS SMALLINT
	,@factor AS DECIMAL(15,4)
	,@idum_almacen AS SMALLINT
	,@factor_almacen AS DECIMAL(15,4)
	,@afectaref AS BIT
	,@tablaref AS VARCHAR(30)
	,@idtran2 AS BIGINT
	,@idmov2 AS MONEY
	,@msg AS VARCHAR(200)
	,@cont AS SMALLINT
	,@cont2 AS SMALLINT
	,@comando AS VARCHAR(4000)
	,@cant AS DECIMAL(15,4)
	,@cantidad2 AS DECIMAL(15,4)
	,@existenciaLote AS DECIMAL(15,4)
	,@importe AS DECIMAL(15,4)
	,@importe2 AS DECIMAL(15,4)
	,@ximporte AS DECIMAL(15,4)
	,@ximporte2 AS DECIMAL(15,4)
	,@yimporte AS DECIMAL(15,4)
	,@yimporte2 AS DECIMAL(15,4)
	,@serie AS VARCHAR(100)
	,@idmov AS MONEY
	,@idr2 AS INT
	,@actualizarCosto AS BIT
	,@b AS BIT
	,@codarticulo AS VARCHAR(50)
	
--Datos para actualización de costo
DECLARE
	@itm_costo AS DECIMAL(12,2)
	,@itm_costo2 AS DECIMAL(12,2)
	,@idconcepto SMALLINT
	,@costo_u AS DECIMAL(18,6)

SELECT @msg = ''

DECLARE cur_inv_transacciones_mov_i CURSOR FOR
	SELECT
		a.idtran
		, b.idr
		, a.fecha
		, a.transaccion
		, a.folio
		, a.referencia
		, a.idalmacen
		, a.idtran2
		, a.idu
		, b.idr
		, b.afectaref
		, b.tablaref
		, b.idmov2
		, b.idpedimento
		, b.idcapa
		, b.afectainv
		, b.invafectado
		, b.consecutivo
		, b.tipo
		, b.idalmacen
		, b.idarticulo
		, b.cantidad
		, b.costo
		, b.costo2
		, b.lote
		, b.fecha_caducidad
		, b.idum
		, e.factor
		, d.idum_almacen
		, f.factor
		, d.series
		, d.pedimento
		, d.lotes
		, itm.idmov
		, d.codigo
		, a.idconcepto
	FROM 
		inserted AS b 
		LEFT JOIN ew_inv_transacciones AS a 
			ON a.idtran = b.idtran
		LEFT JOIN ew_inv_almacenes AS c 
			ON c.idalmacen = a.idalmacen
		LEFT JOIN ew_articulos AS d 
			ON d.idarticulo = b.idarticulo
		LEFT JOIN ew_cat_unidadesMedida AS e 
			ON e.idum = b.idum
		LEFT JOIN ew_cat_unidadesMedida AS f 
			ON f.idum = d.idum_almacen
		LEFT JOIN ew_inv_transacciones_mov AS itm 
			ON itm.idr=b.idr
		LEFT JOIN ew_inv_capas AS ic 
			ON ic.idcapa=b.idcapa
	WHERE 
		d.inventariable = 1

OPEN cur_inv_transacciones_mov_i

FETCH NEXT FROM cur_inv_transacciones_mov_i INTO
	@idtran
	, @idr
	, @fecha
	, @transaccion
	, @folio
	, @referencia
	, @idalmacen
	, @idtran2
	, @usuario
	, @idr
	, @afectaref
	, @tablaref
	, @idmov2
	, @idpedimento
	, @idcapa
	, @afectainv
	, @invafectado
	, @consecutivo
	, @tipo
	, @idalmacen
	, @idarticulo
	, @cant
	, @costo
	, @costo2
	, @lote
	, @fecha_caducidad
	, @idum
	, @factor
	, @idum_almacen
	, @factor_almacen
	, @maneja_series
	, @maneja_pedimentos
	, @maneja_lotes
	, @idmov,@codarticulo
	, @idconcepto

WHILE @@fetch_status = 0
BEGIN
	IF @usuario IS NULL
	BEGIN
		SELECT @usuario = dbo._sys_fnc_usuario()
	END

	IF @idtran IS NULL
	BEGIN
		CLOSE cur_inv_transacciones_mov_i
		DEALLOCATE cur_inv_transacciones_mov_i
		
		RAISERROR('Error: El identificador de transacción es nulo..', 16, 1)
		RETURN
	END
	
	IF @factor_almacen IS NULL OR @factor_almacen = 0
	BEGIN
		SET @factor_almacen = 1
	END
	
	IF @factor IS NULL OR @factor = 0
	BEGIN
		SET @factor = @factor_almacen
	END
	
	-- Convirtiendo las unidades de entrada en unidades de almacen
	SET @cantidad = ROUND(@cant * (@factor / @factor_almacen), 6)
	
	IF @maneja_pedimentos = '1' AND @idpedimento = 0
	BEGIN
		SELECT @idpedimento = 1
	END
	
	-- Afectando el kardex, para aquellos que la cantidad sea mayor a 0
	IF @afectainv = '1' AND @invafectado = '0' AND @tipo IN (1,2) AND @cantidad > 0
	BEGIN
		SELECT @b = 0
		SELECT @actualizarCosto = 0

		-------------------------------------------------------------------------------
		-- 1) ENTRADA ó SALIDA. La capa ha sido indicada
		-------------------------------------------------------------------------------
		IF @idcapa > 0 AND @afectaref = 0
		BEGIN
			---------------------------------------------------------------------------
			-- Modificacion hecha Oct 2012 para la existencia x Lote
			---------------------------------------------------------------------------
			IF @tipo = 2 AND @maneja_lotes = 1
			BEGIN
				SELECT @existenciaLote = 0
				SELECT @existenciaLote = ISNULL(SUM(cantidad),0) 
				FROM [dbo].[fn_inv_capasSalidaLote] (@idalmacen, @idarticulo, @cantidad, @lote, @idcapa)
				
				IF @existenciaLote < @cantidad
				BEGIN
					SELECT @msg = 'Articulo: [' + @codarticulo + '] Lote=[' + @lote + ']  Existencia=' + CONVERT(VARCHAR(15),@existenciaLote) + '  / Salida='+ CONVERT(VARCHAR(15), @cantidad) 
					BREAK
				END

				INSERT INTO ew_inv_movimientos (
					idr2
					, idtran
					, idconcepto
					, idpedimento
					, consecutivo
					, idcapa
					, idalmacen
					, fecha
					, transaccion
					, folio
					, referencia
					, codigo
					, tipo
					, idarticulo
					, cantidad
					, costo
					, costo2
					, usuario
					, comentario
					, idmov2
				)				
				SELECT
					0
					, @idtran
					, @idconcepto
					, @idpedimento
					, @consecutivo
					, cs.idcapa
					, @idalmacen
					, @fecha
					, @transaccion
					, @folio
					, @referencia
					, ''
					, @tipo
					, @idarticulo
					, cs.cantidad
					, cs.costo
					, cs.costo2
					, @usuario
					, ''
					, @idmov
				FROM
					dbo.fn_inv_capasSalidaLote(@idalmacen, @idarticulo, @cantidad, @lote, @idcapa) AS cs
					LEFT JOIN ew_inv_capas AS ic 
						ON ic.idcapa=cs.idcapa	
			END
				ELSE
			BEGIN
				INSERT INTO ew_inv_movimientos (
					idr2
					, idtran
					, idconcepto
					, idpedimento
					, consecutivo
					, idcapa
					, idalmacen
					, fecha
					, transaccion
					, folio
					, referencia
					, codigo
					, tipo
					, idarticulo
					, cantidad
					, costo
					, costo2
					, usuario
					, comentario
					, idmov2
				)				
				VALUES (
					0
					, @idtran
					, @idconcepto
					, @idpedimento
					, @consecutivo
					, @idcapa
					, @idalmacen
					, @fecha
					, @transaccion
					, @folio
					, @referencia
					, ''
					, @tipo
					, @idarticulo
					, @cantidad
					, @costo
					, @costo2
					, @usuario
					, ''
					, @idmov
				)
			END
			SELECT @b = 1
			SELECT @actualizarCosto = (CASE WHEN @tipo = 2 THEN 1 ELSE 0 END)

			IF @tipo = 1 AND @costo = 0
				SELECT @actualizarCosto = 1
		END

		-------------------------------------------------------------------------------
		-- 2) ENTRADA ó SALIDA. Referencia a un movimiento previo en el kardex
		-------------------------------------------------------------------------------
			
		IF (@b = 0) AND (@maneja_series = 0) AND (@idmov2 > 0) AND (@afectaref = '1') 
		BEGIN
			SELECT TOP 1 @idr2 = idr
			FROM ew_inv_movimientos 
			WHERE idmov2 = @idmov2 
			ORDER BY idr DESC
			
			IF @idr2 IS NULL
			BEGIN
				SELECT @msg = 'Error. la referencia al kardex no es correcta para el articulo: ' + @codarticulo
				BREAK			
			END

			-- <BEGIN> Cambios Laurence Saavedra Octubre 2012
			INSERT INTO ew_inv_movimientos (
				idr2
				, idtran
				, idconcepto
				, idpedimento
				, consecutivo
				, idcapa
				, idalmacen
				, fecha
				, transaccion
				, folio
				, referencia
				, codigo
				, tipo
				, idarticulo
				, cantidad
				, costo
				, costo2
				, usuario
				, comentario
				, idmov2
			)
			SELECT
				im.idr
				, @idtran
				, @idconcepto
				, @idpedimento
				, im.consecutivo
				, (CASE WHEN im.idcapa>0 THEN imc.idcapa ELSE (-1) END)
				, @idalmacen
				, @fecha
				, @transaccion
				, @folio
				, @referencia
				, ''
				, @tipo
				, @idarticulo
				, imc.cantidad
				, imc.costo
				, imc.costo2
				, @usuario
				, ''
				, @idmov				
			FROM
				dbo.fn_inv_capasPorIDMOV(@idmov2,@cantidad) AS imc
				LEFT JOIN ew_inv_movimientos AS im 
					ON im.idr = imc.idr
			WHERE 
				im.idmov2 = @idmov2
			
			SELECT @b = 1
			SELECT @actualizarCosto = 1
		END

		-------------------------------------------------------------------------------
		-- 3) ENTRADA. Maneja Series
		-------------------------------------------------------------------------------
		IF (@b = 0) AND (@tipo = 1) AND (@maneja_series = 1)
		BEGIN 
			SELECT @series = CONVERT(VARCHAR(4000), series) 
			FROM 
				ew_inv_transacciones_mov 
			WHERE
				idr = @idr
			
			IF @series IS NULL OR LEN(@series) = 0
			BEGIN
				SELECT @msg = 'Error. no se especificó ningun no. de serie (inv_transacciones_mov.series) para el articulo: ' + @codarticulo
				BREAK
			END
			
			SELECT @cont = 0
			SELECT @cont = COUNT(*) 
			FROM dbo._sys_fnc_series(@series)
			
			IF @cont!=@cantidad 
			BEGIN
				SELECT @msg = 'Error. no se especificaron todos los no. de serie (inv_transacciones_mov.series) para el articulo: ' + @codarticulo
				BREAK
			END
			
			SELECT @ximporte = @costo
			SELECT @ximporte2 = @costo2
			SELECT @cont2 = 0
			
			DECLARE cur_tg_detalle_provee_i2 CURSOR FOR
				SELECT 
					serie 
				FROM 
					dbo._sys_fnc_series(@series)

			OPEN cur_tg_detalle_provee_i2

			FETCH NEXT FROM cur_tg_detalle_provee_i2 INTO 
				@serie
			
			WHILE @@fetch_status = 0
			BEGIN
				SELECT @idcapa = 0
				SELECT @yimporte = 0
				SELECT @yimporte2 = 0
				SELECT @cont2 = @cont2 + 1
				
				IF @cont2 = @cont
				BEGIN
					SELECT @yimporte = @ximporte
					SELECT @yimporte2 = @ximporte2
				END
					ELSE
				BEGIN
					SELECT @yimporte = ROUND(@costo / @cantidad, 2)
					SELECT @yimporte2 = ROUND(@costo2 / @cantidad, 2)
				END
				
				-- Creamos una capa por cada serie, si existe la capa con existencia=0 toma ese numero IDCAPA
				EXEC _inv_prc_capasCrear
					@idcapa OUTPUT
					,@idtran
					,@folio
					,@fecha
					,@idarticulo
					,@serie
					,1
					,@yimporte
					,@yimporte2
					,@lote
					,@fecha_caducidad
					,''
				
				IF @idcapa IS NULL OR @idcapa < 1
				BEGIN
					SELECT @msg = 'Error al intentar crear la capa de costos (SP: _ALM_CAPAS_CREAR.) para el articulo: ' + @codarticulo
					BREAK
				END
				
				-- Realizamos el movimiento en el almacen
				INSERT INTO ew_inv_movimientos (
					idtran
					, idconcepto
					, idpedimento
					, consecutivo
					, idcapa
					, idalmacen
					, fecha
					, transaccion
					, folio
					, referencia
					, codigo
					, tipo
					, idarticulo
					, cantidad
					, costo
					, costo2
					, usuario
					, comentario
					,idmov2
				)
				VALUES  (
					@idtran
					, @idconcepto
					, @idpedimento
					, @consecutivo
					, @idcapa
					, @idalmacen
					, @fecha
					, @transaccion
					, @folio
					, @referencia
					, ''
					,  1
					, @idarticulo
					, 1
					, @yimporte
					, @yimporte2
					, @usuario
					, ''
					, @idmov
				)
				
				SELECT @ximporte = @ximporte - @yimporte
				SELECT @ximporte2 = @ximporte2 - @yimporte2
				
				FETCH NEXT FROM cur_tg_detalle_provee_i2 INTO 
					@serie
			END

			CLOSE cur_tg_detalle_provee_i2
			DEALLOCATE cur_tg_detalle_provee_i2

			SELECT @b = 1
		END

		-------------------------------------------------------------------------------
		-- 4) SALIDA. Maneja Series
		-------------------------------------------------------------------------------			
		IF (@b = 0) AND (@tipo = 2) AND (@maneja_series = 1)
		BEGIN
			-- Validar series
			SELECT 
				@series = CONVERT(VARCHAR(4000), series) 
			FROM 
				ew_inv_transacciones_mov 
			WHERE 
				idr = @idr
			
			IF @series IS NULL OR LEN(@series) = 0
			BEGIN
				SELECT @msg = 'Error. no se especificó ningun no. de serie (inv_transacciones_mov.series) para el articulo: ' + @codarticulo
				BREAK
			END

			SELECT @cont = 0
			SELECT @cont = COUNT(*) FROM dbo._sys_fnc_series(@series)

			IF @cont != @cantidad
			BEGIN
				SELECT @msg = 'Error. no se especificaron todos los no. de serie (inv_transacciones_mov.series) para el articulo: ' + @codarticulo
				BREAK
			END

			DECLARE cur_tg_detalle_provee_i2 CURSOR FOR
				SELECT 
					serie 
				FROM dbo._sys_fnc_series(@series)
			
			OPEN cur_tg_detalle_provee_i2
			
			FETCH NEXT FROM cur_tg_detalle_provee_i2 INTO 
				@serie
			
			WHILE @@fetch_status = 0
			BEGIN
				SELECT 
					@idcapa = ic.idcapa
				FROM 
					ew_inv_capas AS ic
				WHERE
					ic.existencia > 0
					AND ic.serie = @serie
					AND ic.idarticulo = @idarticulo

				IF @idcapa IS NULL OR @idcapa = 0
				BEGIN
					SELECT @msg = 'Error: No se encontró la serie [' + @serie + '], para el articulo: ' + @codarticulo
					BREAK
				END
					ELSE
				BEGIN
					INSERT INTO ew_inv_movimientos (
						idr2
						, idtran
						, idconcepto
						, idpedimento
						, consecutivo
						, idcapa
						, idalmacen
						, fecha
						, transaccion
						, folio
						, referencia
						, codigo
						, tipo
						, idarticulo
						, cantidad
						, costo
						, costo2
						, usuario
						, comentario
						, idmov2
					)
					VALUES (
						@idr
						, @idtran
						, @idconcepto
						, @idpedimento
						, @consecutivo
						, @idcapa
						, @idalmacen
						, @fecha
						, @transaccion
						, @folio
						, @referencia
						, ''
						, @tipo
						, @idarticulo
						, 1
						, @costo
						, @costo2
						, @usuario
						, ''
						,@idmov
					)
				END
				
				FETCH NEXT FROM cur_tg_detalle_provee_i2 INTO 
					@serie
			END
			
			CLOSE cur_tg_detalle_provee_i2
			DEALLOCATE cur_tg_detalle_provee_i2

			SELECT @b = 1
			SELECT @actualizarCosto = 1
		END			
		
		-------------------------------------------------------------------------------
		-- 5) ENTRADA ó SALIDA. Otros
		-------------------------------------------------------------------------------
		IF (@b = 0) 
		BEGIN
			SELECT @idcapa = 0

			IF @tipo = 1
			BEGIN
				EXEC _inv_prc_capasCrear 
					@idcapa OUTPUT
					,@idtran
					,@folio
					,@fecha
					,@idarticulo
					,''
					,@cantidad
					,@costo
					,@costo2
					,@lote
					,@fecha_caducidad
					,''	

				IF @idcapa IS NULL or @idcapa < 1
				BEGIN
					SELECT @msg = 'Error al intentar crear la capa de costos (SP: _ALM_CAPAS_CREAR) para el articulo: ' + @codarticulo
					BREAK
				END
			END
				ELSE
			BEGIN
				SELECT @actualizarCosto = 1
			END
			
			-- Realizamos el movimiento en el almacen
			INSERT INTO ew_inv_movimientos (
				idtran
				, idconcepto
				, idpedimento
				, consecutivo
				, idcapa
				, idalmacen
				, fecha
				, transaccion
				, folio
				, referencia
				, codigo
				, tipo
				, idarticulo
				, cantidad
				, costo
				, costo2
				, usuario
				, comentario
				,idmov2
			)
			VALUES (
				@idtran
				, @idconcepto
				, @idpedimento
				, @consecutivo
				, @idcapa
				, @idalmacen
				, @fecha
				, @transaccion
				, @folio
				,  @referencia 
				, ''
				, @tipo
				, @idarticulo
				, @cantidad
				, @costo
				, @costo2
				, @usuario
				, ''
				, @idmov
			)

			SELECT @b = 1
		END

		-----------------------------------------------------------------------------------------------------------------
		--   ACTUALIZAR COSTO RESULTANTE EN ew_inv_transacciones_mov --
		-----------------------------------------------------------------------------------------------------------------
		IF (@actualizarCosto = 1)
		BEGIN
			SELECT 
				@itm_costo = SUM(costo)
				,@itm_costo2 = SUM(costo2)
			FROM 
				ew_inv_movimientos
			WHERE 
				idtran = @idtran 
				AND idarticulo = @idarticulo
				AND idmov2 = @idmov

			UPDATE ew_inv_transacciones_mov SET 
				costo = @itm_costo
				,costo2 = @itm_costo2
			WHERE 
				idr = @idr
			
			UPDATE ew_inv_transacciones SET
				total = (
					SELECT
						SUM(itm.costo)
					FROM ew_inv_transacciones_mov AS itm
					WHERE
						itm.idtran = @idtran
				)
			WHERE
				idtran = @idtran
		END

		-----------------------------------------------------------------------------------------
		--  ACTUALIZAR COSTOS EN CATALOGO
		-----------------------------------------------------------------------------------------
		IF @tipo = 1
		BEGIN
			SELECT @costo_u = (@costo / @cantidad)

			EXEC [dbo].[_inv_prc_ultimoCostoValidar] 
				@idarticulo
				, @idalmacen
				, @costo_u

			UPDATE aa SET
				aa.costo_ultimo = (itm.costo / itm.cantidad)
				,aa.costo_promedio = (
					SELECT
						CONVERT(DECIMAL(18,6), SUM(ice.costo) / SUM(ice.existencia))
					FROM 
						ew_inv_capas_existencia AS ice
						LEFT JOIN ew_inv_capas AS ic 
							ON ic.idcapa = ice.idcapa
					WHERE
						ice.existencia > 0
						AND ic.idarticulo = @idarticulo
				)
			FROM
				ew_inv_transacciones_mov AS itm
				LEFT JOIN ew_articulos_almacenes AS aa
					ON aa.idalmacen = itm.idalmacen
					AND aa.idarticulo = itm.idarticulo
			WHERE
				itm.cantidad > 0
				AND itm.idr = @idr
				
			UPDATE ew_articulos_sucursales SET 
				costo_ultimo = (@costo / @cantidad)
				,costo_promedio = (
					SELECT
						CONVERT(DECIMAL(18,6), SUM(ice.costo) / SUM(ice.existencia))
					FROM 
						ew_inv_capas_existencia AS ice
						LEFT JOIN ew_inv_capas AS ic 
							ON ic.idcapa = ice.idcapa
					WHERE
						ice.existencia > 0
						AND ic.idarticulo = @idarticulo
				)
			WHERE 
				idarticulo = @idarticulo
				AND idsucursal = (
					SELECt idsucursal 
					FROM ew_inv_almacenes 
					WHERE idalmacen = @idalmacen
				)
			
			-- Inicia Cambios Julio 2012
			IF @idconcepto = 16
			BEGIN 
				IF @costo2 = 0 
					SELECT @costo2 = @costo

				UPDATE [as] SET
					[as].costo_base = ROUND(itm.costo / itm.cantidad, 2)
				FROM
					inserted AS itm
					LEFT JOIN ew_inv_almacenes AS alm
						ON alm.idalmacen = itm.idalmacen
					LEFT JOIN ew_articulos_sucursales AS [as]
						ON [as].idarticulo = itm.idarticulo
						AND [as].idsucursal = alm.idsucursal
				WHERE
					[as].costeo IN (1,2)
					AND itm.idr = @idr
			END
		END

		-----------------------------------------------------------------------------------------
		--   ACTUALIZAR COSTO RESULTANTE EN suc_art  --
		-----------------------------------------------------------------------------------------
		-- Indicamos que ya realizamos el movimiento en almacen
		UPDATE ew_inv_transacciones_mov SET 
			invafectado = 1 
		WHERE 
			idr = @idr

		IF (@idmov2 > 0) AND (@afectaref = '1')
		BEGIN
			INSERT INTO ew_sys_movimientos_acumula
				(idmov1, idmov2, campo, valor)
			VALUES
				(@idmov, @idmov2, 'surtido', @cantidad)
		END
	END
	
	-- Siguiente Registro
	FETCH NEXT FROM cur_inv_transacciones_mov_i INTO
		@idtran
		, @idr
		, @fecha
		, @transaccion
		, @folio
		, @referencia
		, @idalmacen
		, @idtran2
		, @usuario
		, @idr
		, @afectaref
		, @tablaref
		, @idmov2
		, @idpedimento
		, @idcapa
		, @afectainv
		, @invafectado
		, @consecutivo
		, @tipo
		, @idalmacen
		, @idarticulo
		, @cant
		, @costo
		, @costo2
		, @lote
		, @fecha_caducidad
		, @idum
		, @factor
		, @idum_almacen
		, @factor_almacen
		, @maneja_series
		, @maneja_pedimentos
		, @maneja_lotes
		, @idmov,@codarticulo
		, @idconcepto
END

CLOSE cur_inv_transacciones_mov_i
DEALLOCATE cur_inv_transacciones_mov_i

IF LEN(@msg) > 0 
BEGIN
	RAISERROR(@msg, 16, 1)
	RETURN
END
GO
