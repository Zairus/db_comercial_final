USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151031
-- Description:	Datos para referencia en ticket de venta
-- =============================================
ALTER PROCEDURE _ven_prc_ticketVentaReferenciaDatos
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idturno AS INT
	,@pago_en_caja AS BIT
	,@idu AS INT = dbo._sys_fnc_usuario()
	,@idcuenta AS INT

SELECT @idturno = dbo.fn_sys_turnoActual(@idu)
SELECT @pago_en_caja = CONVERT(BIT, valor) FROM objetos_datos WHERE grupo = 'GLOBAL' AND codigo = 'PAGO_EN_CAJA'

IF @idu > 0 AND @idturno IS NULL AND @pago_en_caja = 0
BEGIN
	RAISERROR('Error: El usuario no ha iniciado turno.', 16, 1)
	RETURN
END

SELECT
	@idcuenta = st.idcuenta
FROM
	ew_sys_turnos AS st
WHERE
	st.idturno = @idturno

SELECT
	[idcliente] = vd.idcliente
	,[idfacturacion] = c.idfacturacion
	,[rfc] = cfa.rfc
	,[direccion] = cfa.direccion1
	,[noExterior] = cfa.noExterior
	,[colonia] = cfa.colonia
	,[ciudad] = cd.ciudad + ', ' + cd.estado
	,[codigo_postal] = cfa.codpostal
	,[telefono1] = cfa.telefono1
	,[idmoneda] = vd.idmoneda
	,[tipocambio] = vd.tipocambio
	,[idimpuesto1_valor] = ci1.valor
	,[idimpuesto1] = vd.idimpuesto1
	,[idlista] = vd.idlista
	,[codigo_vendedor] = v.codigo
	,[idvendedor] = vd.idvendedor
	,[nombre_vendedor] = v.nombre
	,[credito] = ctr.credito
	,[referencia] = vd.folio
	,[idtran2] = vd.idtran
	,[cliente] = c.codigo
	,[nombre] = c.nombre
	,[pago_en_caja] = @pago_en_caja
	,[idturno] = @idturno
	,[comentario] = vd.comentario
	,[idcuenta] = @idcuenta
FROM
	ew_ven_documentos AS vd
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vd.idcliente
	LEFT JOIN ew_clientes_facturacion AS cfa
		ON cfa.idcliente = c.idcliente
		AND cfa.idfacturacion = c.idfacturacion
	LEFT JOIN ew_sys_ciudades AS cd
		ON cd.idciudad = cfa.idciudad
	LEFT JOIN ew_cat_impuestos AS ci1
		ON ci1.idimpuesto = vd.idimpuesto1
	LEFT JOIN ew_ven_vendedores AS v
		ON v.idvendedor = vd.idvendedor
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = c.idcliente
WHERE
	vd.idtran = @idtran
GO
