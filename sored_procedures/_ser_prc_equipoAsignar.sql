USE db_comercial_final
GO
IF OBJECT_ID('_ser_prc_equipoAsignar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ser_prc_equipoAsignar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190730
-- Description:	Asignar equipo a plan de cliente
-- =============================================
CREATE PROCEDURE [dbo].[_ser_prc_equipoAsignar]
	@idequipo AS INT
	, @idcliente AS INT
	, @plan_codigo AS VARCHAR(10)
AS

SET NOCOUNT ON

INSERT INTO ew_clientes_servicio_equipos (
	idequipo
	, idcliente
	, plan_codigo
)
SELECT
	[idequipo] = @idequipo
	, [idcliente] = @idcliente
	, [plan_codigo] = @plan_codigo
WHERE
	(
		SELECT COUNT(*) 
		FROM 
			ew_clientes_servicio_equipos AS cse 
		WHERE 
			cse.idequipo = @idequipo
	) = 0

SELECT
	[serie] = se.serie
	, [idr] = cse.idr
	, [idequipo] = cse.idequipo
	, [codarticulo] = a.codigo
	, [articulo] = a.nombre
	, [precio_lista] = vlm.precio1
	, [ubicacion] = cu.nombre
	, [idubicacion] = cse.idubicacion
	, [tecnico] = st.codigo
	, [idtecnico] = cse.idtecnico
	, [referencia] = cse.referencia
FROM
	ew_clientes_servicio_equipos AS cse
	LEFT JOIN ew_ser_equipos AS se
		ON se.idequipo = cse.idequipo
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = se.idarticulo
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idlista = [dbo].[_sys_fnc_parametroTexto]('SER_LISTA_PRECIOS_RENTA')
		AND vlm.idarticulo = a.idarticulo
	LEFT JOIN ew_clientes_ubicaciones AS cu
		ON cu.idcliente = cse.idcliente
		AND cu.idubicacion = cse.idubicacion
	LEFT JOIN ew_ser_tecnicos AS st
		ON st.idtecnico = cse.idtecnico
WHERE
	cse.idcliente = @idcliente
	AND cse.plan_codigo = @plan_codigo
	AND cse.idequipo = @idequipo
GO
