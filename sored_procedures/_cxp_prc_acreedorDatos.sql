USE db_comercial_final
GO
IF OBJECT_ID('_cxp_prc_acreedorDatos') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxp_prc_acreedorDatos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170104
-- Description:	Datos de acreedor para Factura de Gasto
-- =============================================
CREATE PROCEDURE [dbo].[_cxp_prc_acreedorDatos]
	 @codigo AS VARCHAR(30)
	,@idsucursal AS SMALLINT
	,@idmoneda AS TINYINT = 0
	,@fecha AS SMALLDATETIME = ''
AS

SET NOCOUNT ON
SET DATEFORMAT DMY

SELECT TOP 1
	 p.idproveedor
	,codacreedor = p.codigo
	,acreedor = p.nombre
	,p.rfc 
	,[proveedor_tipo] = p.tipo
	,p.telefono1 
	,[credito_dias] = pt.credito_plazo
	,[acreedor_saldo] = ISNULL(csa.saldo, 0)
	,[acreedor_limite] = ISNULL(pt.credito_limite, 0)
	,[acreedor_credito] = (ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))
	,[iva] = (
		CASE
			WHEN p.extranjero = 1 THEN 0
			ELSE
				(
					SELECT
						s.iva
					FROM
						ew_sys_sucursales AS s
					WHERE
						s.idsucursal = @idsucursal
				)
			END
	)
	,[combustible] = 0
	,[idmoneda] = @idmoneda
	,[tipocambio] = dbo.fn_ban_obtenerTC(@idmoneda, @fecha)
	,[acreedor_cuenta] = (
		CASE 
			WHEN p.tipo = 0 THEN
				CASE
					WHEN p.extranjero = 1 THEN '21090' + LTRIM(RTRIM(STR(@idsucursal))) + '000'
					ELSE '21080' + LTRIM(RTRIM(STR(@idsucursal))) + '000'
				END
			ELSE
				CASE
					WHEN p.extranjero = 1 THEN '21130' + LTRIM(RTRIM(STR(@idsucursal))) + '000'
					ELSE '21010' + LTRIM(RTRIM(STR(@idsucursal))) + '000'
				END
		END
	)
FROM 
	ew_proveedores AS p
	LEFT JOIN ew_proveedores_terminos AS pt
		ON pt.idproveedor = p.idproveedor
	LEFT JOIN ew_cxp_saldos_actual AS csa
		ON csa.idproveedor = p.idproveedor
		AND csa.idmoneda = @idmoneda
WHERE
	p.codigo = @codigo
GO
