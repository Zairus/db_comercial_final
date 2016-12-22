USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110426
-- Description:	Dato de contacto
-- =============================================
ALTER FUNCTION [dbo].[fn_sys_contactoDato]
(
	 @idcontacto AS INT
	,@dato AS VARCHAR(10)
)
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE
		@dato_valor AS VARCHAR(100)
	
	/*
	Tipos de registro:
	0: Dirección
	1: Teléfono Fijo
	2: Teléfono Móvil
	3: Fax
	4: Teléfono Celular
	5: Correo electrónico
	6: Sitio Web
	7: Otro
	*/
	
	SELECT @dato_valor = ''
	
	SELECT
		@dato_valor = (
			@dato_valor 
			+(
				CASE 
					WHEN LEN(@dato_valor) > 0 THEN ', ' 
					ELSE '' 
				END
			) 
			+(
				CASE 
					WHEN UPPER(@dato) = 'DIR' THEN ISNULL((dato1 + ' ' + dato2 + ' ' + dato3), '')
					WHEN UPPER(@dato) IN ('TEL', 'FAX') THEN ISNULL((dato1 + CASE WHEN dato2 <> '' THEN ' ext. ' + dato2 ELSE '' END), '')
					WHEN UPPER(@dato) IN ('CEL','EML','WEB','OTR') THEN ISNULL(dato1, '')
				END
			)
		)
	FROM
		ew_cat_contactos_contacto
	WHERE
		idcontacto = @idcontacto
		AND tipo IN (
			CASE UPPER(@dato)
				WHEN 'DIR' THEN 0
				WHEN 'TEL' THEN 1
				WHEN 'CEL' THEN 2
				WHEN 'FAX' THEN 3
				WHEN 'EML' THEN 4
				WHEN 'WEB' THEN 6
				WHEN 'OTR' THEN 7
			END
		)
	
	SELECT @dato_valor = ISNULL(@dato_valor, '')
	
	RETURN @dato_valor
END
GO
