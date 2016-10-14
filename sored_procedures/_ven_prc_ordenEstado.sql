USE [db_comercial_final]
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 201012
-- Description:	Actualizar Estado de la Orden
--
-- EXEC _ven_prc_ordenEstado '100012'
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_ordenEstado]
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	 @cantidad AS DECIMAL(15,4)
	,@surtir AS DECIMAL(15,4)
	,@facturar AS DECIMAL(15,4)
	,@idestado AS SMALLINT

SELECT @idestado = dbo.fn_sys_estadoActual(@idtran)

IF @idestado IN (0,255)
BEGIN
	RETURN
END

SELECT 
	 @cantidad = ISNULL(SUM(om.cantidad_autorizada), 0)
	,@surtir = ISNULL(SUM(om.cantidad_porSurtir * a.inventariable), 0)
	,@facturar = ISNULL(SUM(om.cantidad_porFacturar), 0)
FROM 
	ew_ven_ordenes_mov AS om
	LEFT JOIN ew_ven_ordenes AS o
		ON o.idtran=om.idtran 
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = om.idarticulo
WHERE
	o.idtran = @idtran
	AND om.cantidad_autorizada != 0
GROUP BY
	o.idtran

IF (@cantidad = @surtir) AND (@cantidad = @facturar)
BEGIN
	SELECT @idestado = dbo.fn_sys_estadoID('AUT')
END
	ELSE
BEGIN
	IF (@surtir = 0) AND (@facturar = 0)
	BEGIN
		SELECT @idestado=dbo.fn_sys_estadoID('CERR')
	END
		ELSE
	BEGIN
		IF @surtir = 0
			SELECT @idestado=dbo.fn_sys_estadoID('SURT')
		ELSE
			SELECT @idestado=dbo.fn_sys_estadoID('SUR~')
	END
END

IF dbo.fn_sys_estadoActual(@idtran) != @idestado
BEGIN
	INSERT INTO ew_sys_transacciones2 (idtran, idestado, idu) 
	VALUES (@idtran, @idestado, @idu)
END
GO
