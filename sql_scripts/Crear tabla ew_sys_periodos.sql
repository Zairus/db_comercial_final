USE db_comercial_final
GO
IF OBJECT_ID('ew_sys_periodos') IS NOT NULL
BEGIN
	DROP TABLE ew_sys_periodos
END
GO
CREATE TABLE ew_sys_periodos (
	idr INT IDENTITY
	, ejercicio INT NOT NULL
	, periodo INT NOT NULL
	, idmodulo INT NOT NULL
	, activo BIT NOT NULL DEFAULT 1

	, CONSTRAINT [PK_ew_sys_periodos] PRIMARY KEY CLUSTERED (
		ejercicio ASC
		, periodo ASC
		, idmodulo ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO
IF OBJECT_ID('_sys_prc_ejercicioInicializar') IS NOT NULL
BEGIN
	DROP PROCEDURE _sys_prc_ejercicioInicializar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190417
-- Description:	Inicializar ejercicio de sistema
-- =============================================
CREATE PROCEDURE _sys_prc_ejercicioInicializar
	@ejercicio AS INT
AS

SET NOCOUNT ON

INSERT INTO ew_sys_periodos (
	ejercicio
	, periodo
	, idmodulo
)
SELECT
	[ejercicio] = @ejercicio
	, [periodo] = m.id
	, [idmodulo] = em.idmodulo
FROM
	db_comercial.dbo.evoluware_modulos AS em
	LEFT JOIN ew_sys_periodos_datos AS m
		ON m.grupo = 'meses'
WHERE
	(
		SELECT COUNT(*) 
		FROM ew_sys_periodos AS sp 
		WHERE 
			sp.ejercicio = @ejercicio 
			AND sp.periodo = m.id 
			AND sp.idmodulo = em.idmodulo
	) = 0
GO
DECLARE
	@cmd AS NVARCHAR(4000) = ''

SELECT 
	@cmd = (
		SELECT DISTINCT 
			'EXEC _sys_prc_ejercicioInicializar ' + LTRIM(RTRIM(STR(YEAR(fecha)))) + '; '
		FROM
			ew_sys_transacciones
		FOR XML PATH('')
	)

EXEC sp_executesql @cmd

SELECT * FROM ew_sys_periodos
