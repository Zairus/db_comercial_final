USE [db_comercial_final]
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER FUNCTION [dbo].[_sys_fnc_separarMultilinea] (
	@cadena VARCHAR(8000),
	@separador VARCHAR(20)
)
RETURNS @tabla TABLE (idr INT IDENTITY, valor VARCHAR(500)) 
AS
BEGIN
	DECLARE	@registro AS INT,
			@posicion1 AS SMALLINT,
			@posicion2 AS SMALLINT,
			@var AS VARCHAR(50)
	
	SELECT @registro = 0
	SELECT @posicion1 = 1
	SELECT @posicion2 = LEN(@cadena) + 1
	
	WHILE @registro = 0
	BEGIN
		SELECT @posicion2 = CHARINDEX(@separador, @cadena, @posicion1)
		
		IF @posicion2 = 0 
		BEGIN
			SELECT @registro = 1
			SELECT @posicion2 = LEN(@cadena) + 1
		END
		
		SELECT @var = ''
		
		SELECT @var = SUBSTRING(@cadena , @posicion1 , @posicion2 - @posicion1)
		
		INSERT INTO @tabla (valor) VALUES (@var)
		
		SELECT @posicion1 = @posicion2 + 1
		
		IF @posicion1 > LEN(@cadena)
		BEGIN
			SELECT @registro = 1
		END
	END
	
	RETURN
END
GO
