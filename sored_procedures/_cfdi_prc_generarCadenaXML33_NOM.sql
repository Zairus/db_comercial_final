USE db_comercial_final
GO
IF OBJECT_ID('_cfdi_prc_generarCadenaXML33_NOM') IS NOT NULL
BEGIN
	DROP PROCEDURE _cfdi_prc_generarCadenaXML33_NOM
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180430
-- Description:	Generar Cadena XML CFDi 3.3 Nomina
-- =============================================
CREATE PROCEDURE [dbo].[_cfdi_prc_generarCadenaXML33_NOM]
	@idtran AS INT
	, @comprobante AS VARCHAR(MAX) OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@xml AS XML

DECLARE
	@cfd_fecha AS DATETIME = GETDATE()
	, @namespace_text AS VARCHAR(MAX) = ''
	, @schema_location AS VARCHAR(MAX) = ''

CREATE TABLE #_tmp_ns (
	codigo VARCHAR(50)
)

INSERT INTO #_tmp_ns (codigo) VALUES ('xsi'), ('cfdi'), ('nomina12')

SELECT
	@cfd_fecha = cc.cfd_fecha
FROM
	ew_cfd_comprobantes AS cc
WHERE
	cc.idtran = @idtran

SELECT
	@schema_location = @schema_location + xmlns.uri + ' ' + xmlns.xsd + ' '
FROM
	db_comercial.dbo.evoluware_cfd_sat_xmlnamespace AS xmlns
WHERE
	(LEN(xmlns.uri) > 0 AND LEN(xmlns.xsd) > 0)
	AND xmlns.codigo IN (SELECT tns.codigo FROM #_tmp_ns AS tns)

SELECT @schema_location = REPLACE(@schema_location, '  ', ' ')
SELECT @schema_location = LTRIM(RTRIM(@schema_location))

;WITH XMLNAMESPACES ( 
	'http://www.sat.gob.mx/cfd/3' AS cfdi
	, 'http://www.sat.gob.mx/nomina12 http://www.sat.gob.mx/sitio_internet/cfd/nomina/nomina12.xsd' AS nomina12
	, 'http://www.w3.org/2001/XMLSchema-instance' AS xsi 
)
SELECT
	@xml = g.XML
FROM (
	SELECT
		@schema_location AS '@xsi:schemaLocation'
		, '3.3' AS '@Version'
		, cc.cfd_serie AS '@Serie'
		, CONVERT(VARCHAR(15), cc.cfd_folio) AS '@Folio'
		, CONVERT(VARCHAR(19), @cfd_fecha, 126) AS '@Fecha'
		, cer.noCertificado AS '@NoCertificado'
		, 'N' AS '@TipoDeComprobante'
		, ISNULL(s.codpostal, '83000') AS '@LugarExpedicion'
		, cc.cfd_Moneda AS '@Moneda'
		, dbo._sys_fnc_decimales(cc.cfd_TipoCambio, (CASE WHEN cc.cfd_Moneda = 'MXN' THEN 0 ELSE 6 END)) AS '@TipoCambio'
		, dbo._sys_fnc_decimales(cc.cfd_subtotal, csm.decimales) AS '@SubTotal'
		
		, (
			SELECT
				SUM(
					CONVERT(DECIMAL(18,2), ntm.importe_gravado)
					+ CONVERT(DECIMAL(18,2), ntm.importe_exento)
				)
			FROM
				ew_nom_transacciones_mov AS ntm
			WHERE
				ntm.idtran = cc.idtran
		) AS '@Total'

		, (
			SELECT
				CONVERT(
					DECIMAL(18,2)
					, SUM(ABS(
						CONVERT(DECIMAL(18,2), ntm.importe_gravado) 
						+ CONVERT(DECIMAL(18,2), ntm.importe_exento)
					))
				)
			FROM
				ew_nom_transacciones_mov AS ntm
				LEFT JOIN ew_nom_conceptos AS nc
					ON nc.idconcepto = ntm.idconcepto
				LEFT JOIN ew_nom_conceptos_tipos AS nct
					ON nct.idtipo = nc.idtipo
			WHERE
				nc.tipo = 1
				AND ntm.idtran = cc.idtran
		) AS '@Descuento'

		, (CASE WHEN cc.cfd_tipoDeComprobante NOT IN ('P') THEN cc.cfd_metodoDePago ELSE NULL END) AS '@FormaPago'
		, (CASE WHEN cc.cfd_tipoDeComprobante NOT IN ('P') THEN cc.cfd_formaDePago ELSE NULL END) AS '@MetodoPago'
		, dbEVOLUWARE.dbo.base64_read(cer.certificado) AS '@Certificado'

		--Emisor
		,(
			SELECT
				cc.rfc_emisor AS '@Rfc'
				, emisor_rfc.cfd_nombre AS '@Nombre'
				, [dbo].[_sys_fnc_parametroTexto]('CFDI_REGIMEN') AS '@RegimenFiscal'
			FOR XML PATH('cfdi:Emisor'), TYPE
		) AS '*'

		--Receptor
		,(
			SELECT
				cc.rfc_receptor AS '@Rfc'
				,(
					CASE 
						WHEN LEN(receptor_rfc.cfd_nombre) = 0 THEN NULL 
						ELSE receptor_rfc.cfd_nombre 
					END
				) AS '@Nombre'
				,NULL AS '@ResidenciaFiscal' --ISNULL(csat_p.c_pais, 'MEX')
				,'P01' AS '@UsoCFDI'
			FOR XML PATH('cfdi:Receptor'), TYPE
		) AS '*'
		
		--Conceptos
		,(
			SELECT
				'84111505' AS '@ClaveProdServ'
				, NULL AS '@NoIdentificacion'
				, 1 AS '@Cantidad'
				, 'ACT' AS '@ClaveUnidad'
				, NULL AS '@Unidad'
				, 'Pago de nómina' AS '@Descripcion'
				, dbo._sys_fnc_decimales(cc.cfd_subtotal, csm.decimales) AS '@ValorUnitario'
				, dbo._sys_fnc_decimales(cc.cfd_subtotal, csm.decimales) AS '@Importe'
				, (
					SELECT
						CONVERT(
							DECIMAL(18,2)
							, SUM(ABS(
								CONVERT(DECIMAL(18,2), ntm.importe_gravado) 
								+ CONVERT(DECIMAL(18,2), ntm.importe_exento)
							))
						)
					FROM
						ew_nom_transacciones_mov AS ntm
						LEFT JOIN ew_nom_conceptos AS nc
							ON nc.idconcepto = ntm.idconcepto
						LEFT JOIN ew_nom_conceptos_tipos AS nct
							ON nct.idtipo = nc.idtipo
					WHERE
						nc.tipo = 1
						AND ntm.idtran = cc.idtran
				) AS '@Descuento'
			FOR XML PATH('cfdi:Concepto'), TYPE
		) AS 'cfdi:Conceptos'

		--Complemento
		,(
			SELECT
				(
					SELECT
						'1.2' AS '@Version'
						, (
							dbo._sys_fnc_rellenar(YEAR(nt.fecha_inicial), 4, '0')
							+ '-'
							+ dbo._sys_fnc_rellenar(MONTH(nt.fecha_inicial), 2, '0')
							+ '-'
							+ dbo._sys_fnc_rellenar(DAY(nt.fecha_inicial), 2, '0')
						) AS '@FechaInicialPago'
						, (
							dbo._sys_fnc_rellenar(YEAR(nt.fecha_final), 4, '0')
							+ '-'
							+ dbo._sys_fnc_rellenar(MONTH(nt.fecha_final), 2, '0')
							+ '-'
							+ dbo._sys_fnc_rellenar(DAY(nt.fecha_final), 2, '0')
						) AS '@FechaFinalPago'
						, (
							dbo._sys_fnc_rellenar(YEAR(nt.fecha), 4, '0')
							+ '-'
							+ dbo._sys_fnc_rellenar(MONTH(nt.fecha), 2, '0')
							+ '-'
							+ dbo._sys_fnc_rellenar(DAY(nt.fecha), 2, '0')
						) AS '@FechaPago'
						, DATEDIFF(DAY, nt.fecha_inicial, nt.fecha_final) AS '@NumDiasPagados'
						, 'O' AS '@TipoNomina'
						, ISNULL((
							SELECT
								CONVERT(
									DECIMAL(18,2)
									, SUM(ABS(
										CONVERT(DECIMAL(18,2), ntm.importe_gravado) 
										+ CONVERT(DECIMAL(18,2), ntm.importe_exento)
									))
								)
							FROM
								ew_nom_transacciones_mov AS ntm
								LEFT JOIN ew_nom_conceptos AS nc
									ON nc.idconcepto = ntm.idconcepto
								LEFT JOIN ew_nom_conceptos_tipos AS nct
									ON nct.idtipo = nc.idtipo
							WHERE
								nc.tipo = 0
								AND nct.clave IN ('038')
								AND ntm.idtran = cc.idtran
						), 0) AS '@TotalOtrosPagos'
						, ISNULL((
							SELECT
								CONVERT(
									DECIMAL(18,2)
									, SUM(ABS(
										CONVERT(DECIMAL(18,2), ntm.importe_gravado) 
										+ CONVERT(DECIMAL(18,2), ntm.importe_exento)
									))
								)
							FROM
								ew_nom_transacciones_mov AS ntm
								LEFT JOIN ew_nom_conceptos AS nc
									ON nc.idconcepto = ntm.idconcepto
								LEFT JOIN ew_nom_conceptos_tipos AS nct
									ON nct.idtipo = nc.idtipo
							WHERE
								nc.tipo = 0
								AND nct.clave NOT IN ('038')
								AND ntm.idtran = cc.idtran
						), 0) AS '@TotalPercepciones'
						, (
							SELECT
								CONVERT(
									DECIMAL(18,2)
									, SUM(ABS(
										CONVERT(DECIMAL(18,2), ntm.importe_gravado) 
										+ CONVERT(DECIMAL(18,2), ntm.importe_exento)
									))
								)
							FROM
								ew_nom_transacciones_mov AS ntm
								LEFT JOIN ew_nom_conceptos AS nc
									ON nc.idconcepto = ntm.idconcepto
								LEFT JOIN ew_nom_conceptos_tipos AS nct
									ON nct.idtipo = nc.idtipo
							WHERE
								nc.tipo = 1
								AND ntm.idtran = cc.idtran
						) AS '@TotalDeducciones'

						--Emisor
						,(
							SELECT
								ISNULL(dbo.fn_sys_parametro('REGISTRO_PATRONAL'),'') AS '@RegistroPatronal'
								, cc.rfc_emisor AS '@RfcPatronOrigen'
								, (CASE WHEN dbo.fn_sys_parametro('CURP') = '' THEN NULL ELSE dbo.fn_sys_parametro('CURP') END) AS '@Curp'
							FOR XML PATH('nomina12:Emisor'), TYPE
						) AS '*'

						--Receptor
						,(
							SELECT
								'P' + LTRIM(RTRIM(STR( ((DATEDIFF(DAY, ne.fecha_alta, nt.fecha_final) + 1) / 7) ))) + 'W' AS '@Antigüedad'
								, 'SON' AS '@ClaveEntFed'
								, ne.clabe AS '@CuentaBancaria'
								, ne.curp AS '@Curp'
								, nd.codigo AS '@Departamento'
								, (
									dbo._sys_fnc_rellenar(YEAR(ne.fecha_alta), 4, '0')
									+ '-'
									+ dbo._sys_fnc_rellenar(MONTH(ne.fecha_alta), 2, '0')
									+ '-'
									+ dbo._sys_fnc_rellenar(DAY(ne.fecha_alta), 2, '0')
								) AS '@FechaInicioRelLaboral'
								, ne.num_emp AS '@NumEmpleado'
								, REPLACE(REPLACE(ne.numero_ss, '-', ''), ' ', '') AS '@NumSeguridadSocial'
								, '04' AS '@PeriodicidadPago'
								, (
									CASE 
										WHEN LEN(ne.clabe) =  18 THEN NULL
										ELSE RIGHT(sbb.c_banco, 3)
									END
								) AS '@Banco'
								, ne.puesto AS '@Puesto'
								, LTRIM(RTRIM(STR(ne.idriesgo))) AS '@RiesgoPuesto'
								, CONVERT(DECIMAL(18,2), ne.sueldo_diario_integrado) AS '@SalarioDiarioIntegrado'
								, 'No' AS '@Sindicalizado'
								, tc.codigo AS '@TipoContrato'
								, tj.codigo AS '@TipoJornada'
								, tr.codigo AS '@TipoRegimen'
							FOR XML PATH('nomina12:Receptor'), TYPE
						) AS '*'

						--Percepciones
						,(
							SELECT
								(
									SELECT
										CONVERT(DECIMAL(18,2), SUM(ntm.importe_gravado))
										+ CONVERT(DECIMAL(18,2), SUM(ntm.importe_exento))
									FROM
										ew_nom_transacciones_mov AS ntm
										LEFT JOIN ew_nom_conceptos AS nc
											ON nc.idconcepto = ntm.idconcepto
										LEFT JOIN ew_nom_conceptos_tipos AS nct
											ON nct.idtipo = nc.idtipo
									WHERE
										nc.tipo = 0
										AND nct.clave NOT IN ('022', '023', '025', '039', '044', '017', '038')
										AND ntm.idtran = cc.idtran
								) AS '@TotalSueldos'
								, (
									SELECT
										CONVERT(DECIMAL(18,2), SUM(ntm.importe_gravado))
									FROM
										ew_nom_transacciones_mov AS ntm
										LEFT JOIN ew_nom_conceptos AS nc
											ON nc.idconcepto = ntm.idconcepto
										LEFT JOIN ew_nom_conceptos_tipos AS nct
											ON nct.idtipo = nc.idtipo
									WHERE
										nc.tipo = 0
										AND nct.clave NOT IN ('022', '023', '039', '044', '017')
										AND ntm.idtran = cc.idtran
								) AS '@TotalGravado'
								, (
									SELECT
										CONVERT(DECIMAL(18,2), SUM(ntm.importe_gravado))
										+ CONVERT(DECIMAL(18,2), SUM(ntm.importe_exento))
									FROM
										ew_nom_transacciones_mov AS ntm
										LEFT JOIN ew_nom_conceptos AS nc
											ON nc.idconcepto = ntm.idconcepto
										LEFT JOIN ew_nom_conceptos_tipos AS nct
											ON nct.idtipo = nc.idtipo
									WHERE
										nc.tipo = 0
										AND nct.clave IN ('025')
										AND ntm.idtran = cc.idtran
								) AS '@TotalSeparacionIndemnizacion'
								, (
									SELECT
										CONVERT(DECIMAL(18,2), SUM(ntm.importe_exento))
									FROM
										ew_nom_transacciones_mov AS ntm
										LEFT JOIN ew_nom_conceptos AS nc
											ON nc.idconcepto = ntm.idconcepto
										LEFT JOIN ew_nom_conceptos_tipos AS nct
											ON nct.idtipo = nc.idtipo
									WHERE
										nc.tipo = 0
										AND nct.clave NOT IN ('022', '023', '039', '044', '017', '038')
										AND ntm.idtran = cc.idtran
								) AS '@TotalExento'
								, (
									SELECT
										nct.clave AS '@TipoPercepcion'
										,nct.clave AS '@Clave'
										,nc.nombre AS '@Concepto'
										,CONVERT(DECIMAL(18,2), ntm.importe_gravado) AS '@ImporteGravado'
										,CONVERT(DECIMAL(18,2), ntm.importe_exento) AS '@ImporteExento'
										,(
											SELECT
												1 AS '@Dias'
												,'01' AS '@TipoHoras'
												,1 AS '@HorasExtra'
												,(
													CONVERT(DECIMAL(18,2), ntm.importe_gravado) 
													+CONVERT(DECIMAL(18,2), ntm.importe_exento)
												) AS '@ImportePagado'
											WHERE
												nct.clave IN ('019')
											FOR XML PATH('nomina12:HorasExtra'), TYPE
										)
									FROM 
										ew_nom_transacciones_mov AS ntm
										LEFT JOIN ew_nom_conceptos AS nc
											ON nc.idconcepto = ntm.idconcepto
										LEFT JOIN ew_nom_conceptos_tipos AS nct
											ON nct.idtipo = nc.idtipo
									WHERE
										nc.tipo = 0
										AND nct.clave NOT IN ('022', '023', '039', '044', '017', '038')
										AND ntm.idtran = cc.idtran
									FOR XML PATH('nomina12:Percepcion'), TYPE
								) AS '*'
								, (
									SELECT
										(
											CONVERT(DECIMAL(18,2), ntm.importe_gravado) 
											+ CONVERT(DECIMAL(18,2), ntm.importe_exento)
										) AS '@TotalPagado'
										, CONVERT(INT, ROUND((DATEDIFF(MONTH, ne.fecha_alta, nt.fecha) / 12.0), 0)) AS '@NumAñosServicio'
										, CONVERT(DECIMAL(18,2), (ne.sueldo_diario_integrado * 30.4)) AS '@UltimoSueldoMensOrd'
										, 0 AS '@IngresoAcumulable'
										, (
											CONVERT(DECIMAL(18,2), ntm.importe_gravado) 
											+CONVERT(DECIMAL(18,2), ntm.importe_exento)
										) AS '@IngresoNoAcumulable'
									FROM
										ew_nom_transacciones_mov AS ntm
										LEFT JOIN ew_nom_conceptos AS nc
											ON nc.idconcepto = ntm.idconcepto
										LEFT JOIN ew_nom_conceptos_tipos AS nct
											ON nct.idtipo = nc.idtipo
									WHERE
										nct.clave IN ('025')
										AND ntm.idtran = cc.idtran
									FOR XML PATH('nomina12:SeparacionIndemnizacion'), TYPE
								) AS '*'
							FOR XML PATH('nomina12:Percepciones'), TYPE
						) AS '*'

						--Deducciones
						,(
							SELECT
								(
									SELECT
										CONVERT(
											DECIMAL(18,2)
											, SUM(ABS(
												CONVERT(DECIMAL(18,2), ntm.importe_gravado) 
												+ CONVERT(DECIMAL(18,2), ntm.importe_exento)
											))
										)
									FROM
										ew_nom_transacciones_mov AS ntm
										LEFT JOIN ew_nom_conceptos AS nc
											ON nc.idconcepto = ntm.idconcepto
										LEFT JOIN ew_nom_conceptos_tipos AS nct
											ON nct.idtipo = nc.idtipo
									WHERE
										nc.tipo = 1
										AND nct.clave NOT IN ('002')
										AND ntm.idtran = cc.idtran
								) AS '@TotalOtrasDeducciones'
								, (
									SELECT
										CONVERT(
											DECIMAL(18,2)
											, SUM(ABS(
												CONVERT(DECIMAL(18,2), ntm.importe_gravado) 
												+ CONVERT(DECIMAL(18,2), ntm.importe_exento)
											))
										)
									FROM
										ew_nom_transacciones_mov AS ntm
										LEFT JOIN ew_nom_conceptos AS nc
											ON nc.idconcepto = ntm.idconcepto
										LEFT JOIN ew_nom_conceptos_tipos AS nct
											ON nct.idtipo = nc.idtipo
									WHERE
										nc.tipo = 1
										AND nct.clave IN ('002')
										AND ntm.idtran = cc.idtran
								) AS '@TotalImpuestosRetenidos'
								, (
									SELECT
										nct.clave AS '@TipoDeduccion'
										, nct.clave AS '@Clave'
										, nc.nombre AS '@Concepto'
										, ABS(
											CONVERT(DECIMAL(18,2), ntm.importe_gravado)
											+ CONVERT(DECIMAL(18,2), ntm.importe_exento)
										) AS '@Importe'
									FROM 
										ew_nom_transacciones_mov AS ntm
										LEFT JOIN ew_nom_conceptos AS nc
											ON nc.idconcepto = ntm.idconcepto
										LEFT JOIN ew_nom_conceptos_tipos AS nct
											ON nct.idtipo = nc.idtipo
									WHERE
										nc.tipo = 1
										AND ntm.idtran = cc.idtran
									FOR XML PATH('nomina12:Deduccion'), TYPE
								)
							WHERE
								(
									SELECT COUNT(*)
									FROM 
										ew_nom_transacciones_mov AS ntm
										LEFT JOIN ew_nom_conceptos AS nc
											ON nc.idconcepto = ntm.idconcepto
										LEFT JOIN ew_nom_conceptos_tipos AS nct
											ON nct.idtipo = nc.idtipo
									WHERE
										nc.tipo = 1
										AND ntm.idtran = cc.idtran
								) > 0
							FOR XML PATH('nomina12:Deducciones'), TYPE
						) AS '*'

						--OtrosPagos
						,(
							SELECT
								(
									SELECT
										'002' AS '@TipoOtroPago'
										, '002' AS '@Clave'
										, 'Subsidio al empleo' AS '@Concepto'
										, CONVERT(DECIMAL(18,2), ntm.importe_exento) AS '@Importe'
										, (
											SELECT
												CONVERT(DECIMAL(18,2), ntm.importe_exento) AS '@SubsidioCausado'
											FOR XML PATH('nomina12:SubsidioAlEmpleo'), TYPE
										)
									FOR XML PATH('nomina12:OtroPago'), TYPE
								)
							FROM
								ew_nom_transacciones_mov AS ntm
								LEFT JOIN ew_nom_conceptos AS nc
									ON nc.idconcepto = ntm.idconcepto
								LEFT JOIN ew_nom_conceptos_tipos AS nct
									ON nct.idtipo = nc.idtipo
							WHERE
								nct.clave IN ('038')
								AND ntm.idtran = cc.idtran
							FOR XML PATH('nomina12:OtrosPagos'), TYPE
						) AS '*'
						
					FOR XML PATH('nomina12:Nomina'), TYPE
				)
			FOR XML PATH ('cfdi:Complemento'), TYPE
		) AS '*'
	FROM
		ew_cfd_comprobantes AS cc
		LEFT JOIN ew_sys_sucursales AS s
			ON s.idsucursal = cc.idsucursal
		LEFT JOIN ew_sys_ciudades AS cd
			ON cd.idciudad = s.idciudad

		LEFT JOIN ew_cfd_rfc AS emisor_rfc
			ON emisor_rfc.cfd_rfc = cc.rfc_emisor
		LEFT JOIN ew_cfd_rfc AS receptor_rfc
			ON receptor_rfc.cfd_rfc = cc.rfc_receptor
		
		LEFT JOIN ew_nom_transacciones AS nt
			ON nt.idtran = cc.idtran
		LEFT JOIN ew_nom_empleados AS ne
			ON ne.idempleado = nt.idempleado
		LEFT JOIN ew_nom_departamentos AS nd
			ON nd.idr = ne.iddepto
		LEFT JOIN ew_ban_bancos AS bb
			ON bb.idbanco = ne.idbanco
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_bancos AS sbb
			ON sbb.rfc = bb.rfc
		LEFT JOIN ew_nom_tipos_contrato AS tc
			ON tc.idtipocontrato = ne.idtipocontrato
		LEFT JOIN ew_nom_tipos_jornada AS tj
			ON tj.idtipojornada = ne.idtipojornada
		LEFT JOIN ew_nom_tipos_regimen AS tr
			ON tr.idtiporegimen = ne.idtiporegimen
		LEFT JOIN ew_nom_periodicidad_pago AS pp
			ON pp.idperiodicidad = ne.idperiodicidad
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_pais AS csat_p 
			ON csat_p.descripcion = 'México'
		LEFT JOIN objetos AS o
			ON o.codigo = nt.transaccion
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_tiporelacion_objetos AS csto
			ON csto.objeto = o.objeto
			
		LEFT JOIN ew_cfd_folios AS f
			ON f.idfolio = cc.idfolio
		LEFT JOIN ew_cfd_certificados AS cer
			ON cer.idcertificado = f.idcertificado
		LEFT JOIN db_comercial.dbo.evoluware_cfd_sat_monedas AS csm
			ON csm.c_moneda = cc.cfd_Moneda
	WHERE
		cc.idtran = @idtran
	FOR XML PATH('cfdi:Comprobante'), TYPE
) AS g(XML)

SELECT @comprobante = '<?xml version="1.0" encoding="utf-8"?>' + CONVERT(VARCHAR(MAX), @xml)

SELECT
	@comprobante = (
		REPLACE(REPLACE(@comprobante, ' xmlns:' + xmlns.codigo + '="' + xmlns.uri + '"', ''), ' xmlns:' + xmlns.codigo + '="' + xmlns.uri + ' ' + xmlns.xsd + '"', '')
	)
	,@namespace_text = (
		@namespace_text 
		+ (
			CASE 
				WHEN xmlns.codigo IN (SELECT tns.codigo FROM #_tmp_ns AS tns) THEN 
					' xmlns:' + xmlns.codigo + '="' + xmlns.uri + '"' 
				ELSE 
					'' 
			END
		)
	)
FROM
	db_comercial.dbo.evoluware_cfd_sat_xmlnamespace AS xmlns
	
SELECT @namespace_text = '<cfdi:Comprobante' + @namespace_text

SELECT @comprobante = REPLACE(@comprobante, '<cfdi:Comprobante', @namespace_text)

DROP TABLE #_tmp_ns
GO
