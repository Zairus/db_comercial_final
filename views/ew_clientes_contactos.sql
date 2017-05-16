USE db_comercial_final
GO
ALTER VIEW [dbo].[ew_clientes_contactos]
AS
SELECT
	idr
	, idcontacto
	, idrelacion
	, [idcliente] = identidad
	, idsucursal
	, iddepto
	, puesto
	, horario
	, enviar_facturas
	, comentario
FROM
	dbo.ew_cat_contactos_entidades
WHERE
	idrelacion = 4
GO
