USE [db_comercial_final]
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 201508
-- Description:	Timbra un comprobante 2do paso
-- =============================================
ALTER PROCEDURE [dbo].[_cfd_prc_timbrarComprobante]
	 @idtran AS INT
	 ,@idu AS INT
AS

SET NOCOUNT ON

DECLARE 
	@msg AS VARCHAR(500)
	,@comando AS VARCHAR(4000)
	,@tipo AS TINYINT
	,@idcomando AS TINYINT
	,@cfd_idfolio AS SMALLINT
	,@cfd_folio AS INT
	,@serie AS VARCHAR(10)
	,@transaccion AS VARCHAR(5)
	,@idsucursal AS SMALLINT
	,@fecha AS DATE

	,@folio_documento AS VARCHAR(15)

/*
Validamos que exista la transaccion en la tabla EW_CFD_TRANSACCIONES
*/
IF NOT EXISTS(SELECT idtran FROM dbo.ew_cfd_transacciones WHERE idtran = @idtran)
BEGIN
	SELECT 
		@transaccion = transaccion
		,@idsucursal = idsucursal
		,@fecha = fecha 
	FROM 
		ew_sys_transacciones 
	WHERE
		idtran = @idtran

	EXEC _cfd_prc_obtenerFolio 
		@idsucursal
		,@transaccion
		,@cfd_idfolio OUTPUT
		,@cfd_folio OUTPUT
		,@serie OUTPUT
	
	IF EXISTS(
		SELECT TOP 1
			[tipo] = i.tipo,
			[idcomando] = i.idcomando,
			[comando] = c.comando
		FROM 
			dbo.ew_cfd_transacciones AS i 
			LEFT JOIN dbo.ew_cfd_comandos AS c 
				ON c.idcomando = i.idcomando
		WHERE
			i.cfd_idfolio = @cfd_idfolio
	)
	BEGIN
		SELECT TOP 1
				@tipo = i.tipo,
				@idcomando = i.idcomando,
				@comando = c.comando
			FROM 
				dbo.ew_cfd_transacciones AS i 
				LEFT JOIN dbo.ew_cfd_comandos AS c 
					ON c.idcomando=i.idcomando
			WHERE
				i.cfd_idfolio = @cfd_idfolio

		INSERT INTO ew_cfd_transacciones(
			cfd_idfolio
			,cfd_folio
			,idtran
			,tipo
			,idcomando
			,fecha
		)
		VALUES (
			@cfd_idfolio
			,@cfd_folio
			,@idtran
			,@tipo
			,@idcomando
			,@fecha
		)
	END
		ELSE
	BEGIN
		SELECT
			@tipo = ct.tipo
			,@fecha = ct.fecha
			,@idcomando = CONVERT(INT, od.valor)
		FROM
			ew_cxc_transacciones AS ct
			LEFT JOIN objetos AS o
				ON o.codigo = ct.transaccion
			LEFT JOIN objetos_datos AS od
				ON od.codigo = 'CFD'
				AND od.objeto = o.objeto
		WHERE
			ct.idtran = @idtran

		INSERT INTO ew_cfd_transacciones(
			cfd_idfolio
			,cfd_folio
			,idtran
			,tipo
			,idcomando
			,fecha
		)
		VALUES (
			@cfd_idfolio
			,@cfd_folio
			,@idtran
			,@tipo
			,@idcomando
			,@fecha
		)
	END
	
	IF NOT EXISTS(SELECT idtran FROM dbo.ew_cfd_transacciones WHERE idtran = @idtran)
	BEGIN
		SELECT @msg = '[1001] No existe registro en ew_cfd_transacciones.'
		RAISERROR(@msg, 16, 1)
		RETURN
	END
END

/*
Validamos que la transaccion se encuentre en estado APLICADO
*/
IF @transaccion NOT IN('NFA1') -- QUE SOLO VALIDE APLICADO O PAGADO CUANDO NO SEA RECIBO DE NOMINA
BEGIN
	IF NOT EXISTS(SELECT idtran FROM dbo.ew_sys_transacciones2 WHERE idtran = @idtran AND (idestado = 5 OR idestado = 50))
	BEGIN
		SELECT @msg='[1003] La transaccion no se encuentra en estado APLICADO o PAGADO'
		RAISERROR(@msg, 16, 1)
		RETURN
	END
END

--Validamos que la transaccion no se encuentre timbrada
IF NOT EXISTS(SELECT idtran FROM dbo.ew_cfd_comprobantes_timbre WHERE idtran = @idtran)
BEGIN
	--Obtenemos el comando que utilizaremos para timbrar
	SELECT TOP 1
		@tipo = i.tipo
		,@idcomando = i.idcomando
		,@comando = c.comando
		,@cfd_idfolio = i.cfd_idfolio
		,@cfd_folio = i.cfd_folio
	FROM 
		dbo.ew_cfd_transacciones AS i 
		LEFT JOIN dbo.ew_cfd_comandos AS c 
			ON c.idcomando=i.idcomando
	WHERE
		i.idtran = @idtran
	
	--Validamos que haya un comando que ejecutar
	IF @comando IS NULL OR @comando = ''
	BEGIN
		SELECT @msg = '[1004] No existe ningun comando para timbrar el documento'
		RAISERROR(@msg, 16, 1)
		RETURN
	END

	SELECT @comando = REPLACE(@comando, '{idtran}', RTRIM(CONVERT(VARCHAR(8),@idtran)))
	SELECT @comando = REPLACE(@comando, '{cfd_idfolio}', RTRIM(CONVERT(VARCHAR(3),@cfd_idfolio)))
	SELECT @comando = REPLACE(@comando, '{cfd_folio}', @cfd_folio)
	SELECT @comando = REPLACE(@comando, '{tipo}', @tipo)

	EXEC(@comando)

	INSERT INTO dbo.ew_sys_transacciones2 (
		idtran
		,idestado
		,idu
	)
	VALUES(
		@idtran
		,23
		,@idu
	)

	SELECT
		@folio_documento = (
			cf.serie
			+dbo._sys_fnc_rellenar(@cfd_folio, 6, '0')
		)
	FROM 
		ew_cfd_folios AS cf
	WHERE
		cf.idfolio = @cfd_idfolio

	UPDATE ew_sys_transacciones SET folio = @folio_documento WHERE idtran = @idtran
	UPDATE ew_ven_transacciones SET folio = @folio_documento WHERE idtran = @idtran
	UPDATE ew_cxc_transacciones SET folio = @folio_documento WHERE idtran = @idtran
END
GO
