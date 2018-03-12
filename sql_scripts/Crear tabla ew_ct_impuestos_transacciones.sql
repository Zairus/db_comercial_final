USE [db_comercial_final]
GO
IF OBJECT_ID('ew_ct_impuestos_transacciones') IS NOT NULL
BEGIN
	GOTO TABLE_EXISTS
END

CREATE TABLE [dbo].[ew_ct_impuestos_transacciones] (
	[idr] [int] IDENTITY(1,1) NOT NULL
	,[idtran] [int] NOT NULL
	,[idmov] [money] NOT NULL
	,[idtasa] [int] NOT NULL
	,[base] [decimal](18, 6) NOT NULL
	,[importe] [decimal](18, 6) NOT NULL
	CONSTRAINT [PK_ew_ct_impuestos_transacciones] PRIMARY KEY CLUSTERED (
		[idtran] ASC
		,[idmov] ASC
		,[idtasa] ASC
	) WITH (
		PAD_INDEX = OFF
		, STATISTICS_NORECOMPUTE = OFF
		, IGNORE_DUP_KEY = OFF
		, ALLOW_ROW_LOCKS = ON
		, ALLOW_PAGE_LOCKS = ON
	) ON [PRIMARY]
) ON [PRIMARY]

TABLE_EXISTS: