USE db_comercial_final
GO

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_tablaAgregarCampo]
	@tabla = 'ew_ven_documentos_mov'
	, @campo = 'idimpuesto1_ret'
	, @campo_tipo = 'INT'
	, @campo_null = 0
	, @campo_default = '0'
GO

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_tablaAgregarCampo]
	@tabla = 'ew_ven_documentos_mov'
	, @campo = 'idimpuesto1_ret_valor'
	, @campo_tipo = 'DECIMAL(18, 6)'
	, @campo_null = 0
	, @campo_default = '0'
GO

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_tablaAgregarCampo]
	@tabla = 'ew_ven_documentos_mov'
	, @campo = 'impuesto1_ret'
	, @campo_tipo = 'DECIMAL(18, 6)'
	, @campo_null = 0
	, @campo_default = '0'
GO

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_tablaAgregarCampo]
	@tabla = 'ew_ven_documentos_mov'
	, @campo = 'idimpuesto2_ret'
	, @campo_tipo = 'INT'
	, @campo_null = 0
	, @campo_default = '0'
GO

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_tablaAgregarCampo]
	@tabla = 'ew_ven_documentos_mov'
	, @campo = 'idimpuesto2_ret_valor'
	, @campo_tipo = 'DECIMAL(18, 6)'
	, @campo_null = 0
	, @campo_default = '0'
GO

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_tablaAgregarCampo]
	@tabla = 'ew_ven_documentos_mov'
	, @campo = 'impuesto2_ret'
	, @campo_tipo = 'DECIMAL(18, 6)'
	, @campo_null = 0
	, @campo_default = '0'
GO
