USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_ordenProcesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_ordenProcesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 200912
-- Description:	Procesar orden de venta
-- Modificado Por: Tere Valdez 20091217 	
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_ordenProcesar]
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@error_mensaje AS VARCHAR(500)

SELECT
	@error_mensaje = (
		'Error: No se puede vender el artículo '
		+ '[' + a.codigo + '] '
		+ a.nombre
		+ ', en ' + CONVERT(VARCHAR(25), CONVERT(DECIMAL(18,2), vom.importe / vom.cantidad_autorizada))
		+ ', por debajo del costo. ' 
	)
FROM
	ew_ven_ordenes_mov AS vom
	LEFT JOIN ew_ven_ordenes AS vo
		ON vo.idtran = vom.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vom.idarticulo

	LEFT JOIN ew_articulos_sucursales AS sa
		ON sa.idsucursal = vo.idsucursal
		AND sa.idarticulo = vom.idarticulo
WHERE
	vom.idtran = @idtran
	AND sa.bajo_costo = 0
	AND a.inventariable = 1
	AND vom.cantidad_autorizada > 0
	AND (
		(
			SELECT COUNT(*) 
			FROM 
				ew_articulos_insumos AS ai
			WHERE
				ai.idarticulo_superior IN (
					SELECT vom1.idarticulo 
					FROM 
						ew_ven_ordenes_mov AS vom1
					WHERE
						vom1.idtran = @idtran
				)
		) = 0
	)
	AND (
		(vom.importe / vom.cantidad_autorizada)
		< [dbo].[_ven_fnc_articuloPrecioMinimoPorSucursal](sa.idarticulo, sa.idsucursal, sa.costo_base)
	)

IF @error_mensaje IS NOT NULL
BEGIN
	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END

EXEC [dbo].[_ven_prc_existenciaComprometer]

EXEC [dbo].[_ven_prc_ordenValidar] @idtran, @idu

EXEC [dbo].[_sys_prc_genera_consecutivo] @idtran, ''

EXEC [dbo].[_ven_prc_ordenProcesarImpuestos] @idtran
GO
