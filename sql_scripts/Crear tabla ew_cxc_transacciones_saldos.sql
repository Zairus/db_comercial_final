USE db_comercial_final
GO
IF OBJECT_ID('ew_cxc_transacciones_saldos') IS NOT NULL
BEGIN
	DROP TABLE ew_cxc_transacciones_saldos
END
GO
CREATE TABLE [dbo].[ew_cxc_transacciones_saldos] (
	[idr] [int] IDENTITY(1,1) NOT NULL,
	[idtran] [int] NOT NULL,
	[fecha] [smalldatetime] NOT NULL,
	[saldo] [decimal](18, 6) NOT NULL,
	[idmov2] [money] NOT NULL,
	[transaccion] [varchar](5) NOT NULL,
	CONSTRAINT [PK_ew_cxc_transacciones_saldos] PRIMARY KEY CLUSTERED (
		[idtran] ASC,
		[fecha] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ew_cxc_transacciones_saldos] ADD  CONSTRAINT [DF_ew_cxc_transacciones_saldos_saldo]  DEFAULT ((0)) FOR [saldo]
GO
ALTER TABLE [dbo].[ew_cxc_transacciones_saldos] ADD  DEFAULT ('') FOR [transaccion]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Saldos de transacciones CXC' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_cxc_transacciones_saldos'
GO
