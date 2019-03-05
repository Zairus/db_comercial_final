USE db_comercial_final
GO
IF OBJECT_ID('ew_sys_empresa') IS NOT NULL
BEGIN
	DROP VIEW ew_sys_empresa
END
GO
CREATE VIEW ew_sys_empresa
AS
SELECT
	[nombre] = c.nombre
	, [nombre_corto] = c.nombre_corto
	, [razon_social] = cfa.razon_social
	, [rfc] = cfa.rfc
	, [calle] = cfa.calle
	, [noExterior] = cfa.noExterior
	, [noInterior] = cfa.noInterior
	, [referencia] = cfa.referencia
	, [colonia] = cfa.colonia
	, [idciudad] = cfa.idciudad
	, [ciudad] = cd.ciudad
	, [estado] = cd.estado
	, [pais] = cd.pais
	, [codigo_postal] = cfa.codpostal
	, [direccion] = [dbo].[_sys_fnc_direccionCadena] (
		cfa.calle
		, cfa.noExterior
		, cfa.noInterior
		, cfa.referencia
		, cfa.colonia
		, cfa.idciudad
		, cfa.codpostal
	)
	, [telefono1] = cfa.telefono1
	, [telefono2] = cfa.telefono2
	, [sitio_web] = cfa.sitio_web
	, [email] = cfa.email
FROM 
	ew_clientes AS c
	LEFT JOIN ew_clientes_facturacion AS cfa
		ON cfa.idfacturacion = 0
		AND cfa.idcliente = c.idcliente
	LEFT JOIN ew_sys_ciudades AS cd
		ON cd.idciudad = cfa.idciudad
WHERE
	c.idcliente = 0
GO
