USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_ordenEstado') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_ordenEstado
END
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 201012
-- Description:	Actualizar Estado de la Orden
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_ordenEstado]
	@idtran AS BIGINT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@cantidad AS DECIMAL(15,4)
	, @surtir AS DECIMAL(15,4)
	, @facturar AS DECIMAL(15,4)
	, @idestado AS TINYINT

SELECT @idestado = dbo.fn_sys_estadoActual(@idtran)

IF @idestado IN (0, 255)
BEGIN
	RETURN
END

SELECT 
	@cantidad = ISNULL(SUM(om.cantidad_autorizada), 0)
	, @surtir = ISNULL(SUM(om.cantidad_surtida), 0)
	, @facturar = ISNULL(SUM(om.cantidad_facturada), 0)
FROM 
	ew_com_ordenes_mov AS om
	LEFT JOIN ew_com_ordenes AS o 
		ON o.idtran = om.idtran 
WHERE
	o.idtran = @idtran
	AND om.cantidad_autorizada != 0
GROUP BY
	o.idtran

IF @surtir + @facturar = 0
BEGIN
	SELECT @idestado = dbo.fn_sys_estadoID('AUT')
END
	ELSE
BEGIN
	IF (@surtir = @cantidad) AND (@facturar = @cantidad)
	BEGIN
		SELECT @idestado = dbo.fn_sys_estadoID('CERR')
	END
		ELSE
	BEGIN
		IF @surtir = @cantidad 
			SELECT @idestado = dbo.fn_sys_estadoID('RCBO')
		ELSE
			SELECT @idestado = dbo.fn_sys_estadoID('SUR~')
	END
END

IF dbo.fn_sys_estadoActual(@idtran) != @idestado
BEGIN
	INSERT INTO ew_sys_transacciones2 (
		idtran
		, idestado
		, idu
	) VALUES (
		@idtran
		, @idestado
		, @idu
	)
END
GO
