USE db_comercial_final
GO
IF OBJECT_ID('_ser_prc_web_calendarioTecnicoCoincidencia') IS NOT NULL
BEGIN
	DROP PROCEDURE _ser_prc_web_calendarioTecnicoCoincidencia
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200323
-- Description:	Buscar coincidencias de tecnico por nombre
-- =============================================
CREATE PROCEDURE [dbo].[_ser_prc_web_calendarioTecnicoCoincidencia]
	@texto AS VARCHAR(200)
	, @tipo AS INT = 0 --0: todos, 1: internos, 2: externos
AS

SET NOCOUNT ON

SELECT
	[codigo] = st.codigo
	, [nombre] = ISNULL(u.nombre, st.nombre)
	, [score1] = 0
	, [score2] = 0
	, [score3] = 0
INTO
	#_tmp_tecnicos_b
FROM
	ew_ser_tecnicos AS st
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = st.idu
WHERE
	(
		@tipo = 1
		AND st.idu > 0
	)
	OR (
		@tipo = 2
		AND st.idu = 0
	)
	OR (
		@tipo = 0
	)

UPDATE t SET
	score1 = (
		SELECT COUNT(*)
		FROM
			#_tmp_tecnicos_b AS tb
		WHERE
			tb.codigo = t.codigo
			AND tb.nombre = @texto COLLATE Modern_Spanish_CI_AI
	)
	, score2 = (
		SELECT COUNT(*)
		FROM
			#_tmp_tecnicos_b AS tb
		WHERE
			tb.codigo = t.codigo
			AND tb.nombre LIKE '%' + @texto + '%' COLLATE Modern_Spanish_CI_AI
	)
	, score3 = (
		SELECT COUNT(*) 
		FROM 
			[dbo].[_sys_fnc_separarMultilinea](t.nombre, ' ') AS p1
		WHERE
			p1.valor COLLATE Modern_Spanish_CI_AI IN (
				SELECT p2.valor COLLATE Modern_Spanish_CI_AI
				FROM 
					[dbo].[_sys_fnc_separarMultilinea](@texto, ' ') AS p2
			)
	)
FROM
	#_tmp_tecnicos_b AS t

SELECT * 
FROM 
	#_tmp_tecnicos_b
WHERE
	(score1 + score2 + score3) > 0
ORDER BY
	score1 DESC
	, score2 DESC
	, score3 DESC
GO
