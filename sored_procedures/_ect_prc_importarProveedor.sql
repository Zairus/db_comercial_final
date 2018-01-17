USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151209
-- Description:	Importar proveedor de comprobante.
-- =============================================
ALTER PROCEDURE [dbo].[_ect_prc_importarProveedor]
	@idcomprobante AS INT
AS

SET NOCOUNT ON

DECLARE
	@idproveedor AS INT

SELECT
	@idproveedor = MAX(p.idproveedor)
FROM
	ew_proveedores AS p

SELECT @idproveedor = ISNULL(@idproveedor, 0) + 1

INSERT INTO ew_proveedores (
	idproveedor
	,codigo
	,nombre
	,nombre_corto
	,activo
	,tipo
	,rfc
	,direccion1
	,colonia
	,idciudad
	,codigo_postal
	,comentario
	,contabilidad
)

SELECT
	[idproveedor] = @idproveedor
	,[codigo] = ccr.Emisor_rfc
	,[nombre] = ccr.Emisor_nombre
	,[nombre_corto] = LEFT(ccr.Emisor_nombre, 10)
	,[activo] = 1
	,[tipo] = 0
	,[rfc] = ccr.Emisor_rfc
	,[direccion1] = ccr.Emisor_calle + ' ' + ccr.Emisor_noExterior + ' ' + ccr.Emisor_noInterior
	,[colonia] = ccr.Emisor_colonia
	,[idciudad] = ISNULL((SELECT TOP 1 cd.idciudad FROM ew_sys_ciudades AS cd WHERE cd.ciudad = ccr.Emisor_municipio), 0)
	,[codigo_postal] = ccr.Emisor_codigoPostal
	,[comentario] = 'Importado de XML: ' +  ccr.Timbre_UUID
	,[contabilidad] = '2100001000'
FROM 
	ew_cfd_comprobantes_recepcion AS ccr
WHERE
	ccr.idcomprobante = @idcomprobante
	
SELECT
	idproveedor
	,codigo
	,nombre
	,nombre_corto
	,activo
	,tipo
	,rfc
	,direccion1
	,colonia
	,idciudad
	,codigo_postal
	,comentario
FROM 
	ew_proveedores AS p
WHERE
	p.idproveedor = @idproveedor
GO
