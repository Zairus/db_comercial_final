USE db_comercial_final
GO

IF OBJECT_ID('[dbo].[ew_cxc_transacciones_rel]') IS NOT NULL
BEGIN
	GOTO DONE
END

CREATE TABLE [dbo].[ew_cxc_transacciones_rel](
	[idr] [int] IDENTITY(1,1) NOT NULL,
	[idtran] [int] NOT NULL,
	[idtran2] [int] NOT NULL,
	[idmov] [money] NULL,
	[saldo] [decimal](18, 6) NOT NULL,
	[comentario] [text] NOT NULL,
 CONSTRAINT [PK_ew_cxc_transacciones_rel] PRIMARY KEY CLUSTERED 
(
	[idtran] ASC,
	[idtran2] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[ew_cxc_transacciones_rel] ADD  CONSTRAINT [DF_ew_cxc_transacciones_rel_saldo]  DEFAULT ((0)) FOR [saldo]

ALTER TABLE [dbo].[ew_cxc_transacciones_rel] ADD  CONSTRAINT [DF_ew_cxc_transacciones_rel_comentario]  DEFAULT ('') FOR [comentario]

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de registro' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_cxc_transacciones_rel', @level2type=N'COLUMN',@level2name=N'idr'

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de transacción' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_cxc_transacciones_rel', @level2type=N'COLUMN',@level2name=N'idtran'

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de transacción a la que se hace referencia' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_cxc_transacciones_rel', @level2type=N'COLUMN',@level2name=N'idtran2'

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificador de movimientos' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_cxc_transacciones_rel', @level2type=N'COLUMN',@level2name=N'idmov'

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Relación de documentos de CXC' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_cxc_transacciones_rel'

DONE:
