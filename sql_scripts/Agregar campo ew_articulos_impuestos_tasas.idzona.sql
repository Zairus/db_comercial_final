USE db_comercial_final

ALTER TABLE [dbo].[ew_articulos_impuestos_tasas]
DROP CONSTRAINT [PK_ew_articulos_impuestos_tasas]

IF NOT EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID('ew_articulos_impuestos_tasas') AND [name] = 'idzona')
BEGIN
	ALTER TABLE [dbo].[ew_articulos_impuestos_tasas] ADD idzona INT NOT NULL DEFAULT 0
END

ALTER TABLE [dbo].[ew_articulos_impuestos_tasas] 
ADD CONSTRAINT [PK_ew_articulos_impuestos_tasas] PRIMARY KEY CLUSTERED 
(
	[idarticulo] ASC
	, [idtasa] ASC
	, [idzona] ASC
) WITH (
	PAD_INDEX = OFF
	, STATISTICS_NORECOMPUTE = OFF
	, SORT_IN_TEMPDB = OFF
	, IGNORE_DUP_KEY = OFF
	, ONLINE = OFF
	, ALLOW_ROW_LOCKS = ON
	, ALLOW_PAGE_LOCKS = ON
) ON [PRIMARY]
