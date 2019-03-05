USE db_comercial_final
GO
IF OBJECT_ID('_sys_fnc_direccionCadena') IS NOT NULL
BEGIN
	DROP FUNCTION [dbo].[_sys_fnc_direccionCadena]
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190222
-- Description:	Regresa cadena de direccion a partir de datos
-- =============================================
CREATE FUNCTION [dbo].[_sys_fnc_direccionCadena]
(
	@calle AS VARCHAR(200)
	, @noExterior AS VARCHAR(200)
	, @noInterior AS VARCHAR(200)
	, @referencia AS VARCHAR(200)
	, @colonia AS VARCHAR(1000)
	, @idciudad AS INT
	, @codigo_postal AS VARCHAR(10)
)
RETURNS VARCHAR(4000)
AS
BEGIN
	DECLARE
		@direccion AS VARCHAR(4000)

	SELECT
		@direccion = (
			d.calle
			+ (
				CASE
					WHEN LEN(d.noExterior) > 0 THEN
						' ' + d.noExterior
					ELSE ''
				END
			)
			+ (
				CASE
					WHEN LEN(d.noInterior) > 0 THEN
						' ' + d.noInterior
					ELSE ''
				END
			)
			+ (
				CASE
					WHEN LEN(d.referencia) > 0 THEN
						'. ' + d.referencia
					ELSE ''
				END
			)
			+ (
				CASE
					WHEN LEN(d.colonia) > 0 THEN
						'. Col: ' + d.colonia
					ELSE ''
				END
			)
			+ (
				CASE
					WHEN cd.ciudad IS NOT NULL THEN
						'. '
						+ cd.ciudad
						+ ', ' + cd.estado
						+ ', ' + cd.pais
					ELSE ''
				END
			)
			+ (
				CASE
					WHEN LEN(d.codigp_postal) > 0 THEN
						'. ' + d.codigp_postal
					ELSE ''
				END
			)
		)
	FROM
		(
			SELECT
				[calle] = @calle
				, [noExterior] = @noExterior
				, [noInterior] = @noInterior
				, [referencia] = @referencia
				, [colonia] = @colonia
				, [codigp_postal] = @codigo_postal
		) AS d
		LEFT JOIN ew_sys_ciudades AS cd
			ON cd.idciudad = @idciudad

	RETURN @direccion
END
GO
