USE [db_comercial_final]
GO
ALTER PROCEDURE [dbo].[_sys_prc_empresa]
AS

SET NOCOUNT ON

DECLARE 
	@regimen AS VARCHAR(100) = ''
	,@razon_social AS VARCHAR(200) = ''
	,@rfc AS VARCHAR(15) = ''

SELECT 
	@regimen = (
		c_regimenfiscal 
		+ ' - ' 
		+ descripcion
	)
FROM 
	db_comercial.dbo.evoluware_cfd_sat_regimen 
WHERE 
	c_regimenfiscal = dbo.fn_sys_parametro('CFDI_REGIMEN')

SELECT 
	@razon_social = razon_social 
	,@rfc = rfc
FROM 
	ew_clientes_facturacion 
WHERE 
	idcliente = 0 
	AND idfacturacion = 0

SELECT     
	[empresa] = @razon_social
	,[rfc] = @rfc
	,[logo] = dbo.fn_sys_parametro('IMG_LOGO')
	,[publicidad1] = dbo.fn_sys_parametro('IMG_PUBLICIDAD1')
	,[publicidad2] = dbo.fn_sys_parametro('IMG_PUBLICIDAD2')
	,[cedula] = dbo.fn_sys_parametro('IMG_CEDULA')
	,[email] = dbo.fn_sys_parametro('EMAIL_CUENTA')
	,[webpage] = dbo.fn_sys_parametro('WEB_PAGE')
	,[regimen] = @regimen
GO
