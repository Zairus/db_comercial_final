USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_ordenProcesarImpuestos') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_ordenProcesarImpuestos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180307
-- Description:	Procesar impuestos por partida
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_ordenProcesarImpuestos]
	@idtran AS INT
AS

SET NOCOUNT ON

IF EXISTS (SELECT * FROM ew_ven_ordenes_mov AS vom WHERE (vom.idmov IS NULL OR vom.idmov = 0) AND vom.idtran = @idtran)
BEGIN
	EXEC _sys_prc_generarIdmovPorIdtran @idtran, 'ew_ven_ordenes_mov'
END

IF EXISTS (SELECT * FROM ew_ven_ordenes_mov AS vom WHERE (vom.idmov IS NULL OR vom.idmov = 0) AND vom.idtran = @idtran)
BEGIN
	RAISERROR('Error: Existen registros con identificador en 0.', 16, 1)
	RETURN
END

DELETE FROM ew_ct_impuestos_transacciones
WHERE
	idtran = @idtran

INSERT INTO ew_ct_impuestos_transacciones (
	idtran
	,idmov
	,idtasa
	,base
	,importe
)
SELECT
	[idtran] = vom.idtran
	,[idmov] = vom.idmov
	,[idtasa] = ait.idtasa
	,[base] = CONVERT(DECIMAL(18,2), (vom.importe * cit.base_proporcion))
	,[importe] = CONVERT(DECIMAL(18,2), (CONVERT(DECIMAL(18,2), (vom.importe * cit.base_proporcion)) * cit.tasa))
FROM
	ew_ven_ordenes_mov AS vom
	LEFT JOIN ew_ven_ordenes AS vo
		ON vo.idtran = vom.idtran
	LEFT JOIN ew_articulos_impuestos_tasas AS ait
		ON ait.idarticulo = vom.idarticulo
		AND (
			ait.idzona = [dbo].[_ct_fnc_idzonaFiscal](vo.idsucursal)
			OR ait.idzona = 0
		)
	LEFT JOIN ew_cat_impuestos_tasas AS cit
		ON cit.idtasa = ait.idtasa
WHERE
	vom.idmov NOT IN (
		SELECT citrn.idmov 
		FROM 
			ew_ct_impuestos_transacciones AS citrn 
		WHERE 
			citrn.idtran = @idtran
	)
	AND vom.idtran = @idtran
	AND ait.idtasa IS NOT NULL

UPDATE vom1 SET
	vom1.idimpuesto1 = vom2.idimpuesto1
	,vom1.idimpuesto2 = vom2.idimpuesto2
	,vom1.idimpuesto1_ret = vom2.idimpuesto1_ret
	,vom1.idimpuesto2_ret = vom2.idimpuesto2_ret

	,vom1.impuesto1 = vom2.impuesto1
	,vom1.impuesto2 = vom2.impuesto2
	,vom1.impuesto1_ret = vom2.impuesto1_ret
	,vom1.impuesto2_ret = vom2.impuesto2_ret
FROM
	ew_ven_ordenes_mov AS vom1
	LEFT JOIN (
		SELECT
			vom.idmov

			,[idimpuesto1] = MAX(ISNULL((CASE WHEN ci.grupo = 'IVA' AND cit.tipo = 1 THEN cit.idimpuesto ELSE 0 END), 0))
			,[idimpuesto2] = MAX(ISNULL((CASE WHEN ci.grupo = 'IEPS' AND cit.tipo = 1 THEN cit.idimpuesto ELSE 0 END), 0))
			,[idimpuesto1_ret] = MAX(ISNULL((CASE WHEN ci.grupo = 'IVA' AND cit.tipo = 2 THEN cit.idimpuesto ELSE 0 END), 0))
			,[idimpuesto2_ret] = MAX(ISNULL((CASE WHEN ci.grupo = 'ISR' AND cit.tipo = 2 THEN cit.idimpuesto ELSE 0 END), 0))

			,[impuesto1] = SUM(ISNULL((CASE WHEN ci.grupo = 'IVA' AND cit.tipo = 1 THEN citr.importe ELSE 0 END), 0))
			,[impuesto2] = SUM(ISNULL((CASE WHEN ci.grupo = 'IEPS' AND cit.tipo = 1 THEN citr.importe ELSE 0 END), 0))
			,[impuesto1_ret] = SUM(ISNULL((CASE WHEN ci.grupo = 'IVA' AND cit.tipo = 2 THEN citr.importe ELSE 0 END), 0))
			,[impuesto2_ret] = SUM(ISNULL((CASE WHEN ci.grupo = 'ISR' AND cit.tipo = 2 THEN citr.importe ELSE 0 END), 0))
		FROM
			ew_ven_ordenes_mov AS vom
			LEFT JOIN ew_ct_impuestos_transacciones AS citr
				ON citr.idtran = vom.idtran
				AND citr.idmov = vom.idmov
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = citr.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = cit.idimpuesto
		WHERE
			vom.idtran = @idtran
		GROUP BY
			vom.idmov
	) AS vom2
		ON vom2.idmov = vom1.idmov
WHERE
	vom1.idtran = @idtran

UPDATE vo SET
	vo.impuesto1 = ISNULL((SELECT SUM(vom.impuesto1) FROM ew_ven_ordenes_mov AS vom WHERE vom.idtran = vo.idtran), 0)
	,vo.impuesto2 = ISNULL((SELECT SUM(vom.impuesto2) FROM ew_ven_ordenes_mov AS vom WHERE vom.idtran = vo.idtran), 0)
	,vo.impuesto1_ret = ISNULL((SELECT SUM(vom.impuesto1_ret) FROM ew_ven_ordenes_mov AS vom WHERE vom.idtran = vo.idtran), 0)
	,vo.impuesto2_ret = ISNULL((SELECT SUM(vom.impuesto2_ret) FROM ew_ven_ordenes_mov AS vom WHERE vom.idtran = vo.idtran), 0)
FROM
	ew_ven_ordenes AS vo
WHERE
	vo.idtran = @idtran
GO
