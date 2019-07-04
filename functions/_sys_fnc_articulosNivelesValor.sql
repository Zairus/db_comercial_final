USE db_comercial_final
GO
IF OBJECT_ID('_sys_fnc_articulosNivelesValor') IS NOT NULL
BEGIN
	DROP FUNCTION _sys_fnc_articulosNivelesValor
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190618
-- Description:	Regresa ruta o clave de clasificacion de producto
-- =============================================
CREATE FUNCTION [dbo].[_sys_fnc_articulosNivelesValor]
(
	@nivel_idr AS INT
	, @tipo_valor AS VARCHAR(20)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE
		@valor AS VARCHAR(MAX)

	SELECT
		@valor = (
			(
				CASE
					WHEN ans.idr IS NOT NULL THEN
						[dbo].[_sys_fnc_articulosNivelesValor](ans.idr, @tipo_valor)
						+ IIF(@tipo_valor = 'ruta', '>>', '')
					ELSE ''
				END
			)
			+(
				CASE @tipo_valor
					WHEN 'ruta' THEN
						an.nombre
					WHEN 'orden' THEN
						[dbo].[_sys_fnc_rellenar](an.orden, 6, '0')
						+ [dbo].[_sys_fnc_rellenar](
							ISNULL((
								SELECT
									anord.ord
								FROM
									(
										SELECT
											anr1.idr
											, [ord] = ROW_NUMBER() OVER (ORDER BY anr1.nombre)
										FROM
											ew_articulos_niveles AS anr1
										WHERE
											anr1.nivel = an.nivel
									) AS anord
								WHERE
									anord.idr = an.idr
							), 0)
							, 6
							, '0'
						)
					ELSE ''
				END
			)
		)
	FROM
		ew_articulos_niveles AS an
		LEFT JOIN ew_articulos_niveles AS ans
			ON ans.codigo = an.codigo_superior
	WHERE
		an.idr = @nivel_idr

	SELECT @valor = ISNULL(@valor, '')

	RETURN @valor
END
GO
