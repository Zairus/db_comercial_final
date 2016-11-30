USE db_comercial_final
GO
IF OBJECT_ID('ew_ven_viasEmbarque') IS NOT NULL
BEGIN
	DROP TABLE ew_ven_viasEmbarque
END
GO
CREATE TABLE [dbo].[ew_ven_viasEmbarque] (
	[idr] [smallint] IDENTITY(1,1) NOT NULL,
	[idviaembarque] [smallint] NOT NULL,
	[codigo] [varchar](10) NOT NULL,
	[nombre] [varchar](60) NOT NULL,
	[direccion] [varchar](50) NOT NULL,
	[ciudad] [varchar](60) NOT NULL,
	[telefono1] [varchar](20) NOT NULL,
	[telefono2] [varchar](20) NOT NULL,
	[fax] [varchar](20) NOT NULL,
	[email] [varchar](60) NOT NULL,
	[encargado] [varchar](60) NOT NULL,
 CONSTRAINT [PK_ew_ven_viasEmbarque] PRIMARY KEY CLUSTERED 
(
	[idviaembarque] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Vías de embarque para la empresa' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_ven_viasEmbarque'
GO
