USE db_comercial_final
GO
-- SP: 	Obtiene el siguiente folio disponible de un comprobante fiscal
-- 		Elaborado por Laurence Saavedra
-- 		Creado en Octubre del 2010
--		Modificado en Mayo del 2011
--		201508 - LAUSAA - El folio se obtiene de la tabla ew_cfd_transacciones por facturacion en 2 tiempos
--
--		
/*
DECLARE @idfolio SMALLINT,@noAprobacion VARCHAR(10),@folio INT,@serie VARCHAR(10)
EXEC _cfd_prc_obtenerFolio 2,'EFA1',@idfolio OUTPUT, @folio OUTPUT, @serie OUTPUT
PRINT @idfolio;PRINT @folio;PRINT @serie
*/
ALTER PROCEDURE [dbo].[_cfd_prc_obtenerFolio]
	 @idsucursal AS SMALLINT
	,@transaccion AS VARCHAR(4)
	,@idfolio AS SMALLINT OUTPUT
	,@folio AS INT OUTPUT
	,@serie AS VARCHAR(10) OUTPUT
AS

SET NOCOUNT ON

DECLARE
	 @noCertificado AS VARCHAR(20)
	,@msg AS VARCHAR(100)
	,@cantidad AS INT
	,@folio_inicial AS INT

-- Localizamos la transaccion en los folios de los comprobantes
SELECT TOP 1
	@idfolio = a.idfolio
	,@serie = a.serie
	,@cantidad = a.cantidad
	,@folio_inicial = a.folio_inicial
	-- @idCertificado=a.idcertificado
	--,@noCertificado=c.noCertificado
	--,@noAprobacion=a.noAprobacion
FROM
	ew_cfd_folios AS a
	LEFT JOIN evoluware_certificados AS c
		ON c.idcertificado = a.idcertificado
WHERE
	a.activo = '1'
ORDER BY
	(
		SELECT TOP 1 valor 
		FROM 
			dbo.fn_sys_split(a.sucursales,',') 
		WHERE 
			valor IN (@idsucursal,'*') 
		ORDER BY 
			valor DESC
	) DESC
	,(
		SELECT TOP 1 valor 
		FROM 
			dbo.fn_sys_split(a.transacciones,',') 
		WHERE 
			valor IN (@transaccion,'*') 
		ORDER BY 
			valor DESC
	) DESC

IF @@ROWCOUNT = 0
BEGIN
	-- No existe la la transaccion en los folios de los comprobantes
	SELECT TOP 1
		@idfolio = @idfolio
		-- @idCertificado=b.idcertificado
		--,@noCertificado=c.noCertificado
		--,@noAprobacion=b.noAprobacion
		,@serie=b.serie
		,@cantidad=b.cantidad
		,@folio_inicial=b.folio_inicial
	FROM
		ew_cfd_folios b 
		LEFT JOIN evoluware_certificados c 
			ON c.idcertificado=b.idcertificado
	WHERE
		b.activo = '1'
	ORDER BY
		(CASE WHEN b.sucursales = RTRIM(CONVERT(VARCHAR(3),@idsucursal)) THEN 0 ELSE 1 END)
		,b.fechaVencimiento DESC
		
	IF @@ROWCOUNT=0
	BEGIN
		SELECT @msg='Error. No existe ningún grupo de folios disponibles ...'
		RAISERROR(@msg,16,1)
		RETURN
	END
END

SELECT 
	@folio = ISNULL(MAX(cfd_folio), (@folio_inicial-1)) + 1
FROM
	ew_cfd_transacciones
WHERE
	cfd_idfolio=@idfolio

IF @folio >= (@cantidad + @folio_inicial)
BEGIN
	UPDATE ew_cfd_folios SET 
		activo = 0 
	WHERE 
		idfolio = @idfolio  -- idcertificado=@idCertificado AND noAprobacion=@noAprobacion AND serie=@serie

	SELECT @folio = NULL
END
GO
