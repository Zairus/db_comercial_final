USE db_comercial_final
GO
ALTER TABLE [dbo].[ew_cfd_comprobantes_impuesto] DROP CONSTRAINT [PK_ew_cfd_comprobantes_impuesto]
GO
ALTER TABLE [dbo].[ew_cfd_comprobantes_impuesto] ADD CONSTRAINT [PK_ew_cfd_comprobantes_impuesto] PRIMARY KEY CLUSTERED 
(
	[idtran] ASC,
	[idtipo] ASC,
	[cfd_impuesto] ASC,
	[cfd_tasa] ASC
) WITH (
	PAD_INDEX = OFF
	, STATISTICS_NORECOMPUTE = OFF
	, SORT_IN_TEMPDB = OFF
	, IGNORE_DUP_KEY = OFF
	, ONLINE = OFF
	, ALLOW_ROW_LOCKS = ON
	, ALLOW_PAGE_LOCKS = ON
) ON [PRIMARY]
GO
