USE [db_comercial_final]
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20080501
-- Description:	Generar la llave de una cuenta y toda su descendencia
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_generarLlave]
	@cuenta0 AS VARCHAR(20)
AS

SET NOCOUNT ON

-- Feneramos las llaves
-- Este procedimiento crea la tabla temporal global ##nodos
EXEC _ct_prc_nodos @cuenta0, '0'

-- Usamos la tabla ##nodos para actualizar llave, nivel y consecutivo
UPDATE b SET 
	b.llave = a.llave
	, b.nivel = a.nivel
	, b.consecutivo = a.consecutivo
FROM
	##nodos a
	LEFT JOIN ew_ct_cuentas b ON b.cuenta=a.cuenta
GO
