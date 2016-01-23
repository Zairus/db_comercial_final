USE db_comercial_final
GO
ALTER VIEW ew_ven_notasVentaClientes
AS
SELECT 
	[codcliente_o] = 'Todos'
	, [idcliente_o] = 0
	, [nombre_o] = 'NOTAS DE TODOS LOS CLIENTES' 
	, [rfc] = 'XAXX010101000'

UNION ALL 

SELECT 
	[codcliente_o] = c.codigo
	, [idcliente_o] = c.idcliente
	, [nombre_o] = c.nombre 
	, [rfc] = cfa.rfc
FROM 
	ew_clientes AS c 
	LEFT JOIN ew_clientes_facturacion AS cfa
		ON cfa.idcliente = c.idcliente
WHERE 
	c.activo = 1
GO
SELECT * FROM ew_ven_notasVentaClientes
