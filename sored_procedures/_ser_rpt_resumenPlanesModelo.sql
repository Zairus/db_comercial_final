USE db_comercial_final
GO
IF OBJECT_ID('_ser_rpt_resumenPlanesModelo') IS NOT NULL
BEGIN
	DROP PROCEDURE _ser_rpt_resumenPlanesModelo
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190701
-- Description:	Resumen de planes de servicio
-- =============================================
GO
CREATE PROCEDURE [dbo].[_ser_rpt_resumenPlanesModelo]
	@cliente_codigo AS VARCHAR(30) = ''
	, @plan_codigo AS VARCHAR(10) = ''
AS

SELECT
	[plan_grupo] = c.nombre + ' [' + csp.plan_codigo + ']'
	, [plan_codigo] = csp.plan_codigo
	, [periodo_facturacion] = (
		CASE csp.periodo
			WHEN 1 THEN 'Mensual'
			WHEN 2 THEN 'Bimestral'
			WHEN 3 THEN 'Trimestral'
			WHEN 6 THEN 'Semestral'
			WHEN 7 THEN 'Anual'
		END
	)
	, [monto] = (
		CASE
			WHEN (ROW_NUMBER () OVER (PARTITION BY csp.idcliente, csp.plan_codigo ORDER BY a.codigo)) = 1 THEN ISNULL(NULLIF(csp.costo_especial, 0), csp.costo)
			ELSE 0
		END
	)

	, [articulo_codigo] = a.codigo
	, [articulo_codigo_n] = 1
	
	, [costo_especial] = (
		CASE
			WHEN (ROW_NUMBER () OVER (PARTITION BY csp.idcliente, csp.plan_codigo ORDER BY a.codigo)) = 1 THEN csp.costo_especial
			ELSE 0
		END
	)

	, [articulo_precio_lista] = vlm.precio1
	
	, [cliente] = c.nombre
	, [razon_social] = c.razon_social
	, [contacto_pagos] = ISNULL((
		SELECT TOP 1
			ccc.nombre + ' ' + ccc.apellido
		FROM
			ew_clientes_contactos AS cc
			LEFT JOIN ew_cat_contactos AS ccc
				ON ccc.idcontacto = cc.idcontacto
		WHERE
			cc.idcliente = c.idcliente
			AND cc.iddepto IN (9,2)
		--SELECT iddepto, nombre FROM ew_cat_departamentos
	), '')
	, [revision_dia] = rd.descripcion
	, [revision_hora] = ctr.hora_revision
	, [pago_dia] = pd.descripcion
	, [pago_hora] = ctr.hora_pago
	, [forma_pago] = ISNULL(bf.nombre, '')
	, [domicilio_pago] = [dbo].[_sys_fnc_direccionCadena] (
		c.calle
		, c.noExterior
		, c.noInterior
		, c.referencia
		, '' --c.colonia
		, 0 --c.idciudad
		, '' --c.codpostal
	)
	, [colonia] = c.colonia
	, [ciudad] = cd.ciudad
	, [telefono] = (
		ISNULL((
			SELECT TOP 1
				NULLIF([dbo].[fn_cat_contactoInformacion](ccc.idcontacto, 1, 1), '')
			FROM
				ew_clientes_contactos AS cc
				LEFT JOIN ew_cat_contactos AS ccc
					ON ccc.idcontacto = cc.idcontacto
			WHERE
				cc.idcliente = c.idcliente
				AND cc.iddepto IN (9,2)
		), c.telefono1)
	)
	, [comentario] = csp.comentario

	--SELECT * FROM ew_clientes_contactos
	--SELECT * FROM ew_cat_contactos WHERE idcontacto = 510
FROM 
	ew_clientes_servicio_planes AS csp
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = csp.idcliente
	LEFT JOIN ew_clientes_servicio_equipos AS cse
		ON cse.plan_codigo = csp.plan_codigo
		AND cse.idcliente = csp.idcliente
	LEFT JOIN ew_ser_equipos AS se
		ON se.idequipo = cse.idequipo
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = se.idarticulo
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idlista = [dbo].[_sys_fnc_parametroTexto]('SER_LISTA_PRECIOS_RENTA')
		AND vlm.idarticulo = a.idarticulo
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = c.idcliente
	LEFT JOIN ew_sys_periodos_datos AS rd
		ON rd.grupo = 'dias_semana'
		AND rd.id = ctr.dia_revision
	LEFT JOIN ew_sys_periodos_datos AS pd
		ON pd.grupo = 'dias_semana'
		AND pd.id = ctr.dia_pago
	LEFT JOIN ew_ban_formas_aplica AS bf
		ON bf.idforma = c.idforma
	LEFT JOIN ew_sys_ciudades AS cd
		ON cd.idciudad = c.idciudad
WHERE 
	c.codigo = ISNULL(NULLIF(@cliente_codigo, ''), c.codigo)
	AND csp.plan_codigo = ISNULL(NULLIF(@plan_codigo, ''), csp.plan_codigo)

	AND (
		SELECT COUNT(*) 
		FROM 
			ew_clientes_servicio_equipos AS cse 
		WHERE 
			cse.idcliente = csp.idcliente
			AND cse.plan_codigo = csp.plan_codigo
	) > 0

ORDER BY
	c.nombre
	, csp.plan_codigo
GO
