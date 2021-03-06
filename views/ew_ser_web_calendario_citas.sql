USE db_comercial_final
GO
IF OBJECT_ID('ew_ser_web_calendario_citas') IS NOT NULL
BEGIN
	DROP VIEW ew_ser_web_calendario_citas
END
GO
CREATE VIEW [dbo].[ew_ser_web_calendario_citas]
AS
SELECT
	[TaskID] = sc.idevento
	, [OwnerID] = ISNULL(f.idr, 2)
	, [Title] = sc.referencia
	, [Cliente] = ISNULL(c.nombre, '-No Especificado-')
	, [ClienteCodigo] = ISNULL(c.codigo, '')
	, [Description] = sc.comentario
	, [StartTimezone] = NULL
	, [Start] = sc.fecha_inicial
	, [End] = sc.fecha_final
	, [EndTimezone] = NULL
	, [RecurrenceRule] = NULL
	, [RecurrenceID]= NULL
	, [RecurrenceException] = NULL
	, [IsAllDay] = sc.dia_completo
	, [Campo1] = 'Pruebas pruebas'

	, [MedicoOrdenante] = ISNULL(sto.nombre, '')
	, [MedicoOrdenanteCodigo] = ISNULL(sto.codigo, '')

	, [Files] = (
		'['
		+ ISNULL((
			SELECT
				(
					CASE
						WHEN ROW_NUMBER() OVER (ORDER BY sca.nombre) > 1 THEN ','
						ELSE ''
					END
				)
				+ '{'
				+ 'name:"' + sca.nombre + '",'
				+ 'size:' + LTRIM(RTRIM(STR(sca.tamano))) + ','
				+ 'extension:"' + sca.extension + '",'
				+ 'locationUrl:"' + '/Calendar/GetFile?fileuid=' + sca.archivo_uid + '",'
				+ 'icon:"' + sca.icono + '",'
				+ 'uid:"' + sca.archivo_uid + '"'
				+ '}'
			FROM
				ew_ser_calendario_archivos AS sca
			WHERE
				sca.idevento = sc.idevento
			ORDER BY
				sca.nombre
			FOR XML PATH('')
		), '')
		+ ']'
	)
FROM
	ew_ser_calendario AS sc
	LEFT JOIN ew_articulos_niveles AS f
		ON f.nivel = 1
		AND f.codigo = sc.familia_codigo
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = sc.idcliente
	LEFT JOIN ew_ser_tecnicos AS sto
		ON sto.idtecnico = sc.idtecnico_ordenante
WHERE
	sc.cancelado = 0
GO
