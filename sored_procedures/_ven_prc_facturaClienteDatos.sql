USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20121112
-- Description:	Datos de cliente en factura electrónica de tickets
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaClienteDatos]
	 @codcliente AS VARCHAR(30)
	,@idsucursal AS INT
	,@venta AS BIT = 0
AS

SET NOCOUNT ON

DECLARE 
	@codigo_p AS VARCHAR(30)

DECLARE
	 @idcliente AS INT
	,@activo AS BIT

DECLARE
	 @error AS INT
	,@error_mensaje AS VARCHAR(2000)

SELECT @error = 0
SELECT @error_mensaje = ''

SELECT 
	@codigo_p = CONVERT(VARCHAR(30), valor) 
FROM objetos_datos 
WHERE 
	grupo = 'GLOBAL' 
	AND codigo = 'CLIENTE_PUBLICO'

SELECT
	 @idcliente = c.idcliente
	,@activo = c.activo
FROM
	ew_clientes AS c
WHERE
	c.codigo = @codcliente

IF @venta = 1
BEGIN
	IF @activo = 0
	BEGIN
		SELECT @error = @error + 10
		SELECT @error_mensaje = @error_mensaje + 'Error: El cliente se encuentra inactivo.'
	END
END

SELECT
	[idcliente] = c.idcliente
	, [facturara] = cf.razon_social
	, [nombre] = cf.razon_social
	, [rfc] = cf.rfc
	, [idfacturacion] = cf.idfacturacion
	, [cliente] = c.nombre
	, [codcliente] = c.codigo
	, [direccion] = (cf.calle + ISNULL(' ' + cf.noExterior, '') + ISNULL(' ' + cf.noInterior, ''))
	, [colonia] = cf.colonia
	, [codciudad] = fac.codciudad
	, [ciudad] = fac.ciudad
	, [estado] = fac.estado
	, [pais] = fac.pais
	, [codigopostal] = cf.codpostal
	, [codigo_postal] = cf.codpostal
	, [telefono1] = cf.telefono1
	, [email] = cf.email
	, [idfacturacion] = c.idfacturacion
	, [metodoDePago] = RTRIM(c.cfd_metodoDePago) + ' ' + RTRIM(c.cfd_NumCtaPago)
	, [referencia] = RTRIM(c.cfd_NumCtaPago)
	, [modificar] = c.modificar
	, [modifica_precio_neg] = 0
	, [clasificacion] = ''
	
	, [idmoneda] = c.idmoneda
	, [tipocambio] = bm.tipocambio
	, [idforma] = c.idforma
	, [cfd_iduso] = c.cfd_iduso
	, [suspender] = ct.credito_suspendido
	, [credito] = ct.credito
	, [c_mensaje] = (
		CASE 
			WHEN ct.credito_suspendido = 1 THEN 'Crédito suspendido'
			WHEN (csa.saldo >= ct.credito_limite) THEN 'No hay crédito disponible'
			ELSE 'Ok'
		END
	)
	
	, [idvendedor] = ct.idvendedor
	, [cliente_saldo] = csa.saldo
	, [credito_disponible] = (ct.credito_limite - csa.saldo)
	, [credito_dias] = ct.credito_plazo
	, [porc_pe] = 0
	, [inv_partes] = 0
	, [idcontacto] = c.idcontacto
	, [nombre_contacto] = ccc.nombre
	, [telefono_contacto] = ''
	, [fax_contacto] = ''
	, [horario_contacto] = cc.horario
	, [email] = cf.email
	
	, [codcliente_o] = c.codigo
	, [idcliente_o] = c.idcliente
	, [nombre_o] = c.nombre
	
	, [idubicacion] = cu.idubicacion
	, [nombre_ubicacion] = cu.nombre_ubicacion
	, [direccion_ubicacion] = cu.direccion_ubicacion
	, [colonia_ubicacion] = cu.colonia_ubicacion
	, [ciudad_ubicacion] = cu.ciudad_ubicacion
	, [cp_ubicacion] = cu.cp_ubicacion
	, [telefono_ubicacion] = cu.telefono_ubicacion
	
	, [cliente_notif] = dbo._sys_fnc_parametroActivo('CFDI_NOTIFICAR_AUTOMATICO')
	, [idmetodo] = (CASE WHEN ct.credito = 1 THEN 2 ELSE 1 END)
	, [idforma] = c.idforma
	, [cfd_iduso] = c.cfd_iduso
FROM
	ew_clientes AS c
	LEFT JOIN ew_clientes_facturacion AS cf
		ON cf.idcliente = c.idcliente
		AND cf.idfacturacion = cf.idfacturacion
	LEFT JOIN ew_sys_ciudades AS fac 
		ON fac.idciudad = cf.idciudad
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = c.idmoneda
	LEFT JOIN ew_clientes_terminos AS ct
		ON ct.idcliente = c.idcliente
	LEFT JOIN ew_cxc_saldos_actual AS csa
		ON csa.idcliente = c.idcliente
		AND csa.idmoneda = c.idmoneda
	LEFT JOIN ew_clientes_contactos AS cc
		ON cc.idcliente = c.idcliente
		AND cc.idcontacto = c.idcontacto
	LEFT JOIN ew_cat_contactos AS ccc
		ON ccc.idcontacto = cc.idcontacto
	LEFT JOIN (
		SELECT TOP 1
			 cu.idcliente
			,cu.idubicacion
			,[nombre_ubicacion] = cu.nombre
			,[direccion_ubicacion] = cu.direccion1
			,[colonia_ubicacion] = cu.colonia
			,[ciudad_ubicacion] = (cd.ciudad + ', ' + cd.estado)
			,[cp_ubicacion] = cu.codpostal
			,[telefono_ubicacion] = cu.telefono1
		FROM
			ew_clientes_ubicaciones AS cu
			LEFT JOIN ew_sys_ciudades AS cd
				ON cd.idciudad= cu.idciudad
		WHERE
			cu.idcliente = @idcliente
	) AS cu
		ON cu.idcliente = c.idcliente
WHERE
	c.codigo = @codcliente
GO
