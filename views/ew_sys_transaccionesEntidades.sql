USE db_comercial_final
GO
CREATE VIEW [dbo].[ew_sys_transaccionesEntidades]
AS
SELECT
	 st.idtran
	,st.transaccion
	,st.idsucursal
	,st.folio
	,[entidad] = ISNULL((
		CASE 
			WHEN st.transaccion LIKE 'GD%' THEN
				(
					SELECT TOP 1
						alm.nombre
					FROM
						ew_inv_transacciones_mov AS it
						LEFT JOIN ew_inv_almacenes AS alm
							ON alm.idalmacen = it.idalmacen
					WHERE
						it.idtran = st.idtran
				)
			WHEN st.transaccion LIKE 'EOR%' THEN 
				(
					SELECT
						c.nombre
					FROM
						ew_ven_ordenes AS vo
						LEFT JOIN ew_clientes AS c
							ON c.idcliente = vo.idcliente
					WHERE
						vo.idtran = st.idtran
				)
			WHEN st.transaccion LIKE 'EFA%' OR st.transaccion LIKE 'EDE%' THEN 
				(
					SELECT
						c.nombre
					FROM
						ew_ven_transacciones AS vt
						LEFT JOIN ew_clientes AS c
							ON c.idcliente = vt.idcliente
					WHERE
						vt.idtran = st.idtran
				)
			WHEN st.transaccion IN ('BDC2', 'FDC1', 'FDC2', 'FDA1', 'FDA2') THEN 
				(
					SELECT
						c.nombre
					FROM
						ew_cxc_transacciones AS ct
						LEFT JOIN ew_clientes AS c
							ON c.idcliente = ct.idcliente
					WHERE
						ct.idtran = st.idtran
				)
			WHEN st.transaccion LIKE 'COR%' THEN 
				(
					SELECT
						p.nombre
					FROM
						ew_com_ordenes AS co
						LEFT JOIN ew_proveedores AS p
							ON p.idproveedor = co.idproveedor
					WHERE
						co.idtran = st.idtran
				)
			WHEN st.transaccion LIKE 'CFA%' OR st.transaccion LIKE 'CDE%' THEN 
				(
					SELECT
						p.nombre
					FROM
						ew_com_transacciones AS ct
						LEFT JOIN ew_proveedores AS p
							ON p.idproveedor = ct.idproveedor
					WHERE
						ct.idtran = st.idtran
				)
			WHEN st.transaccion IN ('AFA1', 'AFA2', 'AFA3', 'DPR1', 'DDC1', 'DDC2', 'DDA1', 'DDA2', 'DDA3', 'DDA4' ) THEN 
				(
					SELECT
						p.nombre
					FROM
						ew_cxp_transacciones AS ct
						LEFT JOIN ew_proveedores AS p
							ON p.idproveedor = ct.idproveedor
					WHERE
						ct.idtran = st.idtran
				)
			WHEN st.transaccion IN ('BDC1', 'BOR1', 'BOR2', 'BDA1', 'BDA2', 'BDA3', 'BDA4', 'BDT1' ) THEN 
				(
					SELECT TOP 1
						bb.nombre + '-' + bc.no_cuenta
					FROM
						ew_ban_transacciones AS bt
						LEFT JOIN ew_ban_cuentas AS bc
							ON bc.idcuenta = bt.idcuenta
						LEFT JOIN ew_ban_bancos AS bb
							ON bb.idbanco = bc.idbanco
					WHERE
						bt.idtran = st.idtran
				)
			WHEN st.transaccion IN ('CRE1') THEN 'Recepción en Almacenes'
			WHEN st.transaccion IN ('APO1') THEN 'Póliza Contable'
			WHEN st.transaccion IN ('') THEN ''
		END
	), '-No identificado-')
	,st.fecha
FROM
	ew_sys_transacciones AS st
GO
