USE db_comercial_final
GO
IF OBJECT_ID('ew_cfd_comprobantes_xml') IS NOT NULL
BEGIN
	DROP TABLE ew_cfd_comprobantes_xml
END
GO
CREATE TABLE ew_cfd_comprobantes_xml (
	idr INT IDENTITY
	,uuid VARCHAR(50)
	,xml_base64 VARCHAR(MAX)
	,xml_cfdi XML
	,xml_modificado XML

	,CONSTRAINT [PK_ew_cfd_comprobantes_xml] PRIMARY KEY CLUSTERED (
		[uuid] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO

SELECT * FROM ew_cfd_comprobantes_xml