USE db_comercial_final
GO
IF OBJECT_ID('ew_sys_departamentos') IS NOT NULL
BEGIN
	DROP TABLE ew_sys_departamentos
END
GO
CREATE TABLE [dbo].[ew_sys_departamentos] (
	[idr] [smallint] IDENTITY(1,1) NOT NULL,
	[iddepartamento] [smallint] NOT NULL,
	[nombre] [varchar](200) NOT NULL,
	[nombre_corto] [varchar](50) NOT NULL,
	[idsucursal] [smallint] NOT NULL,
	[porcentaje] [smallint] NOT NULL,
 CONSTRAINT [PK_ew_sys_departamentos] PRIMARY KEY CLUSTERED 
(
	[iddepartamento] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ew_sys_departamentos] ADD  CONSTRAINT [DF_ew_sys_departamentos_nombre]  DEFAULT ('') FOR [nombre]
GO
ALTER TABLE [dbo].[ew_sys_departamentos] ADD  CONSTRAINT [DF_ew_sys_departamentos_nombre_corto]  DEFAULT ('') FOR [nombre_corto]
GO
ALTER TABLE [dbo].[ew_sys_departamentos] ADD  CONSTRAINT [DF_ew_sys_departamentos_idsucursal]  DEFAULT ((0)) FOR [idsucursal]
GO
ALTER TABLE [dbo].[ew_sys_departamentos] ADD  CONSTRAINT [DF_ew_sys_departamentos_porcentaje]  DEFAULT ((0)) FOR [porcentaje]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Departamentos de la empresa' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ew_sys_departamentos'
GO
