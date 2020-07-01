USE db_comercial_final

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_tablaAgregarCampo]
	@tabla = 'ew_articulos_niveles'
	, @campo = 'tipo'
	, @campo_tipo = 'INT'
	, @campo_null = 0
	, @campo_default = '0'

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_tablaAgregarCampo]
	@tabla = 'ew_articulos_niveles'
	, @campo = 'activo'
	, @campo_tipo = 'BIT'
	, @campo_null = 0
	, @campo_default = '1'
