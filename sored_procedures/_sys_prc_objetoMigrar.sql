USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160514
-- Description:	Migrar objeto de sistema
-- =============================================
ALTER PROCEDURE _sys_prc_objetoMigrar
	@codigo_origen AS VARCHAR(5)
	,@codigo_destino AS VARCHAR(5)
AS

SET NOCOUNT ON

DECLARE
	@objeto_origen AS INT
	,@objeto_destino AS INT

SELECT @objeto_origen = objeto FROM objetos WHERE codigo = @codigo_origen
SELECT @objeto_destino = objeto FROM objetos WHERE codigo = @codigo_destino

IF @objeto_origen IS NULL
BEGIN
	RAISERROR('Error: El objeto de origen no existe.', 16, 1)
	RETURN
END

IF @objeto_destino IS NULL
BEGIN
	RAISERROR('Error: El objeto de destino no existe.', 16, 1)
	RETURN
END

INSERT INTO objetos_acciones (
	[objeto]
	,[codigo]
	,[orden]
	,[caption]
	,[enabled]
	,[visible]
	,[save]
	,[datatype]
	,[default]
	,[command]
	,[when]
	,[password]
	,[password2]
	,[confirmation]
	,[tooltip]
	,[ignore]
)
SELECT
	[objeto] = @objeto_destino
	,[codigo]
	,[orden]
	,[caption]
	,[enabled]
	,[visible]
	,[save]
	,[datatype]
	,[default]
	,[command]
	,[when]
	,[password]
	,[password2]
	,[confirmation]
	,[tooltip]
	,[ignore]
FROM
	objetos_acciones
WHERE
	objeto = @objeto_origen

INSERT INTO objetos_botones (
	[objeto]
	,[codigo]
	,[caption]
	,[enabled]
	,[visible]
	,[command]
	,[commandedit]
	,[when]
	,[password]
	,[procedure]
	,[procedure2]
	,[error]
	,[default]
	,[tooltip]
)
SELECT
	[objeto] = @objeto_destino
	,[codigo]
	,[caption]
	,[enabled]
	,[visible]
	,[command]
	,[commandedit]
	,[when]
	,[password]
	,[procedure]
	,[procedure2]
	,[error]
	,[default]
	,[tooltip]
FROM
	objetos_botones
WHERE
	objeto = @objeto_origen

INSERT INTO objetos_columnas (
	[objeto]
	,[grid]
	,[codigo]
	,[orden]
	,[caption]
	,[visible]
	,[save]
	,[findkey]
	,[enabled]
	,[edit]
	,[when]
	,[datatype]
	,[command]
	,[commandtmp]
	,[validation]
	,[isnumeric]
	,[default]
	,[f1]
	,[script]
	,[ctrlenter]
	,[tables]
	,[format]
	,[editmask]
	,[fontcolor]
	,[fontname]
	,[fontsize]
	,[fontbold]
	,[fontitalic]
	,[total]
	,[width]
	,[autosize]
	,[capture]
	,[autofill]
	,[ascfill]
	,[oneedit]
	,[frozen]
	,[clone]
	,[procedure]
	,[procedure2]
	,[noprocedure]
	,[tag]
	,[visiblewhen]
	,[tooltip]
	,[idhelp]
	,[alignment]
)
SELECT
	[objeto] = @objeto_destino
	,[grid]
	,[codigo]
	,[orden]
	,[caption]
	,[visible]
	,[save]
	,[findkey]
	,[enabled]
	,[edit]
	,[when]
	,[datatype]
	,[command]
	,[commandtmp]
	,[validation]
	,[isnumeric]
	,[default]
	,[f1]
	,[script]
	,[ctrlenter]
	,[tables]
	,[format]
	,[editmask]
	,[fontcolor]
	,[fontname]
	,[fontsize]
	,[fontbold]
	,[fontitalic]
	,[total]
	,[width]
	,[autosize]
	,[capture]
	,[autofill]
	,[ascfill]
	,[oneedit]
	,[frozen]
	,[clone]
	,[procedure]
	,[procedure2]
	,[noprocedure]
	,[tag]
	,[visiblewhen]
	,[tooltip]
	,[idhelp]
	,[alignment]
FROM
	objetos_columnas
WHERE
	objeto = @objeto_origen

INSERT INTO db_comercial.dbo.evoluware_objetos_conceptos (
	objeto
	,idconcepto
	,contabilidad
)
SELECT
	[objeto] = @objeto_destino
	,idconcepto
	,contabilidad
FROM
	db_comercial.dbo.evoluware_objetos_conceptos
WHERE
	objeto = @objeto_origen

INSERT INTO objetos_datos_global (
	[objeto]
	,[grupo]
	,[codigo]
	,[valor]
	,[orden]
)
SELECT
	[objeto] = @objeto_destino
	,[grupo]
	,[codigo]
	,[valor]
	,[orden]
FROM
	objetos_datos_global
WHERE
	objeto = @objeto_origen

INSERT INTO objetos_datos_local (
	[objeto]
	,[grupo]
	,[codigo]
	,[valor]
	,[orden]
)
SELECT
	[objeto] = @objeto_destino
	,[grupo]
	,[codigo]
	,[valor]
	,[orden]
FROM
	objetos_datos_local
WHERE
	objeto = @objeto_origen

INSERT INTO db_comercial.dbo.evoluware_objetos_estados (
	objeto
	,idestado
	,nombre
	,comando
	,orden
)
SELECT
	[objeto] = @objeto_destino
	,idestado
	,nombre
	,comando
	,orden
FROM
	db_comercial.dbo.evoluware_objetos_estados
WHERE
	objeto = @objeto_origen

INSERT INTO objetos_grids (
	[objeto]
	,[codigo]
	,[orden]
	,[page]
	,[tables]
	,[gridrefresh]
	,[fontname]
	,[fontsize]
	,[total]
	,[totrows]
	,[rowheight]
	,[browser]
	,[gridheader]
	,[sorteable]
	,[niveles]
	,[niveles_col]
	,[niveles_pos]
	,[sql_field]
	,[sql_field2]
	,[sql_select]
	,[sql_filter]
	,[sql_caption]
	,[appearance]
	,[border]
	,[dataview]
	,[can_add]
	,[can_edit]
	,[can_del]
	,[frozen]
	,[visible]
	,[gridheight]
	,[headerheight]
)
SELECT
	[objeto] = @objeto_destino
	,[codigo]
	,[orden]
	,[page]
	,[tables]
	,[gridrefresh]
	,[fontname]
	,[fontsize]
	,[total]
	,[totrows]
	,[rowheight]
	,[browser]
	,[gridheader]
	,[sorteable]
	,[niveles]
	,[niveles_col]
	,[niveles_pos]
	,[sql_field]
	,[sql_field2]
	,[sql_select]
	,[sql_filter]
	,[sql_caption]
	,[appearance]
	,[border]
	,[dataview]
	,[can_add]
	,[can_edit]
	,[can_del]
	,[frozen]
	,[visible]
	,[gridheight]
	,[headerheight]
FROM
	objetos_grids
WHERE
	objeto = @objeto_origen

INSERT INTO objetos_prepolizas (
	[objeto]
	,[codigo]
	,[estatus]
	,[procedure]
	,[when]
)
SELECT
	[objeto] = @objeto_destino
	,[codigo]
	,[estatus]
	,[procedure]
	,[when]
FROM
	objetos_prepolizas
WHERE
	objeto = @objeto_origen

INSERT INTO objetos_procedimientos (
	[objeto]
	,[codigo]
	,[command]
	,[grids]
	,[errormsg]
)
SELECT
	[objeto] = @objeto_destino
	,[codigo]
	,[command]
	,[grids]
	,[errormsg]
FROM
	objetos_procedimientos
WHERE
	objeto = @objeto_origen

INSERT INTO objetos_scripts (
	[objeto]
	,[codigo]
	,[valor]
)
SELECT
	[objeto] = @objeto_destino
	,[codigo]
	,[valor]
FROM
	objetos_scripts
WHERE
	objeto = @objeto_origen

INSERT INTO objetos_subtotales (
	[objeto]
	,[codigo]
	,[orden]
	,[caption]
	,[groupon]
	,[operation]
	,[totalon]
	,[format]
	,[fontcolor]
	,[fontbold]
	,[backcolor]
	,[totalonly]
)
SELECT
	[objeto] = @objeto_destino
	,[codigo]
	,[orden]
	,[caption]
	,[groupon]
	,[operation]
	,[totalon]
	,[format]
	,[fontcolor]
	,[fontbold]
	,[backcolor]
	,[totalonly]
FROM
	objetos_subtotales
WHERE
	objeto = @objeto_origen

INSERT INTO objetos_tablas (
	[objeto]
	,[codigo]
	,[orden]
	,[tablename]
	,[idkey]
	,[findkey]
	,[cargardoc]
	,[cargarref]
	,[procedure]
	,[procedure2]
	,[readonly]
	,[SQLInsertInto]
)
SELECT
	[objeto] = @objeto_destino
	,[codigo]
	,[orden]
	,[tablename]
	,[idkey]
	,[findkey]
	,[cargardoc]
	,[cargarref]
	,[procedure]
	,[procedure2]
	,[readonly]
	,[SQLInsertInto]
FROM
	objetos_tablas
WHERE
	objeto = @objeto_origen
GO
