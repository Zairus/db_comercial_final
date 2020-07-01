USE db_comercial_final
GO
IF OBJECT_ID('_cxp_prc_referenciaDatos') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxp_prc_referenciaDatos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100212
-- Description:	Datos de referencia para aplicación de gastos
-- =============================================
CREATE PROCEDURE [dbo].[_cxp_prc_referenciaDatos]
	@referencia_tipo AS TINYINT
	, @idtran AS INT
AS

SET NOCOUNT ON

IF @referencia_tipo = 1
BEGIN
	SELECT
		[referencia] = co.folio
		, [idtran2] = co.idtran
		, [idmov2] = co.idmov
		, [codigo] = p.codigo
		, [nombre] = p.nombre
		, [referencia_importe] = co.total
		, [referencia_cantidad] = ISNULL((
			SELECT 
				SUM(com.cantidad_autorizada) 
			FROM 
				ew_com_ordenes_mov AS com
			WHERE
				com.idtran = co.idtran
		), 0)
		, [referencia_criterio] = (
			CASE [dbo].[_sys_fnc_parametroTexto]('COM_CRITERIO_PRORRATEO')
				WHEN 'IMPORTE' THEN 0
				ELSE 1
			END
		)
	FROM
		ew_com_ordenes AS co
		LEFT JOIN ew_proveedores AS p
			ON p.idproveedor = co.idproveedor
	WHERE
		co.idtran = @idtran
END
	ELSE
BEGIN
	SELECT
		[referencia] = id.folio
		, [idtran2] = id.idtran
		, [idmov2] = id.idmov
		, [codigo] = alm.idalmacen
		, [nombre] = alm.nombre
		, [referencia_importe] = id.total
		, [referencia_cantidad] = ISNULL((
			SELECT 
				SUM(idm.cantidad) 
			FROM 
				ew_inv_documentos_mov AS idm
			WHERE
				idm.idtran = id.idtran
		), 0)
		, [referencia_criterio] = (
			CASE [dbo].[_sys_fnc_parametroTexto]('COM_CRITERIO_PRORRATEO')
				WHEN 'IMPORTE' THEN 0
				ELSE 1
			END
		)
	FROM
		ew_inv_documentos AS id
		LEFT JOIN ew_inv_almacenes AS alm
			ON alm.idalmacen = id.idalmacen
	WHERE
		id.idtran = @idtran
END
GO