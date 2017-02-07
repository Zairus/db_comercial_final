USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170131
-- Description:	Cargar toma de inventario
-- =============================================
ALTER PROCEDURE [dbo].[_xac_GDT2_cargardoc]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	id.transaccion
	,id.idsucursal
	,id.idalmacen
	,id.folio
	,id.fecha
	,id.idconcepto
	,id.tipo
	,id.filtrar
	,id.parametro
	,id.codigo1
	,id.codigo2
	
	,[ejecutar] = ''
	,[obtener] = 'Obtener Registros'

	,id.referencia

	,[estado] = oe.nombre
	,[codart] = ''

	,id.idtran
	,id.idr

	,id.idu
	,id.comentario
FROM
	ew_inv_documentos AS id
	LEFT JOIN ew_sys_transacciones As st
		ON st.idtran = id.idtran
	LEFT JOIN objetos AS o
		ON o.codigo = st.transaccion
	LEFT JOIN objetos_estados AS oe
		ON oe.objeto = o.objeto
		AND oe.idestado = st.idestado
WHERE
	id.idtran = @idtran

SELECT
	idm.consecutivo
	,[codarticulo] = a.codigo
	,idm.idarticulo
	,a.nombre
	,idm.congelar
	,idm.solicitado
	,idm.cantidad
	,[diferencia] = idm.cantidad - idm.solicitado
	,[serie] = a.series
	,[xdif2] = ''
	,idm.series
	,idm.comentario
	,idm.idr
	,idm.idtran
	,idm.idmov
	,[spa] = '.'
FROM 
	ew_inv_documentos_mov AS idm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = idm.idarticulo
WHERE
	idm.idtran = @idtran

SELECT 
	idr
	,objidtran
	,idtran2
	,consecutivo
	,fecha
	,tipo_nombre
	,folio
	,referencia
	,cuenta
	,cuenta_nombre
	,cargos
	,abonos
	,concepto
FROM
	contabilidad 
WHERE  
	idtran2 = @idtran 

SELECT
	b.fechahora
	, b.codigo
	, b.nombre
	, b.usuario_nombre
	, b.host
	, b.comentario
FROM 
	bitacora AS b
WHERE
	b.idtran = @idtran
ORDER BY 
	b.fechahora
GO
