USE db_comercial_final
GO
IF OBJECT_ID('_ser_prc_web_calendarioClienteCoincidencia') IS NOT NULL
BEGIN
	DROP PROCEDURE _ser_prc_web_calendarioClienteCoincidencia
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200323
-- Description:	Buscar coincidencias de cliente por nombre
-- =============================================
CREATE PROCEDURE [dbo].[_ser_prc_web_calendarioClienteCoincidencia]
	@texto AS VARCHAR(200)
AS

SET NOCOUNT ON

SELECT
	c.codigo
	, c.nombre
	, [score1] = (
		SELECT COUNT(*)
		FROM
			vew_clientes AS c1
		WHERE
			c1.idcliente = c.idcliente
			AND c1.nombre = @texto COLLATE Modern_Spanish_CI_AI
	)
	, [score2] = (
		SELECT COUNT(*)
		FROM
			vew_clientes AS c1
		WHERE
			c1.idcliente = c.idcliente
			AND c1.nombre LIKE '%' + @texto + '%' COLLATE Modern_Spanish_CI_AI
	)
	, [score3] = (
		SELECT COUNT(*) 
		FROM 
			[dbo].[_sys_fnc_separarMultilinea](c.nombre, ' ') AS p1
		WHERE
			p1.valor COLLATE Modern_Spanish_CI_AI IN (
				SELECT p2.valor COLLATE Modern_Spanish_CI_AI
				FROM 
					[dbo].[_sys_fnc_separarMultilinea](@texto, ' ') AS p2
			)
	)
INTO
	#_tmp_clientes_b
FROM
	vew_clientes AS c

SELECT
	codigo
	, nombre
	, score1
	, score2
	, score3
FROM 
	#_tmp_clientes_b
WHERE
	(score1 + score2 + score3) > 0
ORDER BY
	score1 DESC
	, score2 DESC
	, score3 DESC
GO
