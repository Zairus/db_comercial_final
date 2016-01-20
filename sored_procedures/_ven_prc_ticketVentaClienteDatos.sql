USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150615
-- Description:	Datos de cliente en nuevo ticket de venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_ticketVentaClienteDatos]
	@cliente_codigo AS VARCHAR(30)
	,@idsucursal AS SMALLINT
	,@idmoneda AS SMALLINT
	,@idu AS SMALLINT = 0
AS

SET NOCOUNT ON

DECLARE
	@idturno AS INT
	,@pago_en_caja AS BIT
	,@idcuenta AS INT
	,@error_mensaje AS VARCHAR(500)

SELECT @idturno = [dbo].[fn_sys_turnoActualR2](@idu, 0)
SELECT @pago_en_caja = CONVERT(BIT, valor) FROM objetos_datos WHERE grupo = 'GLOBAL' AND codigo = 'PAGO_EN_CAJA'

IF @idu > 0 AND @idturno IS NULL AND @pago_en_caja = 0
BEGIN
	SELECT @idturno = [dbo].[fn_sys_turnoActualR2](@idu, 1)

	IF @idturno IS NULL
	BEGIN
		SELECT @error_mensaje = 'Error: El usuario no ha iniciado turno.'
	END
		ELSE
	BEGIN
		SELECT
			@error_mensaje = (
				'El usuario '
				+u.nombre
				+', '
				+CHAR(13)
				+'tiene turno abierto con fecha '
				+CONVERT(VARCHAR(8), st.fecha_inicio, 3)
				+'.'
				+CHAR(13)
				+'Es necesario primero cerrar ese turno.'
			)
		FROM
			ew_sys_turnos AS st
			LEFT JOIN evoluware_usuarios AS u
				ON u.idu = st.idu
		WHERE
			idturno = @idturno
	END

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

IF @pago_en_caja = 0
BEGIN
	SELECT @idcuenta = idcuenta FROM ew_sys_turnos WHERE idturno = @idturno
	EXEC _ban_prc_validarCorteAbierto @idcuenta
END

SELECT
	[idcliente] = c.idcliente
	,[cliente] = c.codigo
	,[idfacturacion] = c.idfacturacion
	,[nombre] = c.nombre
	,[rfc] = cf.rfc
	,[direccion] = cf.direccion1
	,[noExterior] = cf.noExterior
	,[colonia] = cf.colonia
	,[ciudad] = cd.ciudad
	,[codigo_postal] = cf.codpostal
	,[telefono1] = cf.telefono1
	,[idimpuesto1_valor] = ci.valor
	,[idimpuesto1] = s.idimpuesto
	,[idlista] = ctr.idlista
	,[codigo_vendedor] = vv.codigo
	,[idvendedor] = ctr.idvendedor
	,[nombre_vendedor] = vv.nombre
	,[credito] = ctr.credito
	,[credito_dias] = ctr.credito_plazo
	,[cliente_saldo] = csa.saldo

	,ctr.credito_limite
	,ctr.credito_suspendido

	,[idcuenta] = ISNULL((SELECT CASE WHEN t.idcuenta = 0 THEN 3 ELSE t.idcuenta END FROM ew_sys_turnos AS t WHERE t.idturno = @idturno), 0)
	,[pago_en_caja] = @pago_en_caja
	,[idturno] = @idturno
FROM
	ew_clientes AS c
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = c.idcliente
	LEFT JOIN ew_clientes_facturacion AS cf
		ON cf.idcliente = c.idcliente
		AND cf.idfacturacion = c.idfacturacion
	LEFT JOIN ew_ven_vendedores AS vv
		ON vv.idvendedor = ctr.idvendedor
	LEFT JOIN ew_sys_ciudades AS cd
		ON cd.idciudad = cf.idciudad
	LEFT JOIN ew_cxc_saldos_actual AS csa
		On csa.idcliente = c.idcliente
		AND csa.idmoneda = @idmoneda
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = @idsucursal
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = s.idimpuesto
WHERE
	c.codigo = @cliente_codigo
GO
