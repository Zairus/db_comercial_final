USE db_comercial_final
GO
ALTER PROCEDURE [dbo].[_sys_prc_empresa]
AS

SET NOCOUNT ON

DECLARE 
	@regimen AS VARCHAR(100) = ''
	,@razon_social AS VARCHAR(200) = ''
	,@rfc AS VARCHAR(15) = ''

	,@calle AS VARCHAR(200) = ''
	,@referencia AS VARCHAR(200) = ''
	,@noExterior AS VARCHAR(20) = ''
	,@colonia AS VARCHAR(200) = ''
	,@codpostal AS VARCHAR(50) = ''
	,@telefono1 AS VARCHAR(50) = ''
	,@ciudad AS VARCHAR(100) = ''

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
	@razon_social = cf.razon_social 
	,@rfc = cf.rfc
	,@calle = cf.calle
	,@referencia = cf.referencia
	,@noExterior = CASE WHEN cf.noExterior='' THEN cf.noInterior ELSE cf.NoExterior END
	,@colonia = cf.colonia
	,@codpostal = cf.codpostal
	,@telefono1 = cf.telefono1
	,@ciudad = sc.ciudad + ', ' + sc.estado
FROM 
	ew_clientes_facturacion cf
	LEFT JOIN ew_sys_ciudades sc
		ON sc.idciudad = cf.idciudad
WHERE 
	cf.idcliente = 0 
	AND cf.idfacturacion = 0

SELECT     
	[empresa] = @razon_social
	,[rfc] = @rfc
	,[logo] = dbo.fn_sys_parametro('IMG_LOGO')
	,[logo_sm] = REPLACE(dbo.fn_sys_parametro('IMG_LOGO'), '.jpg', '_sm.jpg')
	,[publicidad1] = dbo.fn_sys_parametro('IMG_PUBLICIDAD1')
	,[publicidad2] = dbo.fn_sys_parametro('IMG_PUBLICIDAD2')
	,[cedula] = dbo.fn_sys_parametro('IMG_CEDULA')
	,[email] = dbo.fn_sys_parametro('EMAIL_CUENTA')
	,[webpage] = dbo.fn_sys_parametro('WEB_PAGE')
	,[regimen] = @regimen

	,[datos_empresa] = @razon_social + CHAR(13) + CHAR(10) + @calle + ' No. ' + @noExterior + ' ' + @referencia + CHAR(13) + CHAR(10) + 'COL. ' + @colonia + ' C.P. ' + @codpostal + ' TEL: ' + @telefono1 + ' ' + @ciudad
GO
