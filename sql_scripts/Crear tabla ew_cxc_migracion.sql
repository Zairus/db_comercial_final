USE db_comercial_final

IF OBJECT_ID('_tmp_cxc_carga') IS NOT NULL
BEGIN
	DROP TABLE _tmp_cxc_carga
END

IF OBJECT_ID('ew_cxc_migracion') IS NOT NULL
BEGIN
	DROP TABLE ew_cxc_migracion
END

CREATE TABLE [dbo].[ew_cxc_migracion] (
	[idr] [int] IDENTITY(1,1) NOT NULL,
	[folio] [varchar](15) NOT NULL DEFAULT (''),
	[fecha] [smalldatetime] NOT NULL DEFAULT (getdate()),
	[idcliente] [smallint] NOT NULL DEFAULT ((0)),
	[codcliente] [varchar](30) NOT NULL DEFAULT (''),
	[vencimiento] [smalldatetime] NOT NULL  DEFAULT (getdate()),
	[idmoneda] [smallint] NOT NULL DEFAULT ((0)),
	[saldo] [decimal](18, 6) NOT NULL DEFAULT ((0)),
	[importe] [decimal](18, 6) NOT NULL DEFAULT ((0)),
	[impuesto1] [decimal](18, 6) NOT NULL DEFAULT ((0)),
	[impuesto2] [decimal](18, 6) NOT NULL DEFAULT ((0)),
	[impuesto3] [decimal](18, 6) NOT NULL DEFAULT ((0)),
	[impuesto4] [decimal](18, 6) NOT NULL DEFAULT ((0)),
 CONSTRAINT [PK__tmp_cxc_carga] PRIMARY KEY CLUSTERED 
(
	[folio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

SELECT * FROM ew_cxc_migracion
