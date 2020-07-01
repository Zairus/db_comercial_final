USE db_comercial_final

ALTER TABLE [dbo].[ew_articulos] DROP CONSTRAINT [DF_ew_articulos_nivel0]
ALTER TABLE [dbo].[ew_articulos] DROP CONSTRAINT [DF_ew_articulos_nivel1]
ALTER TABLE [dbo].[ew_articulos] DROP CONSTRAINT [DF_ew_articulos_nivel2]
ALTER TABLE [dbo].[ew_articulos] DROP CONSTRAINT [DF_ew_articulos_nivel3]

ALTER TABLE ew_articulos ALTER COLUMN nivel0 VARCHAR(30) NOT NULL
ALTER TABLE ew_articulos ALTER COLUMN nivel1 VARCHAR(30) NOT NULL
ALTER TABLE ew_articulos ALTER COLUMN nivel2 VARCHAR(30) NOT NULL
ALTER TABLE ew_articulos ALTER COLUMN nivel3 VARCHAR(30) NOT NULL

ALTER TABLE [dbo].[ew_articulos] ADD  CONSTRAINT [DF_ew_articulos_nivel0]  DEFAULT ('') FOR [nivel0]
ALTER TABLE [dbo].[ew_articulos] ADD  CONSTRAINT [DF_ew_articulos_nivel1]  DEFAULT ('') FOR [nivel1]
ALTER TABLE [dbo].[ew_articulos] ADD  CONSTRAINT [DF_ew_articulos_nivel2]  DEFAULT ('') FOR [nivel2]
ALTER TABLE [dbo].[ew_articulos] ADD  CONSTRAINT [DF_ew_articulos_nivel3]  DEFAULT ('') FOR [nivel3]
