USE db_comercial_final
GO
IF OBJECT_ID('_cfd_prc_timbrarComprobante') IS NOT NULL
BEGIN
	DROP PROCEDURE _cfd_prc_timbrarComprobante
END
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20150801
-- Description:	Timbra un comprobante 2do paso
-- =============================================
CREATE PROCEDURE [dbo].[_cfd_prc_timbrarComprobante]
	@idtran AS INT
	, @idu AS INT
	, @cfd_version AS VARCHAR(10) = NULL
AS

SET NOCOUNT ON

DECLARE 
	@msg AS VARCHAR(500)
	, @comando AS VARCHAR(4000)
	, @tipo AS TINYINT
	, @idcomando AS TINYINT
	, @cfd_idfolio AS SMALLINT
	, @cfd_folio AS INT
	, @serie AS VARCHAR(10)
	, @transaccion AS VARCHAR(5)
	, @idsucursal AS SMALLINT
	, @fecha AS DATE

SELECT @cfd_version = ISNULL(@cfd_version, dbo._sys_fnc_parametroTexto('CFDI_VERSION'))

-- ########################################################
-- Validamos que exista la transaccion en la tabla EW_CFD_TRANSACCIONES

IF NOT EXISTS(
	SELECT idtran 
	FROM 
		dbo.ew_cfd_transacciones 
	WHERE 
		idtran = @idtran
)
BEGIN
	SELECT 
		@transaccion = transaccion
		, @idsucursal = idsucursal
		, @fecha = fecha 
	FROM 
		ew_sys_transacciones 
	WHERE 
		idtran = @idtran

	IF @transaccion = 'BDC2' AND @cfd_version = '3.2'
	BEGIN
		RAISERROR('Error: Se intento timbrar un pago en version 3.2', 16, 1)
		RETURN
	END

	EXEC _cfd_prc_obtenerFolio 
		@idsucursal
		, @transaccion
		, @cfd_idfolio OUTPUT
		, @cfd_folio OUTPUT
		, @serie OUTPUT

	IF EXISTS(
		SELECT TOP 1
			i.idtran
		FROM 
			dbo.ew_cfd_transacciones AS i
		WHERE
			i.cfd_idfolio = @cfd_idfolio
	)
	BEGIN
		SELECT TOP 1
			@tipo = i.tipo
			, @idcomando = i.idcomando
			, @comando = c.comando
		FROM
			dbo.ew_cfd_transacciones AS i 
			LEFT JOIN dbo.ew_cfd_comandos AS c 
				ON c.idcomando = i.idcomando
		WHERE
			i.cfd_idfolio = @cfd_idfolio
		ORDER BY
			i.idtran DESC

		INSERT INTO ew_cfd_transacciones(
			cfd_idfolio
			, cfd_folio
			, idtran
			, tipo
			, idcomando
			, fecha
		) 
		SELECT 
			[cfd_idfolio] = @cfd_idfolio
			, [cfd_folio] = @cfd_folio
			, [idtran] = @idtran
			, [tipo] = @tipo
			, [idcomando] = @idcomando
			, [fecha] = @fecha
	END
		ELSE
	BEGIN
		INSERT INTO ew_cfd_transacciones (
			cfd_idfolio
			, cfd_folio
			, idtran
			, tipo
			, idcomando
			, fecha
		) 
		SELECT 
			[cfd_idfolio] = @cfd_idfolio
			, [cfd_folio] = @cfd_folio
			, [idtran] = @idtran
			, [tipo] = ISNULL(
				(
					SELECT ct.tipo 
					FROM ew_cxc_transacciones AS ct 
					WHERE ct.idtran = @idtran
				)
				, ISNULL(
					(
						SELECT ct.tipo 
						FROM ew_cxp_transacciones AS ct 
						WHERE ct.idtran = @idtran
					)
					, 1
				)
			)
			, [idcomando] = 0
			, [fecha] = @fecha
	END

	IF NOT EXISTS(SELECT idtran FROM dbo.ew_cfd_transacciones WHERE idtran = @idtran)
	BEGIN
		SELECT @msg = '[1001] No existe registro en ew_cfd_transacciones.'

		RAISERROR(@msg, 16, 1)
		RETURN
	END
END

-- ########################################################
-- Validamos que la transaccion no se encuentre timbrada

IF EXISTS (
	SELECT idtran 
	FROM dbo.ew_cfd_comprobantes_timbre 
	WHERE idtran = @idtran
)
BEGIN
	SELECT @msg = '[1002] La transaccion ya se encuentra timbrada.'

	RAISERROR(@msg, 16, 1)
	RETURN
END

-- ########################################################
-- Validamos que la transaccion se encuentre en estado APLICADO
-- QUE SOLO VALIDE APLICADO O PAGADO CUANDO NO SEA RECIBO DE NOMINA

IF @transaccion NOT IN('NFA1')
BEGIN
	IF NOT EXISTS(SELECT idtran FROM dbo.ew_sys_transacciones2 WHERE idtran = @idtran AND (idestado = 5 OR idestado = 50))
	BEGIN
		SELECT @msg = '[1003] La transaccion no se encuentra en estado APLICADO o PAGADO'

		RAISERROR(@msg, 16, 1)
		RETURN
	END
END

-- ########################################################
-- Actualizar folio en tablas de transaccion

UPDATE ctrn SET
	ctrn.folio = f.serie + [dbo].[_sys_fnc_rellenar](LTRIM(RTRIM(STR(ct.cfd_folio))), 6, '0')
FROM
	ew_cfd_transacciones AS ct
	LEFT JOIN ew_cfd_folios AS f
		ON f.idfolio = ct.cfd_idfolio
	LEFT JOIN ew_cxc_transacciones AS ctrn
		ON ctrn.idtran = ct.idtran
WHERE
	ct.idtran = @idtran

UPDATE vtrn SET
	vtrn.folio = f.serie + [dbo].[_sys_fnc_rellenar](LTRIM(RTRIM(STR(ct.cfd_folio))), 6, '0')
FROM
	ew_cfd_transacciones AS ct
	LEFT JOIN ew_cfd_folios AS f
		ON f.idfolio = ct.cfd_idfolio
	LEFT JOIN ew_ven_transacciones AS vtrn
		ON vtrn.idtran = ct.idtran
WHERE
	ct.idtran = @idtran

UPDATE st SET
	st.folio = f.serie + [dbo].[_sys_fnc_rellenar](LTRIM(RTRIM(STR(ct.cfd_folio))), 6, '0')
FROM
	ew_cfd_transacciones AS ct
	LEFT JOIN ew_cfd_folios AS f
		ON f.idfolio = ct.cfd_idfolio
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = ct.idtran
WHERE
	ct.idtran = @idtran

-- ########################################################
-- Obtenemos el comando que utilizaremos para timbrar

UPDATE ew_cfd_transacciones SET
	idcomando = 4
WHERE
	idcomando = 0
	AND idtran = @idtran

SELECT TOP 1
	@tipo = i.tipo
	,@idcomando = i.idcomando
	,@comando = c.comando
	,@cfd_idfolio = i.cfd_idfolio
	,@cfd_folio = i.cfd_folio
FROM 
	dbo.ew_cfd_transacciones AS i 
	LEFT JOIN dbo.ew_cfd_comandos AS c 
		ON c.idcomando = i.idcomando
WHERE
	i.idtran = @idtran

SELECT @comando = ISNULL(@comando, '')

SELECT @comando = REPLACE(@comando, '{idtran}', RTRIM(CONVERT(VARCHAR(8),@idtran)))
SELECT @comando = REPLACE(@comando, '{cfd_idfolio}', RTRIM(CONVERT(VARCHAR(3),@cfd_idfolio)))
SELECT @comando = REPLACE(@comando, '{cfd_folio}', @cfd_folio)
SELECT @comando = REPLACE(@comando, '{tipo}', @tipo)

EXEC(@comando)

IF LEN(@comando) > 0
BEGIN
	INSERT INTO dbo.ew_sys_transacciones2 (
		idtran
		, idestado
		, idu
	)
	VALUES (
		@idtran
		, 23
		, @idu
	)
END
GO
