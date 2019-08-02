USE db_comercial_final
GO
IF OBJECT_ID('_sys_fnc_equipoAsignado') IS NOT NULL
BEGIN
	DROP FUNCTION _sys_fnc_equipoAsignado
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190722
-- Description:	Indica si un equipo se encuentra asignado
-- =============================================
CREATE FUNCTION [dbo].[_sys_fnc_equipoAsignado]
(
	@idequipo AS INT
)
RETURNS BIT
AS
BEGIN
	DECLARE
		@asignado AS BIT = 0

	IF EXISTS(
		SELECT * 
		FROM 
			ew_clientes_servicio_equipos 
		WHERE 
			idequipo = @idequipo
	)
	BEGIN
		SELECT @asignado = 1
	END

	RETURN @asignado
END
GO
