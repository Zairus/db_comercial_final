USE db_comercial_final
GO
IF OBJECT_ID('_sys_prc_menuXml') IS NOT NULL
BEGIN
	DROP PROCEDURE _sys_prc_menuXml
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190624
-- Description:	Cadena XML del Menu de Sistema
-- =============================================
CREATE PROCEDURE [dbo].[_sys_prc_menuXml]
	@usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @return_text AS BIT = 1
AS

DECLARE
	@menu_xml AS XML

SELECT
	@menu_xml = g.XML
FROM
	(
		SELECT
			'1.0' AS '@version'
			, (
				SELECT
					(
						SELECT
							m.nombre AS '@Name'
							, m.codigo AS '@Code'
							, 'Home' AS '@Controller'
							, '' AS '@Action'
							, '' AS '@Url'
							, '' AS '@IconClass'
							, 'MAIN' AS '@MenuType'
							, (
								SELECT
									sm.nombre AS '@Name'
									, sm.codigo AS '@Code'
									, 'Home' AS '@Controller'
									, '' AS '@Action'
									, sm.url AS '@Url'
									, '' AS '@IconClass'
									, sm.tipo AS '@MenuType'
									, (
										SELECT
											sm_o1.nombre AS '@Name'
											, sm_o1.codigo AS '@Code'
											, 'Home' AS '@Controller'
											, '' AS '@Action'
											, (
												CASE sm_o1.tipo
													WHEN 'AUX' THEN '/Report?Obj=' + sm_o1.codigo
													WHEN 'CAT' THEN '/Operation?Obj=' + sm_o1.codigo
													WHEN 'XAC' THEN '/Operation?Obj=' + sm_o1.codigo
												END
											) AS '@Url'
											, '' AS '@IconClass'
											, sm_o1.tipo AS '@MenuType'
										FROM
											ew_sys_objetos_empresa AS oe1
											LEFT JOIN objetos AS sm_o1
												ON sm_o1.objeto = oe1.objeto
										WHERE
											sm_o1.visible = 1
											AND sm_o1.menu = m.menu
											AND sm_o1.submenu > 0
											AND sm_o1.submenu = sm.submenu
										FOR XML PATH('MenuNode'), TYPE
									) AS '*'
								FROM
									(
										SELECT
											[nombre] = sm_o.nombre
											, [codigo] = sm_o.codigo
											, [url] = (
												CASE sm_o.tipo
													WHEN 'AUX' THEN '/Report?Obj=' + sm_o.codigo
													WHEN 'CAT' THEN '/Operation?Obj=' + sm_o.codigo
													WHEN 'XAC' THEN '/Operation?Obj=' + sm_o.codigo
												END
											)
											, [tipo] = sm_o.tipo
											, [orden1] = 1
											, [orden2] = sm_o.orden

											, [submenu] = 0
										FROM 
											ew_sys_objetos_empresa AS oe
											LEFT JOIN objetos AS sm_o
												ON sm_o.objeto = oe.objeto
										WHERE
											sm_o.visible = 1
											AND sm_o.submenu = 0
											AND sm_o.menu = m.menu

										UNION ALL

										SELECT
											[nombre] = sm1.nombre
											, [codigo] = sm1.codigo
											, [url] = ''
											, [tipo] = 'SUB'
											, [orden1] = 2
											, [orden2] = sm1.orden

											, [submenu] = sm1.submenu
										FROM 
											evoluware_menus AS sm1
										WHERE
											sm1.activo = 1
											AND sm1.submenu > 0
											AND sm1.menu = m.menu
									) AS sm
								ORDER BY
									[sm].[orden1]
									, [sm].[orden2]
								FOR XML PATH('MenuNode'), TYPE
							) AS '*'
						FROM
							evoluware_menus AS m
						WHERE
							m.activo = 1
							AND m.submenu = 0
						ORDER BY
							m.orden
						FOR XML PATH('MenuNode'), TYPE
					) AS '*'
				FOR XML PATH('MenuNode'), TYPE
			) AS '*'
		FOR XML PATH('Menu'), TYPE
	) AS g(XML)

IF @return_text = 1
BEGIN
	SELECT [menu_xml] = CONVERT(VARCHAR(MAX), @menu_xml)
END
	ELSE
BEGIN
	SELECT [menu_xml] = @menu_xml
END
GO
