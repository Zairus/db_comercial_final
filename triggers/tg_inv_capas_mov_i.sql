USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20080228
-- Description:	Calcular costos y existencias por capa y por almacén
-- =============================================
ALTER TRIGGER [dbo].[tg_inv_capas_mov_i]
	ON  [dbo].[ew_inv_capas_mov]
	FOR INSERT
AS

Set Nocount On

DECLARE @idr AS INT
DECLARE @idcapa AS INT
DECLARE @idpedimento AS INT
DECLARE @idinv AS INT
DECLARE @idalmacen AS SMALLINT
DECLARE @tipo AS SMALLINT
DECLARE @cantidad AS DECIMAL(18,6)
DECLARE @costo AS DECIMAL(18,6)
DECLARE @costo2 AS DECIMAL(18,6)
DECLARE @idarticulo AS SMALLINT
DECLARE @existencia AS DECIMAL(18,6)
DECLARE @valor AS DECIMAL(18,6)
DECLARE @valor2 AS DECIMAL(18,6)

DECLARE @idtran AS INT
DECLARE @msg AS VARCHAR(200)

SELECT @msg = ''

DECLARE cur_capasmov Cursor For
	SELECT 
		a.idr, a.idcapa, a.idpedimento, a.idinv, a.idalmacen, a.tipo, a.cantidad, 
		a.costo, a.costo2, b.idarticulo, c.existencia, c.costo, c.costo2
	FROM inserted AS a 
	LEFT JOIN ew_inv_capas AS b 
		ON b.idcapa = a.idcapa
	LEFT JOIN ew_inv_capas_existencia AS c 
		ON c.idcapa = a.idcapa 
		AND c.idalmacen = a.idalmacen

Open cur_capasmov

Fetch Next From cur_capasmov Into
	@idr, @idcapa, @idpedimento, @idinv, @idalmacen, @tipo, @cantidad, 
	@costo, @costo2, @idarticulo, @existencia, @valor, @valor2

While @@fetch_status = 0
Begin
	-- Afectando la existencia total de la capa
	UPDATE ew_inv_capas SET 
		existencia = existencia + (CASE @tipo WHEN 1 THEN @cantidad ELSE @cantidad * (-1) END) 
	WHERE idcapa = @idcapa
	
	IF @@error != 0 OR @@rowcount = 0
	BEGIN
		SELECT @msg = 'Ocurrió un error al actualizar la existencia de la capa de costos (ALM_CAPAS)...'
		BREAK
	END
	
	-- En caso de dar Salida, el costo se calcula automaticamente
	IF @tipo = 2
	BEGIN
		IF @existencia = @cantidad
			SELECT @costo = @valor, @costo2 = @valor2
		ELSE
			SELECT 
				@costo = ((@cantidad * @valor) / @existencia), 
				@costo2 = ((@cantidad * @valor2) / @existencia)
		
		UPDATE ew_inv_capas_mov SET 
			costo = @costo, costo2 = @costo2 
		WHERE idr = @idr
	END
	
	-- Afectando la existencia de la capa en el almacen
	UPDATE ew_inv_capas_existencia SET 
		existencia = existencia + (CASE @tipo WHEN 1 THEN @cantidad ELSE @cantidad * (-1) END),
		costo = costo + (CASE @tipo WHEN 1 THEN @costo ELSE @costo * (-1) END),
		costo2 = costo2 + (CASE @tipo WHEN 1 THEN @costo2 ELSE @costo2 * (-1) END)
	WHERE  
		idcapa = @idcapa 
		AND idpedimento = @idpedimento 
		AND idalmacen = @idalmacen
	
	IF @@rowcount = 0 AND @tipo = 1
	BEGIN
		INSERT INTO ew_inv_capas_existencia 
			(idcapa, idpedimento, idalmacen, existencia, costo, costo2, fecha)
		VALUES 
			(@idcapa, @idpedimento, @idalmacen, @cantidad, @costo, @costo2, GETDATE())
	END
	
	IF @@error != 0
	BEGIN
		SELECT @msg = 'Ocurrió un error al actualizar la existencia de la capa de costos en el almacen (ALM_CAPAS_MOV)...'
		BREAK
	END
	
	/*
	-- Afectando la existencia total del pedimento
	IF @idpedimento > 0
	BEGIN
		IF @idpedimento = 1
		BEGIN
			-- SI el idpedimento = 1 entonces se trata de una compra nacional
			SELECT @idtran = 0
			SELECT @idtran = idtran FROM ew_inv_pedimentos WHERE idpedimento = 1
			
			IF @@rowcount = 0
			BEGIN
				-- No hay movimientos en PI
				INSERT INTO ew_inv_pedimentos 
					(idtran, idtran2, idsucursal, folio, fecha, codigo)
				VALUES
					(0, 0, 0, 'MX', '01/01/2007', 'MX')
			END
			
			UPDATE ew_inv_pedimentos_mov SET 
				cantidad = cantidad + @cantidad 
			WHERE 
				idtran = @idtran 
				AND idarticulo = @idarticulo
			
			IF @@rowcount = 0
			Begin
				INSERT INTO ew_inv_pedimentos_mov
					(idtran, idarticulo, cantidad)
				VALUES(@idtran, @idarticulo, @cantidad)
			End
		END

		UPDATE ew_inv_pedimentos_mov SET 
			ew_inv_pedimentos_mov.existencia = existencia + (CASE @tipo WHEN 1 THEN @cantidad ELSE @cantidad * (-1) END) 
		FROM ew_inv_pedimentos_mov
		LEFT JOIN ew_inv_pedimentos 
			ON ew_inv_pedimentos.idtran = ew_inv_pedimentos_mov.idtran
		WHERE
			ew_inv_pedimentos.idpedimento = @idpedimento
			AND ew_inv_pedimentos_mov.idarticulo = @idarticulo
		
		IF @@error != 0 OR @@rowcount=0
		BEGIN
			SELECT @msg = 'Ocurrió un error al actualizar la existencia del pedimento (PED_PEDIMENTO_MOV)...' + char(13) + 'IDPedimento = ' + convert(varchar(12),@idpedimento)
			BREAK
		END
	END
	*/
	
	Fetch Next From cur_capasmov Into
		@idr, @idcapa, @idpedimento, @idinv, @idalmacen, @tipo, @cantidad, 
		@costo, @costo2, @idarticulo, @existencia, @valor, @valor2
End

Close cur_capasmov 
Deallocate cur_capasmov

If Len(@msg) > 0
Begin
	RAISERROR(@msg, 16, 1)
	Return
End
GO
